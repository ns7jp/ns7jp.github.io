# Azure Lab — ハイブリッド前提の Terraform 検証構成

> **AZ-104 学習ロードマップに沿った Lab。**
> オンプレ前提（`infra-lab.html` の VLAN 構成図）を、Azure へ拡張するときの
> 最小構成を Terraform で書き起こしています。実機デプロイは Azure 無料枠を想定。

---

## ゴール

| 観点 | 内容 |
|------|------|
| クラウド経験 | 「Terraform で IaC を書き、`plan` / `apply` で再現できる」を示す |
| ハイブリッド | オンプレ Active Directory と Entra ID（旧 Azure AD）の同期構成を図示 |
| ネットワーク | VNet / Subnet / NSG / Bastion の最小単位を組み立てる |
| セキュリティ | パブリック SSH 公開を禁止し、Bastion 経由のみ許可 |
| IaC ベストプラクティス | `variables.tf` で環境差分を吸収、`tfstate` は別管理を想定 |

---

## 想定アーキテクチャ

![Azure Portal で表示した Lab リソースグループの概念図。Terraform で apply した結果 shimada-lab-rg リソースグループに作成された 9 リソース（VNet、2サブネット、NSG、NIC、Linux VM、Public IP、Bastion）と、Terraform plan/apply 出力、NSG ルール（AllowBastionSSHIn 1000 → Allow / DenyInternetIn 4000 → Deny / DenyAllInbound 65500 → Implicit）の詳細を Azure Portal 風のスタイルで示すレイアウト概念図。](../image/azure-portal.svg)

![Azure Bastion 経由で Linux VM へ SSH 接続したターミナル画面の概念図。左ペインで Bastion 接続フォーム（Username opsadmin、SSH 秘密鍵 id_ed25519）と Security posture（VM has no public IP、NSG blocks Internet、SSH key-only、Session logged）を表示。右ペインで uname/uptime/ip/systemctl/ss/sshd_config/ufw/fail2ban 出力により、Ansible playbook 適用後の状態を確認している様子を示す。](../image/azure-bastion-ssh.svg)

```
                       Internet
                          │
                  +---------------+
                  | Azure Bastion |   (10.50.255.0/27)
                  |  443 only     |
                  +-------+-------+
                          │ RDP/SSH (private)
                          ▼
+-----------------------------------------------+
| VNet  10.50.0.0/16                            |
|                                               |
|  +---- snet-app (10.50.10.0/24) -----------+ |
|  |  Linux VM (Ubuntu 22.04, Standard_B1s)   | |
|  |  ─ NSG: allow Bastion 22 / deny Internet | |
|  |  ─ Public IP なし                         | |
|  +-------------------------------------------+ |
|                                               |
+----------------+------------------------------+
                 │ ExpressRoute or S2S VPN（将来）
                 ▼
       +-------------------+        +-----------------+
       | On-prem AD DS     | <----- | Entra Connect   |
       | 10.0.20.10        |  sync  | (ハイブリッド ID) |
       +-------------------+        +-----------------+
                 │
                 ▼
       Entra ID テナント (Conditional Access + Defender for Endpoint)
```

オンプレ側の VLAN 設計は [`../infra-lab.html`](../infra-lab.html) の構成図と同じ
表記で結合しています。両方を併せて読むと、**社内 → クラウド** までの一貫したネットワーク設計
として読めるようにしています。

---

## ファイル構成

```
azure-lab/
├── README.md                 ... 本ファイル
├── terraform/
│   ├── main.tf               ... VNet / Subnet / NSG / VM / Bastion
│   ├── variables.tf          ... prefix / location / admin_username / admin_pubkey
│   ├── outputs.tf            ... VM 内部 IP、Bastion 公開 URL
│   ├── providers.tf          ... azurerm v4 系を固定
│   └── README.md             ... terraform fmt / init / plan / apply 手順
└── diagrams/
    └── azure-hybrid.txt      ... ASCII 構成図（オンプレ↔Azure↔Entra ID）
```

---

## 実行手順（概略）

> Lab を実機にデプロイするには Azure サブスクリプションが必要です。
> 本リポジトリでは構成と plan までを再現可能にし、apply は任意です。

```bash
cd azure-lab/terraform

# 1. 初期化（プロバイダ取得）
terraform init

# 2. 構文チェック
terraform fmt -check
terraform validate

# 3. 何が作成されるか確認（apply しない）
terraform plan -var "admin_pubkey=$(cat ~/.ssh/id_ed25519.pub)"

# 4. 実機 Apply（任意）
az login
terraform apply -var "admin_pubkey=$(cat ~/.ssh/id_ed25519.pub)"

# 5. 破棄
terraform destroy
```

---

## 設計上の判断

| 項目 | 採用 | 理由 |
|------|------|------|
| **SSH 公開 IP** | 付与しない | 原則 Bastion 経由のみ。総当たり攻撃対象にしない |
| **NSG 既定拒否** | Internet → VM を 4000 番で明示拒否 | implicit deny だけに頼らない（運用時の見える化） |
| **VM サイズ** | Standard_B1s | 無料枠で動かしやすく、Lab 検証に十分 |
| **OS イメージ** | Ubuntu 22.04 LTS | オンプレ Ansible Playbook と一致 |
| **State 管理** | ローカル（Lab）/ 本番は Azure Storage backend を想定 | チーム運用なら別 RG にバックエンドを切る |
| **タグ** | `env`, `owner`, `purpose` を必須化 | コスト管理と棚卸しの軸 |
| **Bastion SKU** | Basic | 検証用途。SSO や Native client が要るなら Standard |

---

## ハイブリッド構成への発展

このシンプルな Lab は、以下の順で本番相当の構成へ拡張できます。

| Step | 追加内容 | 関連リンク |
|------|----------|------------|
| 1 | サブネットを追加し、Web/DB を分離 | [SLO 定義](../support-docs/slo-definitions.md) で SLI を切り出す |
| 2 | Site-to-Site VPN または ExpressRoute でオンプレと接続 | [VPN/ACL 例](../support-docs/network-acl-vpn-examples.md) |
| 3 | Entra Connect でオンプレ AD と Entra ID を同期 | `infra-lab.html` の AD/M365 想定と一致 |
| 4 | Defender for Cloud と Microsoft Sentinel を有効化 | malware / インシデント対応と接続 |
| 5 | Azure Monitor + Log Analytics で Prometheus と並走 | [`../monitoring-stack/`](../monitoring-stack/) |
| 6 | Bicep / ARM への置き換えも可能（同等の IaC を確保） | — |

---

## 注意

- `admin_pubkey` を必ず指定してください。ハードコード厳禁です。
- Lab を実 Apply するとコストが発生します（Bastion Basic は時間課金）。**演習後は必ず destroy** してください。
- 本ファイルは公開リポジトリ用の Lab サンプルです。本番ではリソースグループ単位の **RBAC + Lock + Policy** を必ず併用してください。
