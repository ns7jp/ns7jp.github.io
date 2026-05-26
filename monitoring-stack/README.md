# Monitoring Stack — Metrics + Logs + Verified Alert Delivery (Lab)

自宅検証VMや評価Linux 1台に立てられる、**観測性 (Observability) の Metrics + Logs と通知経路を検証するスタック**です。`docker compose up -d` で Prometheus / Grafana / node_exporter / Loki / Promtail に加え、blackbox_exporter / Alertmanager / 検証用 HTTP target / webhook receiver が起動します。Grafana を開けば

- **メトリクス**: CPU / メモリ / ディスク / Load / ネットワーク（Node Overview ダッシュボード）
- **ログ**: syslog / journald / Docker コンテナログ + SSH 認証ログ（Logs Overview ダッシュボード）
- **外形監視**: HTTP probe の `probe_success` と `LabProbeTargetDown` アラート
- **通知実証**: Alertmanager が firing / resolved をローカル webhook に配送

を確認できます。Traces、外部通知先、認証、Windows exporter は本番化差分として扱います。

> 自作の Flask サーバー監視ダッシュボードと、既存の監視スタックの両方に触れていることを示すための Lab です。本番運用ではない検証用構成のため、認証・TLS・外部通知・スケーリングは対象外です。

![Grafana ダッシュボード「Node Overview (Lab)」のレイアウト概念図。CPU 使用率 23.4%, メモリ使用率 78.1%（warning しきい値超過）, ディスク空き 42.6% の Stat パネル 3 枚、Load average (1/5/15) と ネットワーク受信 (bytes/s) の time-series 2 枚、下部に HostHighMemory アラートのバナー。](../image/grafana-dashboard.svg)

---

## 構成

| コンテナ | 役割 | 公開ポート |
|---|---|---|
| `prom/prometheus:v2.54.1` | メトリクス収集、アラート評価 | `9090` |
| `prom/node-exporter:v1.8.2` | ホストの CPU/メモリ/ディスク/ネット 指標を公開 | `9100` (host network) |
| `grafana/grafana:11.2.0` | ダッシュボード表示 (Metrics + Logs を統合 UI で表示) | `3000` |
| `grafana/loki:3.2.0` | ★ ログ集約 (LogQL で検索可能) | `3100` |
| `grafana/promtail:3.2.0` | ★ /var/log + journal + Docker ログ を Loki へ送信 | `9080` |
| `prom/blackbox-exporter:v0.28.0` | 検証用 HTTP ターゲットの外形監視 | `9115` |
| `prom/alertmanager:v0.27.0` | アラートのグルーピングと webhook 配送 | `9093` |
| `nginx:1.27-alpine` | 障害注入で停止する検証用 HTTP ターゲット | 内部のみ |
| `python:3.12-alpine` | Alertmanager 配送を記録する webhook receiver | `18080` |

```
+-------------+  /probe   +----------+       +-------------+
| Prometheus  |----------->| blackbox |------>| probe-target|
| 9090        |            | exporter | HTTP  | nginx       |
+------+------+            +----------+       +-------------+
       | alert                                      ^ stop/start
       v                                            |
+------+-------+ webhook  +------------------+     | CI drill
| Alertmanager |--------->| webhook-receiver |<----+
+--------------+          +------------------+

node_exporter ---- metrics ----> Prometheus ---- datasource ----> Grafana
Promtail --------- logs -------> Loki ---------- datasource ----> Grafana
```

---

## 起動方法

```bash
cd monitoring-stack
docker compose up -d
```

ブラウザで以下を開きます。

- Prometheus: http://localhost:9090
- Grafana:    http://localhost:3000  （admin / changeme）
- Loki:       http://localhost:3100  （/ready で疎通確認）
- Alertmanager: http://localhost:9093
- blackbox_exporter: http://localhost:9115

Grafana 左メニュー > Dashboards > Lab に、以下 2 種のダッシュボードが自動登録されます。

- **Node Overview (Lab)** — CPU / メモリ / ディスク / Load / ネットワーク（Prometheus）
- **Logs Overview (Lab)** — syslog / journal / SSH 認証 / Docker コンテナログ（Loki）

---

## ファイル構成

```
monitoring-stack/
├── docker-compose.yml          ... 監視・外形 probe・通知検証サービス
├── prometheus/
│   ├── prometheus.yml          ... スクレイプ設定
│   └── alert.rules.yml         ... ホスト4アラート + HTTP probe SLI / alert
├── blackbox/
│   └── blackbox.yml            ... HTTP 2xx 外形監視 module
├── alertmanager/
│   └── alertmanager.yml        ... Lab webhook への配送経路
├── loki/
│   └── loki-config.yml         ... ★ Loki シングルバイナリ設定 (filesystem / 7日リテンション)
├── promtail/
│   └── promtail-config.yml     ... ★ /var/log + journal + Docker ログ収集
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── prometheus.yml          ... Prometheus + Loki を起動時に自動登録
        └── dashboards/
            ├── dashboards.yml          ... ダッシュボード読込設定
            ├── node-overview.json      ... 4パネル構成のメトリクスダッシュボード
            └── logs-overview.json      ... ★ ログ件数 / SSH 認証失敗 / severity 別ストリーム
```

