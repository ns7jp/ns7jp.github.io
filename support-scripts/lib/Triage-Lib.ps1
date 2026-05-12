<#
.SYNOPSIS
Triage 系スクリプトで使う、判定ロジックの再利用ライブラリ。

.DESCRIPTION
Test-DiskCapacity.ps1 / Test-SecurityBaseline.ps1 などのスクリプトは、
「データ収集」と「しきい値判定」を 1 ファイル内で行っています。
判定部分だけを純粋関数として切り出し、Pester で単体テストできるようにしています。

呼び出し例:
    . "$PSScriptRoot\lib\Triage-Lib.ps1"
    Get-DiskStatus -UsedPercent 92 -WarningPercent 80   # -> 'Warning'

このファイルは副作用を持ちません。
ファイル書き込み・サービス起動・コマンド実行は行いません。
#>

function Get-DiskStatus {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][double]$UsedPercent,
        [Parameter(Mandatory)][int]$WarningPercent
    )
    if ($UsedPercent -ge $WarningPercent) { 'Warning' } else { 'OK' }
}

function Get-OverallStatus {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string[]]$Statuses
    )
    if ($Statuses -contains 'Warning') {
        return 'Warning'
    }
    if ($Statuses -contains 'Unknown') {
        return 'PartiallyChecked'
    }
    return 'OK'
}

function Get-DefenderStatus {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][bool]$AntivirusEnabled,
        [Parameter(Mandatory)][bool]$RealTimeProtectionEnabled,
        [Parameter()][Nullable[double]]$SignatureAgeHours,
        [Parameter(Mandatory)][int]$SignatureWarningHours
    )
    if (-not $AntivirusEnabled -or -not $RealTimeProtectionEnabled) {
        return 'Warning'
    }
    if ($null -eq $SignatureAgeHours) {
        return 'Warning'
    }
    if ($SignatureAgeHours -gt $SignatureWarningHours) {
        return 'Warning'
    }
    return 'OK'
}

function Get-UpdateStatus {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()][Nullable[int]]$DaysSinceLastUpdate,
        [Parameter(Mandatory)][int]$UpdateWarningDays
    )
    if ($null -eq $DaysSinceLastUpdate) {
        return 'Warning'
    }
    if ($DaysSinceLastUpdate -gt $UpdateWarningDays) {
        return 'Warning'
    }
    return 'OK'
}

function ConvertTo-SafeMessage {
    <#
    .SYNOPSIS
    チケット添付時に長すぎるログメッセージを切り詰める純関数。
    .DESCRIPTION
    Get-RecentSupportEvents.ps1 で 500 文字に切り詰めているのと同じロジックを
    関数として外出しし、テスト可能にしています。
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][AllowEmptyString()][AllowNull()][string]$Message,
        [int]$MaxLength = 500
    )
    if ($null -eq $Message) { return '' }
    if ($Message.Length -le $MaxLength) { return $Message }
    return $Message.Substring(0, $MaxLength)
}
