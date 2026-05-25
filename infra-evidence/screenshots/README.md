# Visual Evidence — 実機実行時の表示イメージ

このフォルダは、`monitoring-stack/` を `docker compose up -d` で起動したときに **Grafana / Prometheus が実際にどう見えるか** を、実機キャプチャの代わりに **高精度 SVG モックアップ**で示すための置き場です。

---

## 透明性の注意

公開ポートフォリオを GitHub Actions の Ubuntu runner と本リポジトリのコンテナのみで構築している関係上、**実機ホストでスタックを長時間稼働させた実キャプチャ画像は含めていません**。本フォルダの SVG は次の方針で作成しています:

- **本物の画面と区別がつくレベルの単純化**は意図的に避けず、レイアウト・パネル種別・配色・凡例・データ密度を本物の Grafana 11 / Prometheus に揃えている
- **使用しているクエリ・しきい値・ラベル**は `monitoring-stack/` 内の実ファイルと整合（`prometheus.yml` / `alert.rules.yml` / `logs-overview.json` の値そのまま）
- **数値（CPU 使用率、ログ件数など）は架空のサンプル値**で、実環境で測定したデータではない
- **本物のキャプチャに置き換えやすい構造**: 同名で `.png` を上書きする想定で、HTML 側の `<img src>` を変えなくて済む

> 採用担当者の方が「**実機で動かして撮った画面が見たい**」場合は、後述の「ローカル再現手順」で 10 分以内に同じ画面を出せます。

---

## 収録 SVG

| ファイル | 表現している画面 | 使われている実ファイル |
|---|---|---|
| [`grafana-node-overview.svg`](./grafana-node-overview.svg) | Grafana > Lab > **Node Overview** ダッシュボード | [node-overview.json](../../monitoring-stack/grafana/provisioning/dashboards/node-overview.json) |
| [`grafana-logs-overview.svg`](./grafana-logs-overview.svg) | Grafana > Lab > **Logs Overview** ダッシュボード | [logs-overview.json](../../monitoring-stack/grafana/provisioning/dashboards/logs-overview.json) |
| [`grafana-explore-logql.svg`](./grafana-explore-logql.svg) | Grafana > Explore（Loki LogQL クエリと結果） | Loki + Promtail の実構成 |
| [`prometheus-alerts.svg`](./prometheus-alerts.svg) | Prometheus > Alerts（4 ルール全部の評価状態） | [alert.rules.yml](../../monitoring-stack/prometheus/alert.rules.yml) |
| [`prometheus-targets.svg`](./prometheus-targets.svg) | Prometheus > Status > Targets（スクレイプ先一覧） | [prometheus.yml](../../monitoring-stack/prometheus/prometheus.yml) |

---

## ローカルで実機キャプチャを撮る手順（10 分）

1. リポジトリを clone し、Docker Desktop を起動

   ```bash
   git clone https://github.com/ns7jp/ns7jp.github.io.git
   cd ns7jp.github.io/monitoring-stack
   docker compose up -d
   ```

2. 1 〜 2 分待ってから、ブラウザで Grafana を開く

   ```
   http://localhost:3000  (admin / changeme)
   ```

3. 左メニュー > **Dashboards > Lab** から `Node Overview (Lab)` / `Logs Overview (Lab)` を順に開く

4. ブラウザのキャプチャ機能で PNG を保存し、本フォルダの SVG と差し替え

   - macOS: `Cmd+Shift+4` でエリア選択
   - Windows: Win+Shift+S（Snipping Tool）
   - Linux: `gnome-screenshot` / `flameshot`

5. PNG ファイル名を SVG と同じ stem にすると、本 README は変更不要

---

## 実行ログ（テキスト証跡）

画面イメージと併せて、`docker compose up -d` から各サービスが Ready 状態になるまでの**実行トレースのリアル再現**を、別ファイルに置いています。

| ファイル | 内容 |
|---|---|
| [`../lab-execution-trace.sample.txt`](../lab-execution-trace.sample.txt) | docker compose up → Prometheus / Loki / Grafana の Ready 確認 → ログ件数確認まで |
| [`../ansible-check-diff.sample.txt`](../ansible-check-diff.sample.txt) | `ansible-playbook --check --diff` を実機 Ubuntu 22.04 に当てた想定の差分出力 |
| [`../linux-triage-realhost.sample.txt`](../linux-triage-realhost.sample.txt) | `linux-triage.sh` を実機 Ubuntu に当てた想定の全項目出力 |

---

## 関連リンク

- [Monitoring Stack README](../../monitoring-stack/) — 構成と起動方法
- [Infra Evidence README](../README.md) — 検証コマンドの全体
- [Production Readiness](../../production-readiness.md) — 本番化で足す Alertmanager / SSO / ログ長期保管
