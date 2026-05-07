<#
.SYNOPSIS
ネットワークにつながらない時の一次切り分けを行います。

.DESCRIPTION
「インターネットに接続できない」「社内システムにアクセスできない」
という問い合わせを受けた時に、端末側・DNS・ゲートウェイ・外部疎通の
どこに問題がありそうかを確認するための読み取り中心スクリプトです。

このスクリプトはネットワーク設定を変更しません。
確認結果をJSONで表示、またはファイルへ保存します。

初学者向けの見方:
- Get-NetIPConfiguration は、現在のIPアドレスやゲートウェイを確認します。
- Test-Connection は ping のように、相手先へ届くかを確認します。
- Resolve-DnsName は、microsoft.com のような名前をIPアドレスに変換できるかを確認します。
- try/catch は、DNS確認に失敗してもスクリプト全体を止めないための書き方です。

.PARAMETER Targets
疎通確認したい宛先です。IPアドレスとドメイン名の両方を指定できます。

.PARAMETER DnsName
DNS名前解決を確認するための名前です。

.PARAMETER OutputPath
結果をJSONファイルへ保存する場合の出力先です。
指定しない場合は、画面にJSONを表示します。

.EXAMPLE
.\Test-NetworkTriage.ps1

既定の宛先へ疎通確認し、結果を画面に表示します。

.EXAMPLE
.\Test-NetworkTriage.ps1 -Targets 8.8.8.8,github.com -DnsName microsoft.com -OutputPath .\network.json

指定した宛先とDNS名を確認し、結果をJSONファイルへ保存します。
#>

[CmdletBinding()]
param(
    # 外部疎通確認の宛先。8.8.8.8はGoogle Public DNS、github.comは名前解決も含む確認に使えます。
    [string[]]$Targets = @("8.8.8.8", "microsoft.com", "github.com"),
    # DNSで名前解決できるかを確認するためのドメイン名です。
    [string]$DnsName = "microsoft.com",
    # 指定した場合だけファイル保存します。未指定なら画面へJSONを表示します。
    [string]$OutputPath
)

# PCに設定されているIPアドレス、DNS、ゲートウェイなどを取得します。
$ipConfigurations = Get-NetIPConfiguration -ErrorAction SilentlyContinue

# IPv4アドレスとデフォルトゲートウェイがあるインターフェースを、現在の通信に使う候補として扱います。
$activeConfig = $ipConfigurations |
    Where-Object { $_.IPv4Address -and $_.IPv4DefaultGateway } |
    Select-Object -First 1

# デフォルトゲートウェイは、社内LANやインターネットへ出る時の入口です。
$gateway = if ($activeConfig -and $activeConfig.IPv4DefaultGateway) {
    $activeConfig.IPv4DefaultGateway.NextHop
} else {
    $null
}

# 指定された各宛先へ疎通確認します。届けばReachable=True、届かなければFalseです。
$pingChecks = foreach ($target in $Targets) {
    $ping = Test-Connection -ComputerName $target -Count 2 -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Target = $target
        Reachable = [bool]$ping
        AverageMs = if ($ping) { [math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 1) } else { $null }
    }
}

# ゲートウェイへ届くか確認します。ここが失敗する場合、端末からLAN出口までに問題がある可能性があります。
$gatewayCheck = if ($gateway) {
    $ping = Test-Connection -ComputerName $gateway -Count 2 -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Target = $gateway
        Reachable = [bool]$ping
        AverageMs = if ($ping) { [math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 1) } else { $null }
    }
} else {
    [pscustomobject]@{
        Target = "No default gateway detected"
        Reachable = $false
        AverageMs = $null
    }
}

# DNS名前解決を確認します。疎通はできるのに名前解決だけ失敗する場合、DNS設定の問題が疑われます。
try {
    $dnsResult = Resolve-DnsName -Name $DnsName -ErrorAction Stop |
        Select-Object -First 5 Name, Type, IPAddress, NameHost
    $dnsStatus = "OK"
} catch {
    $dnsResult = @()
    $dnsStatus = "Failed: $($_.Exception.Message)"
}

# チケットに貼り付けやすいよう、確認結果を1つのまとまりにします。
$result = [ordered]@{
    CheckedAt = (Get-Date).ToString("s")
    ComputerName = $env:COMPUTERNAME
    ActiveInterface = if ($activeConfig) { $activeConfig.InterfaceAlias } else { $null }
    IPv4Address = if ($activeConfig -and $activeConfig.IPv4Address) { $activeConfig.IPv4Address.IPAddress } else { $null }
    DefaultGateway = $gateway
    GatewayCheck = $gatewayCheck
    TargetChecks = $pingChecks
    DnsName = $DnsName
    DnsStatus = $dnsStatus
    DnsResult = $dnsResult
}

# OutputPath が指定されていればファイル保存、なければ画面表示にします。
if ($OutputPath) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Host "Saved network triage result to $OutputPath"
} else {
    $result | ConvertTo-Json -Depth 6
}
