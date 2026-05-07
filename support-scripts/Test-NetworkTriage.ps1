[CmdletBinding()]
param(
    [string[]]$Targets = @("8.8.8.8", "microsoft.com", "github.com"),
    [string]$DnsName = "microsoft.com",
    [string]$OutputPath
)

$ipConfigurations = Get-NetIPConfiguration -ErrorAction SilentlyContinue
$activeConfig = $ipConfigurations |
    Where-Object { $_.IPv4Address -and $_.IPv4DefaultGateway } |
    Select-Object -First 1

$gateway = if ($activeConfig -and $activeConfig.IPv4DefaultGateway) {
    $activeConfig.IPv4DefaultGateway.NextHop
} else {
    $null
}

$pingChecks = foreach ($target in $Targets) {
    $ping = Test-Connection -ComputerName $target -Count 2 -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Target = $target
        Reachable = [bool]$ping
        AverageMs = if ($ping) { [math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 1) } else { $null }
    }
}

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

try {
    $dnsResult = Resolve-DnsName -Name $DnsName -ErrorAction Stop |
        Select-Object -First 5 Name, Type, IPAddress, NameHost
    $dnsStatus = "OK"
} catch {
    $dnsResult = @()
    $dnsStatus = "Failed: $($_.Exception.Message)"
}

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

if ($OutputPath) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Host "Saved network triage result to $OutputPath"
} else {
    $result | ConvertTo-Json -Depth 6
}
