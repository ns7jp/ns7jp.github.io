mock_provider "aws" {}

run "approved_admin_cidr_and_sg_reference" {
  # The mock provider resolves generated security group IDs without calling AWS.
  command = apply

  variables {
    admin_cidr = "203.0.113.10/32"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.bastion_ssh.cidr_ipv4 == "203.0.113.10/32"
    error_message = "Bastion SSH must use only the explicitly approved administrator CIDR."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.private_ssh_from_bastion.referenced_security_group_id == aws_security_group.bastion.id
    error_message = "Private SSH must be restricted to the bastion security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.private_node_exporter_from_bastion.referenced_security_group_id == aws_security_group.bastion.id
    error_message = "Private monitoring access must be restricted to the bastion security group."
  }
}

run "reject_world_open_ssh" {
  command = plan

  variables {
    admin_cidr = "0.0.0.0/0"
  }

  expect_failures = [var.admin_cidr]
}
