# Support Scripts — IT サポート向け PowerShell サンプル

ITサポート・ヘルプデスク・社内SE補助で使う場面を想定した、読み取り中心の PowerShell サンプルです。

公開ポートフォリオ用のため、社内固有のサーバー名、ユーザーID、IPアドレス、認証情報は含めていません。実運用で使う場合は、自社のセキュリティポリシー、ログ取得範囲、個人情報の取り扱いルールに合わせて調整してください。

---

## 初学者向け: このフォルダで見てほしいこと

このフォルダは「すごい自動化をする」よりも、**問い合わせを受けた後に、同じ順番で状態を確認し、結果を記録できること**を目的にしています。

PowerShell 初学者の方は、まず次の順番で読むと理解しやすいです。

1. `README.md` で、各スクリプトが何の確認に使われるかを把握する
2. 各 `.ps1` ファイル先頭のコメントヘルプを読む
3. `param(...)` の中を見て、実行時に変更できる値を確認する
4. `Get-...` / `Test-...` / `Export-...` のようなコマンドが、何を取得・確認・出力しているかを見る
5. 最後に `ConvertTo-Json` / `Export-Csv` / `Set-Content` で、結果をどの形式で保存しているかを見る

このサンプルでは、削除・設定変更・サービス再起動のような破壊的な操作は入れていません。基本は **読む、確認する、記録する** ためのスクリプトです。

---

## PowerShell の基本的な読み方

PowerShell では、コマンド名が `動詞-名詞` の形になっています。初学者は、まず動詞に注目すると処理の意味をつかみやすいです。

| 例 | ざっくりした意味 | このフォルダでの使い方 |
|---|---|---|
| `Get-...` | 情報を取得する | PC情報、イベントログ、ADユーザー、M365ライセンスを取得 |
| `Test-...` | 状態を確認する | ネットワーク疎通、ディスク容量、セキュリティ状態を確認 |
| `Select-Object` | 必要な項目だけ選ぶ | 取得結果から、チケットに必要な列だけ残す |
| `Where-Object` | 条件で絞り込む | エラーだけ、休眠アカウントだけ、警告状態だけ抽出 |
| `Sort-Object` | 並び替える | 日付の新しい順、利用率の高い順などに並べる |
| `ConvertTo-Json` | JSONに変換する | 端末状態を機械的に扱いやすい形式で保存 |
| `Export-Csv` | CSVに出力する | Excelやチケット添付で見やすい形式に保存 |

`param(...)` は「実行時に外から渡せる設定値」です。たとえば `-OutputPath` を指定すると、出力ファイル名や保存場所を変えられます。

```powershell
.\Collect-PcInventory.ps1 -OutputPath .\pc-inventory.json
```

この例では、`Collect-PcInventory.ps1` の中にある `$OutputPath` という変数へ `.\pc-inventory.json` が入ります。

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
| `Get-StaleUserAccounts.ps1` | Active Directory の休眠ユーザーを検出（読み取り専用） | 退職者・長期休職者アカウントの棚卸し、内部監査 |
| `Get-M365LicenseInventory.ps1` | Microsoft Graph 経由で M365 ライセンス割当を CSV 出力 | ライセンス棚卸し、コスト最適化、部署別利用状況の把握 |

---

## 出力サンプル

採用担当者やレビュー担当者が「実行すると何が残るか」を確認しやすいよう、架空端末・架空ユーザーのサンプル出力を用意しています。

| サンプル | 想定元スクリプト | 使いどころ |
|---|---|---|
| [`samples/pc-inventory.sample.json`](./samples/pc-inventory.sample.json) | `Collect-PcInventory.ps1` | 問い合わせ受付時の端末情報をチケットへ添付 |
| [`samples/network-triage.sample.csv`](./samples/network-triage.sample.csv) | `Test-NetworkTriage.ps1` | ネットワーク不可の一次切り分け結果を共有 |
| [`samples/endpoint-daily-report.sample.html`](./samples/endpoint-daily-report.sample.html) | `New-EndpointDailyReport.ps1` | 日次点検のHTMLサマリーとして引き継ぎ |

サンプルは公開用に作成したダミーデータです。実在の端末名、ユーザーID、IPアドレス、社内サーバー名、認証情報は含めていません。

---

## 各スクリプトの詳しい説明

### `Collect-PcInventory.ps1`

端末の基本情報を JSON ファイルに保存します。PC交換、問い合わせ受付、資産管理の入口として「このPCは何者か」を確認するためのスクリプトです。

取得する主な情報は、PC名、ログインユーザー名、メーカー、型番、ドメイン、メモリ容量、OS情報、BIOSシリアル番号、CPU、ディスク、ネットワークアダプター、直近の更新プログラムです。

初学者向けの見どころ:

- `Get-CimInstance` で Windows 管理情報を取得している
- `[ordered]@{ ... }` で、出力する項目の順番を決めている
- `ConvertTo-Json -Depth 6` で、階層のある情報をJSONに変換している

