<#
.SYNOPSIS
Active Directoryの休眠ユーザーをCSVへ出力します。

.DESCRIPTION
長期間ログインしていないユーザー、未ログインユーザー、無効化済みユーザーを抽出し、
退職者・長期休職者・不要アカウントの棚卸しに使えるCSVを作成します。

このスクリプトは読み取り専用です。
ユーザーを無効化する、削除する、グループから外すなどの操作は行いません。

初学者向けの見方:
- ActiveDirectory モジュールは、ADをPowerShellから読むための追加機能です。
- Get-ADUser はADユーザーを取得するコマンドです。
- LastLogonDate は厳密な最終ログオンではなく、棚卸し向けの近似値として使います。
- Where-Object で Active 以外のユーザーだけを抽出しています。

.PARAMETER InactiveDaysThreshold
何日以上ログインしていなければ休眠(Stale)とみなすかを指定します。既定は90日です。

.PARAMETER SearchBase
検索対象のOUを限定したい場合に指定します。
例: OU=Users,DC=corp,DC=local

.PARAMETER IncludeDisabled
無効化済みアカウントも検索対象に含めます。
指定しない場合、最初の検索対象から無効化済みアカウントを除外します。

.PARAMETER OutputPath
CSVファイルの保存先です。指定しない場合は日時付きファイル名で保存します。

.EXAMPLE
.\Get-StaleUserAccounts.ps1 -InactiveDaysThreshold 90 -OutputPath .\stale-accounts.csv

90日以上ログインしていないユーザーを抽出してCSVへ保存します。

.EXAMPLE
.\Get-StaleUserAccounts.ps1 -SearchBase "OU=Users,DC=corp,DC=local" -IncludeDisabled

指定OU配下を対象に、無効化済みアカウントも含めて棚卸しします。
#>

[CmdletBinding()]
param(
    # この日数以上ログインがない有効ユーザーを Stale と判定します。
    [int]$InactiveDaysThreshold = 90,
    # 検索対象のOUを絞りたい場合に指定します。未指定ならドメイン全体を対象にします。
    [string]$SearchBase,
    # 指定すると、無効化済みアカウントもレポート対象に含めます。
    [switch]$IncludeDisabled,
    # CSVの保存先です。未指定なら日時付きファイル名で保存します。
    [string]$OutputPath = (Join-Path (Get-Location) ("stale-accounts-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date)))
)

# === ActiveDirectory モジュールの存在確認 ===
# RSAT-AD-PowerShell またはドメインコントローラー上のPowerShellで利用できます。
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "ActiveDirectory モジュールが見つかりません。RSAT-AD-PowerShell をインストールするか、ドメインコントローラ上で実行してください。"
    exit 1
}
Import-Module ActiveDirectory -ErrorAction Stop

# 休眠判定の基準日です。例: 90日前より古いログオンならStale候補になります。
$cutoff = (Get-Date).AddDays(-$InactiveDaysThreshold)

# === ADユーザー取得（読み取り専用） ===
# LastLogonDate は lastLogonTimestamp (DC間で14日周期で複製) にマップされる近似値。
# 厳密値が必要なら全DCに対し lastLogon 属性を直接取得する必要があるが、
# 棚卸し用途では LastLogonDate で十分。
$adParams = @{
    Filter = '*'
    Properties = @('LastLogonDate', 'Enabled', 'Description', 'whenCreated', 'EmailAddress', 'Department', 'Title')
}

# SearchBase が指定されている場合だけ、検索対象OUをパラメータに追加します。
if ($SearchBase) { $adParams.SearchBase = $SearchBase }

# ADユーザーを取得します。ここでは読み取りだけで、変更操作は行いません。
$allUsers = Get-ADUser @adParams

# 既定では、すでに無効化されているユーザーを最初の対象から外します。
# IncludeDisabled を付けた場合は、無効化済みアカウントも棚卸し対象に含めます。
if (-not $IncludeDisabled) {
    $allUsers = $allUsers | Where-Object { $_.Enabled }
}

# === 休眠判定 ===
# 1ユーザーずつ確認し、Active / Stale / NeverLoggedIn / Disabled に分類します。
$result = $allUsers | ForEach-Object {
    $days = if ($_.LastLogonDate) {
        [math]::Round(((Get-Date) - $_.LastLogonDate).TotalDays, 0)
    } else {
        $null
    }

    $status = if (-not $_.Enabled) {
        "Disabled"
    } elseif ($null -eq $_.LastLogonDate) {
        "NeverLoggedIn"
    } elseif ($days -ge $InactiveDaysThreshold) {
        "Stale"
    } else {
        "Active"
    }

    [pscustomobject]@{
        SamAccountName     = $_.SamAccountName
        DisplayName        = $_.Name
        Email              = $_.EmailAddress
        Department         = $_.Department
        Title              = $_.Title
        Enabled            = $_.Enabled
        LastLogonDate      = $_.LastLogonDate
        DaysInactive       = $days
        Status             = $status
        WhenCreated        = $_.whenCreated
        Description        = $_.Description
        DistinguishedName  = $_.DistinguishedName
    }
}

# 休眠 / 未ログイン / 無効化アカウントのみを抽出（Active は除外）
# Activeは問題なしとしてCSVから除外し、確認が必要そうなアカウントだけを出力します。
$stale = $result | Where-Object { $_.Status -ne "Active" } |
    Sort-Object @{Expression="Status"}, @{Expression="DaysInactive"; Descending=$true}

# 棚卸し結果をCSVに保存します。
$stale | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8

# === コンソールサマリー ===
# 画面にも件数サマリーを表示し、実行直後にざっくり状況を確認できるようにします。
Write-Host ""
Write-Host "AD Stale Account Audit"
Write-Host "----------------------"
Write-Host "Threshold        : $InactiveDaysThreshold days (cutoff: $($cutoff.ToString('yyyy-MM-dd')))"
Write-Host "SearchBase       : $(if ($SearchBase) { $SearchBase } else { '(domain root)' })"
Write-Host "Total scanned    : $($allUsers.Count)"
Write-Host "Stale / Inactive : $($stale.Count)"
Write-Host "Output           : $OutputPath"
Write-Host ""

$result | Group-Object Status |
    Select-Object @{N='Status';E={$_.Name}}, @{N='Count';E={$_.Count}} |
    Sort-Object Status |
    Format-Table -AutoSize
