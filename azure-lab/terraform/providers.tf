# azurerm プロバイダのバージョン固定。
# 4.x 系は 2024 後半以降の安定系列。
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # 本番ではこちらに切り替え、State をリモート管理する。
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstateXXXX"
  #   container_name       = "tfstate"
  #   key                  = "azure-lab.tfstate"
  # }
}

provider "azurerm" {
  features {}
}
