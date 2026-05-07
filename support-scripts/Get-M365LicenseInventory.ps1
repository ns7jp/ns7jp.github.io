<#
.SYNOPSIS
Microsoft 365のライセンス割当状況をCSVへ出力します。

.DESCRIPTION
Microsoft Graph PowerShell SDK を使い、テナント内のユーザーごとのライセンス割当、
SKUごとの購入数・割当数・残数・利用率、部署別の利用状況をCSVに保存します。

ライセンス棚卸し、コスト最適化、未割当や過剰購入の確認を想定したサンプルです。
このスクリプトはライセンスを追加・削除・変更しません。

初学者向けの見方:
- Microsoft Graph は、Microsoft 365の情報を取得するためのAPIです。
- Connect-MgGraph は、Microsoft 365へサインインして接続するコマンドです。
- Get-MgSubscribedSku は、契約しているライセンス種別(SKU)を取得します。
- Get-MgUser は、ユーザー情報と割り当て済みライセンスを取得します。
- Export-Csv で、Excelや棚卸し資料に使いやすいCSVへ保存します。

.PARAMETER OutputDir
CSVファイル一式を保存するフォルダです。
指定しない場合は、m365-licenses-年月日時分秒 というフォルダを作成します。

.EXAMPLE
.\Get-M365LicenseInventory.ps1 -OutputDir .\m365-inventory

Microsoft 365ライセンス棚卸しCSVを m365-inventory フォルダへ保存します。

.NOTES
実行には Microsoft Graph PowerShell SDK と、User.Read.All / Organization.Read.All /
Directory.Read.All などの読み取り権限が必要です。
#>

[CmdletBinding()]
param(
    # 出力フォルダ。複数CSVを保存するため、ファイルではなくフォルダを指定します。
    [string]$OutputDir = (Join-Path (Get-Location) ("m365-licenses-{0:yyyyMMdd-HHmmss}" -f (Get-Date)))
)

# === Microsoft Graph PowerShell SDK の存在確認 ===
# Microsoft 365へ接続してユーザーやライセンスを読むために必要なモジュールです。
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
# まだ接続していない場合はブラウザサインインが開きます。
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

# CSV一式を保存する出力フォルダを作ります。
$null = New-Item -ItemType Directory -Path $OutputDir -Force

Write-Host "Tenant : $($context.TenantId)"
Write-Host "Account: $($context.Account)"
Write-Host ""

# === テナント保有のSKU(ライセンス)を取得 ===
# SKUはライセンス商品の種類です。例: Microsoft 365 Business Premium など。
$skus = Get-MgSubscribedSku -All

# SkuId(GUID)だけだと読みにくいため、SkuPartNumberへ変換する対応表を作ります。
$skuMap = @{}
foreach ($sku in $skus) {
    $skuMap[$sku.SkuId] = $sku.SkuPartNumber
}

# === 全ユーザー × ライセンス割当の取得 ===
# AssignedLicenses を含めて取得し、ユーザーごとのライセンス有無を確認します。
$users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, AssignedLicenses, Department, JobTitle

# 1ユーザーが複数ライセンスを持つことがあるため、ユーザー×ライセンスの行に展開します。
$assignments = foreach ($u in $users) {
    if ($null -eq $u.AssignedLicenses -or $u.AssignedLicenses.Count -eq 0) {
        # ライセンス未割当ユーザーも棚卸し対象として分かるよう、(no license) の行を作ります。
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
            # Graphから返るSkuIdを、人が読みやすいSkuPartNumberへ置き換えます。
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
# SKUごとの購入数・利用数・残数をまとめ、ライセンス不足や過剰購入の目安にします。
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
        # 95%以上は残数が少ない、50%以下かつ購入数が多い場合は過剰気味として目印を付けます。
        Status             = if ($util -ge 95) { "NearlyFull" }
                             elseif ($util -le 50 -and $purchased -ge 10) { "Underutilized" }
                             else { "Normal" }
    }
}

$assignmentsPath = Join-Path $OutputDir "user-license-assignments.csv"
$skuSummaryPath  = Join-Path $OutputDir "sku-summary.csv"

# ユーザー別とSKU別のCSVを保存します。
$assignments | Export-Csv -LiteralPath $assignmentsPath -NoTypeInformation -Encoding UTF8
$skuSummary  | Sort-Object SkuPartNumber |
    Export-Csv -LiteralPath $skuSummaryPath -NoTypeInformation -Encoding UTF8

# === 部署別 集計（補助CSV） ===
# Department とライセンス種別でグループ化し、部署ごとの利用傾向を見られるようにします。
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
# 保存先とSKU利用率を画面に表示します。詳細はCSVを開いて確認します。
Write-Host "Microsoft 365 License Inventory"
Write-Host "-------------------------------"
Write-Host "User assignments    : $assignmentsPath ($($assignments.Count) rows)"
Write-Host "SKU summary         : $skuSummaryPath"
Write-Host "Department summary  : $byDeptPath"
Write-Host ""
$skuSummary | Sort-Object UtilizationPercent -Descending | Format-Table -AutoSize
