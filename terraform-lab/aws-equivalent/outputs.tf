output "instance_public_ip" {
  description = "EC2 のグローバル IP (EIP)。Prometheus target に渡す。"
  value       = aws_eip.lab.public_ip
}

output "ssh_command" {
  description = "そのままコピペできる SSH コマンド"
  value       = "ssh -i <private_key> ubuntu@${aws_eip.lab.public_ip}"
}

output "prometheus_target" {
  description = "monitoring-stack の prometheus.yml にそのまま貼れる target"
  value       = "${aws_eip.lab.public_ip}:9100"
}
