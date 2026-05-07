[CmdletBinding()]
param(
    [string]$OutputDir = (Join-Path (Get-Location) ("daily-report-{0:yyyyMMdd-HHmmss}" -f (Get-Date))),
    [string[]]$NetworkTargets = @("8.8.8.8", "github.com"),
    [int]$EventHours = 24,
    [int]$DiskWarningPercent = 80,
    [int]$UpdateWarningDays = 30,
    [int]$EventWarningCount = 30
)

$null = New-Item -ItemType Directory -Path $OutputDir -Force

$invPath  = Join-Path $OutputDir "01-pc-inventory.json"
$netPath  = Join-Path $OutputDir "02-network-triage.json"
$diskPath = Join-Path $OutputDir "03-disk-capacity.json"
$evtPath  = Join-Path $OutputDir "04-support-events.csv"
$secPath  = Join-Path $OutputDir "05-security-baseline.json"

Write-Host "Running endpoint health checks..."
& "$PSScriptRoot\Collect-PcInventory.ps1"     -OutputPath $invPath
& "$PSScriptRoot\Test-NetworkTriage.ps1"      -Targets $NetworkTargets -OutputPath $netPath
& "$PSScriptRoot\Test-DiskCapacity.ps1"       -WarningPercent $DiskWarningPercent -OutputPath $diskPath
& "$PSScriptRoot\Get-RecentSupportEvents.ps1" -Hours $EventHours -OutputPath $evtPath
& "$PSScriptRoot\Test-SecurityBaseline.ps1"   -UpdateWarningDays $UpdateWarningDays -OutputPath $secPath

$inv  = Get-Content -Raw -LiteralPath $invPath  | ConvertFrom-Json
$net  = Get-Content -Raw -LiteralPath $netPath  | ConvertFrom-Json
$disk = Get-Content -Raw -LiteralPath $diskPath | ConvertFrom-Json
$sec  = Get-Content -Raw -LiteralPath $secPath  | ConvertFrom-Json
$evtCount = (Import-Csv -LiteralPath $evtPath | Measure-Object).Count

$netStatus = if ($net.GatewayCheck.Reachable -and $net.DnsStatus -eq "OK") { "OK" } else { "Warning" }
$evtStatus = if ($evtCount -lt $EventWarningCount) { "OK" } else { "Warning" }

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

$rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$tableRows = $rows | ForEach-Object {
    $cls = switch ($_.Status) { "OK" { "ok" } "Warning" { "warn" } default { "unk" } }
    $det = $_.Detail -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
    "<tr class='$cls'><td>$($_.Category)</td><td>$($_.Status)</td><td>$det</td></tr>"
}

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

$html | Set-Content -LiteralPath $htmlPath -Encoding UTF8

Write-Host ""
Write-Host "Daily report folder: $OutputDir"
Write-Host " - Summary HTML: $htmlPath"
Write-Host " - Summary CSV : $csvPath"
$rows | Format-Table -AutoSize