### `Test-NetworkTriage.ps1`

「ネットにつながらない」という問い合わせの一次切り分けを行います。デフォルトゲートウェイ、外部宛先への疎通、DNS名前解決を確認します。

初学者向けの見どころ:

- `Get-NetIPConfiguration` で現在使っているネットワーク設定を確認している
- `Test-Connection` は PowerShell 版の ping と考えると分かりやすい
- `Resolve-DnsName` で、名前解決ができるかを確認している
- `try { ... } catch { ... }` で、失敗しても結果として記録できるようにしている

### `Get-RecentSupportEvents.ps1`

Windows のイベントログから、直近の警告・エラーを CSV に出力します。PC不調、アプリ異常終了、再起動調査などで「何か記録が残っていないか」を確認する用途です。

初学者向けの見どころ:

- `Get-WinEvent` でイベントログを読む
- `Level = 2, 3` はエラーと警告を意味する
- メッセージが長すぎると扱いにくいため、500文字までに短くしている

### `Test-DiskCapacity.ps1`

各ドライブの使用率と物理ディスクの状態を確認します。容量不足、PC低速化、監視前の棚卸しで使う想定です。

初学者向けの見どころ:

- `Win32_LogicalDisk` は Cドライブなどの論理ドライブ情報
- `Get-PhysicalDisk` は物理ディスクの健康状態
- `$WarningPercent` 以上なら `Warning` として扱う

### `Test-SecurityBaseline.ps1`

Defender、Firewall、BitLocker、Windows Update の状態をまとめて確認します。これはセキュリティ設定を変更するスクリプトではなく、現在の状態を読み取って記録するスクリプトです。

初学者向けの見どころ:

- 各チェックを `try/catch` で分け、取得できない項目があっても全体を止めない
- `OK` / `Warning` / `Unknown` のように、人が見て判断しやすい状態名へ変換している
- 最後に全体の総合判定を作っている

### `New-EndpointDailyReport.ps1`

端末確認系のスクリプトをまとめて実行し、日次レポートを作ります。個別スクリプトの結果を読み込み、CSV と HTML のサマリーにまとめます。

初学者向けの見どころ:

- `& "$PSScriptRoot\..."` で、同じフォルダ内の別スクリプトを呼び出している
- JSON / CSV を読み戻して、要約行を作っている
- HTMLを文字列として組み立て、ブラウザで見やすい一覧を作っている

### `Get-StaleUserAccounts.ps1`

Active Directory から、長期間ログインしていないユーザーを抽出します。退職者・長期休職者・不要アカウントの棚卸しを想定しています。

初学者向けの見どころ:

- 実行には RSAT の ActiveDirectory モジュールが必要
- `LastLogonDate` は厳密な最終ログオンではなく、棚卸し向けの近似値
- このスクリプトは読み取り専用で、アカウント無効化や削除は行わない

### `Get-M365LicenseInventory.ps1`

Microsoft Graph PowerShell SDK を使って、Microsoft 365 のライセンス割当状況を CSV に出力します。ライセンスの余り、不足、部署別利用状況を把握するためのサンプルです。

初学者向けの見どころ:

- `Connect-MgGraph` で Microsoft 365 テナントへ接続する
- `Get-MgSubscribedSku` で契約しているライセンス種別を取得する
- `Get-MgUser` でユーザーごとのライセンス割当を取得する
- 利用率から `NearlyFull` / `Underutilized` / `Normal` を判定している

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

Active Directory の 90 日以上未ログインのアカウントを CSV で抽出します（読み取り専用）。

```powershell
# RSAT-AD-PowerShell が必要。ドメイン参加端末で実行する。
.\Get-StaleUserAccounts.ps1 -InactiveDaysThreshold 90 `
    -SearchBase "OU=Users,DC=corp,DC=local" `
    -OutputPath .\stale-accounts.csv
```

Microsoft 365 のライセンス割当一覧を取得します（Microsoft Graph PowerShell SDK が必要）。

```powershell
# 初回のみ: Install-Module Microsoft.Graph -Scope CurrentUser
# 実行時にブラウザでサインイン (User.Read.All / Organization.Read.All)
.\Get-M365LicenseInventory.ps1 -OutputDir .\m365-inventory
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

## 必要モジュール / 前提

| スクリプト | 必要なもの | 想定実行アカウント |
|---|---|---|
| 端末系 6本 | Windows PowerShell 5.1 以上 | 管理者権限（Get-WinEvent等） |
| `Get-StaleUserAccounts.ps1` | RSAT-AD-PowerShell（または DC 上） | ドメインユーザーの読み取り権限 |
| `Get-M365LicenseInventory.ps1` | Microsoft.Graph PowerShell SDK | User.Read.All / Organization.Read.All / Directory.Read.All |

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
