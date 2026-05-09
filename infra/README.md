# infra/ — Cloud Server Bootstrap (AWS Free Tier + Terraform + cloud-init)

「**Linux サーバーを最小構成で・安全に・再現可能に立ち上げる**」ことを示す Infrastructure-as-Code サンプルです。Terraform で VPC + EC2 を AWS Free Tier 内に構築し、cloud-init で SSH ハードニング・ホスト FW・自動更新・[`support-scripts`](../support-scripts/) (Bash 版) の cron 連携までを初回起動時に完結させます。

ポートフォリオ作品の中では、`support-scripts/` の **Bash スクリプトが「実際にどこで動くのか」** を示す位置づけです。スクリプト単体のサンプルから一歩進め、**運用環境ごと IaC で再現できる** 形に仕上げました。

| 項目 | 値 |
|---|---|
| 想定クラウド | AWS (リージョンは `ap-northeast-1` をデフォルト) |
| インスタンス | EC2 t3.micro (Free Tier 対象) |
| OS | Ubuntu 22.04 LTS (Canonical 公式 AMI、`data` source で動的解決) |
| IaC ツール | Terraform 1.5+ / AWS Provider ~> 5.0 |
| 想定月額 | **$0** (Free Tier 範囲内: t3.micro 750h + EBS gp3 30GB) / 期限後は約 $9-10 |
| 作成リソース数 | 7 個 (VPC / Subnet / IGW / Route Table / RTA / SG / EC2) |

---

## 🗺 構成図

![Cloud Server Bootstrap 構成図 — 運用者 PC からインターネット越しに AWS Region (ap-northeast-1) の VPC 10.0.0.0/16 に SSH 接続。Public Subnet 10.0.1.0/24 内の EC2 t3.micro (Ubuntu 22.04 LTS) で cloud-init が SSH ハードニング、ufw、fail2ban、unattended-upgrades、support-toolkit クローンと cron 登録までを冪等に実行する 10 ステップを示した図](../image/cloud-architecture.svg)

