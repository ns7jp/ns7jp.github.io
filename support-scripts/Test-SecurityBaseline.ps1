[CmdletBinding()]
param(
    [int]$SignatureWarningHours = 48,
    [int]$UpdateWarningDays = 30,
    [string]$OutputPath
)

# === Microsoft Defender ===
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    $sigAge = if ($mp.AntivirusSignatureLastUpdated) {
        [math]::Round(((Get-Date) - $mp.AntivirusSignatureLastUpdated).TotalHours, 1)
    } else { $null }
    $defender = [ordered]@{
        AntivirusEnabled = $mp.AntivirusEnabled
        RealTimeProtectionEnabled = $mp.RealTimeProtectionEnabled
        AntispywareEnabled = $mp.AntispywareEnabled
        SignatureLastUpdated = $mp.AntivirusSignatureLastUpdated
        SignatureAgeHours = $sigAge
        Status = if ($mp.AntivirusEnabled -and $mp.RealTimeProtectionEnabled -and
                    ($null -ne $sigAge) -and ($sigAge -le $SignatureWarningHours)) {
            "OK"
        } else { "Warning" }
    }
} catch {
    $defender = [ordered]@{ Status = "Unknown"; Error = $_.Exception.Message }
}

# === Firewall (Domain / Private / Public プロファイル) ===
try {
    $profiles = Get-NetFirewallProfile -ErrorAction Stop |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
    $firewall = [ordered]@{
        Profiles = $profiles
        Status = if (-not ($profiles | Where-Object { -not $_.Enabled })) { "OK" } else { "Warning" }
    }
} catch {
    $firewall = [ordered]@{ Status = "Unknown"; Error = $_.Exception.Message }
}

# === BitLocker (システムドライブの保護状態) ===
try {
    $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    $bitlocker = [ordered]@{
        MountPoint = $bl.MountPoint
        VolumeStatus = "$($bl.VolumeStatus)"
        ProtectionStatus = "$($bl.ProtectionStatus)"
        EncryptionMethod = "$($bl.EncryptionMethod)"
        EncryptionPercentage = $bl.EncryptionPercentage
        Status = if ("$($bl.ProtectionStatus)" -eq "On" -and "$($bl.VolumeStatus)" -eq "FullyEncrypted") {
            "OK"
        } else { "Warning" }
    }
} catch {
    $bitlocker = [ordered]@{ Status = "Unknown"; Error = $_.Exception.Message }
}

# === Windows Update (直近で適用済みの修正プログラム) ===
try {
    $latest = Get-HotFix -ErrorAction Stop |
        Where-Object InstalledOn |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 1
    $days = if ($latest) {
        [math]::Round(((Get-Date) - $latest.InstalledOn).TotalDays, 0)
    } else { $null }
    $update = [ordered]@{
        LatestHotFixID = $latest.HotFixID
        LatestInstalledOn = $latest.InstalledOn
        DaysSinceLastUpdate = $days
        Status = if (($null -ne $days) -and ($days -le $UpdateWarningDays)) { "OK" } else { "Warning" }
    }
} catch {
    $update = [ordered]@{ Status = "Unknown"; Error = $_.Exception.Message }
}

# === 総合判定 ===
$statuses = @($defender.Status, $firewall.Status, $bitlocker.Status, $update.Status)
$overall = if ($statuses -contains "Warning") {
    "Warning"
} elseif ($statuses -contains "Unknown") {
    "PartiallyChecked"
} else {
    "OK"
}

$result = [ordered]@{
    CheckedAt = (Get-Date).ToString("s")
    ComputerName = $env:COMPUTERNAME
    Defender = $defender
    Firewall = $firewall
    BitLocker = $bitlocker
    WindowsUpdate = $update
    OverallStatus = $overall
}

if ($OutputPath) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Host "Saved security baseline result to $OutputPath"
} else {
    $result | ConvertTo-Json -Depth 6
}
