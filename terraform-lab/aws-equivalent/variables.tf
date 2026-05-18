variable "project" {
  description = "リソース名プレフィックス"
  type        = string
  default     = "infralab"
}

variable "environment" {
  description = "dev / stg / prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment must be one of: dev, stg, prod."
  }
}

variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "EC2 インスタンスタイプ。Graviton で安価。"
  type        = string
  default     = "t4g.nano"
}

variable "ssh_public_key_path" {
  description = "ローカルの SSH 公開鍵パス"
  type        = string
}

variable "admin_source_cidr" {
  description = "SSH / node_exporter を許可する送信元 IP。0.0.0.0/0 は禁止。"
  type        = string

  validation {
    condition     = var.admin_source_cidr != "0.0.0.0/0"
    error_message = "admin_source_cidr に 0.0.0.0/0 は指定できません。"
  }
}
