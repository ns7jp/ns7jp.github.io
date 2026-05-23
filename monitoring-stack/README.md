# Monitoring Stack — Prometheus + Alertmanager + Loki + Grafana + node_exporter (Lab)

自宅検証VMや評価Linux 1台にすぐ立てられる、**メトリクス + ログ + アラート通知 を一通り揃えた監視スタック**です。`docker compose up -d` だけで全コンテナが起動し、Grafana を開けば CPU / メモリ / ディスク / Load / ネットワーク のダッシュボードと、`/var/log` のログ検索が利用できます。

> 自作の Flask サーバー監視ダッシュボードと、業界標準のスタックの両方に触れていることを示すための Lab です。本番運用ではない検証用構成のため、認証・TLS・データ永続化・スケーリングは最小限です。

![Grafana ダッシュボード「Node Overview (Lab)」のレイアウト概念図。CPU 使用率 23.4%, メモリ使用率 78.1%（warning しきい値超過）, ディスク空き 42.6% の Stat パネル 3 枚、Load average (1/5/15) と ネットワーク受信 (bytes/s) の time-series 2 枚、下部に HostHighMemory アラートのバナー。](../image/grafana-dashboard.svg)

---

## 構成

| コンテナ | 役割 | 公開ポート |
|---|---|---|
| `prom/prometheus:v2.54.1` | メトリクス収集、アラート評価 | `9090` |
| `prom/node-exporter:v1.8.2` | ホストの CPU/メモリ/ディスク/ネット 指標を公開 | `9100` (host network) |
| `prom/alertmanager:v0.27.0` | アラートのルーティング・抑制・通知 | `9093` |
| `grafana/loki:3.1.1` | ログ集約（Prometheus と同じラベル思想） | `3100` |
| `grafana/promtail:3.1.1` | `/var/log` を Loki へ転送するエージェント | `9080` |
| `grafana/grafana:11.2.0` | ダッシュボード表示（メトリクス + ログ） | `3000` |

```
                       +-------------+
+----------+   scrape  |  Prometheus |  alerts   +---------------+
| node_    |---------> |    9090     |---------> |  Alertmanager |
| exporter |           +------+------+           |     9093      |
+----------+                  |                  +-------+-------+
                              | datasource               |
+----------+   push           |                          | Slack / Email
| promtail |-------> +--------+----+                     v
| (logs)   |         |    Loki     |              [ Slack #ops-alerts ]
+----------+         |    3100     |              [ ops@example.com  ]
                     +------+------+
                            |
                            v
                     +------+------+
                     |   Grafana   |
                     |   3000      |
                     +-------------+
```

---

## 起動方法

```bash
cd monitoring-stack
docker compose up -d
```

ブラウザで以下を開きます。

- Prometheus  : http://localhost:9090
- Alertmanager: http://localhost:9093
- Loki API    : http://localhost:3100/ready
- Grafana     : http://localhost:3000  （admin / changeme）

Grafana 左メニュー > Dashboards > Lab > **Node Overview (Lab)** に、CPU / メモリ / ディスク / Load / ネットワーク のパネルが表示されます。
Explore メニューで Loki を選び `{job="syslog"}` などを入力すると `/var/log` のログを検索できます。

---

## ファイル構成

```
monitoring-stack/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml          ... スクレイプ設定 + alertmanagers + loki ジョブ
│   └── alert.rules.yml         ... アラートルール（CPU/メモリ/ディスク/exporterダウン + AM/Loki監視）
├── alertmanager/
│   └── alertmanager.yml        ... ルーティング (critical → Slack+Email, warning → Slack)、抑制ルール
├── loki/
│   └── loki-config.yml         ... 単一バイナリ構成、14日保管
├── promtail/
│   └── promtail-config.yml     ... syslog / auth / nginx / apt の 4 ジョブ
├── samples/
│   ├── prometheus-targets.sample.txt   ... /api/v1/targets 出力
│   └── alert-firing.sample.txt         ... firing → Slack/Email → silence → resolved の検証ログ
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── prometheus.yml          ... Prometheus / Loki / Alertmanager を起動時に自動登録
        └── dashboards/
            ├── dashboards.yml          ... ダッシュボード読込設定
            └── node-overview.json      ... 4パネル構成の基本ダッシュボード
```

---

## アラートの考え方

`alert.rules.yml` に Lab 用のルールを 6本 定義しています。しきい値の根拠は
[`../support-docs/slo-definitions.md`](../support-docs/slo-definitions.md) で SLO から逆算しています。

| アラート名 | 条件 | 重大度 | 想定アクション |
|---|---|---|---|
| `HostHighCpu` | CPU使用率 > 85% が10分継続 | warning | プロセス上位を確認、bashトリアージ実行 |
| `HostHighMemory` | available < 10% が15分継続 | warning | OOM兆候とswap傾向を確認 |
| `HostLowDisk` | 空き < 10% が10分継続 | critical | logrotate / 古いバックアップを精査 |
| `NodeExporterDown` | up{job="node"} == 0 が5分継続 | critical | サーバー疎通とサービス状態を確認 |
| `AlertmanagerDown` | up{job="alertmanager"} == 0 が5分継続 | critical | 通知経路死活。compose ログ確認 |
| `LokiDown` | up{job="loki"} == 0 が5分継続 | warning | ログ集約停止。Promtail も併せて確認 |

### Alertmanager 経路

`alertmanager/alertmanager.yml` でルーティングを定義しています。

| severity | 経路 | 抑制 |
|---|---|---|
| `critical` | Slack `#ops-alerts` + メール `ops@example.com` | — |
| `warning` | Slack `#ops-alerts` | 同 alertname + instance の critical 発火中は抑制 |

検証用に **firing → Slack/Email → silence → resolved** の一連の動作ログを
[`samples/alert-firing.sample.txt`](./samples/alert-firing.sample.txt) に置いています。

---

## ポートフォリオでの位置づけ

- **自作 Flask 監視ダッシュボード** ([ns7jp/server-monitor](https://github.com/ns7jp/server-monitor)) は **psutil の挙動とAPI設計の学習** が目的
- **このスタック** は **既存運用に合流できる "業界標準" を扱える** ことを示すのが目的
- 両方を同じポートフォリオ上に並べることで、自作と既製の **棲み分けを理解している** ことを伝える

---

## 注意

- ポートフォリオ用の最小構成です。`GF_SECURITY_ADMIN_PASSWORD=changeme` を変更せずに公開ホストへ展開しないでください。
- node_exporter は `network_mode: host` でホストネットワーク上の :9100 に公開し、Prometheus 側は `host.docker.internal:9100` で読み取ります。Linux Docker Engine では `host.docker.internal` が自動解決されないため、Prometheus 側に `extra_hosts: "host.docker.internal:host-gateway"` を入れて両環境（Linux / Docker Desktop）で同じ設定が動くようにしています（Docker 20.10+）。
- 永続化ボリュームは `prometheus_data` / `grafana_data` です。再構築時は `docker compose down -v` で初期化できます。
- `docker compose config` で構文・ボリューム・ポートの整合が確認できます（CI でも回せます）。
