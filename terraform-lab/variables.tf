# 変数定義。tfvars / 環境変数 / CLI 引数のいずれからでも上書きできる。
# 機密値 (admin_source_cidr など) は tfvars をローカルに置き、.gitignore で除外する。

variable "project" {
  description = "リソース名のプレフィックスに使う短い識別子"
  type        = string
  default     = "infralab"
}

variable "environment" {
  description = "dev / stg / prod のいずれか。タグとリソース名に反映される。"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment must be one of: dev, stg, prod."
  }
}

variable "location" {
  description = "Azure リージョン"
  type        = string
  default     = "japaneast"
}

variable "vm_size" {
  description = "VM サイズ。学習用途は B1s で月数百円。"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "SSH ログインユーザー"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "ローカルの SSH 公開鍵パス。例: ~/.ssh/id_ed25519.pub"
  type        = string
}

variable "admin_source_cidr" {
  description = "SSH / node_exporter を許可する送信元 IP レンジ。自宅 IP/32 を推奨。0.0.0.0/0 は NG。"
  type        = string

  validation {
    condition     = var.admin_source_cidr != "0.0.0.0/0"
    error_message = "admin_source_cidr に 0.0.0.0/0 を指定しないでください。許可送信元は最小化が前提です。"
  }
}
