###############################################################################
# variables.tf — 入力変数
#
# - 必須変数 (default なし) は ssh_key_name, allowed_ssh_cidr, operator_pubkey
# - 値は terraform.tfvars または -var で渡す。 terraform.tfvars.example を参照。
###############################################################################

variable "aws_region" {
  description = "AWS リージョン。Free Tier 期間中はどのリージョンでも対象 (東京: ap-northeast-1, 米バージニア: us-east-1 など)。"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "EC2 インスタンスタイプ。Free Tier は t3.micro / t2.micro が対象 (リージョンにより異なる)。"
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "EC2 にアタッチする AWS Key Pair 名。AWS コンソールで事前に作成しておくこと。"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "SSH を許可する送信元 CIDR (例: 自宅 IP / VPN 出口)。0.0.0.0/0 は明示的に拒否する。"
  type        = string

  validation {
    condition     = var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "全世界に SSH を開放するのは危険です。allowed_ssh_cidr に自分の IP/CIDR を指定してください (例: 203.0.113.42/32)。"
  }

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]+$", var.allowed_ssh_cidr))
    error_message = "allowed_ssh_cidr は CIDR 形式で指定してください (例: 203.0.113.42/32)。"
  }
}

variable "operator_username" {
  description = "cloud-init で作成する運用ユーザー名。デフォルトの ubuntu/ec2-user とは別に作成し、sudo を付与する。"
  type        = string
  default     = "ops"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_-]{0,30}$", var.operator_username))
    error_message = "operator_username は小文字英数字・ハイフン・アンダースコアで 1〜31 文字以内にしてください。"
  }
}

variable "operator_pubkey" {
  description = "operator_username の ~/.ssh/authorized_keys に書き込む SSH 公開鍵 (ssh-ed25519 推奨)。"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-) ", var.operator_pubkey))
    error_message = "operator_pubkey は OpenSSH 公開鍵フォーマット (ssh-ed25519 / ssh-rsa / ecdsa-sha2-) で指定してください。"
  }
}

variable "portfolio_repo" {
  description = "cloud-init が support-scripts をクローンする Git URL。デフォルトはこのポートフォリオ。"
  type        = string
  default     = "https://github.com/ns7jp/ns7jp.github.io.git"
}

# --------------------- Server Monitor 公開デモ関連 ---------------------

variable "enable_server_monitor_demo" {
  description = "Server Monitor (https://github.com/ns7jp/server-monitor) を Caddy + sslip.io 経由で公開デモとして起動する。true にすると 80/443 が 0.0.0.0/0 から許可される (公開デモ用途)。"
  type        = bool
  default     = true
}

variable "server_monitor_repo" {
  description = "Server Monitor のクローン元 Git URL (公開リポジトリのみ対応)。"
  type        = string
  default     = "https://github.com/ns7jp/server-monitor.git"
}

variable "acme_email" {
  description = "Let's Encrypt 証明書取得時の連絡先メール。期限切れ通知に使われる。デフォルトはダミーで動作するが、実運用では自分のメールに変更を強く推奨。"
  type        = string
  default     = "demo@example.invalid"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.acme_email))
    error_message = "acme_email はメールアドレス形式で指定してください (例: alice@example.com)。"
  }
}
