# Azure 版 (../main.tf) と等価な構成を AWS で書いた版。
# 同じ要件を別クラウドでどう書き換えるか、を見せるための姉妹モジュール。
#
# - VPC + Subnet + IGW + Route Table (Azure の VNet + Subnet 相当)
# - Security Group (Azure NSG 相当)
# - EC2 t4g.nano (Azure B1s 相当の最小サイズ)
# - cloud-init で node_exporter 自動セットアップ (Azure 版と同じ手順)
# - state は S3 + DynamoDB lock を想定 (../backend-bootstrap の AWS 版相当)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
      owner       = "ns7jp"
    }
  }
}

# 最新の Ubuntu 22.04 ARM AMI を動的に取得 (Graviton で安価)
data "aws_ami" "ubuntu_2204_arm" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.project}-${var.environment}"
  }
}

resource "aws_subnet" "server" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.20.20.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "snet-server-${var.environment}"
  }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags = {
    Name = "igw-${var.project}-${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = {
    Name = "rtb-public-${var.environment}"
  }
}

resource "aws_route_table_association" "server" {
  subnet_id      = aws_subnet.server.id
  route_table_id = aws_route_table.public.id
}

# SG: SSH (22) と node_exporter (9100) を admin IP のみ許可。Azure NSG と同じ思想。
resource "aws_security_group" "server" {
  name        = "sg-server-${var.environment}"
  description = "Allow SSH and node_exporter from admin only"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_source_cidr]
  }

  ingress {
    description = "node_exporter from admin"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.admin_source_cidr]
  }

  egress {
    description = "Allow all outbound (security patches, package install)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "key-${var.project}-${var.environment}"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_eip" "lab" {
  domain = "vpc"
  tags = {
    Name = "eip-${var.project}-${var.environment}"
  }
}

resource "aws_network_interface" "lab" {
  subnet_id       = aws_subnet.server.id
  security_groups = [aws_security_group.server.id]

  tags = {
    Name = "eni-${var.project}-${var.environment}"
  }
}

resource "aws_eip_association" "lab" {
  network_interface_id = aws_network_interface.lab.id
  allocation_id        = aws_eip.lab.id
}

resource "aws_instance" "lab" {
  ami           = data.aws_ami.ubuntu_2204_arm.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.admin.key_name

  network_interface {
    network_interface_id = aws_network_interface.lab.id
    device_index         = 0
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 強制 (SSRF 対策)
    http_put_response_hop_limit = 1
  }

  user_data = templatefile("${path.module}/../cloud-init.yaml", {
    node_exporter_version = "1.8.2"
  })

  tags = {
    Name = "ec2-${var.project}-${var.environment}"
  }
}
