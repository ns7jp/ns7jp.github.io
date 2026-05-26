# Production Readiness — Lab から本番運用へ足すもの

このドキュメントは、ポートフォリオ内の Infra Operation Lab / Linux Lab / Monitoring Stack / Ansible / Cloud Lab を、本番相当の運用へ近づける場合に追加すべき観点を整理したものです。

Lab では「学習しやすさ」「公開しやすさ」「安全に読めること」を優先しています。本番では、監視・通知・認証・秘密情報・バックアップ・変更管理・監査を追加し、障害時に人が迷わない状態まで整えます。

---

## 1. 監視 / 通知

| Lab の状態 | 本番で足すもの | 理由 |
|---|---|---|
| Prometheus + Grafana + Loki + 4 アラート | Alertmanager / 通知先 / 抑止 / エスカレーション | アラートを見えるだけでなく、担当者へ届く状態にする |
| 固定しきい値 | ベースライン収集 / SLO / エラーバジェット ([具体例](./support-docs/slo-error-budget.md)) | 環境ごとの正常値に合わせる |
| node_exporter 単体 | blackbox_exporter / windows_exporter / アプリメトリクス | 外形監視とOS別監視を追加する |
| Loki + Promtail (Lab) | retention 90 日 / S3 オブジェクトストレージ / X-Scope-OrgID 認証 | ログの長期保管とテナント分離 |
| Metrics + Logs のみ | Traces (OpenTelemetry / Tempo) | 観測性の三本柱を揃える |
| 手動確認 | Runbook link / ダッシュボードURL / 初動手順 | アラートから初動へ直結させる |

最小本番化例:

```yaml
route:
  receiver: teams-primary
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
```

---

## 2. 認証 / アクセス制御

| 領域 | 本番での方針 |
|---|---|
| Linux SSH | パスワード認証無効、鍵 + MFA、踏み台 / SSM / VPN 経由 |
| Windows / AD | 管理者権限は日常アカウントと分離、JIT / PAM を検討 |
| M365 | 条件付きアクセス、MFA、サインインログ監視 |
| Cloud | IAM Identity Center、最小権限ロール、Break-glass アカウント |
| Grafana | ローカル admin 固定ではなく SSO / RBAC / 監査ログ |

---

## 3. 秘密情報 / 設定値

| Lab の状態 | 本番で足すもの |
|---|---|
| README にダミー値を明記 | `.env` / Secret Manager / Ansible Vault / GitHub Actions Secrets |
| Ansible の `admin_pubkey` がサンプル | Vault 分離、ローテーション手順、失効手順 |
| Grafana password が `changeme` | 初期起動時の強制変更、SSO、有効期限管理 |
| Terraform 変数にサンプルCIDR | tfvars は Git 管理外、CI では validate まで |

---

## 4. バックアップ / リストア / DR

| 対象 | 本番で確認すること |
|---|---|
| Windows ファイルサーバー | VSS / Robocopy / ACL復元 / 共有単位復旧 / 月次リストアテスト |
| Linux サーバー | rsync / 世代管理 / systemd timer / オフサイト同期 / 完全復元手順 |
| Grafana / Prometheus | 永続ボリューム、設定ファイル、ダッシュボードJSONのGit管理 |
| Cloud | AWS Backup、世代管理、暗号化、別アカウント保管 |
| **副系切替** | AD FSMO 移譲、DFS Namespace ターゲット切替、DB レプリカ昇格、VIP（Keepalived）、DNS TTL 短縮 → 切替 → 戻し |

バックアップは取得成否だけでなく、**戻せること** を月次で、**副系に切れること** を年次の DR ドリルで証明します。手順の具体例は [Failover Runbook](./support-docs/failover-runbook.md) を参照。

---

## 5. 変更管理

本番では、作業前後の証跡とロールバック条件を必ず残します。

| フェーズ | 残すもの |
|---|---|
| 申請 | 目的、影響範囲、承認者、作業時間、ロールバック方針 |
| 事前確認 | 現在値、対象リソース、バックアップ、利用者影響 |
| 作業 | 実行コマンド、開始・終了時刻、作業者 |
| 検証 | 期待結果、確認結果、利用者確認 |
| クローズ | 添付証跡、残課題、再発防止、ナレッジ更新 |

AD / M365 の具体例は [support-docs/ad-m365-change-case.md](./support-docs/ad-m365-change-case.md) にまとめています。

---

## 6. CI / 品質ゲート

| 対象 | CIで見るもの |
|---|---|
| Static site | リンク切れ、HTML構造、画像サイズ |
| PowerShell | Pester、PSScriptAnalyzer |
| Linux script | `bash -n`、将来的には ShellCheck |
| Prometheus | `promtool check config` / `promtool check rules` |
| Docker Compose | `docker compose config` |
| Ansible | collection install、syntax-check、ansible-lint |
| Terraform | fmt、init without backend、validate |

追加した workflow:

- `.github/workflows/static-check.yml`
- `.github/workflows/pwsh-tests.yml`
- `.github/workflows/infra-check.yml`

---

## 7. 優先度つきロードマップ

| 優先 | 追加するもの | 理由 |
|---|---|---|
| P1 | Alertmanager + 通知先 + Runbook link | 障害検知から初動までをつなぐ |
| P1 | Secrets / Vault / SSO | 公開サンプルから本番運用へ移る際の最低条件 |
| P1 | リストアテスト記録 + 年次 DR ドリル（[Failover Runbook](./support-docs/failover-runbook.md) 実行） | バックアップ・副系切替の実効性を示す |
| P1 | CIS Benchmark 自動監査（OpenSCAP / Lynis） | [現状マッピング](./ansible/cis-benchmark-mapping.md)を継続検証する仕組み |
| P2 | CloudTrail / Flow Logs / GuardDuty | クラウド監査と検知を補う |
| P2 | ansible-lint / Terraform validate のCI強化 | IaC変更の安全性を上げる |
| P3 | SLO / Error Budget | 運用品質を数値で説明できるようにする |

---

## 関連

- [Infra Operation Lab](./infra-lab.html)
- [Linux Lab](./linux-lab.html)
- [Cloud Network Lab](./cloud-lab.html)
- [Monitoring Stack](./monitoring-stack/) — Prometheus + Grafana + Loki + Promtail
- [Ansible Playbook](./ansible/) / [CIS Benchmark マッピング](./ansible/cis-benchmark-mapping.md) — 業界標準への対応表
- [Infra Evidence](./infra-evidence/) — 検証コマンドサンプル + 失敗→修正対比
- [SLO / Error Budget](./support-docs/slo-error-budget.md) — 運用品質の数値設計（具体例）
- [チケット分類](./support-docs/ticket-taxonomy.md) — ITIL 4 区分の受付テンプレ
- [物理層](./support-docs/office-it-physical-layer.md) — ラック / LAN / UPS / 複合機
- [M365 ポリシー定義](./support-docs/m365-policy-examples/) — Intune / 条件付きアクセス / Defender JSON
- [Backup / Restore Runbook](./support-docs/backup-restore-runbook.md) — RTO / RPO / DR ドリル計画
- [Failover Runbook](./support-docs/failover-runbook.md) — AD / ファイル / DB / VIP / DNS の副系切替手順
- [ネットワーク切り分け証跡](./support-docs/network-triage-evidence.md) — L2-L7 を機械的に当てるコマンドと出力例
