# Ansible — Linux ベースライン Playbook

Ubuntu 22.04 / 24.04 を想定し、サーバー初期構築直後に行うべき設定をまとめた **最小ハードニング Playbook** です。

> 目的は「IaC を1本書ける」「冪等性とドライランの考え方を理解している」ことを示すLabです。本番運用ではここに監査要件・ログ転送・SIEM 連携などを追加します。

---

## 適用内容

| カテゴリ | 内容 | タグ |
|---|---|---|
| パッケージ | `apt update && upgrade`、必須パッケージ導入 | `apt` |
| 自動更新 | `unattended-upgrades` 有効化 | `updates` |
| ユーザー | 管理ユーザー作成、SSH公開鍵投入、sudo付与 | `user` |
| SSH | パスワード認証/root直ログイン/X11/TCP forwarding 無効、鍵認証のみ | `ssh` |
| ファイアウォール | UFW で deny incoming、22 / 80 / 443 のみ許可 | `firewall` |
| 認証ブルートフォース対策 | fail2ban の sshd jail を有効化 | `fail2ban` |
| 監査 | auditd 起動、基本ルール、journald を persistent 保管 | `audit` |
| 時刻 | Asia/Tokyo、systemd-timesyncd | `time` |

---

## 構成

```
ansible/
├── playbook.yml                ... メイン playbook（21タスク + 4ハンドラ）
├── requirements.yml            ... 必要な collection 宣言（ansible.posix / community.general）
├── inventory.ini               ... 対象ホスト一覧（Lab用）
└── templates/
    └── sshd_config.j2          ... Ansible 管理下の sshd_config テンプレート
```

---

## 実行手順

```bash
# 0) 必要な collection をインストール（初回のみ）
ansible-galaxy collection install -r requirements.yml

# 1) 構文チェック
ansible-playbook playbook.yml --syntax-check

# 2) 何が変更されるか事前確認（適用しない）
ansible-playbook -i inventory.ini playbook.yml --check --diff

# 3) 適用
ansible-playbook -i inventory.ini playbook.yml

# 4) 一部だけ（SSH周り）
ansible-playbook -i inventory.ini playbook.yml --tags ssh
```

ansible-core 2.16 以降では非組込モジュール（`authorized_key`, `ufw`, `timezone`）は
collection 経由になるため、`requirements.yml` で明示宣言しています。FQCN
（`ansible.posix.authorized_key` 等）も使用しているので、collection が無い環境
でのコピペ実行を防ぎ、エラーメッセージから原因を辿りやすくしています。

---

## 設計で意識した点

- **冪等性**: 何度実行しても同じ状態になるよう、`copy` / `template` / モジュール経由で記述。`command` は最小限。
- **タグ運用**: SSH のみ、ファイアウォールのみ、など段階適用ができるよう `tags` を全タスクに付与。
- **ロールバック容易性**: 設定ファイルは Ansible で常に上書きする前提にし、Git に履歴を残す。
- **検証可能**: `--check --diff` で適用前の差分が必ず見える。`sshd -t` で SSH 設定の構文を検証してから restart。
- **Vault分離**: 公開鍵・パスワードなど秘匿情報は本来 `ansible-vault` 配下に置く（Lab では平文サンプル）。

---

## ポートフォリオでの位置づけ

- 自作 PowerShell スクリプトが **Windows 系の "状態確認"** の入り口
- この Ansible playbook が **Linux 系の "状態適用"** の入り口
- セットで「**確認 → 適用 → 監視**」が一通り示せる構成（監視は [monitoring-stack/](../monitoring-stack/)）

---

## 注意

- 公開リポジトリ向けの Lab サンプルです。`admin_pubkey` はダミーで、`NOPASSWD:ALL` も Lab 用の妥協です。本番では `ansible-vault encrypt` で機密分離し、`NOPASSWD` 範囲を最小化してください。
- `ufw` の有効化は SSH 接続を切る可能性があります。**事前に SSH 許可ルールが入っているか必ず `--check --diff` で確認**してから適用してください。
