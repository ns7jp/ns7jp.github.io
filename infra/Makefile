# Makefile — Terraform 操作のラッパ
# AWS 認証情報は事前に環境変数 (AWS_PROFILE / AWS_ACCESS_KEY_ID 等) で設定すること。

TF_DIR := terraform

.PHONY: help init validate fmt plan apply destroy show output ssh

help: ## このヘルプを表示
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "\033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

init: ## Terraform プロバイダを初期化
	cd $(TF_DIR) && terraform init

validate: ## 構文チェック
	cd $(TF_DIR) && terraform validate

fmt: ## .tf ファイルを公式フォーマッタで整形
	cd $(TF_DIR) && terraform fmt -recursive

plan: ## 変更プランを表示 (apply 前に必ず実行)
	cd $(TF_DIR) && terraform plan -out=tfplan

apply: ## plan で生成した tfplan を適用
	cd $(TF_DIR) && terraform apply tfplan

destroy: ## 作成したリソースを完全削除 (課金停止のため使い終わったら必ず)
	cd $(TF_DIR) && terraform destroy

show: ## 現在の state を表示
	cd $(TF_DIR) && terraform show

output: ## outputs.tf の値を表示
	cd $(TF_DIR) && terraform output

ssh: ## apply 後の EC2 に SSH (output の ssh_command を実行)
	$$(cd $(TF_DIR) && terraform output -raw ssh_command)
