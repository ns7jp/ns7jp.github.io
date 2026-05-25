terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project
    Environment = "lab"
    ManagedBy   = "terraform"
    Purpose     = "portfolio-cloud-network-lab"
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-vpc"
  })
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = merge(local.common_tags, {
    Name = "${var.project}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-public-a"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project}-private-a"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg"
  description = "Allow SSH from the approved admin CIDR only"
  vpc_id      = aws_vpc.lab.id

  tags = merge(local.common_tags, {
    Name = "${var.project}-bastion-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from admin CIDR"
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  description       = "Outbound for package updates and private host access"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "private_app" {
  name        = "${var.project}-private-app-sg"
  description = "Allow private host access only from bastion security group"
  vpc_id      = aws_vpc.lab.id

  tags = merge(local.common_tags, {
    Name = "${var.project}-private-app-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh_from_bastion" {
  security_group_id            = aws_security_group.private_app.id
  description                  = "SSH from bastion SG"
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "private_node_exporter_from_bastion" {
  security_group_id            = aws_security_group.private_app.id
  description                  = "node_exporter from bastion SG for lab monitoring"
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 9100
  ip_protocol                  = "tcp"
  to_port                      = 9100
}

resource "aws_vpc_security_group_egress_rule" "private_all" {
  security_group_id = aws_security_group.private_app.id
  description       = "Outbound for OS updates through future NAT or proxy"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
