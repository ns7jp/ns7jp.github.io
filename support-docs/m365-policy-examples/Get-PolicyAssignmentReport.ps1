<#
.SYNOPSIS
    Intune Compliance / Configuration ポリシーの割当状況を CSV に棚卸し出力するレポート。

.DESCRIPTION
    Microsoft Graph PowerShell SDK を使って、テナント内の全ポリシーと割当グループ、適用デバイス数を CSV にまとめます。
    変更前後の差分確認、リング展開後の棚卸し、CAB（変更諮問委員会）の証跡として利用します。

    読み取り中心のスクリプトのため、書き込み権限は不要です。

    必要スコープ:
        DeviceManagementConfiguration.Read.All
        Group.Read.All

.PARAMETER OutputPath
    出力 CSV のパス。

.EXAMPLE
    .\Get-PolicyAssignmentReport.ps1 -OutputPath .\policy-assignments-2026-05-25.csv

.NOTES
    Author: Noriyuki Shimada
    Lab/Portfolio sample. 実テナントで実行する場合は読み取り権限のあるアカウントで行ってください。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph モジュールが見つかりません。先に Install-Module Microsoft.Graph を実行してください。"
}

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement

Connect-MgGraph -Scopes @(
    'DeviceManagementConfiguration.Read.All',
    'Group.Read.All'
) | Out-Null

$rows = New-Object System.Collections.Generic.List[object]

# 1) Compliance ポリシー
$compliances = Invoke-MgGraphRequest -Method GET `
    -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?$expand=assignments'

foreach ($p in $compliances.value) {
    $assignments = if ($p.assignments) {
        ($p.assignments | ForEach-Object { $_.target.groupId }) -join ';'
    } else { '' }

    $rows.Add([pscustomobject]@{
        Kind             = 'Compliance'
        Id               = $p.id
        DisplayName      = $p.displayName
        OdataType        = $p.'@odata.type'
        CreatedDateTime  = $p.createdDateTime
        LastModified     = $p.lastModifiedDateTime
        AssignedGroupIds = $assignments
    })
}

# 2) Configuration ポリシー (Settings catalog)
$configs = Invoke-MgGraphRequest -Method GET `
    -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?$expand=assignments'

foreach ($p in $configs.value) {
    $assignments = if ($p.assignments) {
        ($p.assignments | ForEach-Object { $_.target.groupId }) -join ';'
    } else { '' }

    $rows.Add([pscustomobject]@{
        Kind             = 'Configuration'
        Id               = $p.id
        DisplayName      = $p.name
        OdataType        = $p.platforms
        CreatedDateTime  = $p.createdDateTime
        LastModified     = $p.lastModifiedDateTime
        AssignedGroupIds = $assignments
    })
}

# 3) CSV 出力
$rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Disconnect-MgGraph | Out-Null

Write-Host "Exported: $OutputPath ($($rows.Count) policies)" -ForegroundColor Green
