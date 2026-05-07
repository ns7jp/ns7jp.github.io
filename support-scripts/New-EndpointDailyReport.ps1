<#
.SYNOPSIS
端末の日次ヘルスチェックレポートを作成します。

.DESCRIPTION
同じフォルダにある確認用スクリプトをまとめて実行し、
PC情報、ネットワーク、ディスク、イベントログ、セキュリティ状態を
CSV / JSON / HTML として保存します。

日次点検、引き継ぎ資料、問い合わせ対応前の現状確認を想定しています。
このスクリプト自身も、設定変更や削除は行いません。

初学者向けの見方:
- $PSScriptRoot は「このスクリプトが置かれているフォルダ」です。
- & "script.ps1" は、別のPowerShellスクリプトを実行する書き方です。
- 各スクリプトの結果を読み戻し、見やすいsummary.csvとsummary.htmlを作ります。
- HTMLは文字列として作成し、ブラウザで見られる簡易レポートにしています。

.PARAMETER OutputDir
レポート一式を保存するフォルダです。指定しない場合は日時付きフォルダを作成します。

.PARAMETER NetworkTargets
ネットワーク疎通確認で使う宛先です。

.PARAMETER EventHours
イベントログを何時間分確認するかを指定します。

.PARAMETER DiskWarningPercent
ディスク使用率が何パーセント以上なら警告にするかを指定します。

.PARAMETER UpdateWarningDays
Windows Updateの最終適用日から何日以上なら警告にするかを指定します。

.PARAMETER EventWarningCount
警告・エラーイベントが何件以上ならレポート上で警告にするかを指定します。

.EXAMPLE
.\New-EndpointDailyReport.ps1 -OutputDir .\reports\2026-05-07

指定したフォルダに日次レポート一式を作成します。
#>

[CmdletBinding()]
param(
    # レポート保存先。フォルダが存在しない場合は後続のNew-Itemで作成します。
    [string]$OutputDir = (Join-Path (Get-Location) ("daily-report-{0:yyyyMMdd-HHmmss}" -f (Get-Date))),
    # ネットワーク確認で疎通する宛先です。必要に応じて社内サイトなどへ変更できます。
    [string[]]$NetworkTargets = @("8.8.8.8", "github.com"),
    # 何時間分のイベントログを見るかを指定します。
    [int]$EventHours = 24,
    # ディスク使用率の警告しきい値です。
    [int]$DiskWarningPercent = 80,
    # Windows Updateの古さを判定する日数です。
    [int]$UpdateWarningDays = 30,
    # 警告・エラーイベントがこの件数以上ならEventsをWarningにします。
    [int]$EventWarningCount = 30
)

# 出力フォルダを作成します。既に存在する場合も -Force によりエラーにしません。
$null = New-Item -ItemType Directory -Path $OutputDir -Force

# 個別スクリプトの出力ファイル名を決めます。番号を付けて、見る順番を分かりやすくしています。
$invPath  = Join-Path $OutputDir "01-pc-inventory.json"
$netPath  = Join-Path $OutputDir "02-network-triage.json"
$diskPath = Join-Path $OutputDir "03-disk-capacity.json"
$evtPath  = Join-Path $OutputDir "04-support-events.csv"
$secPath  = Join-Path $OutputDir "05-security-baseline.json"

Write-Host "Running endpoint health checks..."

# 同じフォルダ内の各確認スクリプトを順番に実行します。
# $PSScriptRoot を使うことで、どのフォルダから実行しても相対パスが崩れにくくなります。
& "$PSScriptRoot\Collect-PcInventory.ps1"     -OutputPath $invPath
& "$PSScriptRoot\Test-NetworkTriage.ps1"      -Targets $NetworkTargets -OutputPath $netPath
& "$PSScriptRoot\Test-DiskCapacity.ps1"       -WarningPercent $DiskWarningPercent -OutputPath $diskPath
& "$PSScriptRoot\Get-RecentSupportEvents.ps1" -Hours $EventHours -OutputPath $evtPath
& "$PSScriptRoot\Test-SecurityBaseline.ps1"   -UpdateWarningDays $UpdateWarningDays -OutputPath $secPath

# 保存したJSON / CSVを読み戻して、サマリー作成に使います。
$inv  = Get-Content -Raw -LiteralPath $invPath  | ConvertFrom-Json
$net  = Get-Content -Raw -LiteralPath $netPath  | ConvertFrom-Json
$disk = Get-Content -Raw -LiteralPath $diskPath | ConvertFrom-Json
$sec  = Get-Content -Raw -LiteralPath $secPath  | ConvertFrom-Json
$evtCount = (Import-Csv -LiteralPath $evtPath | Measure-Object).Count

