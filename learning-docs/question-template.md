# 安全に質問・相談するテンプレート

質問前に秘密情報を除きます。パスワード、Token、秘密鍵、個人情報は伏せ字にするのではなく、共有する本文から削除します。

```text
やりたいこと:
使用環境(OS / WSL・VM / version):
対象が学習用であること: はい / いいえ / 不明
実行したコマンド:
表示されたエラー全文:
期待していた結果:
直前に行ったこと:
自分で確認したこと:
現在の影響:
戻し方 / snapshot:
事実:
推測:
未確認:
秘密情報を削除した: はい / いいえ
```

## 良い相談の例

```text
やりたいこと: 学習用Ubuntu VMのWeb service状態を確認したい
使用環境: Ubuntu 24.04 / NAT接続のVM
実行したコマンド: systemctl status example.service
表示: Unit example.service could not be found.
期待: activeと表示される
直前操作: package導入手順の3番まで実施
確認: pwd、コマンドの綴り、導入済みpackage一覧
影響: 学習用VMだけ。外部利用者なし
戻し方: clean-install snapshotあり
事実: unitが見つからない / 推測: package名を誤った可能性 / 未確認: 正しいunit名
秘密情報を削除した: はい
```

「動きません」だけでなく、相手が同じ状況を再現し、次の確認を1つ選べる情報を渡すことが目的です。
