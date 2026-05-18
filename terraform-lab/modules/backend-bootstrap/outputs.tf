output "resource_group_name" {
  description = "state を格納する RG 名。backend 設定の resource_group_name に入れる。"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Storage Account 名。backend 設定の storage_account_name に入れる。"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "tfstate を置く Blob コンテナ名。"
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config_hcl" {
  description = "そのまま backend.tf に貼れる HCL スニペット。"
  value       = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.tfstate.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "<env>/<component>.tfstate"
      }
    }
  EOT
}
