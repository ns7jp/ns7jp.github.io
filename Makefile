# Lab 全体のエントリポイント。
# レビュアー / 採用担当者が「とにかく何ができるか」 を 1 ヶ所で把握できるようにする。
#
# 使い方: `make help` で一覧、`make <target>` で実行。
# サブターゲットは各 Lab の README にも書いてあるが、ここでは全部入りで揃える。

.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help
help: ## このヘルプを表示
	@awk 'BEGIN {FS = ":.*?## "; printf "\nUsage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
		/^[a-zA-Z0-9_/.-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# ----- Static site -----
.PHONY: site/check
site/check: ## HTML リンクと構造を検証
	node scripts/check-static-links.js
	node scripts/check-html-structure.js

.PHONY: site/serve
site/serve: ## ローカルで HTML を配信 (http://localhost:8000)
	python3 -m http.server 8000

# ----- Monitoring stack -----
.PHONY: monitoring/up
monitoring/up: ## Prom + Alertmanager + Grafana + Loki + Promtail を起動
	cd monitoring-stack && docker compose up -d

.PHONY: monitoring/down
monitoring/down: ## 監視スタックを停止
	cd monitoring-stack && docker compose down

.PHONY: monitoring/clean
monitoring/clean: ## 監視スタックをボリュームごと削除
	cd monitoring-stack && docker compose down -v

.PHONY: monitoring/validate
monitoring/validate: ## docker compose / アラートルール構文チェック
	cd monitoring-stack && docker compose config --quiet
	@echo "compose: OK"
	@docker run --rm -v $$(pwd)/monitoring-stack/prometheus:/etc/prometheus prom/prometheus:v2.54.1 \
		promtool check config /etc/prometheus/prometheus.yml

# ----- Terraform (Azure) -----
.PHONY: tf/fmt
tf/fmt: ## terraform fmt -recursive (整形チェック)
	cd terraform-lab && terraform fmt -check -recursive -diff

.PHONY: tf/init
tf/init: ## terraform init (backend 無効)
	cd terraform-lab && terraform init -backend=false

.PHONY: tf/validate
tf/validate: tf/init ## terraform validate
	cd terraform-lab && terraform validate

.PHONY: tf/plan
tf/plan: ## terraform plan (terraform.tfvars 必須)
	cd terraform-lab && terraform plan -var-file=terraform.tfvars

.PHONY: tf/apply
tf/apply: ## terraform apply (実機作成 / 課金注意)
	cd terraform-lab && terraform apply -var-file=terraform.tfvars

.PHONY: tf/destroy
tf/destroy: ## terraform destroy (放置課金を避けるため必ず実施)
	cd terraform-lab && terraform destroy -var-file=terraform.tfvars

# ----- Ansible -----
.PHONY: ansible/lint
ansible/lint: ## ansible-lint
	ansible-lint ansible/

.PHONY: ansible/syntax
ansible/syntax: ## syntax-check
	ansible-playbook ansible/playbook.yml --syntax-check -i ansible/inventory.ini

.PHONY: ansible/check
ansible/check: ## dry-run (--check --diff)
	ansible-playbook ansible/playbook.yml --check --diff -i ansible/inventory.ini

# ----- Kubernetes -----
.PHONY: k8s/render
k8s/render: ## base + 3 overlays を全レンダリング
	@for d in base overlays/dev overlays/stg overlays/prod; do \
		echo "=== $$d ==="; \
		kustomize build "k8s-lab/$$d"; \
	done

.PHONY: k8s/validate
k8s/validate: ## kubeconform で base + 3 overlays をスキーマ検証
	@for d in base overlays/dev overlays/stg overlays/prod; do \
		echo "=== $$d ==="; \
		kustomize build "k8s-lab/$$d" | kubeconform -summary; \
	done

.PHONY: k8s/apply-dev
k8s/apply-dev: ## dev overlay を現在のコンテキストへ apply
	kubectl apply -k k8s-lab/overlays/dev/

.PHONY: k8s/apply-prod
k8s/apply-prod: ## prod overlay を現在のコンテキストへ apply (実機注意)
	kubectl apply -k k8s-lab/overlays/prod/

.PHONY: k8s/delete-dev
k8s/delete-dev: ## dev overlay を削除
	kubectl delete -k k8s-lab/overlays/dev/

.PHONY: k8s/diff
k8s/diff: ## dev と prod の差分を表示
	@diff <(kustomize build k8s-lab/overlays/dev) <(kustomize build k8s-lab/overlays/prod) || true

# ----- Docker -----
.PHONY: docker/test
docker/test: ## docker-lab の pytest を実行
	cd docker-lab && pytest -ra

.PHONY: docker/build
docker/build: ## healthcheck-cli をビルド
	DOCKER_BUILDKIT=1 docker build -t healthcheck-cli:dev docker-lab/

.PHONY: docker/lint
docker/lint: ## hadolint で Dockerfile を lint
	docker run --rm -i hadolint/hadolint < docker-lab/Dockerfile

.PHONY: docker/scan
docker/scan: docker/build ## Trivy で HIGH/CRITICAL の脆弱性をスキャン
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed healthcheck-cli:dev

.PHONY: docker/run
docker/run: docker/build ## ローカルで起動 (http://localhost:8080)
	docker run --rm -p 8080:8080 --name hc healthcheck-cli:dev

# ----- Support scripts -----
.PHONY: scripts/test
scripts/test: ## Pester で PowerShell スクリプトをテスト
	pwsh -c "Invoke-Pester -Path support-scripts/tests -Output Detailed"

.PHONY: scripts/lint
scripts/lint: ## PSScriptAnalyzer で静的解析
	pwsh -c "Invoke-ScriptAnalyzer -Path support-scripts -Recurse -Severity Error,Warning"

# ----- まとめ -----
.PHONY: validate
validate: site/check monitoring/validate tf/fmt tf/validate ansible/lint k8s/validate docker/lint docker/test ## 全 Lab を一括検証 (apply はしない)
	@echo ""
	@echo "All labs validated."
