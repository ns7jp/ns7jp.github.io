[CmdletBinding()]
param(
    [int]$WarningPercent = 80,
    [string]$OutputPath
)

$volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    ForEach-Object {
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

try {
    $physicalDisks = Get-PhysicalDisk -ErrorAction Stop |
        Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size
} catch {
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

$result = [ordered]@{
    CheckedAt = (Get-Date).ToString("s")
    ComputerName = $env:COMPUTERNAME
    WarningPercent = $WarningPercent
    Volumes = $volumes
    PhysicalDisks = $physicalDisks
    OverallStatus = if ($volumes.Status -contains "Warning") { "Warning" } else { "OK" }
}

if ($OutputPath) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Host "Saved disk capacity result to $OutputPath"
} else {
    $result | ConvertTo-Json -Depth 6
}
