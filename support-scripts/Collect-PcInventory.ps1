<#
.SYNOPSIS
PCの基本情報を集め、JSONファイルとして保存します。

.DESCRIPTION
問い合わせ対応やPC入替の最初に、「対象PCがどの機種で、どのOSで、
どのネットワーク設定なのか」を確認するための読み取り専用スクリプトです。

このスクリプトは設定変更・削除・再起動を行いません。
Windows が持っている管理情報を読み取り、チケット添付しやすい JSON 形式で保存します。

初学者向けの見方:
- Get-CimInstance は、Windowsの管理情報を取得するコマンドです。
- Select-Object は、取得した情報から必要な列だけ選ぶために使います。
- [ordered]@{ ... } は、出力する項目を順番付きでまとめる書き方です。
- ConvertTo-Json は、PowerShellのオブジェクトをJSON文字列へ変換します。

.PARAMETER OutputPath
結果を保存するJSONファイルのパスです。
指定しない場合は、実行したフォルダに pc-inventory-年月日時分秒.json を作成します。

.EXAMPLE
.\Collect-PcInventory.ps1

現在のフォルダに、端末情報のJSONファイルを自動ファイル名で保存します。

.EXAMPLE
.\Collect-PcInventory.ps1 -OutputPath .\pc-inventory.json

出力先を pc-inventory.json に固定して保存します。
#>

[CmdletBinding()]
param(
    # 出力ファイル名。Join-Path はフォルダパスとファイル名を安全につなげるために使います。
    [string]$OutputPath = (Join-Path (Get-Location) ("pc-inventory-{0:yyyyMMdd-HHmmss}.json" -f (Get-Date)))
)

# OS、PC本体、BIOS、CPUなど、問い合わせ時によく確認する基本情報を取得します。
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$computer = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1

# DriveType=3 はローカルディスクを意味します。Cドライブなどの容量確認に使います。
$logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID, VolumeName,
        @{ Name = "SizeGB"; Expression = { [math]::Round($_.Size / 1GB, 2) } },
        @{ Name = "FreeGB"; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
        @{ Name = "FreePercent"; Expression = {
            if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { $null }
        } }

# IPEnabled=True は、実際にIPアドレスが設定されているネットワークアダプターを意味します。
$networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" |
    Select-Object Description, MACAddress, DHCPEnabled, IPAddress, DefaultIPGateway, DNSServerSearchOrder

# 直近の更新プログラムを10件だけ取得します。多すぎるとチケット添付時に読みづらくなるためです。
$hotfixes = Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 10 HotFixID, Description, InstalledOn

# 取得した情報を1つのまとまりにします。後でJSONへ変換しやすくするため、階層構造にしています。
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

# JSONとして保存します。-Depth 6 は、OSやBIOSなど階層の深い情報を省略しないための指定です。
$inventory | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Saved PC inventory to $OutputPath"
