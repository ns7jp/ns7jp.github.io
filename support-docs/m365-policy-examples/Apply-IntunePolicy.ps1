<#
.SYNOPSIS
    Microsoft Graph PowerShell SDK で Intune Compliance Policy / Configuration Profile を適用するサンプル。

.DESCRIPTION
    JSON で定義されたポリシーを読み込み、Graph API 経由で Intune に登録します。
    ポートフォリオ用の読み取り中心構成のため、デフォルトでは -WhatIf を有効化しています。

    必要モジュール:
        Install-Module Microsoft.Graph -Scope CurrentUser

    必要スコープ（Connect-MgGraph 時）:
        DeviceManagementConfiguration.ReadWrite.All
        DeviceManagementApps.ReadWrite.All

.PARAMETER PolicyFile
    適用する JSON ポリシーファイルのパス。

.PARAMETER TargetGroupName
    割当対象の Entra ID グループ名（リング展開用: Ring-Test / Ring-Pilot / Ring-Prod 等）。

.PARAMETER Apply
    実際に Graph API へ書き込みを行う場合に指定。省略時は -WhatIf 相当で内容のみ表示。

.EXAMPLE
    .\Apply-IntunePolicy.ps1 -PolicyFile .\intune-windows-compliance-policy.json -TargetGroupName 'Ring-Test'
    # Dry-run（実際の書き込みなし）

.EXAMPLE
    .\Apply-IntunePolicy.ps1 -PolicyFile .\intune-windows-compliance-policy.json -TargetGroupName 'Ring-Test' -Apply
    # 実適用

.NOTES
    Author: Noriyuki Shimada
    Lab/Portfolio sample. 実テナント適用前に Test リングで検証してください。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$PolicyFile,

    [Parameter(Mandatory)]
    [string]$TargetGroupName,

    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-PolicyJson {
    param([string]$Path)
    $raw = Get-Content -Path $Path -Raw
    try {
        $json = $raw | ConvertFrom-Json -Depth 32
    }
    catch {
        throw "JSON 解析失敗: $Path — $($_.Exception.Message)"
    }

    if (-not $json.PSObject.Properties.Match('displayName').Count -and
        -not $json.PSObject.Properties.Match('name').Count) {
        throw "displayName または name が見つかりません: $Path"
    }

    return $json
}

function Get-PolicyKind {
    param([Parameter(ValueFromPipeline=$true)]$Policy)
    if ($Policy.PSObject.Properties.Match('@odata.type').Count -gt 0 -and
        $Policy.'@odata.type' -like '*CompliancePolicy*') {
        return 'Compliance'
    }
    if ($Policy.PSObject.Properties.Match('platforms').Count -gt 0 -and
        $Policy.PSObject.Properties.Match('settings').Count -gt 0) {
        return 'Configuration'
    }
    return 'Unknown'
}

Write-Host "===== Apply-IntunePolicy.ps1 =====" -ForegroundColor Cyan
Write-Host "Policy file   : $PolicyFile"
Write-Host "Target group  : $TargetGroupName"
Write-Host "Apply mode    : $([bool]$Apply)"
Write-Host

# 1) JSON 読み込み + 必須キー検証
$policy = Read-PolicyJson -Path $PolicyFile
$kind   = Get-PolicyKind -Policy $policy

Write-Host "Policy kind   : $kind" -ForegroundColor Yellow
$displayName = if ($policy.PSObject.Properties.Match('displayName').Count -gt 0) {
    $policy.displayName
} else {
    $policy.name
}
Write-Host "Display name  : $displayName"

# 2) Graph 接続 (実適用時のみ)
if (-not $Apply) {
    Write-Host
    Write-Host "[Dry-run] 実際の Graph 呼び出しは行いません。" -ForegroundColor Green
    Write-Host "[Dry-run] -Apply を付けると以下を実行します:"
    Write-Host "          - Connect-MgGraph -Scopes DeviceManagementConfiguration.ReadWrite.All"
    Write-Host "          - Get-MgGroup -Filter \"displayName eq '$TargetGroupName'\""
    Write-Host "          - Invoke-MgGraphRequest -Method POST -Uri /v1.0/deviceManagement/<endpoint>"
    Write-Host "          - 適用後の status を Get-MgDevice... で確認"
    return
}

if (-not (Get-Module -ListAvailable Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph モジュールが見つかりません。先に Install-Module Microsoft.Graph を実行してください。"
}

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement
Import-Module Microsoft.Graph.Groups

Connect-MgGraph -Scopes @(
    'DeviceManagementConfiguration.ReadWrite.All',
    'DeviceManagementApps.ReadWrite.All',
    'Group.Read.All'
) | Out-Null

# 3) 対象グループ解決
$group = Get-MgGroup -Filter "displayName eq '$TargetGroupName'" -ConsistencyLevel eventual -Top 1
if (-not $group) {
    Disconnect-MgGraph | Out-Null
    throw "対象グループが見つかりません: $TargetGroupName"
}
Write-Host "Group id      : $($group.Id)"

# 4) ポリシー作成 (kind 別)
$createdId = $null
switch ($kind) {
    'Compliance' {
        $uri  = 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies'
        $body = $policy | Select-Object -ExcludeProperty _*, _assignmentExample | ConvertTo-Json -Depth 32
        $resp = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType 'application/json'
        $createdId = $resp.id
    }
    'Configuration' {
        $uri  = 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies'
        $body = $policy | Select-Object -ExcludeProperty _*, _assignmentExample | ConvertTo-Json -Depth 32
        $resp = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType 'application/json'
        $createdId = $resp.id
    }
    default {
        throw "未対応のポリシー種別: $kind"
    }
}
Write-Host "Created id    : $createdId" -ForegroundColor Green

# 5) グループ割当
$assignmentBody = @{
    assignments = @(
        @{
            target = @{
                '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                groupId       = $group.Id
            }
        }
    )
} | ConvertTo-Json -Depth 8

$assignUri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/$createdId/assign"
if ($kind -eq 'Configuration') {
    $assignUri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$createdId/assign"
}

Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $assignmentBody -ContentType 'application/json' | Out-Null
Write-Host "Assigned to   : $TargetGroupName ($($group.Id))" -ForegroundColor Green

# 6) 後処理
Disconnect-MgGraph | Out-Null
Write-Host
Write-Host "適用後の確認:" -ForegroundColor Cyan
Write-Host "  - Endpoint Manager admin center で対象ポリシーが Test リングに割当されているか"
Write-Host "  - 24h 後に Get-PolicyAssignmentReport.ps1 で適用率を確認"
Write-Host "  - 異常が無ければ Pilot リングへ展開"
