# Terraform — Cloud Network Lab

AWS VPC / Subnet / Route Table / Security Group だけを作る最小 Terraform です。EC2、NAT Gateway、Elastic IP はデフォルトで作らないため、構成理解と構文検証に集中できます。

## Commands

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
terraform plan -var='admin_cidr=203.0.113.10/32'
```

## Notes

- `admin_cidr` は適用前に自分の固定グローバルIPへ変更します。
- `203.0.113.0/24` はドキュメント用の TEST-NET-3 です。実環境では使いません。
- 課金リソースを追加する場合は、削除手順と Budget Alert を先に用意します。
