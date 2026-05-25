# Cloud Network Lab — AWS VPC 最小設計

ITサポート・社内SE補助・インフラ運用支援からクラウド運用へ接続するための、小さな AWS ネットワーク Lab です。目的は「クラウドを触ったことがある」と大きく見せることではなく、**VPC / Subnet / Route / Security Group / Cost Guardrail を、オンプレの VLAN や ACL と対応づけて説明できること**を示すことです。

この Lab は Terraform の構文検証と mock provider による設計テストまでを公開対象にしています。`terraform apply` は AWS 認証情報、課金、削除手順、リージョン制限を確認してから実施します。

---

## 構成概要

| 要素 | 値 / 方針 | オンプレ対応 |
|---|---|---|
| Cloud | AWS | データセンター / 拠点 |
| Region | `ap-northeast-1` | 東京リージョン想定 |
| VPC | `10.20.0.0/16` | L3 Core 配下の社内ネットワーク |
| Public Subnet | `10.20.10.0/24` | DMZ / 踏み台セグメント |
| Private Subnet | `10.20.20.0/24` | Server VLAN |
| Internet Gateway | Public Subnet のみ | Edge FW / Internet 出口 |
| Security Group | Bastion / App を分離 | ACL / FW ルール |
| Flow Logs | 本番化時に有効化 | FW ログ / NetFlow |

---

## 想定アーキテクチャ

```text
----------------------------- AWS VPC 10.20.0.0/16 -----------------------------+
|                                                                                 |
|  Public Subnet 10.20.10.0/24             Private Subnet 10.20.20.0/24           |
|  +---------------------------+            +----------------------------------+  |
|  | Bastion SG                |            | App SG                           |  |
|  | SSH: admin_cidr only      | --SSH-->   | SSH: Bastion SG only             |  |
|  | egress: all               | --9100-->  | node_exporter: Bastion SG only   |  |
|  +------------+--------------+            +----------------------------------+  |
|               |                                                                 |
|       Internet Gateway                                                           |
|               |                                                                 |
+---------------+-----------------------------------------------------------------+
                |
             Internet
```

この構成では NAT Gateway や EC2 を作成していません。Terraform では **VPC / Subnet / Route Table / Security Group** までを管理し、課金インパクトが出やすいリソースは意図的に外しています。

---

## Terraform 検証

```bash
cd cloud-lab/terraform
terraform fmt -check
terraform init -backend=false
terraform validate
terraform test
```

`fmt` / `init -backend=false` / `validate` は変数値を必要としません。

`plan` / `apply` を行う場合は、**`admin_cidr` を必ず自分の管理元 CIDR で明示指定** してください。`variables.tf` ではあえて default を設定しておらず、未指定で `apply` できない設計にしています（RFC 5737 のドキュメント用 CIDR が誤って残ったまま SG を作成されることを防ぐため）。`0.0.0.0/0` は validation でブロックされます。

```bash
terraform plan \
  -var='admin_cidr=YOUR.ADMIN.CIDR/32' \
  -var='project=portfolio-cloud-lab'
```

---

## 見せたい運用観点

| 観点 | この Lab で示すこと |
|---|---|
| セグメント分離 | Public / Private subnet を分け、Private 側へ Internet Gateway の直接経路を作らない |
| 最小権限 | SSH は `admin_cidr`、Private 側は Bastion SG からのみ許可 |
| 変更前検証 | `terraform fmt` / `validate` / `test` / TFLint / Trivy config scan を CI で実行 |
| コスト管理 | NAT Gateway / EC2 / Elastic IP をデフォルトで作らない |
| 本番化差分 | Flow Logs、CloudTrail、GuardDuty、AWS Backup、SSM Session Manager を追加候補として整理 |

---

## 本番化するなら足すもの

- **認証**: IAM Identity Center、MFA、最小権限ロール、Break-glass アカウント
- **接続**: SSH 直接公開ではなく SSM Session Manager / VPN / Zero Trust Access
- **ログ**: CloudTrail、VPC Flow Logs、GuardDuty、Security Hub
- **監視**: CloudWatch Alarm、通知先、SLO、Runbook
- **バックアップ**: AWS Backup、世代管理、リストアテスト
- **コスト**: Budget Alert、タグ必須化、リージョン制限

詳細は [../production-readiness.md](../production-readiness.md) にまとめています。

---

## 関連

- [Cloud Lab ページ](../cloud-lab.html)
- [Terraform files](./terraform/)
- [Validation Evidence](../lab-evidence.html)
- [Incident Drill](../incident-drill.html)
- [Production Readiness](../production-readiness.html)
- [Infra Operation Lab](../infra-lab.html)
- [Ansible Playbook](../ansible/)
