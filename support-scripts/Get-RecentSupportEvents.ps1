[CmdletBinding()]
param(
    [int]$Hours = 24,
    [string[]]$LogName = @("System", "Application"),
    [string]$OutputPath = (Join-Path (Get-Location) ("support-events-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date))),
    [int]$MaxEventsPerLog = 200
)

$startTime = (Get-Date).AddHours(-1 * $Hours)
$events = foreach ($log in $LogName) {
    try {
        Get-WinEvent -FilterHashtable @{
            LogName = $log
            StartTime = $startTime
            Level = 2, 3
        } -MaxEvents $MaxEventsPerLog -ErrorAction Stop |
            Select-Object TimeCreated, LogName, ProviderName, Id, LevelDisplayName,
                @{ Name = "Message"; Expression = {
                    $message = if ($_.Message) { ($_.Message -replace "\s+", " ").Trim() } else { "" }
                    $message.Substring(0, [math]::Min(500, $message.Length))
                } }
    } catch {
        [pscustomobject]@{
            TimeCreated = Get-Date
            LogName = $log
            ProviderName = "Script"
            Id = 0
            LevelDisplayName = "Warning"
            Message = "Could not read log '$log': $($_.Exception.Message)"
        }
    }
}

$events | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Saved $($events.Count) warning/error events to $OutputPath"
