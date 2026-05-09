#Requires -Version 5.1
<#
.SYNOPSIS
PowerShell wrapper for Terraform operations on the Cloud Server Bootstrap.

.DESCRIPTION
Windows / PowerShell 環境向けの Terraform ラッパ。
Linux/macOS の Makefile と同じターゲット名を使えるようにします。
Terraform CLI が PATH 上にあれば動作します (Git Bash や WSL は不要)。

.EXAMPLE
.\build.ps1 doctor
前提環境 (terraform / AWS 認証 / tfvars / SSH 鍵) を確認します。

.EXAMPLE
.\build.ps1 init
.\build.ps1 plan
.\build.ps1 apply
通常のデプロイフロー。

.EXAMPLE
.\build.ps1 destroy
作成したリソースを完全削除します (Free Tier 期限後の課金事故を防ぐため、使い終わったら必ず実行)。
#>

param(
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateSet('init', 'validate', 'fmt', 'plan', 'apply', 'destroy', 'show', 'output', 'ssh', 'doctor', 'help')]
    [string]$Target = 'help'
)

$ErrorActionPreference = 'Stop'
$TfDir = Join-Path $PSScriptRoot 'terraform'

function Show-Help {
    Write-Host ''
    Write-Host 'Usage: .\build.ps1 <target>' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Targets:' -ForegroundColor Yellow
    Write-Host '  doctor     前提環境 (terraform / AWS 認証 / tfvars / SSH 鍵) を確認'
    Write-Host '  init       Terraform プロバイダを初期化'
    Write-Host '  validate   構文チェック'
    Write-Host '  fmt        .tf ファイルを公式フォーマッタで整形'
    Write-Host '  plan       変更プランを表示 (apply 前に必ず実行)'
    Write-Host '  apply      plan で生成した tfplan を適用'
    Write-Host '  destroy    作成したリソースを完全削除 (使い終わったら必ず実行)'
    Write-Host '  show       現在の state を表示'
    Write-Host '  output     outputs.tf の値を表示'
    Write-Host '  ssh        apply 後の EC2 に SSH 接続'
    Write-Host ''
    Write-Host '初回手順 (Windows PowerShell 7+):' -ForegroundColor Yellow
    Write-Host '  1. .\build.ps1 doctor       # 前提を確認'
    Write-Host '  2. Copy-Item terraform\terraform.tfvars.example terraform\terraform.tfvars'
    Write-Host '  3. notepad terraform\terraform.tfvars   # 値を埋める'
    Write-Host '  4. .\build.ps1 init'
    Write-Host '  5. .\build.ps1 plan'
    Write-Host '  6. .\build.ps1 apply'
    Write-Host '  7. .\build.ps1 output       # 公開 URL を確認'
    Write-Host ''
}

function Invoke-Doctor {
    Write-Host ''
    Write-Host '[Cloud Bootstrap doctor]' -ForegroundColor Cyan
    $issues = @()

    Write-Host '[1/4] Terraform CLI ...' -NoNewline
    $tf = Get-Command terraform -ErrorAction SilentlyContinue
    if ($tf) {
        $verLine = (& terraform --version 2>$null) | Select-Object -First 1
        Write-Host " OK ($verLine)" -ForegroundColor Green
    }
    else {
        Write-Host ' MISSING' -ForegroundColor Red
        $issues += 'terraform CLI が見つかりません。インストール: winget install Hashicorp.Terraform (PowerShell を再起動して PATH を反映)'
    }

    Write-Host '[2/4] AWS 認証情報 ...' -NoNewline
    $awsCli = Get-Command aws -ErrorAction SilentlyContinue
    $awsConfig = Test-Path (Join-Path $env:USERPROFILE '.aws\credentials')
    $envCreds = $env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY
    if ($awsCli -and ($awsConfig -or $envCreds)) {
        Write-Host ' OK' -ForegroundColor Green
    }
    else {
        Write-Host ' WARNING' -ForegroundColor Yellow
        if (-not $awsCli) {
            $issues += 'aws CLI が無い (任意ですが推奨)。インストール: winget install Amazon.AWSCLI'
        }
        if (-not ($awsConfig -or $envCreds)) {
            $issues += 'AWS 認証情報が未設定。aws configure を実行するか、AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY 環境変数を設定してください。'
        }
    }

    Write-Host '[3/4] terraform.tfvars ...' -NoNewline
    $tfvars = Join-Path $TfDir 'terraform.tfvars'
    if (Test-Path $tfvars) {
        Write-Host ' OK' -ForegroundColor Green
    }
    else {
        Write-Host ' MISSING' -ForegroundColor Yellow
        $issues += "terraform.tfvars が無い。生成: Copy-Item '$TfDir\terraform.tfvars.example' '$tfvars'  → notepad で値を埋める"
    }

    Write-Host '[4/4] SSH 公開鍵 (~\.ssh\id_ed25519.pub) ...' -NoNewline
    $pubkey = Join-Path $env:USERPROFILE '.ssh\id_ed25519.pub'
    if (Test-Path $pubkey) {
        Write-Host ' OK' -ForegroundColor Green
    }
    else {
        Write-Host ' MISSING' -ForegroundColor Yellow
        $issues += "ed25519 公開鍵が無い。生成: ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519 -N '""""'  (パスフレーズ無しの例)"
    }

    Write-Host ''
    if ($issues.Count -gt 0) {
        Write-Host '対応が必要な項目:' -ForegroundColor Red
        foreach ($i in $issues) { Write-Host "  - $i" }
        Write-Host ''
        exit 1
    }
    else {
        Write-Host '全項目 OK。次は .\build.ps1 plan を実行できます。' -ForegroundColor Green
        Write-Host ''
    }
}

function Invoke-Tf {
    param([string[]]$Args)
    & terraform "-chdir=$TfDir" @Args
    if ($LASTEXITCODE -ne 0) {
        throw "terraform $($Args -join ' ') failed with exit code $LASTEXITCODE"
    }
}

switch ($Target) {
    'help'     { Show-Help }
    'doctor'   { Invoke-Doctor }
    'init'     { Invoke-Tf @('init') }
    'validate' { Invoke-Tf @('validate') }
    'fmt'      { Invoke-Tf @('fmt', '-recursive') }
    'plan'     { Invoke-Tf @('plan', '-out=tfplan') }
    'apply'    { Invoke-Tf @('apply', 'tfplan') }
    'destroy'  { Invoke-Tf @('destroy') }
    'show'     { Invoke-Tf @('show') }
    'output'   { Invoke-Tf @('output') }
    'ssh'      {
        $cmd = (& terraform "-chdir=$TfDir" output -raw ssh_command).Trim()
        Write-Host "Executing: $cmd" -ForegroundColor Cyan
        Invoke-Expression $cmd
    }
}
