[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path (Get-Location) ("pc-inventory-{0:yyyyMMdd-HHmmss}.json" -f (Get-Date)))
)

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$computer = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1

$logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID, VolumeName,
        @{ Name = "SizeGB"; Expression = { [math]::Round($_.Size / 1GB, 2) } },
        @{ Name = "FreeGB"; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
        @{ Name = "FreePercent"; Expression = {
            if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { $null }
        } }

$networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" |
    Select-Object Description, MACAddress, DHCPEnabled, IPAddress, DefaultIPGateway, DNSServerSearchOrder

$hotfixes = Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 10 HotFixID, Description, InstalledOn

$inventory = [ordered]@{
    CollectedAt = (Get-Date).ToString("s")
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    Manufacturer = $computer.Manufacturer
    Model = $computer.Model
    Domain = $computer.Domain
    TotalMemoryGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
    OS = [ordered]@{
        Caption = $os.Caption
        Version = $os.Version
        BuildNumber = $os.BuildNumber
        InstallDate = $os.InstallDate
        LastBootUpTime = $os.LastBootUpTime
    }
    BIOS = [ordered]@{
        SerialNumber = $bios.SerialNumber
        SMBIOSBIOSVersion = $bios.SMBIOSBIOSVersion
    }
    CPU = [ordered]@{
        Name = $processor.Name
        Cores = $processor.NumberOfCores
        LogicalProcessors = $processor.NumberOfLogicalProcessors
    }
    LogicalDisks = $logicalDisks
    NetworkAdapters = $networkAdapters
    RecentHotfixes = $hotfixes
}

$inventory | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Saved PC inventory to $OutputPath"
