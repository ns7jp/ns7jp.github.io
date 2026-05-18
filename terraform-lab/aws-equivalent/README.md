# AWS 等価モジュール

Azure 版 (`../main.tf`) と **同じ要件** を AWS で書き換えたサンプル。「クラウドに依存しない設計力」 と 「Azure / AWS の対応関係の理解」 を示すための姉妹モジュールです。

## Azure ↔ AWS 対応表

| 要件 | Azure 版 | AWS 版 |
|---|---|---|
| 仮想ネットワーク | `azurerm_virtual_network` | `aws_vpc` |
| サブネット | `azurerm_subnet` | `aws_subnet` |
| ファイアウォール | `azurerm_network_security_group` | `aws_security_group` |
| ルーティング | (Subnet に組込) | `aws_route_table` + `aws_internet_gateway` |
| 公開 IP | `azurerm_public_ip` | `aws_eip` |
| 最小 VM | Standard_B1s (x86) | t4g.nano (ARM/Graviton) |
| OS イメージ | `source_image_reference` で Canonical Ubuntu | `data.aws_ami` で動的取得 |
| 初期化 | `custom_data` + cloud-init | `user_data` + cloud-init (**同じファイル**) |
| ディスク暗号化 | デフォルト ON | `encrypted = true` を明示指定 |
| メタデータ保護 | (該当なし) | `http_tokens = required` で IMDSv2 強制 |
| state バックエンド | Azure Storage Account | S3 + DynamoDB lock |
| 月額目安 | ¥2,000 | ¥1,500 (Graviton で更に安い) |

## 同じ cloud-init を使う

`../cloud-init.yaml` を `templatefile()` で両クラウドから読み込みます。node_exporter のセットアップ手順は OS が同じ Ubuntu 22.04 なら一致するので、ファイルを共有して **DRY** にしています。

## 使い方

```bash
cd terraform-lab/aws-equivalent
cp ../terraform.tfvars.example terraform.tfvars  # 編集
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

terraform output prometheus_target

terraform destroy -var-file=terraform.tfvars
```

## ベストプラクティス上のポイント

- **IMDSv2 強制**: `http_tokens = required` で SSRF 経由のメタデータ窃取を防ぐ
- **EBS 暗号化**: `encrypted = true` を明示
- **ARM (Graviton)**: 同性能で 20% 安、消費電力も低い
- **EIP 分離**: インスタンス再作成しても IP が変わらない (NSG/監視設定の追従不要)
- **Default Tags**: provider レベルで全リソースにタグ付け、コスト集計が楽
