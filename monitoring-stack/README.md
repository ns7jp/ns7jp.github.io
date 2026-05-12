# Monitoring Stack — Prometheus + Grafana + node_exporter (Lab)

自宅検証VMや評価Linux 1台にすぐ立てられる、**最小構成の監視スタック**です。`docker compose up -d` だけで Prometheus / Grafana / node_exporter が起動し、Grafana を開けば CPU / メモリ / ディスク / Load / ネットワーク のダッシュボードが表示されます。

> 自作の Flask サーバー監視ダッシュボードと、業界標準のスタックの両方に触れていることを示すための Lab です。本番運用ではない検証用構成のため、認証・TLS・データ永続化・スケーリングは最小限です。

---

## 構成

| コンテナ | 役割 | 公開ポート |
|---|---|---|
| `prom/prometheus:v2.54.1` | メトリクス収集、アラート評価 | `9090` |
| `prom/node-exporter:v1.8.2` | ホストの CPU/メモリ/ディスク/ネット 指標を公開 | `9100` (host network) |
| `grafana/grafana:11.2.0` | ダッシュボード表示 | `3000` |

```
+----------+    scrape     +-------------+
| node_    |<--------------|  Prometheus |
| exporter |   (15s)       |  9090       |
+----------+               +------+------+
   (host metrics)                 | datasource
                                  v
                            +-----+-----+
                            |  Grafana  |
                            |  3000     |
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

Grafana 左メニュー > Dashboards > Lab > **Node Overview (Lab)** に、CPU / メモリ / ディスク / Load / ネットワーク のパネルが表示されます。

---

## ファイル構成

```
monitoring-stack/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml          ... スクレイプ設定
│   └── alert.rules.yml         ... アラートルール（CPU/メモリ/ディスク/exporterダウン）
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── prometheus.yml          ... Prometheusを起動時に自動登録
        └── dashboards/
            ├── dashboards.yml          ... ダッシュボード読込設定
            └── node-overview.json      ... 4パネル構成の基本ダッシュボード
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

## ポートフォリオでの位置づけ

- **自作 Flask 監視ダッシュボード** ([ns7jp/server-monitor](https://github.com/ns7jp/server-monitor)) は **psutil の挙動とAPI設計の学習** が目的
- **このスタック** は **既存運用に合流できる "業界標準" を扱える** ことを示すのが目的
- 両方を同じポートフォリオ上に並べることで、自作と既製の **棲み分けを理解している** ことを伝える

---

## 注意

- ポートフォリオ用の最小構成です。`GF_SECURITY_ADMIN_PASSWORD=changeme` を変更せずに公開ホストへ展開しないでください。
- node_exporter はホストネットワークで動かしています。Docker Desktop (Mac/Windows) では `host.docker.internal` を使うか、`network_mode: host` を Linux 限定で利用する形にしてください。
- 永続化ボリュームは `prometheus_data` / `grafana_data` です。再構築時は `docker compose down -v` で初期化できます。
