<#
.SYNOPSIS
直近のWindowsイベントログから、警告とエラーをCSVへ出力します。

.DESCRIPTION
PC不調、アプリ異常終了、突然の再起動などの問い合わせでは、
Windowsイベントログに原因の手がかりが残っていることがあります。

このスクリプトは System / Application ログなどを読み取り、
指定時間内のエラー(Level 2)と警告(Level 3)をCSVにまとめます。
ログを削除したり、設定を変更したりはしません。

初学者向けの見方:
- Get-WinEvent は、Windowsイベントログを読むためのコマンドです。
- FilterHashtable は、ログ名・開始時刻・レベルなどの検索条件です。
- Export-Csv は、Excelやチケット添付で扱いやすいCSV形式に保存します。
- catch 側では、ログを読めなかった場合もエラー内容をCSVに残します。

.PARAMETER Hours
何時間前から現在までのイベントを見るかを指定します。既定は24時間です。

.PARAMETER LogName
確認するログ名です。既定では System と Application を確認します。

.PARAMETER OutputPath
CSVファイルの保存先です。指定しない場合は自動ファイル名で保存します。

.PARAMETER MaxEventsPerLog
ログ1種類あたり最大何件まで取得するかを指定します。

.EXAMPLE
.\Get-RecentSupportEvents.ps1 -Hours 24 -OutputPath .\support-events.csv

直近24時間の警告・エラーをCSVへ保存します。
#>

[CmdletBinding()]
param(
    # 何時間前から調べるか。問い合わせ発生時刻に合わせて調整します。
    [int]$Hours = 24,
    # SystemはOSやドライバ、Applicationはアプリ関連のログを見る時によく使います。
    [string[]]$LogName = @("System", "Application"),
    # 出力先CSV。未指定なら日時付きファイル名で保存します。
    [string]$OutputPath = (Join-Path (Get-Location) ("support-events-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date))),
    # 取得件数が多すぎるとCSVが読みにくくなるため、ログごとの上限を設けています。
    [int]$MaxEventsPerLog = 200
)

# 検索開始時刻を作ります。例: Hours=24 なら「24時間前」から現在までを対象にします。
$startTime = (Get-Date).AddHours(-1 * $Hours)

# 指定されたログを順番に読み、エラーと警告だけを抽出します。
$events = foreach ($log in $LogName) {
    try {
        Get-WinEvent -FilterHashtable @{
            LogName = $log
            StartTime = $startTime
            Level = 2, 3
        } -MaxEvents $MaxEventsPerLog -ErrorAction Stop |
            Select-Object TimeCreated, LogName, ProviderName, Id, LevelDisplayName,
                @{ Name = "Message"; Expression = {
                    # メッセージは改行や空白が多いので、CSVで読みやすいよう1行に整えます。
                    $message = if ($_.Message) { ($_.Message -replace "\s+", " ").Trim() } else { "" }
                    # 長すぎるメッセージはチケット添付時に扱いづらいため、先頭500文字に丸めます。
                    $message.Substring(0, [math]::Min(500, $message.Length))
                } }
    } catch {
        # 権限不足などでログを読めない場合も、失敗した事実を結果として残します。
        [pscustomobject]@{
            TimeCreated = Get-Date
            LogName = $log
            ProviderName = "Script"
            Id = 0
            LevelDisplayName = "Warning"
            Message = "Could not read log '$log': $($_.Exception.Message)"
        }
    }
}

# CSVへ保存します。-NoTypeInformation はCSV先頭の型情報行を出さないための指定です。
$events | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Saved $($events.Count) warning/error events to $OutputPath"
