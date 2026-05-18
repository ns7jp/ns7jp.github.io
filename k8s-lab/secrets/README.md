# Secret 管理 (SOPS + age)

「Secret を Git に置く」 ことは絶対 NG ですが、**「暗号化された Secret を Git に置く」** のは OK というのが GitOps の標準解です。それを実現するのが SOPS + age の組み合わせです。

## なぜ SealedSecrets ではなく SOPS か

| 観点 | SealedSecrets | SOPS |
|---|---|---|
| 暗号化対象 | k8s Secret のみ | YAML / JSON / .env など何でも |
| 鍵管理 | クラスタに controller を入れる | ローカルに age key を置くだけ |
| GitOps 連携 | ArgoCD 互換 | ArgoCD + helm-secrets / Flux + sops-secrets-operator |
| 学習コスト | 中 (controller の運用) | 低 |
| 適用範囲 | k8s 限定 | Terraform tfvars / Ansible vars にも使える |

Lab では **使い回しが効く SOPS** を採用しています。

## セットアップ

```bash
# 1. age key 生成 (1 ファイルだけ。最重要なのでバックアップ必須)
age-keygen -o ~/.config/sops/age/keys.txt
# 出力例:
#   Public key: age1qfg7yrz5sgnxa8axxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 2. このディレクトリの .sops.yaml に Public key を書く
vi k8s-lab/secrets/.sops.yaml   # age_recipients を書き換える

# 3. SOPS インストール
brew install sops              # macOS
# or
curl -sSL https://github.com/getsops/sops/releases/download/v3.9.0/sops-v3.9.0.linux.amd64 \
  -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops
```

## 使い方

```bash
# 暗号化された Secret を新規作成
sops k8s-lab/secrets/web-credentials.enc.yaml
# エディタで以下を書き、保存すると自動で暗号化される:
#   apiVersion: v1
#   kind: Secret
#   metadata:
#     name: web-credentials
#   stringData:
#     db_password: super-secret

# 復号して確認 (画面に表示)
sops -d k8s-lab/secrets/web-credentials.enc.yaml

# クラスタへ apply (復号して kubectl にパイプ)
sops -d k8s-lab/secrets/web-credentials.enc.yaml | kubectl apply -f -

# 編集 (自動で復号 → エディタ → 暗号化保存)
sops k8s-lab/secrets/web-credentials.enc.yaml
```

## ArgoCD との連携

ArgoCD は SOPS をそのまま読めません。次のいずれかを使います:

- **helm-secrets** プラグイン (Helm chart 中の SOPS を ArgoCD が解釈)
- **Kustomize + KSOPS** プラグイン (Kustomize から SOPS を呼ぶ)
- **Flux + sops-secrets-operator** (Flux の場合は標準対応)

このリポジトリは Kustomize ベースなので、ArgoCD に **KSOPS** プラグインを入れる前提の構成です (Lab では未デプロイ)。

## ファイル

| ファイル | 内容 |
|---|---|
| `.sops.yaml` | 暗号化ルール定義 (どのファイルをどの鍵で暗号化するか) |
| `*.enc.yaml` | 暗号化済み Secret (Git に置いて OK) |

## CI チェック

CI で `git diff --check` 相当のチェックを入れ、`.enc.yaml` 以外で `kind: Secret` を含むファイルを commit させないようにします (`iac-validate.yml` で実装可能、Lab では TODO)。
