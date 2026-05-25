# Infrastructure Evidence — 実行証跡と検証観点

このフォルダは、Infra Operation Lab の成果物を「読める」だけでなく、採用担当者やレビュー担当者が **どのコマンドで検証できるか** を短時間で確認できるようにまとめた証跡置き場です。

公開リポジトリのため、ここに置くログは実ホスト名、実IP、ユーザー名、認証情報を含まないように加工したサンプルです。実行可能性そのものは GitHub Actions の `static-check.yml` / `pwsh-tests.yml` / `infra-check.yml` で継続確認する方針にしています。

サイト上の読みやすい入口は [Validation Evidence](../lab-evidence.html) と [Incident Drill](../incident-drill.html) です。CI で合格した範囲、架空シナリオの演習、実VMで追加取得すべき証跡を分けて提示しています。

---

## 確認できること

| 領域 | 検証コマンド | 証跡 / CI |
|---|---|---|
| 静的サイト | `node scripts/check-static-links.js` / `node scripts/check-html-structure.js` | `static-check.yml` |
| PowerShell 判定ロジック | `Invoke-Pester -Configuration ...` | `pwsh-tests.yml` / `pester-results.xml` |
| PowerShell 静的解析 | `Invoke-ScriptAnalyzer -Path support-scripts -Recurse` | `pwsh-tests.yml` |
| Linux triage script | `bash -n support-scripts/linux-triage.sh` / `shellcheck` | `infra-check.yml` |
| Monitoring Stack | `docker compose config` / `promtool check config` / `promtool check rules` | `infra-check.yml` |
| Ansible | `ansible-galaxy collection install` / `ansible-playbook --syntax-check` / `ansible-lint` | `infra-check.yml` |
| Cloud Lab Terraform | `terraform fmt -check` / `terraform validate` / `terraform test` / `tflint` / Trivy config scan | `infra-check.yml` |

---

## 採用担当者向けの読み方

1. まず [../README.md](../README.md) の「採用担当者向け」表で全体像を見る。
2. [../infra-lab.html](../infra-lab.html) と [../linux-lab.html](../linux-lab.html) で一次切り分けの流れを見る。
3. このフォルダで「検証コマンド」と「CIで確認する対象」を確認する。
4. 本番化の差分は [../production-readiness.html](../production-readiness.html) を見る。

---

## サンプル証跡

| ファイル | 内容 |
|---|---|
| [static-and-pester.sample.txt](./static-and-pester.sample.txt) | 静的サイトチェック、PowerShell Pester、PSScriptAnalyzer の出力例 |
| [monitoring-check.sample.txt](./monitoring-check.sample.txt) | Docker Compose と Prometheus ルール検証の出力例 |
| [ansible-check.sample.txt](./ansible-check.sample.txt) | Ansible collection install、syntax-check、ansible-lint の出力例 |
| [terraform-check.sample.txt](./terraform-check.sample.txt) | Cloud Lab Terraform の fmt / init / validate 出力例 |
| [incident-drill.sample.txt](./incident-drill.sample.txt) | ディスク逼迫アラートを題材にした、架空の切り分け・復旧ログ |
| [ansible-idempotence.template.txt](./ansible-idempotence.template.txt) | 隔離した Ubuntu VM で `changed=0` を採取するための未記入テンプレート |

---

## 実行時の注意

- `docker compose` / `promtool` / `ansible-playbook` / `terraform` はローカル環境に未導入でも、GitHub Actions の Ubuntu runner 上で検証できるようにしています。
- サンプルログは公開用に短縮しています。実際の CI では各 workflow のログと artifact を確認します。
- Terraform は設計検証用です。`terraform apply` は認証情報、課金、リージョン、削除手順を確認してから実行します。
- Ansible の syntax-check / lint は CI 対象ですが、実ホストへの適用と2回目の `changed=0` は実VM検証として別に証跡を採取します。未実施の適用を完了済みとは表示しません。
