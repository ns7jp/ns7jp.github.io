<#
.SYNOPSIS
ドライブ容量と物理ディスクの状態を確認します。

.DESCRIPTION
PCが重い、ファイル保存に失敗する、Windows Updateが進まないなどの問い合わせでは、
ディスク容量不足が原因になることがあります。

このスクリプトは、Cドライブなどのローカルドライブ使用率と、
物理ディスクの健康状態を読み取ります。削除やクリーンアップは行いません。

初学者向けの見方:
- Win32_LogicalDisk は、Cドライブなどの「論理ドライブ」を表します。
- Get-PhysicalDisk は、SSD/HDDなどの「物理ディスク」を表します。
- UsedPercent が WarningPercent 以上なら Warning と判定します。
- OutputPath を指定しない場合は、結果を画面にJSONで表示します。

.PARAMETER WarningPercent
使用率が何パーセント以上なら警告にするかを指定します。既定は80です。

.PARAMETER OutputPath
結果をJSONファイルへ保存する場合の出力先です。

.EXAMPLE
.\Test-DiskCapacity.ps1 -WarningPercent 80

使用率80%以上のドライブを警告として扱い、結果を画面に表示します。

.EXAMPLE
.\Test-DiskCapacity.ps1 -WarningPercent 85 -OutputPath .\disk.json

使用率85%以上を警告として扱い、結果をJSONファイルへ保存します。
#>

[CmdletBinding()]
param(
    # この値以上の使用率なら Warning とします。現場では80%や90%を目安にすることがあります。
    [int]$WarningPercent = 80,
    # 指定するとJSONファイルへ保存します。未指定なら画面に表示します。
    [string]$OutputPath
)

# DriveType=3 はローカル固定ディスクです。USBメモリやDVDドライブは対象外にしています。
$volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    ForEach-Object {
        # 使用率 = (全体容量 - 空き容量) / 全体容量。Size が0の場合は割り算できないため0扱いにします。
        $usedPercent = if ($_.Size -gt 0) {
            [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
        } else {
            0
        }

        [pscustomobject]@{
            Drive = $_.DeviceID
            VolumeName = $_.VolumeName
            SizeGB = [math]::Round($_.Size / 1GB, 2)
            FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            UsedPercent = $usedPercent
            Status = if ($usedPercent -ge $WarningPercent) { "Warning" } else { "OK" }
        }
    }

# 物理ディスクの健康状態を取得します。環境によってはGet-PhysicalDiskが使えないためtry/catchで保護します。
try {
    $physicalDisks = Get-PhysicalDisk -ErrorAction Stop |
        Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size
} catch {
    # 取得できない場合も、Unknownとして結果に残します。スクリプト全体は止めません。
    $physicalDisks = @(
        [pscustomobject]@{
            FriendlyName = "Get-PhysicalDisk unavailable"
            MediaType = $null
            HealthStatus = "Unknown"
            OperationalStatus = $_.Exception.Message
            Size = $null
        }
    )
}

# ドライブ別の結果と物理ディスク情報を1つの結果オブジェクトにまとめます。
$result = [ordered]@{
    CheckedAt = (Get-Date).ToString("s")
    ComputerName = $env:COMPUTERNAME
    WarningPercent = $WarningPercent
    Volumes = $volumes
    PhysicalDisks = $physicalDisks
    OverallStatus = if ($volumes.Status -contains "Warning") { "Warning" } else { "OK" }
}

# OutputPath があれば保存、なければ画面にJSONを表示します。
if ($OutputPath) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Host "Saved disk capacity result to $OutputPath"
} else {
    $result | ConvertTo-Json -Depth 6
}
