variable "project" {
  description = "プロジェクト識別子 (storage account 名に使うので英小数のみ、3-10 文字)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.project))
    error_message = "project は英小文字と数字のみ、3-10 文字で指定してください。"
  }
}

variable "location" {
  description = "Storage Account のリージョン"
  type        = string
  default     = "japaneast"
}

variable "allowed_ip_ranges" {
  description = "state アクセスを許可する IP レンジ。CI ランナー / 自宅 / VPN GW を列挙する。"
  type        = list(string)

  validation {
    condition     = length(var.allowed_ip_ranges) > 0
    error_message = "最低 1 つの IP レンジを指定してください。空配列は public access になります。"
  }
}
