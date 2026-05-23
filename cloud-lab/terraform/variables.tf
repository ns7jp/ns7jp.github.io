variable "aws_region" {
  description = "AWS region for the Cloud Network Lab."
  type        = string
  default     = "ap-northeast-1"
}

variable "availability_zone" {
  description = "Single availability zone used by this low-cost lab."
  type        = string
  default     = "ap-northeast-1a"
}

variable "project" {
  description = "Project prefix used for resource names and tags."
  type        = string
  default     = "portfolio-cloud-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.20.10.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
  default     = "10.20.20.0/24"
}

variable "admin_cidr" {
  description = "Approved source CIDR for SSH to the bastion security group. Replace before applying."
  type        = string
  default     = "203.0.113.10/32"
}
