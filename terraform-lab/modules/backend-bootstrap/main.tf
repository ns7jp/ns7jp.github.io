# Terraform state を Azure Storage Account に保存するためのブートストラップモジュール。
#
# 採用面接で「state はどう管理してますか?」 と聞かれた時の答え:
#   - ローカル state は学習用途のみ
#   - 本番では Azure Storage Account + container を別途 IaC で作り、そこに置く
#   - リソースグループ削除防止ロック (CanNotDelete) を仕掛ける
#   - state container は private、TLS 必須、versioning ON、soft delete 7 日
#   - state ロックは Azure Storage の lease で自動取得 (azurerm backend が処理)
#
# 「state を管理する state はどこに置く?」 という卵が先か鶏が先か問題は、
# このモジュール自体をローカル state で apply し、できた tfstate を別の安全な場所に保管する、
# という割り切りで対応する。または az CLI で手動 bootstrap してから import する。

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Storage Account 名はグローバルユニークなので suffix を付ける
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${var.project}-tfstate"
  location = var.location
  tags = {
    purpose   = "terraform-state"
    project   = var.project
    immutable = "true"
  }
}

# 誤削除防止のロック (CanNotDelete)
# state を消すとリソース全消失と同義なので、必ず仕掛ける。
resource "azurerm_management_lock" "tfstate" {
  name       = "lock-tfstate-no-delete"
  scope      = azurerm_resource_group.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Terraform state を含む RG の誤削除を防ぐ。解除には事前承認を必須とする。"
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "st${var.project}tf${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS" # 別リージョンへの自動レプリ
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties {
    versioning_enabled       = true # 上書き保護
    change_feed_enabled      = true # 変更追跡
    last_access_time_enabled = true

    delete_retention_policy {
      days = 30 # 削除後 30 日は復元可
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ip_ranges
  }

  tags = {
    purpose = "terraform-state"
    project = var.project
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
