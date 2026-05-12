#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    . "$PSScriptRoot/../lib/Triage-Lib.ps1"
}

Describe 'Get-DiskStatus' {
    It 'returns OK when usage is below threshold' {
        Get-DiskStatus -UsedPercent 50 -WarningPercent 80 | Should -Be 'OK'
    }

    It 'returns Warning when usage equals threshold' {
        Get-DiskStatus -UsedPercent 80 -WarningPercent 80 | Should -Be 'Warning'
    }

    It 'returns Warning when usage exceeds threshold' {
        Get-DiskStatus -UsedPercent 92.5 -WarningPercent 80 | Should -Be 'Warning'
    }

    It 'returns OK at 0% used' {
        Get-DiskStatus -UsedPercent 0 -WarningPercent 80 | Should -Be 'OK'
    }

    It 'handles fractional percent values' {
        Get-DiskStatus -UsedPercent 79.9 -WarningPercent 80 | Should -Be 'OK'
        Get-DiskStatus -UsedPercent 80.1 -WarningPercent 80 | Should -Be 'Warning'
    }
}

Describe 'Get-OverallStatus' {
    It 'returns OK when all statuses are OK' {
        Get-OverallStatus -Statuses @('OK','OK','OK') | Should -Be 'OK'
    }

    It 'returns Warning when any status is Warning' {
        Get-OverallStatus -Statuses @('OK','Warning','OK') | Should -Be 'Warning'
    }

    It 'returns Warning even when Unknown is also present (Warning has priority)' {
        Get-OverallStatus -Statuses @('OK','Warning','Unknown') | Should -Be 'Warning'
    }

    It 'returns PartiallyChecked when no Warning but at least one Unknown' {
        Get-OverallStatus -Statuses @('OK','OK','Unknown') | Should -Be 'PartiallyChecked'
    }

    It 'returns OK with a single OK element' {
        Get-OverallStatus -Statuses @('OK') | Should -Be 'OK'
    }
}

Describe 'Get-DefenderStatus' {
    It 'returns OK when all enabled and signature is fresh' {
        Get-DefenderStatus -AntivirusEnabled $true -RealTimeProtectionEnabled $true `
            -SignatureAgeHours 12 -SignatureWarningHours 48 | Should -Be 'OK'
    }

    It 'returns Warning when antivirus is disabled' {
        Get-DefenderStatus -AntivirusEnabled $false -RealTimeProtectionEnabled $true `
            -SignatureAgeHours 1 -SignatureWarningHours 48 | Should -Be 'Warning'
    }

    It 'returns Warning when real-time protection is disabled' {
        Get-DefenderStatus -AntivirusEnabled $true -RealTimeProtectionEnabled $false `
            -SignatureAgeHours 1 -SignatureWarningHours 48 | Should -Be 'Warning'
    }

    It 'returns Warning when signature age is null (never updated / unknown)' {
        Get-DefenderStatus -AntivirusEnabled $true -RealTimeProtectionEnabled $true `
            -SignatureAgeHours $null -SignatureWarningHours 48 | Should -Be 'Warning'
    }

    It 'returns Warning when signature age exceeds threshold' {
        Get-DefenderStatus -AntivirusEnabled $true -RealTimeProtectionEnabled $true `
            -SignatureAgeHours 72 -SignatureWarningHours 48 | Should -Be 'Warning'
    }

    It 'returns OK when signature age equals threshold' {
        Get-DefenderStatus -AntivirusEnabled $true -RealTimeProtectionEnabled $true `
            -SignatureAgeHours 48 -SignatureWarningHours 48 | Should -Be 'OK'
    }
}

Describe 'Get-UpdateStatus' {
    It 'returns OK when recent' {
        Get-UpdateStatus -DaysSinceLastUpdate 5 -UpdateWarningDays 30 | Should -Be 'OK'
    }

    It 'returns OK when exactly at threshold' {
        Get-UpdateStatus -DaysSinceLastUpdate 30 -UpdateWarningDays 30 | Should -Be 'OK'
    }

    It 'returns Warning when stale' {
        Get-UpdateStatus -DaysSinceLastUpdate 45 -UpdateWarningDays 30 | Should -Be 'Warning'
    }

    It 'returns Warning when last update is unknown' {
        Get-UpdateStatus -DaysSinceLastUpdate $null -UpdateWarningDays 30 | Should -Be 'Warning'
    }
}

Describe 'ConvertTo-SafeMessage' {
    It 'returns short messages unchanged' {
        ConvertTo-SafeMessage -Message 'short' | Should -Be 'short'
    }

    It 'truncates to MaxLength' {
        $long = 'a' * 700
        $result = ConvertTo-SafeMessage -Message $long -MaxLength 500
        $result.Length | Should -Be 500
    }

    It 'handles empty string' {
        ConvertTo-SafeMessage -Message '' | Should -Be ''
    }

    It 'handles null gracefully (returns empty string)' {
        ConvertTo-SafeMessage -Message $null | Should -Be ''
    }

    It 'accepts pipeline input' {
        ('abcde' * 200 | ConvertTo-SafeMessage -MaxLength 50).Length | Should -Be 50
    }
}
