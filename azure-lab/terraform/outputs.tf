output "resource_group_name" {
  description = "作成したリソースグループ名"
  value       = azurerm_resource_group.lab.name
}

output "vm_private_ip" {
  description = "VM の内部 IP（Bastion 経由のアクセス先）"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "bastion_fqdn" {
  description = "Azure Bastion のホスト名（Portal から接続）"
  value       = azurerm_bastion_host.lab.dns_name
}

output "ssh_via_bastion_hint" {
  description = "Azure Portal の Bastion 接続画面から、上記 vm_private_ip と admin_username を入力して接続する"
  value       = "Azure Portal → ${azurerm_linux_virtual_machine.lab.name} → 接続 → Bastion → ユーザー=${var.admin_username}, SSH 秘密鍵"
}
