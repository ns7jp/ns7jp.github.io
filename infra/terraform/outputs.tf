###############################################################################
# outputs.tf — apply 後にコンソールへ表示する値
###############################################################################

output "instance_id" {
  description = "EC2 インスタンス ID"
  value       = aws_instance.host.id
}

output "public_ip" {
  description = "EC2 のパブリック IPv4 アドレス"
  value       = aws_instance.host.public_ip
}

output "ami_id" {
  description = "起動に使用した Ubuntu 22.04 AMI ID"
  value       = data.aws_ami.ubuntu_2204.id
}

output "ssh_command" {
  description = "SSH 接続コマンドの例 (operator_username + public_ip)"
  value       = "ssh ${var.operator_username}@${aws_instance.host.public_ip}"
}

output "estimated_monthly_cost_usd" {
  description = "想定月額コスト (Free Tier 範囲内なら $0)"
  value       = "Free Tier 範囲内: $0 (t3.micro 750h/月, EBS gp3 30GB/月, データ転送 1GB/月以内)。期限後は約 $9-10/月 (リージョンにより変動)。"
}

output "server_monitor_url" {
  description = "Server Monitor の公開 URL (enable_server_monitor_demo = true の場合は sslip.io 経由で HTTPS 公開)"
  value       = var.enable_server_monitor_demo ? "https://${aws_instance.host.public_ip}.sslip.io" : "(enable_server_monitor_demo = false のため未公開)"
}

output "next_steps" {
  description = "apply 後にやることのチェックリスト"
  value       = <<-EOT
    1. cloud-init の完了を待つ (4〜6 分。Server Monitor + Caddy のセットアップを含む)。
       ssh ${var.operator_username}@${aws_instance.host.public_ip} 'cloud-init status --wait'
    2. /opt/support-toolkit/ 以下に Bash スクリプトが配置されていることを確認。
    3. /etc/cron.d/support-toolkit-daily の登録を確認 (毎朝 06:00 に容量・セキュリティ点検)。
    %{if var.enable_server_monitor_demo}4. ブラウザで https://${aws_instance.host.public_ip}.sslip.io を開き、Server Monitor が表示されることを確認。
       (初回アクセスは Let's Encrypt の証明書発行で 30〜60 秒かかる場合あり)
    5. 不要になったら 'terraform destroy' で完全に削除する (課金回避)。%{else}4. 不要になったら 'terraform destroy' で完全に削除する (課金回避)。%{endif}
  EOT
}