---

## アラートの考え方

`alert.rules.yml` にはホスト監視 4 本と、障害注入可能な外形監視 1 本を書いています。

| アラート名 | 条件 | 重大度 | 想定アクション |
|---|---|---|---|
| `HostHighCpu` | CPU使用率 > 85% が10分継続 | warning | プロセス上位を確認、bashトリアージ実行 |
| `HostHighMemory` | available < 10% が15分継続 | warning | OOM兆候とswap傾向を確認 |
| `HostLowDisk` | 空き < 10% が10分継続 | critical | logrotate / 古いバックアップを精査 |
| `NodeExporterDown` | up{job="node"} == 0 が5分継続 | critical | サーバー疎通とサービス状態を確認 |
| `LabProbeTargetDown` | `probe_success == 0` が30秒継続 | critical | [Verified Lab Runbook](https://ns7jp.github.io/verified-lab/runbook.html) に沿って復旧 |

Lab では **Alertmanager -> webhook receiver** の配送を実装し、GitHub Actions で firing / resolved の両方を確認します。実運用では通知先（メール / Slack / Teams）、認証、抑止、エスカレーションを環境ごとに定義します。

---

## ログ検索の例 (LogQL)

Grafana > Explore で Loki を選び、以下のクエリで現場と同じ調査ができます。

| 目的 | LogQL クエリ |
|---|---|
| 直近 1h の error / fail / critical を全ホストから抽出 | `{host=~".+"} |~ "(?i)error|fail|critical"` |
| SSH 認証失敗の発生元 IP を集計 | `sum by (host) (count_over_time({unit="ssh.service"} |~ "Failed password" [1h]))` |
| Docker コンテナごとの直近エラー | `{container=~".+"} |~ "(?i)error" | json` |
| systemd ユニット単位で warning 以上 | `{severity=~"warning|err|crit"} | json | unit=~".+"` |
| ある時刻周辺のログを host で絞り込み | `{host="lab-host-01"} \| line_format "{{.message}}"` |

メトリクス側で「CPU が跳ねた瞬間」を見つけ、Grafana の derivedFields 連携で**同じホスト・同じ時刻のログにワンクリック遷移**できます。

---

## 観測性 (Observability) と SLO

- このスタックが**観測性の二本柱 (Metrics + Logs)** を提供
- [SLO / Error Budget](https://ns7jp.github.io/support-docs/slo-error-budget.html) で、観測したデータから**運用品質を数値化**
- [Verified Infrastructure Lab](../verified-lab/) で、`probe_success` の失敗から Alertmanager 配送と復旧までを自動実証
- 本番化差分は [Production Readiness](https://ns7jp.github.io/production-readiness.html) を参照

---

## ポートフォリオでの位置づけ

- **自作 Flask 監視ダッシュボード** ([ns7jp/server-monitor](https://github.com/ns7jp/server-monitor)) は **psutil の挙動とAPI設計の学習** が目的
- **このスタック** は **既存運用に合流できる "業界標準" を扱える** ことを示すのが目的
- Metrics (Prometheus) と Logs (Loki) を**同一 UI から横断検索**でき、HTTP 外形監視の障害を通知経路へ流せる構成にする
- 両方を同じポートフォリオ上に並べることで、自作と既製の **棲み分けを理解している** ことを伝える

---

## 注意

- ポートフォリオ用の最小構成です。`GF_SECURITY_ADMIN_PASSWORD=changeme` を変更せずに公開ホストへ展開しないでください。
- node_exporter は `network_mode: host` でホストネットワーク上の :9100 に公開し、Prometheus 側は `host.docker.internal:9100` で読み取ります。Linux Docker Engine では `host.docker.internal` が自動解決されないため、Prometheus 側に `extra_hosts: "host.docker.internal:host-gateway"` を入れて両環境（Linux / Docker Desktop）で同じ設定が動くようにしています（Docker 20.10+）。
- 永続化ボリュームは `prometheus_data` / `grafana_data` です。再構築時は `docker compose down -v` で初期化できます。
- `docker compose config` / `promtool check config/rules` / `loki -verify-config` / `promtail -check-syntax` / Alertmanager / blackbox config を CI で自動検証しています（[infra-check.yml](../.github/workflows/infra-check.yml)）。
- [`verified-lab.yml`](../.github/workflows/verified-lab.yml) は構成を起動し、ターゲット停止、アラート配送、復旧、解消通知を実行して artifact に証跡を保存します。

## 検証証跡 / 本番化差分

- [Verified Infrastructure Lab](../verified-lab/) — 実際の障害注入と workflow artifact の読み方
- [Infra Evidence](../infra-evidence/) — 構文検証コマンドとサンプル出力 + [失敗→修正サンプル](../infra-evidence/validation-failure-and-fix.sample.txt)
- [SLO / Error Budget](https://ns7jp.github.io/support-docs/slo-error-budget.html) — このスタックで観測したデータを**運用品質の数値**に落とす設計
- [Production Readiness](https://ns7jp.github.io/production-readiness.html) — 外部通知、認証、秘密情報、バックアップなど、本番化で足す観点