# ネットワークとイベントログは、このレポート側で簡単なOK/Warning判定を作ります。
$netStatus = if ($net.GatewayCheck.Reachable -and $net.DnsStatus -eq "OK") { "OK" } else { "Warning" }
$evtStatus = if ($evtCount -lt $EventWarningCount) { "OK" } else { "Warning" }

# HTMLとCSVへ出すための要約行です。1行が1カテゴリの確認結果になります。
$rows = @(
    [pscustomobject]@{
        Category = "Disk"
        Status   = $disk.OverallStatus
        Detail   = (($disk.Volumes | ForEach-Object { "$($_.Drive) used $($_.UsedPercent)%" }) -join " / ")
    }
    [pscustomobject]@{
        Category = "Network"
        Status   = $netStatus
        Detail   = "GW $($net.DefaultGateway) / DNS $($net.DnsStatus)"
    }
    [pscustomobject]@{
        Category = "Events"
        Status   = $evtStatus
        Detail   = "$evtCount warning/error events in last ${EventHours}h"
    }
    [pscustomobject]@{
        Category = "Defender"
        Status   = $sec.Defender.Status
        Detail   = "Realtime=$($sec.Defender.RealTimeProtectionEnabled), SignatureAge=$($sec.Defender.SignatureAgeHours)h"
    }
    [pscustomobject]@{
        Category = "Firewall"
        Status   = $sec.Firewall.Status
        Detail   = (($sec.Firewall.Profiles | ForEach-Object { "$($_.Name)=$($_.Enabled)" }) -join " ")
    }
    [pscustomobject]@{
        Category = "BitLocker"
        Status   = $sec.BitLocker.Status
        Detail   = "$($sec.BitLocker.MountPoint) $($sec.BitLocker.VolumeStatus) ($($sec.BitLocker.EncryptionPercentage)%)"
    }
    [pscustomobject]@{
        Category = "WindowsUpdate"
        Status   = $sec.WindowsUpdate.Status
        Detail   = "$($sec.WindowsUpdate.LatestHotFixID) ($($sec.WindowsUpdate.DaysSinceLastUpdate)d ago)"
    }
)

$csvPath  = Join-Path $OutputDir "summary.csv"
$htmlPath = Join-Path $OutputDir "summary.html"

# CSVサマリーを保存します。Excelで開いたり、チケットに添付したりできます。
$rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

# HTMLテーブル用の行を作ります。Statusに応じてCSSクラスを変え、色分けできるようにしています。
$tableRows = $rows | ForEach-Object {
    $cls = switch ($_.Status) { "OK" { "ok" } "Warning" { "warn" } default { "unk" } }
    # HTMLに直接入れる文字列は、& や < などをエスケープして表示崩れを防ぎます。
    $det = $_.Detail -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
    "<tr class='$cls'><td>$($_.Category)</td><td>$($_.Status)</td><td>$det</td></tr>"
}

# ここからHTMLファイルの本文です。@"..."@ は複数行文字列を作る書き方です。
$html = @"
<!DOCTYPE html>
<html lang="ja"><head><meta charset="UTF-8">
<title>Endpoint Daily Report - $($inv.ComputerName)</title>
<style>
body{font-family:'Segoe UI',sans-serif;margin:24px;color:#222}
h1{font-size:20px;margin:0 0 4px}
.meta{color:#666;font-size:13px;margin-bottom:16px}
table{border-collapse:collapse;width:100%;max-width:900px}
th,td{border:1px solid #ddd;padding:8px 12px;text-align:left;font-size:14px}
th{background:#f4f4f6}
tr.ok td:nth-child(2){color:#0a7a32;font-weight:600}
tr.warn td:nth-child(2){color:#b45309;font-weight:600}
tr.warn{background:#fff8eb}
tr.unk td:nth-child(2){color:#666}
</style></head><body>
<h1>Endpoint Daily Report</h1>
<div class="meta">
Computer: <strong>$($inv.ComputerName)</strong> /
Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm')) /
OS: $($inv.OS.Caption)
</div>
<table>
<thead><tr><th>Category</th><th>Status</th><th>Detail</th></tr></thead>
<tbody>
$($tableRows -join "`n")
</tbody></table>
<p class="meta">詳細JSON / CSV は同じフォルダに保存されています。</p>
</body></html>
"@

# HTMLサマリーを保存します。ブラウザで開くと一覧として見られます。
$html | Set-Content -LiteralPath $htmlPath -Encoding UTF8

# 最後に保存先と要約をコンソールにも表示します。
Write-Host ""
Write-Host "Daily report folder: $OutputDir"
Write-Host " - Summary HTML: $htmlPath"
Write-Host " - Summary CSV : $csvPath"
$rows | Format-Table -AutoSize
