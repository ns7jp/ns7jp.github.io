# Ansible Molecule テスト

`../playbook.yml` を Docker コンテナ上で実際に流し、**冪等性** と **設定が効いているか** を自動検証します。

## なぜ Molecule か

Ansible playbook の「動くかどうか」は実機を立てれば分かりますが、変更後にすべての分岐を毎回手で踏むのは現実的ではありません。Molecule は:

1. Docker コンテナを立て (`create`)
2. playbook を実行 (`converge`)
3. **もう一度** 実行して変更ゼロを確認 (`idempotence`)
4. 期待される状態をテストで検証 (`verify`)
5. コンテナを破棄 (`destroy`)

を自動化します。これで「冪等性壊した」 「設定が間に合ってない」 をレビュー前に潰せます。

## 実行方法

```bash
# Molecule + Docker driver をインストール
pip install 'molecule[docker]' molecule-plugins ansible-lint

# テスト実行 (cd ansible/ から)
cd ansible
molecule test

# converge だけして手動確認したい場合
molecule converge
molecule login -h ubuntu2204
# (コンテナの中で確認)
molecule destroy
```

## CI 連携

`.github/workflows/iac-validate.yml` の `ansible` ジョブで syntax-check と ansible-lint まで実行しています。Molecule の完全実行 (Docker-in-Docker が必要) は重いので、別ワークフロー化するか自宅 PC で回す運用です。

## ファイル構成

```
molecule/
└── default/
    ├── molecule.yml      ... ドライバ / プラットフォーム / シナリオ定義
    ├── converge.yml      ... 本番 playbook を import して実行
    └── verify.yml        ... sshd_config / UFW / fail2ban / auditd の振る舞いを assert
```
