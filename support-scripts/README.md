# Support Scripts — IT サポート向け PowerShell サンプル

ITサポート・ヘルプデスク・社内SE補助で使う場面を想定した、読み取り中心の PowerShell サンプルです。

公開ポートフォリオ用のため、社内固有のサーバー名、ユーザーID、IPアドレス、認証情報は含めていません。実運用で使う場合は、自社のセキュリティポリシー、ログ取得範囲、個人情報の取り扱いルールに合わせて調整してください。

---

## 収録スクリプト

| ファイル | 用途 | 使う場面 |
|---|---|---|
| `Collect-PcInventory.ps1` | 端末情報を JSON で出力 | PC入替、問い合わせ受付時の環境把握 |
| `Test-NetworkTriage.ps1` | ゲートウェイ、DNS、外部疎通を確認 | ネットワークにつながらない時の一次切り分け |
| `Get-RecentSupportEvents.ps1` | 直近の警告・エラーログを CSV 出力 | PC不調、アプリ異常終了、再起動調査 |
| `Test-DiskCapacity.ps1` | ディスク使用率と物理ディスク状態を確認 | PC低速化、容量不足、監視前の棚卸し |

---

## 実行例

PowerShell を管理者権限で開き、必要に応じて実行ポリシーを一時的に緩和します。

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

端末情報を収集します。

```powershell
.\Collect-PcInventory.ps1 -OutputPath .\pc-inventory.json
```

ネットワークの一次切り分けを行います。

```powershell
.\Test-NetworkTriage.ps1 -Targets 8.8.8.8,github.com -DnsName microsoft.com
```

直近24時間の警告・エラーイベントをCSVに出力します。

```powershell
.\Get-RecentSupportEvents.ps1 -Hours 24 -OutputPath .\support-events.csv
```

ディスク容量を確認します。

```powershell
.\Test-DiskCapacity.ps1 -WarningPercent 80
```

---

## 作成で意識したこと

- 端末やネットワークの状態を、担当者が同じ形式で確認できること
- 出力を JSON / CSV にして、チケットや引き継ぎ資料へ貼り付けやすくすること
- 削除、設定変更、サービス再起動などの破壊的操作を含めないこと
- 結果に「確認日時」「端末名」「判定」を含め、後から追えるようにすること

---

## 関連ドキュメント

- [PC キッティング手順書](../support-docs/pc-kitting-guide.md)
- [障害対応事例集](../support-docs/troubleshooting-case-studies.md)
- [ポートフォリオサイト > Skills](https://ns7jp.github.io/skills.html#support-cases)
