# Lab パラメータ。環境差は variables.tfvars で吸収する。

variable "prefix" {
  description = "リソース名のプレフィックス（例: shimada-lab）"
  type        = string
  default     = "shimada-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.prefix))
    error_message = "prefix は小文字英数とハイフンで 3-21 文字にしてください。"
  }
}

variable "location" {
  description = "Azure リージョン"
  type        = string
  default     = "japaneast"
}

variable "admin_username" {
  description = "VM の管理ユーザー名（root はブロックされるため避ける）"
  type        = string
  default     = "opsadmin"
}

variable "admin_pubkey" {
  description = "管理ユーザーに登録する公開鍵（ssh-ed25519 推奨）"
  type        = string
  sensitive   = true
  # 値はコマンドラインで -var "admin_pubkey=$(cat ~/.ssh/id_ed25519.pub)" 渡し
}

variable "vm_size" {
  description = "VM サイズ。Lab は Standard_B1s、DR 演習向けは Standard_D2s_v5 など"
  type        = string
  default     = "Standard_B1s"
}

variable "tags" {
  description = "全リソースに付与する共通タグ"
  type        = map(string)
  default = {
    env     = "lab"
    owner   = "ns7jp"
    purpose = "az104-study"
  }
}
