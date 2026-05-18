# Plan / Apply 結果を Ansible や監視設定に流し込むために、必要最小限を出力する。

output "resource_group_name" {
  description = "作成したリソースグループ名"
  value       = azurerm_resource_group.lab.name
}

output "vm_public_ip" {
  description = "VM のグローバル IP。Ansible / Prometheus の target に渡す。"
  value       = azurerm_public_ip.lab.ip_address
}

output "ssh_command" {
  description = "そのままコピペできる SSH コマンド"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.lab.ip_address}"
}

output "prometheus_target" {
  description = "monitoring-stack の prometheus.yml にそのまま貼れる target"
  value       = "${azurerm_public_ip.lab.ip_address}:9100"
}
