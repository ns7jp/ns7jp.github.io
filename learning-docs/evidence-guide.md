# 証跡の残し方

## ディレクトリ

```text
infra-evidence/
├── measured/       # 実測。日時・commit・環境・command・result必須
├── ci-generated/   # CI artifactへの索引または取得した結果
└── samples/        # 架空例。ファイル名にsampleを付ける
```

## 実測の必須項目

1. UTCの開始・終了日時
2. Git commit SHAとdirty状態
3. OS、kernel、CPU、memory、disk、仮想化方式
4. tool version
5. 実行commandと期待結果
6. stdout / stderr、exit code、合否
7. 秘密情報を除去した確認者
8. 残課題と再試験条件
9. 各fileのSHA-256

`bash scripts/capture-lab-evidence.sh <label> -- <command...>` はmetadata、command、stdout、stderr、exit code、checksumを同じdirectoryへ保存します。保存後に必ず目視し、IP、username、tokenなどを公開してよいか確認します。`scripts/check-secrets.js`によるCI検査は、追跡対象ファイルから既知のcredentialパターンを検出して止めるものであり、内容をマスキング・削除するものではありません（未追跡fileは検査対象外です）。この自動検出だけを信用せず、必ず目視でも確認します。

## 昇格条件

- SAMPLEをMEASUREDへ名前変更してはいけない。実際に再実行して新規採録する。
- CI結果は本人PCの実績と表現しない。
- NOT RUNは、日時・環境・結果がそろった場合だけMEASUREDへ変更する。
- 過去結果と現行mainの状態を分ける。
