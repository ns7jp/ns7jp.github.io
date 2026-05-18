# backend-bootstrap モジュール

Terraform の **リモートステート保管基盤** (Azure Storage Account) を立てる卵が先か鶏が先か問題を解くためのブートストラップモジュールです。

## なぜ別モジュールか

メインの `terraform-lab/` は **ローカル state で apply する Lab 想定** ですが、本番では state を共有・ロック・暗号化・バージョン管理する必要があります。それを満たす Storage Account を Terraform で立てるためのコードを、メインから分離してここに置いています。

## 何を作るか

- Resource Group (削除防止ロック付き)
- Storage Account (TLS 1.2 必須, GRS, versioning, change feed, soft delete 30 日)
- Blob Container (private)
- IP allowlist (default deny)

## 使い方

```bash
# 1. このモジュールだけを apply (ローカル state で OK)
cd modules/backend-bootstrap
terraform init
terraform apply \
  -var='project=infralab' \
  -var='allowed_ip_ranges=["203.0.113.10/32"]'

# 2. 出力された backend HCL をメインの terraform-lab/ に貼る
terraform output -raw backend_config_hcl > ../../backend.tf

# 3. メイン側で migrate
cd ../..
terraform init -migrate-state   # ローカル state を Azure へ移行
```

## state を消したいとき

1. RG の削除ロックを外す (`azurerm_management_lock` を `terraform destroy` で消す前に、ポータルで CanNotDelete を確認)
2. soft delete で 30 日復元可能
3. それでも消すなら `az storage account delete` を **承認フロー** 経由で
