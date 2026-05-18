# Terraform Lab — Azure 最小構成 IaC

AZ-104 学習を実装で裏付ける Lab です。`terraform apply` 一発で、**監視対象としてすぐ使える Linux VM** が Azure 上に立ち上がります。`monitoring-stack/` の Prometheus がそのまま `:9100` をスクレイプできるよう、cloud-init で node_exporter を自動セットアップしています。

> このリポジトリの他の Lab (`monitoring-stack/`, `ansible/`, `k8s-lab/`) と接続して使えるよう、出力 (`prometheus_target`) を Prometheus 設定に貼れる形にしています。

---

## 構成

```
+----- Azure Resource Group (rg-infralab-dev) -----+
|                                                  |
|   VNet 10.20.0.0/16                              |
|     └─ Subnet 10.20.20.0/24 (server)             |
|         └─ NIC ──── NSG (SSH/9100 from admin IP) |
|              └─ Linux VM (Standard_B1s, Ubuntu)  |
|                  └─ cloud-init: node_exporter    |
|                                                  |
|   Public IP (Static) ────────────────────────────┘
|                          ↑
|                          │ scrape :9100
|                          │
+──────────────── monitoring-stack/Prometheus
```

| リソース | 用途 | 月額目安 (japaneast) |
|---|---|---|
| Resource Group | リソース束ね | 無料 |
| VNet + Subnet + NSG | ネットワーク分離 | 無料 |
| Public IP (Standard, Static) | 固定 IP | 約 ¥600 |
| Linux VM (Standard_B1s) | 監視対象 | 約 ¥1,300 |
| OS Disk (Standard_LRS 30GB) | OS 領域 | 約 ¥200 |

**合計目安: 月 ¥2,000 前後**（24時間稼働、為替次第）。学習後は `terraform destroy` で確実に破棄してください。

---

## 前提

- Terraform >= 1.5.0
- Azure CLI (`az login` 済み)
- SSH 公開鍵 (`~/.ssh/id_ed25519.pub` など)
- 固定 IP / 既知の送信元 IP (NSG で許可するため)

---

## 使い方

```bash
cd terraform-lab

# 1. 変数ファイルを用意 (機密扱い、gitignore 済み)
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars   # admin_source_cidr を自分の IP/32 に書き換える

# 2. 初期化と Plan
terraform init
terraform plan -var-file=terraform.tfvars

# 3. Apply
terraform apply -var-file=terraform.tfvars

# 4. 出力を確認
terraform output
# → ssh_command, prometheus_target

# 5. 監視に組み込む (monitoring-stack/prometheus/prometheus.yml に追記)
#   - job_name: azure-vm
#     static_configs:
#       - targets: ['<prometheus_target の値>']

# 6. 学習後は必ず破棄
terraform destroy -var-file=terraform.tfvars
```

---

## 設計上の判断

| ポイント | 判断 | 根拠 |
|---|---|---|
| VM サイズ | `Standard_B1s` | バーストで足りる学習用途。月 ¥1,300 程度。 |
| Public IP | `Static` + `Standard` SKU | NSG ルールの送信元固定、SLA 99.99% |
| 認証 | SSH 公開鍵のみ (パスワード無効) | パスワード総当たり攻撃を遮断 |
| NSG | SSH / 9100 を admin IP/32 のみ許可、最後に Deny all | 最小権限。`0.0.0.0/0` は variable validation で拒否 |
| OS Disk | `Standard_LRS` 30GB | コスト優先。本番は `Premium_LRS` |
| State 管理 | ローカル (Lab 用) | 本番では Azure Storage Account + state lock が必須 |
| タグ | project / environment / managed_by / owner | コスト集計と棚卸しが楽になる最小セット |

---

## 本番運用へのギャップ (意図的に省略した点)

このコードは **学習・公開検証用** です。本番に持っていく際は最低限以下が必要です。

- [ ] State をリモートバックエンド (Azure Storage Account + RBAC) に移す
- [ ] CI/CD で `terraform plan` を PR 自動レビュー、`apply` は手動承認
- [ ] `tflint` / `tfsec` / `checkov` を CI に追加
- [ ] Bastion / Azure AD ログイン / Just-in-Time アクセス
- [ ] Diagnostic Settings → Log Analytics で監査ログを集約
- [ ] Backup Vault でディスクスナップショット
- [ ] Network Watcher で NSG Flow Logs

---

## 関連 Lab

- [`monitoring-stack/`](../monitoring-stack/) — この VM をスクレイプする Prometheus + Grafana
- [`ansible/`](../ansible/) — この VM に対する OS ハードニング
- [`k8s-lab/`](../k8s-lab/) — この VM 上で動かせる Kubernetes ワークロード
