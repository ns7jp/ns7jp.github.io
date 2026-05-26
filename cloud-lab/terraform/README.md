# Terraform — Cloud Network Lab

AWS VPC / Subnet / Route Table / Security Group だけを作る最小 Terraform です。EC2、NAT Gateway、Elastic IP はデフォルトで作らないため、構成理解と構文検証に集中できます。

## Commands

```bash
terraform fmt -check -recursive
terraform init -backend=false -lockfile=readonly
terraform validate
terraform test
terraform plan -var='admin_cidr=203.0.113.10/32'
```

## Notes

- `admin_cidr` は適用前に自分の固定グローバルIPへ変更します。
- `203.0.113.0/24` はドキュメント用の TEST-NET-3 です。実環境では使いません。
- `.terraform.lock.hcl` は CI とローカル検証で使用する AWS provider の版とチェックサムを固定します。
- `tests/network_security.tftest.hcl` は mock provider を使い、AWS にリソースを作らずに世界公開 SSH の拒否と Private 側の SG 参照制限を検証します。
- 課金リソースを追加する場合は、削除手順と Budget Alert を先に用意します。
