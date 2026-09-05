# Monitoring Stack — Prometheus + Grafana + Loki + Promtail (Lab / アーカイブ)

> ## ⚠ この構成はアーカイブです（2026-08-23）
>
> **Promtail は 2026-03-02 に EOL** となりました。主作品の
> [server-monitor](https://github.com/ns7jp/server) は収集エージェントを
> **Grafana Alloy** へ移行済みで、Docker socket も直接マウントせず、
> GET / HEAD 限定の専用 proxy 経由に変更しています。
>
> このディレクトリは、そこへ至る前の**初期の学習作品**として履歴を残しているものです。
> 現在の設計として提示しているものではありません。
> 現行の構成はこちらを参照してください。
>
> | 現行 | 場所 |
> | --- | --- |
> | 監視スタック本体（Alloy 版） | [server-monitor `compose.yaml`](https://github.com/ns7jp/server/blob/main/compose.yaml) |
> | 収集エージェントの移行理由 | [server-monitor README「ログ集約」](https://github.com/ns7jp/server#ログ集約) |
> | 実測証跡 | [検証証跡台帳](https://github.com/ns7jp/server/blob/main/docs/evidence/README.md) |
>
> 以下は当時のままの記述です。

自宅検証VMや評価Linux 1台にすぐ立てられる、**観測性 (Observability) の Metrics + Logs を網羅した最小構成スタック**です。`docker compose up -d` だけで Prometheus / Grafana / node_exporter / Loki / Promtail が起動し、Grafana を開けば

- **メトリクス**: CPU / メモリ / ディスク / Load / ネットワーク（Node Overview ダッシュボード）
- **ログ**: syslog / journald / Docker コンテナログ + SSH 認証ログ（Logs Overview ダッシュボード）

の両方が表示されます。Traces は本番化差分で扱うため、Lab では **Metrics + Logs の二本柱** までを対象とします。

> 自作の Flask サーバー監視ダッシュボードと、業界標準のスタックの両方に触れていることを示すための Lab です。本番運用ではない検証用構成のため、認証・TLS・データ永続化・スケーリングは最小限です。

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

```
+----------+    scrape     +-------------+
| node_    |<--------------|  Prometheus |
| exporter |   (15s)       |  9090       |
+----------+               +------+------+
   (host metrics)                 | datasource
                                  v
+----------+    push       +-------+-----+
| Promtail |-------------->|   Grafana   |  <-- 単一 UI で Metrics + Logs
+----+-----+   (HTTP)      |   3000      |
     |                     +------+------+
     | tails                      | datasource
     v                            v
/var/log                    +-----+-----+
journald          push      |   Loki    |
docker logs   ------------->|   3100    |
                            +-----------+
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

Grafana 左メニュー > Dashboards > Lab に、以下 2 種のダッシュボードが自動登録されます。

- **Node Overview (Lab)** — CPU / メモリ / ディスク / Load / ネットワーク（Prometheus）
- **Logs Overview (Lab)** — syslog / journal / SSH 認証 / Docker コンテナログ（Loki）

---

## ファイル構成

```
monitoring-stack/
├── docker-compose.yml          ... 5 サービス (Prom / node_exp / Grafana / Loki / Promtail)
├── prometheus/
│   ├── prometheus.yml          ... スクレイプ設定
│   └── alert.rules.yml         ... アラートルール（CPU/メモリ/ディスク/exporterダウン）
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

`alert.rules.yml` には Lab 用の最小ルールを4本だけ書いています。

| アラート名 | 条件 | 重大度 | 想定アクション |
|---|---|---|---|
| `HostHighCpu` | CPU使用率 > 85% が10分継続 | warning | プロセス上位を確認、bashトリアージ実行 |
| `HostHighMemory` | available < 10% が15分継続 | warning | OOM兆候とswap傾向を確認 |
| `HostLowDisk` | 空き < 10% が10分継続 | critical | logrotate / 古いバックアップを精査 |
| `NodeExporterDown` | up{job="node"} == 0 が5分継続 | critical | サーバー疎通とサービス状態を確認 |

実運用ではここに **アラートマネージャー (Alertmanager)** を足し、しきい値や通知先（メール / Slack / Teams）を環境ごとに分けます。

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
- [SLO / Error Budget](../support-docs/slo-error-budget.md) で、観測したデータから**運用品質を数値化**
- 本番化差分は [Production Readiness](../production-readiness.md) を参照

---

## ポートフォリオでの位置づけ

- **自作 Flask 監視ダッシュボード** ([ns7jp/server-monitor](https://github.com/ns7jp/server)) は **psutil の挙動とAPI設計の学習** が目的
- **このスタック** は **既存運用に合流できる "業界標準" を扱える** ことを示すのが目的
- Metrics (Prometheus) と Logs (Loki) を**同一 UI から横断検索**できる構成にすることで、観測性の三本柱のうち二本を Lab 向けに設計・実装していることを示す（現時点の検証証跡は `docker compose config` / `promtool check` / `loki -verify-config` / `promtail -check-syntax` による**構成・構文検証**まで — 実際に起動した Grafana / Loki の画面キャプチャやアラート発火ログなど、稼働中の実機観測はまだ未取得）
- 両方を同じポートフォリオ上に並べることで、自作と既製の **棲み分けを理解している** ことを伝える

---

## 注意

- ポートフォリオ用の最小構成です。`GF_SECURITY_ADMIN_PASSWORD=changeme` を変更せずに公開ホストへ展開しないでください。
- node_exporter は `network_mode: host` でホストネットワーク上の :9100 に公開し、Prometheus 側は `host.docker.internal:9100` で読み取ります。Linux Docker Engine では `host.docker.internal` が自動解決されないため、Prometheus 側に `extra_hosts: "host.docker.internal:host-gateway"` を入れて両環境（Linux / Docker Desktop）で同じ設定が動くようにしています（Docker 20.10+）。
- 永続化ボリュームは `prometheus_data` / `grafana_data` です。再構築時は `docker compose down -v` で初期化できます。
- `docker compose config` / `promtool check config/rules` / `loki -verify-config` / `promtail -check-syntax` で構文整合性を CI で自動検証しています（[infra-check.yml](../.github/workflows/infra-check.yml)）。

## 検証証跡 / 本番化差分

- [Infra Evidence](../infra-evidence/) — `docker compose config` / `promtool` の検証コマンドとサンプル出力 + [失敗→修正サンプル](../infra-evidence/validation-failure-and-fix.sample.txt)
- [SLO / Error Budget](../support-docs/slo-error-budget.md) — このスタックで観測したデータを**運用品質の数値**に落とす設計
- [Production Readiness](../production-readiness.md) — Alertmanager、通知先、SLO、秘密情報、バックアップなど、本番化で足す観点
