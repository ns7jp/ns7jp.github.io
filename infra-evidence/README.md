# Infrastructure Evidence — 実行証跡と検証観点

このフォルダは、Infra Operation Lab の成果物を「読める」だけでなく、採用担当者やレビュー担当者が **どのコマンドで検証できるか** を短時間で確認できるようにまとめた証跡置き場です。

公開リポジトリのため、ここに置くログは実ホスト名、実IP、ユーザー名、認証情報を含まないように加工したサンプルです。構文・単体検証は GitHub Actions の `static-check.yml` / `pwsh-tests.yml` / `infra-check.yml`、実際にサービスを停止して通知と復旧を確認する動作証跡は `verified-lab.yml` の artifact で継続確認します。

---

## 確認できること

| 領域 | 検証コマンド | 証跡 / CI |
|---|---|---|
| 静的サイト | `node scripts/check-static-links.js` / `node scripts/check-html-structure.js` | `static-check.yml` |
| PowerShell 判定ロジック | `Invoke-Pester -Configuration ...` | `pwsh-tests.yml` / `pester-results.xml` |
| PowerShell 静的解析 | `Invoke-ScriptAnalyzer -Path support-scripts -Recurse` | `pwsh-tests.yml` |
| Linux triage script | `bash -n support-scripts/linux-triage.sh` | `infra-check.yml` |
| Monitoring Stack 設定 | `docker compose config` / `promtool` / Alertmanager / blackbox config check | `infra-check.yml` |
| Monitoring Stack 動作 | HTTP target 停止 → alert firing → webhook → 復旧 → resolved | `verified-lab.yml` artifact |
| Loki / Promtail | `docker run loki -verify-config` / `docker run promtail -check-syntax` | `infra-check.yml` |
| Ansible | `ansible-galaxy collection install` / `ansible-playbook --syntax-check` / `ansible-lint` | `infra-check.yml` |
| Cloud Lab Terraform | `terraform fmt -check` / `validate` / `terraform test`（SG安全条件） | `infra-check.yml` |
| M365 ポリシー JSON | JSON 構文 / 必須キー / 対応 Intune 2 種の dry-run | `infra-check.yml` |

---

## 採用担当者向けの読み方

1. まず [ポートフォリオ README](https://github.com/ns7jp/ns7jp.github.io#readme) の「採用担当者向け」表で全体像を見る。
2. [../infra-lab.html](../infra-lab.html) と [../linux-lab.html](../linux-lab.html) で一次切り分けの流れを見る。
3. このフォルダで「検証コマンド」と「CIで確認する対象」を確認する。
4. 本番化の差分は [Production Readiness](https://ns7jp.github.io/production-readiness.html) を見る。

---

## サンプル証跡

| ファイル | 内容 |
|---|---|
| [static-and-pester.sample.txt](./static-and-pester.sample.txt) | 静的サイトチェック、PowerShell Pester、PSScriptAnalyzer の出力例 |
| [monitoring-check.sample.txt](./monitoring-check.sample.txt) | Docker Compose と Prometheus ルール検証の出力例 |
| [ansible-check.sample.txt](./ansible-check.sample.txt) | Ansible collection install、syntax-check、ansible-lint の出力例 |
| [terraform-check.sample.txt](./terraform-check.sample.txt) | Cloud Lab Terraform の fmt / init / validate 出力例 |
| [m365-policy-check.sample.txt](./m365-policy-check.sample.txt) | M365 ポリシー JSON の構文検証 + Apply-IntunePolicy.ps1 dry-run 出力例 |
| [validation-failure-and-fix.sample.txt](./validation-failure-and-fix.sample.txt) | ★ promtool / ansible-lint / terraform validate の**失敗 → 修正 → 成功**の対比証跡 |

---

## 動作ドリルの実測証跡

[Verified Infrastructure Lab](../verified-lab/) は固定の成功ログではなく、GitHub Actions が実行ごとに生成する `verified-monitoring-incident-evidence` artifact を証跡にします。そこには外形監視の正常値、意図的な停止、アラート配送、復旧と解消配送の時系列が残ります。

---

## 実行時の注意

- `docker compose` / `promtool` / `ansible-playbook` / `terraform` はローカル環境に未導入でも、GitHub Actions の Ubuntu runner 上で検証できるようにしています。
- サンプルログは公開用に短縮しています。実際の CI では各 workflow のログと artifact を確認します。
- Terraform は plan と mock provider による test までの設計検証用です。実 AWS に対する `terraform apply` は認証情報、課金、リージョン、削除手順を確認してから実行します。
