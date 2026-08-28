# Infrastructure Evidence — 架空出力例と検証観点（未採録）

このフォルダは、Infra Operation Lab の検証方法を短時間で確認できるようにまとめた、**架空の出力例と検証観点の置き場**です。ここにある <code>*.sample.txt</code> は説明用サンプルであり、実行日時・commit・実行環境を伴う実測証跡ではありません。

実測を新しく採録する場合は `bash scripts/capture-lab-evidence.sh <label> -- <command...>` を使い、`measured/` へ保存します。CI由来の結果は `ci-generated/`、既存の `*.sample.txt` はSAMPLEとして混在させません。公開前に[証跡ガイド](../learning-docs/evidence-guide.md)に従って秘密情報と個人情報を目視確認します。

公開リポジトリのため、例示するホスト名、IP、ユーザー名、コマンド出力は架空です。`static-check.yml` / `pwsh-tests.yml` / `infra-check.yml` は構文・静的検査をCIで再現するための定義であり、このフォルダ自体はCI完走を証明しません。

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
| **ネットワーク切り分け** | `ip` / `mtr` / `dig` / `openssl s_client` / `tcpdump` / `curl -w` | 手動実行（[network-triage.sample.txt](./network-triage.sample.txt) に出力例） |

---

## 採用担当者向けの読み方

1. まず [../README.md](../README.md) の「採用担当者向け」表で全体像を見る。
2. [../infra-lab.html](../infra-lab.html) と [../linux-lab.html](../linux-lab.html) で一次切り分けの流れを見る。
3. このフォルダで「検証コマンド」と「CIで確認する対象」を確認する。
4. 本番化の差分は [../production-readiness.md](../production-readiness.md) を見る。

---

## 架空の出力例（実行証跡ではありません）

| ファイル | 内容 |
|---|---|
| [static-and-pester.sample.txt](./static-and-pester.sample.txt) | 静的サイトチェック、PowerShell Pester、PSScriptAnalyzer の出力例 |
| [monitoring-check.sample.txt](./monitoring-check.sample.txt) | Docker Compose と Prometheus ルール検証の出力例 |
| [ansible-check.sample.txt](./ansible-check.sample.txt) | Ansible collection install、syntax-check、ansible-lint の出力例 |
| [terraform-check.sample.txt](./terraform-check.sample.txt) | Cloud Lab Terraform の fmt / init / validate 出力例 |
| [m365-policy-check.sample.txt](./m365-policy-check.sample.txt) | M365 ポリシー JSON の構文検証 + Apply-IntunePolicy.ps1 dry-run 出力例 |
| [validation-failure-and-fix.sample.txt](./validation-failure-and-fix.sample.txt) | promtool / ansible-lint / terraform validate の**失敗 → 修正 → 成功**の対比例 |
| [network-triage.sample.txt](./network-triage.sample.txt) | ★ L2 〜 L7 切り分けコマンドの出力サンプル（link / route / ping / mtr / dig / curl / openssl / tcpdump）|

---

## 実行時の注意

- `docker compose` / `promtool` / `ansible-playbook` / `terraform` はローカル環境に未導入でも、GitHub Actions の Ubuntu runner 上で検証できるようにしています。
- サンプルログは公開用に短縮しています。実際の CI では各 workflow のログと artifact を確認します。
- Terraform は設計検証用です。`terraform apply` は認証情報、課金、リージョン、削除手順を確認してから実行します。
