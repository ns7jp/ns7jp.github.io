[CmdletBinding()]
param(
    [string]$OutputDir = (Join-Path (Get-Location) ("m365-licenses-{0:yyyyMMdd-HHmmss}" -f (Get-Date)))
)

# === Microsoft Graph PowerShell SDK の存在確認 ===
$required = @('Microsoft.Graph.Users', 'Microsoft.Graph.Identity.DirectoryManagement')
foreach ($m in $required) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Error "$m モジュールが見つかりません。次のコマンドでインストールしてください: Install-Module Microsoft.Graph -Scope CurrentUser"
        exit 1
    }
}
Import-Module Microsoft.Graph.Users -ErrorAction Stop
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop

# === Microsoft Graph への接続 ===
# 既存接続があれば再利用、なければ対話的サインイン
$context = Get-MgContext -ErrorAction SilentlyContinue
if (-not $context) {
    try {
        Connect-MgGraph -Scopes "User.Read.All", "Organization.Read.All", "Directory.Read.All" -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "Microsoft Graph への接続に失敗しました: $($_.Exception.Message)"
        exit 1
    }
    $context = Get-MgContext
}

$null = New-Item -ItemType Directory -Path $OutputDir -Force

Write-Host "Tenant : $($context.TenantId)"
Write-Host "Account: $($context.Account)"
Write-Host ""

# === テナント保有のSKU(ライセンス)を取得 ===
$skus = Get-MgSubscribedSku -All

$skuMap = @{}
foreach ($sku in $skus) {
    $skuMap[$sku.SkuId] = $sku.SkuPartNumber
}

# === 全ユーザー × ライセンス割当の取得 ===
$users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, AssignedLicenses, Department, JobTitle

$assignments = foreach ($u in $users) {
    if ($null -eq $u.AssignedLicenses -or $u.AssignedLicenses.Count -eq 0) {
        [pscustomobject]@{
            UserPrincipalName    = $u.UserPrincipalName
            DisplayName          = $u.DisplayName
            Department           = $u.Department
            JobTitle             = $u.JobTitle
            Enabled              = $u.AccountEnabled
            LicenseSkuPartNumber = "(no license)"
            SkuId                = $null
        }
    } else {
        foreach ($lic in $u.AssignedLicenses) {
            $skuName = $skuMap[$lic.SkuId]
            if (-not $skuName) { $skuName = "Unknown SKU" }
            [pscustomobject]@{
                UserPrincipalName    = $u.UserPrincipalName
                DisplayName          = $u.DisplayName
                Department           = $u.Department
                JobTitle             = $u.JobTitle
                Enabled              = $u.AccountEnabled
                LicenseSkuPartNumber = $skuName
                SkuId                = $lic.SkuId
            }
        }
    }
}

# === SKUサマリー: 購入 / 割当 / 残数 / 利用率 ===
$skuSummary = foreach ($sku in $skus) {
    $purchased = $sku.PrepaidUnits.Enabled
    $assigned  = $sku.ConsumedUnits
    $available = $purchased - $assigned
    $util      = if ($purchased -gt 0) { [math]::Round(($assigned / $purchased) * 100, 1) } else { 0 }

    [pscustomobject]@{
        SkuPartNumber      = $sku.SkuPartNumber
        Purchased          = $purchased
        Assigned           = $assigned
        Available          = $available
        UtilizationPercent = $util
        Status             = if ($util -ge 95) { "NearlyFull" }
                             elseif ($util -le 50 -and $purchased -ge 10) { "Underutilized" }
                             else { "Normal" }
    }
}

$assignmentsPath = Join-Path $OutputDir "user-license-assignments.csv"
$skuSummaryPath  = Join-Path $OutputDir "sku-summary.csv"
$assignments | Export-Csv -LiteralPath $assignmentsPath -NoTypeInformation -Encoding UTF8
$skuSummary  | Sort-Object SkuPartNumber |
    Export-Csv -LiteralPath $skuSummaryPath -NoTypeInformation -Encoding UTF8

# === 部署別 集計（補助CSV） ===
$byDept = $assignments |
    Where-Object { $_.LicenseSkuPartNumber -ne "(no license)" } |
    Group-Object Department, LicenseSkuPartNumber |
    Select-Object @{N='Department';E={ ($_.Group | Select-Object -First 1).Department }},
                  @{N='SkuPartNumber';E={ ($_.Group | Select-Object -First 1).LicenseSkuPartNumber }},
                  @{N='UserCount';E={$_.Count}} |
    Sort-Object Department, SkuPartNumber

$byDeptPath = Join-Path $OutputDir "by-department.csv"
$byDept | Export-Csv -LiteralPath $byDeptPath -NoTypeInformation -Encoding UTF8

# === コンソール出力 ===
Write-Host "Microsoft 365 License Inventory"
Write-Host "-------------------------------"
Write-Host "User assignments    : $assignmentsPath ($($assignments.Count) rows)"
Write-Host "SKU summary         : $skuSummaryPath"
Write-Host "Department summary  : $byDeptPath"
Write-Host ""
$skuSummary | Sort-Object UtilizationPercent -Descending | Format-Table -AutoSize
