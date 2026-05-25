mock_provider "aws" {
  override_during = plan
}

run "plans_segmented_network_with_restricted_ssh" {
  command = plan

  variables {
    admin_cidr = "203.0.113.10/32"
  }

  assert {
    condition     = aws_subnet.public.map_public_ip_on_launch == true
    error_message = "The public subnet must explicitly permit public addressing for the bastion scenario."
  }

  assert {
    condition     = aws_subnet.private.map_public_ip_on_launch == false
    error_message = "The private subnet must not auto-assign public IP addresses."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.bastion_ssh.cidr_ipv4 == "203.0.113.10/32"
    error_message = "Bastion SSH must be restricted to the supplied administrator CIDR."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.private_ssh_from_bastion.referenced_security_group_id == aws_security_group.bastion.id
    error_message = "Private SSH must be limited to the bastion security group."
  }
}

run "rejects_world_open_bastion_ssh" {
  command = plan

  variables {
    admin_cidr = "0.0.0.0/0"
  }

  expect_failures = [
    var.admin_cidr,
  ]
}
