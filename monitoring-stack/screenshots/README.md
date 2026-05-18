# monitoring-stack 動作証跡

このディレクトリには `docker compose up -d` 後の **期待される出力** をテキストで残しています。

レビュアー / 採用担当者がローカルで実際に立てなくても、何が起きるか分かるようにするのが目的です。

## ファイル

| ファイル | 内容 |
|---|---|
| `docker-compose-ps.expected.txt` | 6 コンテナが Healthy で立ち上がる状態 |
| `prometheus-targets.expected.txt` | Prometheus がターゲットと Alertmanager に接続できている状態 |
| `loki-query.expected.txt` | Loki に対する代表的な LogQL クエリの期待結果 |

## ローカルで実行する手順

```bash
cd monitoring-stack
docker compose up -d

# 30 秒待つ
sleep 30

# Prometheus
open http://localhost:9090/targets       # ターゲットが UP か確認
open http://localhost:9090/alerts        # アラートルール (6 個) が表示

# Alertmanager
open http://localhost:9093               # 設定が反映されている

# Grafana (admin / changeme)
open http://localhost:3000
# Dashboards > Lab > Node Overview / Logs Overview

# 後片付け
docker compose down -v
```

## 関連

- メイン README: [`../README.md`](../README.md)
- アラートルール: [`../prometheus/alert.rules.yml`](../prometheus/alert.rules.yml)
- Alertmanager 設定: [`../alertmanager/alertmanager.yml`](../alertmanager/alertmanager.yml)
- Loki dashboard: [`../grafana/provisioning/dashboards/logs-overview.json`](../grafana/provisioning/dashboards/logs-overview.json)
