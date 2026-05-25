# Infrastructure Evidence — 実行証跡と検証観点

このフォルダは、Infra Operation Lab の成果物を「読める」だけでなく、採用担当者やレビュー担当者が **どのコマンドで検証できるか** を短時間で確認できるようにまとめた証跡置き場です。

公開リポジトリのため、ここに置くログは実ホスト名、実IP、ユーザー名、認証情報を含まないように加工したサンプルです。実行可能性そのものは GitHub Actions の `static-check.yml` / `pwsh-tests.yml` / `infra-check.yml` で継続確認する方針にしています。

---

## 確認できること

| 領域 | 検証コマンド | 証跡 / CI |
|---|---|---|
| 静的サイト | `node scripts/check-static-links.js` / `node scripts/check-html-structure.js` | `static-check.yml` |
| PowerShell 判定ロジック | `Invoke-Pester -Configuration ...` | `pwsh-tests.yml` / `pester-results.xml` |
| PowerShell 静的解析 | `Invoke-ScriptAnalyzer -Path support-scripts -Recurse` | `pwsh-tests.yml` |
| Linux triage script | `bash -n support-scripts/linux-triage.sh` | `infra-check.yml` |
| Monitoring Stack | `docker compose config` / `promtool check config` / `promtool check rules` | `infra-check.yml` |
| Loki / Promtail | `docker run loki -verify-config` / `docker run promtail -check-syntax` | `infra-check.yml` |
| Ansible | `ansible-galaxy collection install` / `ansible-playbook --syntax-check` / `ansible-lint` | `infra-check.yml` |
| Cloud Lab Terraform | `terraform fmt -check` / `terraform init -backend=false` / `terraform validate` | `infra-check.yml` |
| M365 ポリシー JSON | `jq -e . *.json` (構文検証) / 必須キー検査 | `infra-check.yml` |

---

## 採用担当者向けの読み方

1. まず [../README.md](../README.md) の「採用担当者向け」表で全体像を見る。
2. [../infra-lab.html](../infra-lab.html) と [../linux-lab.html](../linux-lab.html) で一次切り分けの流れを見る。
3. このフォルダで「検証コマンド」と「CIで確認する対象」を確認する。
4. [screenshots/](./screenshots/) で **実機実行時に Grafana / Prometheus がどう見えるか** を SVG モックアップで確認する。
5. [lab-execution-trace.sample.txt](./lab-execution-trace.sample.txt) で `docker compose up -d` 以降のリアルな出力を確認する。
6. 本番化の差分は [../production-readiness.md](../production-readiness.md) を見る。

> **実機の "本物の" スクリーンショットを見たい場合**: [screenshots/README.md](./screenshots/README.md) の「ローカルで実機キャプチャを撮る手順 (10 分)」を参考に、自分の環境で `docker compose up -d` を実行して撮影し、本リポジトリの SVG と差し替えてください。

---

## サンプル証跡

| ファイル | 内容 |
|---|---|
| [static-and-pester.sample.txt](./static-and-pester.sample.txt) | 静的サイトチェック、PowerShell Pester、PSScriptAnalyzer の出力例 |
| [monitoring-check.sample.txt](./monitoring-check.sample.txt) | Docker Compose と Prometheus ルール検証の出力例 |
| [ansible-check.sample.txt](./ansible-check.sample.txt) | Ansible collection install、syntax-check、ansible-lint の出力例 |
| [terraform-check.sample.txt](./terraform-check.sample.txt) | Cloud Lab Terraform の fmt / init / validate 出力例 |
| [m365-policy-check.sample.txt](./m365-policy-check.sample.txt) | M365 ポリシー JSON の構文検証 + Apply-IntunePolicy.ps1 dry-run 出力例 |
| [validation-failure-and-fix.sample.txt](./validation-failure-and-fix.sample.txt) | promtool / ansible-lint / terraform validate の**失敗 → 修正 → 成功**の対比証跡 |
| [lab-execution-trace.sample.txt](./lab-execution-trace.sample.txt) | ★ `docker compose up -d` から監視データ取得までの実行トレース全体 |
| [ansible-check-diff.sample.txt](./ansible-check-diff.sample.txt) | ★ `ansible-playbook --check --diff` を Ubuntu 22.04 に当てた想定の差分出力 |
| [linux-triage-realhost.sample.txt](./linux-triage-realhost.sample.txt) | ★ `linux-triage.sh` を負荷上昇中ホストに当てた想定の全項目出力 |
| [screenshots/](./screenshots/) | ★ Grafana / Prometheus 画面の高精度 SVG モックアップ + 実機キャプチャ手順 |

---

## 実行時の注意

- `docker compose` / `promtool` / `ansible-playbook` / `terraform` はローカル環境に未導入でも、GitHub Actions の Ubuntu runner 上で検証できるようにしています。
- サンプルログは公開用に短縮しています。実際の CI では各 workflow のログと artifact を確認します。
- Terraform は設計検証用です。`terraform apply` は認証情報、課金、リージョン、削除手順を確認してから実行します。
