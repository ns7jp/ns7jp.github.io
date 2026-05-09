###############################################################################
# main.tf — AWS Free Tier (t3.micro) で Linux サーバーを 1 台構築する
#
# 目的:
#   Support Toolkit (Bash 版) を実行する想定の Linux サーバーを、最小構成で
#   再現可能に立ち上げる。Free Tier 範囲 (t3.micro 750h/月, EBS 30GB/月) で
#   月額 $0 になるよう調整した。
#
# 構成:
#   - VPC (10.0.0.0/16) + Public Subnet (10.0.1.0/24) + IGW + Route Table
#   - Security Group: 運用者 IP からの SSH のみ許可 (0.0.0.0/0 は validation で拒否)
#   - EC2: t3.micro, Ubuntu 22.04 LTS (Canonical 公式 AMI を data source で動的取得)
#   - cloud-init: SSH ハードニング, ufw, fail2ban, unattended-upgrades, cron 連携
#
# 設計判断:
#   - IMDSv2 強制 (http_tokens = required) で SSRF 経由のメタデータ漏洩を防ぐ
#   - EBS は gp3 + 暗号化 (Free Tier 内, 性能は gp2 と同等以上で安価)
#   - default_tags でコスト集計と所有確認用のタグを自動付与
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "support-toolkit-demo"
      ManagedBy   = "Terraform"
      Environment = "free-tier-demo"
      Owner       = var.operator_username
    }
  }
}

# ---------- AMI: Canonical 公式 Ubuntu 22.04 LTS (HVM, gp2/gp3) を取得 ----------
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical 公式

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --------------------------------- ネットワーク ---------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "support-toolkit-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "support-toolkit-public-1a"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "support-toolkit-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "support-toolkit-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --------------------------- Security Group ---------------------------
# - SSH: 運用者 CIDR からのみ許可
# - HTTP/HTTPS: enable_server_monitor_demo = true のときだけ 0.0.0.0/0 を許可
#   (Server Monitor を公開する demo 目的。dynamic ブロックでオン・オフ可能)
resource "aws_security_group" "host" {
  name        = "support-toolkit-host-sg"
  description = "SSH from operator CIDR; HTTP(S) from anywhere when public demo is enabled."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  dynamic "ingress" {
    for_each = var.enable_server_monitor_demo ? toset([80, 443]) : toset([])
    content {
      description = ingress.value == 80 ? "HTTP (Let's Encrypt ACME challenge / 301 redirect to HTTPS)" : "HTTPS (Server Monitor public demo via Caddy)"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "All outbound (apt update, package install, ACME, monitoring egress)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "support-toolkit-host-sg"
  }
}

# --------------------------------- EC2 インスタンス ---------------------------------
resource "aws_instance" "host" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.host.id]
  key_name               = var.ssh_key_name

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    operator_username          = var.operator_username
    operator_pubkey            = var.operator_pubkey
    portfolio_repo             = var.portfolio_repo
    enable_server_monitor_demo = var.enable_server_monitor_demo
    server_monitor_repo        = var.server_monitor_repo
    acme_email                 = var.acme_email
  })

  # IMDSv2 強制 (SSRF 経由のメタデータ漏洩対策)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "support-toolkit-host"
  }
}