> ポートフォリオサイトでは [Works ページの「Cloud Server Bootstrap」セクション](https://ns7jp.github.io/works.html#work-cloud-bootstrap) でも同じ図を掲載しています。

---

## 📂 ファイル構成

```text
infra/
├── README.md                          ... このファイル
├── Makefile                           ... terraform init/plan/apply/destroy のラッパ
├── .gitignore                         ... tfstate / tfvars をコミット対象外にする
└── terraform/
    ├── main.tf                        ... VPC + IGW + Subnet + RT + SG + EC2 + AMI lookup
    ├── variables.tf                   ... 入力変数 + validation (CIDR・公開鍵フォーマット等)
    ├── outputs.tf                     ... public_ip, ssh_command, 推定コスト, 次のステップ
    ├── cloud-init.yaml                ... 初回起動時の OS ハードニング + support-toolkit 連携
    └── terraform.tfvars.example       ... 値の埋め方サンプル (コピーして terraform.tfvars に)
```

---

## 🚀 デプロイ手順

### 0. 前提

- AWS アカウント (Free Tier 期間内なら 12 か月以内に作成したもの)
- Terraform 1.5+ がローカルに入っていること: `terraform -version`
- AWS 認証情報が環境変数 (`AWS_PROFILE` / `AWS_ACCESS_KEY_ID`+`AWS_SECRET_ACCESS_KEY`) で設定済み
- AWS コンソールで EC2 Key Pair を 1 つ作成済み (秘密鍵をローカルに保存)
- 自分の固定 IP (自宅・VPN 出口など) を `203.0.113.42/32` 形式で把握

### 1. 値を設定

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を開き、最低限以下を自分の環境に合わせて書き換える:

```hcl
ssh_key_name     = "my-tokyo-keypair"          # AWS で作った Key Pair 名
allowed_ssh_cidr = "203.0.113.42/32"           # 自分の固定 IP
operator_pubkey  = "ssh-ed25519 AAAAC3..."     # ~/.ssh/id_ed25519.pub の中身
```

> `0.0.0.0/0` を `allowed_ssh_cidr` に入れると Terraform 側の validation で拒否されます (全世界に SSH を開放するのは危険なため)。

### 2. プラン → 適用

リポジトリルートから:

```bash
cd infra
make init     # terraform init (初回のみ)
make plan     # 何が作られるかを確認 (7 リソース)
make apply    # tfplan を適用 (3〜5 分)
```

### 3. 接続確認

```bash
make ssh      # outputs.tf の ssh_command を実行し、operator_username で SSH
```

cloud-init が完了するまで 1〜3 分かかります。`cloud-init status --wait` で完了を待てます。

### 4. 動作確認

```bash
# 日次 cron が登録されている
cat /etc/cron.d/support-toolkit-daily

# Bash スクリプトが配置されている
ls -la /opt/support-toolkit/

# 一発手動実行してみる
/opt/support-toolkit/test-disk-capacity.sh | jq .

# fail2ban / ufw / unattended-upgrades が走っている
systemctl is-active fail2ban unattended-upgrades
sudo ufw status verbose
```

### 5. 後片付け (重要)

```bash
make destroy  # 全リソースを削除して課金を止める
```

`terraform destroy` を実行しないと Free Tier 期限後に EC2 と EBS で課金が続きます。**ポートフォリオ用にデモした後は必ず destroy** してください。

---

## 🔒 セキュリティ設計

| 防御層 | 実装 |
|---|---|
| ① ネットワーク | Security Group で 22/tcp を運用者 CIDR からのみ許可。`0.0.0.0/0` は Terraform validation で拒否。 |
| ② ホスト FW | ufw を `deny incoming` で起動し、22/tcp のみ allow。Security Group との二重防御。 |
| ③ SSH 認証 | パスワード認証無効、root ログイン禁止、公開鍵 (ed25519 推奨) のみ。`drop-in` 設定で OS アップデートに耐える。 |
| ④ ブルートフォース | fail2ban で 10 分以内 5 回失敗 → 1 時間 ban。 |
| ⑤ パッチ | unattended-upgrades で自動セキュリティパッチ。 |
| ⑥ メタデータ | IMDSv2 強制 (`http_tokens = required`) で SSRF 経由の漏洩対策。 |
| ⑦ ストレージ | EBS root volume を `encrypted = true` で暗号化。 |
| ⑧ 監査 | journald + cron 出力 + `support-toolkit` の日次 JSON が `/var/log/support-toolkit/` に蓄積。logrotate で 90 日保持。 |

---

## 🧠 設計判断とトレードオフ

| 判断 | 理由 |
|---|---|
| **Terraform を採用** (vs CloudFormation / CDK / Pulumi) | プロバイダ非依存、求人での出現頻度が高い、コミュニティの StackOverflow が厚い。 |
| **cloud-init を Terraform から渡す** (vs Ansible 後追い実行) | Free Tier 規模では別プロビジョニングサーバーを立てるコストが見合わない。`templatefile()` で IaC 内で完結する。 |
| **Public Subnet に EC2 を直接配置** (vs ALB + Private Subnet) | Free Tier 内で完結させるため、ALB と NAT GW のコストを避ける。本番では NAT GW + ALB に置き換え可能 (この差は README の「将来の拡張」で言及)。 |
| **AMI は data source で動的解決** (vs 固定 AMI ID) | リージョンを変えても動く / 最新パッチ済み AMI を自動取得 / IaC のポータビリティが上がる。 |
| **operator user を別途作成** (vs ubuntu user 流用) | 命名で運用責任が明確化、`ubuntu` の慣習に依存しない。 |
| **`set -euo pipefail` 風の Terraform validation** | `allowed_ssh_cidr` の `0.0.0.0/0` 拒否、`operator_pubkey` の OpenSSH 形式チェック。誤設定を CI 段階でブロック。 |
| **terraform.tfvars を `.gitignore`** | 公開鍵以外にも自分の IP / Key Pair 名が混ざるため、誤コミットを防ぐ。 |

---

## 🚧 意図的に省いた要素 (本番で必要なもの)

このサンプルは **「最小構成で安全な単発デモ」** を目的としているため、以下は意図的に含めていません。本番運用で必要になる要素として認識しています。

- **マルチ AZ / Auto Scaling Group** — 単一インスタンスのため SPOF。
- **ALB + Route53 + ACM** — TLS 終端と公開ホスト名。t3.micro 単体に Let's Encrypt を入れる代替もある。
- **RDS / ElastiCache** — このデモは状態を持たない (運用ログだけ)。データベースが必要な系では別途。
- **VPC Flow Logs / CloudTrail / GuardDuty** — 監査・脅威検知。本番では必須だが Free Tier 外。
- **Terraform リモートバックエンド (S3 + DynamoDB lock)** — 複数人での state 共有と排他制御。
- **CI/CD パイプライン** — `terraform plan` を PR 上で diff 表示する Atlantis / GitHub Actions など。
- **Ansible / Chef での構成管理** — 本サンプルは初回 cloud-init のみ。差分適用が必要なら別途。
- **タグポリシー / SCP** — 組織横断のガードレール。
- **Bastion Host / SSM Session Manager** — Public Subnet ではなく Private Subnet に EC2 を置く構成への移行。

---

## ✅ 動作確認チェックリスト

apply 後に SSH してから次を確認すると、IaC + 構成管理が一通り通ったことが分かります。

```bash
# 1. cloud-init が完了している
sudo cat /var/log/cloud-init-output.log | tail -20
test -f /var/log/support-toolkit/.bootstrap-complete && echo "bootstrap OK"

# 2. SSH ハードニング drop-in が効いている
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"
# 期待: permitrootlogin no, passwordauthentication no

# 3. ホスト FW が有効
sudo ufw status verbose
# 期待: Status: active / 22/tcp ALLOW

# 4. fail2ban の sshd jail が走っている
sudo fail2ban-client status sshd

# 5. 自動更新が動いている
systemctl is-active unattended-upgrades

# 6. cron 登録と Bash スクリプト
ls -la /etc/cron.d/support-toolkit-daily /opt/support-toolkit/

# 7. support-toolkit の手動実行
/opt/support-toolkit/test-security-baseline.sh | jq '.Overall, .Checks[] | {Name, Status}'
```

---

## 関連リンク

- [`../support-scripts/`](../support-scripts/) — このサーバー上で cron 実行される Bash スクリプト本体
- [`../support-docs/`](../support-docs/) — 想定環境と運用手順の文書集
- 🌐 [ポートフォリオサイト Works](https://ns7jp.github.io/works.html) — 全制作物のカード形式紹介

---

**著者**: 島田則幸 (Noriyuki Shimada) / 📧 net7jp@gmail.com
