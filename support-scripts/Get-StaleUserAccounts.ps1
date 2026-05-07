[CmdletBinding()]
param(
    [int]$InactiveDaysThreshold = 90,
    [string]$SearchBase,
    [switch]$IncludeDisabled,
    [string]$OutputPath = (Join-Path (Get-Location) ("stale-accounts-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date)))
)

# === ActiveDirectory モジュールの存在確認 ===
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "ActiveDirectory モジュールが見つかりません。RSAT-AD-PowerShell をインストールするか、ドメインコントローラ上で実行してください。"
    exit 1
}
Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDaysThreshold)

# === ADユーザー取得（読み取り専用） ===
# LastLogonDate は lastLogonTimestamp (DC間で14日周期で複製) にマップされる近似値。
# 厳密値が必要なら全DCに対し lastLogon 属性を直接取得する必要があるが、
# 棚卸し用途では LastLogonDate で十分。
$adParams = @{
    Filter = '*'
    Properties = @('LastLogonDate', 'Enabled', 'Description', 'whenCreated', 'EmailAddress', 'Department', 'Title')
}
if ($SearchBase) { $adParams.SearchBase = $SearchBase }

$allUsers = Get-ADUser @adParams

if (-not $IncludeDisabled) {
    $allUsers = $allUsers | Where-Object { $_.Enabled }
}

# === 休眠判定 ===
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
$stale = $result | Where-Object { $_.Status -ne "Active" } |
    Sort-Object @{Expression="Status"}, @{Expression="DaysInactive"; Descending=$true}

$stale | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8

# === コンソールサマリー ===
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
