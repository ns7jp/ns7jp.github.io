<#
.SYNOPSIS
端末の基本的なセキュリティ状態を確認します。

.DESCRIPTION
Microsoft Defender、Windows Firewall、BitLocker、Windows Update の状態を読み取り、
端末が最低限のセキュリティ基準を満たしていそうかを確認します。

このスクリプトは状態確認専用です。
Defenderを有効化する、Firewall設定を変更する、BitLockerを開始する、
Windows Updateを実行する、といった変更操作は行いません。

初学者向けの見方:
- 各項目を try/catch で分けているため、1つの確認に失敗しても他の確認を続けます。
- OK は想定範囲内、Warning は確認や対応が必要そうな状態、Unknown は取得できなかった状態です。
- 最後に個別結果をまとめ、OverallStatus で総合判定を出します。

.PARAMETER SignatureWarningHours
Defender定義ファイルが何時間以上古ければ警告にするかを指定します。既定は48時間です。

.PARAMETER UpdateWarningDays
最後のWindows Update適用から何日以上経過したら警告にするかを指定します。既定は30日です。

.PARAMETER OutputPath
結果をJSONファイルへ保存する場合の出力先です。

.EXAMPLE
.\Test-SecurityBaseline.ps1 -OutputPath .\security-baseline.json

セキュリティ状態を確認し、JSONファイルへ保存します。
#>

[CmdletBinding()]
param(
    # Defenderの定義ファイルがこの時間より古い場合、Warning と判定します。
    [int]$SignatureWarningHours = 48,
    # 最後に適用された更新プログラムがこの日数より古い場合、Warning と判定します。
    [int]$UpdateWarningDays = 30,
    # 指定するとJSONファイルへ保存します。未指定なら画面に表示します。
    [string]$OutputPath
)

# === Microsoft Defender ===
# ウイルス対策とリアルタイム保護、定義ファイルの更新時刻を確認します。
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
    # Defender情報を取得できない端末や権限不足の場合、Unknownとして記録します。
    $defender = [ordered]@{ Status = "Unknown"; Error = $_.Exception.Message }
}

# === Firewall (Domain / Private / Public プロファイル) ===
# Windows Firewallには Domain / Private / Public の3種類のプロファイルがあります。
# どれか1つでも無効なら Warning として扱います。
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
# BitLockerはディスク暗号化の仕組みです。ここではシステムドライブだけを確認します。
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
# Get-HotFixから、最後に適用された更新プログラムの日付を確認します。
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
# どれか1つでもWarningなら総合もWarningにします。
# Unknownのみが含まれる場合は、確認が一部できていないためPartiallyCheckedにします。
$statuses = @($defender.Status, $firewall.Status, $bitlocker.Status, $update.Status)
$overall = if ($statuses -contains "Warning") {
    "Warning"
} elseif ($statuses -contains "Unknown") {
    "PartiallyChecked"
} else {
    "OK"
}

# 個別の確認結果をまとめ、チケットやレポートに添付しやすい形にします。
$result = [ordered]@{
    CheckedAt = (Get-Date).ToString("s")
    ComputerName = $env:COMPUTERNAME
    Defender = $defender
    Firewall = $firewall
    BitLocker = $bitlocker
    WindowsUpdate = $update
    OverallStatus = $overall
}

# OutputPath があれば保存、なければ画面にJSONを表示します。
if ($OutputPath) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Host "Saved security baseline result to $OutputPath"
} else {
    $result | ConvertTo-Json -Depth 6
}
