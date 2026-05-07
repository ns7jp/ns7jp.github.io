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
| `Test-SecurityBaseline.ps1` | Defender / Firewall / BitLocker / Windows Update の状態を一括確認 | セキュリティ監査、棚卸し前の一括チェック |
| `New-EndpointDailyReport.ps1` | 上記全スクリプトを実行し CSV/HTML サマリーを生成 | 日次点検、引き継ぎ資料作成、タスクスケジューラ連携 |

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

セキュリティ基準（Defender / Firewall / BitLocker / Windows Update）を一括確認します。

```powershell
.\Test-SecurityBaseline.ps1 -OutputPath .\security-baseline.json
```

上記すべてを実行し、CSV / HTML の日次レポートを生成します（タスクスケジューラ連携を想定）。

```powershell
.\New-EndpointDailyReport.ps1 -OutputDir .\reports\2026-05-07
```

---

## タスクスケジューラ連携例

`New-EndpointDailyReport.ps1` を毎朝自動実行する場合のタスク登録コマンド例です。実行アカウントや出力先は環境に合わせて調整してください。

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\support-scripts\New-EndpointDailyReport.ps1`" -OutputDir `"C:\reports`""
$trigger = New-ScheduledTaskTrigger -Daily -At 08:00
Register-ScheduledTask -TaskName "Endpoint Daily Report" `
    -Action $action -Trigger $trigger -RunLevel Highest -Description "毎朝の端末ヘルスレポート"
```

## 作成で意識したこと

- 端末やネットワークの状態を、担当者が同じ形式で確認できること
- 出力を JSON / CSV にして、チケットや引き継ぎ資料へ貼り付けやすくすること
- 削除、設定変更、サービス再起動などの破壊的操作を含めないこと
- 結果に「確認日時」「端末名」「判定」を含め、後から追えるようにすること
- 個別スクリプトと統合スクリプトを分け、単体実行と日次自動レポートの両方に対応すること

---

## 関連ドキュメント

- [PC キッティング手順書](../support-docs/pc-kitting-guide.md)
- [障害対応事例集](../support-docs/troubleshooting-case-studies.md)
- [ポートフォリオサイト > Skills](https://ns7jp.github.io/skills.html#support-cases)
