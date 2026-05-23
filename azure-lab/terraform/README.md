# Azure Lab — Terraform 実行手順

## 1. 前提

| ツール | バージョン |
|--------|------------|
| Terraform | 1.5 以上 |
| Azure CLI | 2.50 以上（`az login` 用） |
| Azure サブスクリプション | 無料枠で可（Bastion Basic は 1 時間 $0.19 程度の課金あり） |
| SSH 鍵 | ed25519 推奨 (`ssh-keygen -t ed25519`) |

## 2. 初期化と確認

```bash
cd azure-lab/terraform

# プロバイダのダウンロード
terraform init

# コードのフォーマット確認（差分があれば一覧表示）
terraform fmt -check -recursive

# 構文と参照整合の確認
terraform validate
```

## 3. 何が作成されるかを Plan

```bash
terraform plan \
  -var "admin_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -out=plan.out
```

`plan` 内訳の例（Lab 想定）:

```
Plan: 9 to add, 0 to change, 0 to destroy.

  + azurerm_resource_group.lab
  + azurerm_virtual_network.lab
  + azurerm_subnet.app
  + azurerm_subnet.bastion
  + azurerm_network_security_group.app
  + azurerm_subnet_network_security_group_association.app
  + azurerm_network_interface.vm
  + azurerm_linux_virtual_machine.lab
  + azurerm_public_ip.bastion
  + azurerm_bastion_host.lab
```

## 4. Apply（任意 / 実機デプロイ）

```bash
az login
terraform apply plan.out
```

完了後の outputs:

```
Outputs:

resource_group_name = "shimada-lab-rg"
vm_private_ip       = "10.50.10.4"
bastion_fqdn        = "bst-xxxx.bastion.azure.com"
ssh_via_bastion_hint = "Azure Portal → shimada-lab-vm → 接続 → Bastion → ユーザー=opsadmin, SSH 秘密鍵"
```

## 5. 接続

Azure Portal → VM → 「接続」→ Bastion を選択 → 上記の username と SSH 秘密鍵で接続。
Internet からの直接 SSH（22 番）は NSG で拒否済のため、Bastion 経由が唯一の経路です。

## 6. 後片付け

```bash
terraform destroy
```

Bastion は **時間課金** なので、検証後は必ず destroy してください。

## 7. オンプレ Ansible との接続

VM 起動後は、本リポジトリの [`../../ansible/`](../../ansible/) Playbook を **Bastion 経由** で実行できます。

```bash
# Azure Bastion native client 経由でローカルにポートフォワード
az network bastion ssh \
  --name shimada-lab-bastion \
  --resource-group shimada-lab-rg \
  --target-resource-id $(az vm show -g shimada-lab-rg -n shimada-lab-vm --query id -o tsv) \
  --auth-type ssh-key \
  --username opsadmin \
  --ssh-key ~/.ssh/id_ed25519

# 別ターミナルで ansible 実行
ansible-playbook -i azure-inventory.ini ../../ansible/playbook.yml --check --diff
```

> オンプレ用 Playbook が **クラウド側でもそのまま流せる** ことが、`infra-lab.html` の VLAN と統一した
> 設計の利点です。`/etc/timezone`, `unattended-upgrades`, `ufw`, `fail2ban` などはオンプレ・クラウド共通で
> 効きます。
