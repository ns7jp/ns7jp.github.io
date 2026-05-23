output "vpc_id" {
  description = "Created VPC ID."
  value       = aws_vpc.lab.id
}

output "public_subnet_id" {
  description = "Public subnet ID for bastion-style entry points."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID for internal servers."
  value       = aws_subnet.private.id
}

output "bastion_security_group_id" {
  description = "Security group that accepts SSH only from admin_cidr."
  value       = aws_security_group.bastion.id
}

output "private_app_security_group_id" {
  description = "Security group that accepts SSH and node_exporter only from the bastion SG."
  value       = aws_security_group.private_app.id
}
