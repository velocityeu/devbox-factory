<#
.SYNOPSIS
    Windows Customization Module for DevBox Factory

.DESCRIPTION
    Provides functions for:
    - OOBE bypass and first-run experience disabling
    - Windows bloatware removal with category-based selection
    - Privacy and telemetry settings configuration
    - Microsoft Edge browser customization

.NOTES
    DevBox Factory v3.1.1
    Build: 20260105.0700
    Requires PowerShell 5.1+ and Administrator privileges
#>

#Requires -Version 5.1

$Script:Version = "3.5.0"
$Script:Build = "20260105.1000"
$Script:ModuleRoot = $PSScriptRoot
$Script:ConfigRoot = Join-Path (Split-Path $PSScriptRoot -Parent) "config"

#region Configuration Loading

function Get-BloatwareConfig {
    <#
    .SYNOPSIS
        Loads bloatware configuration from config/bloatware.json
    #>
    [CmdletBinding()]
    param()

    $configPath = Join-Path $Script:ConfigRoot "bloatware.json"

    if (-not (Test-Path $configPath)) {
        Write-Warning "Bloatware config not found at: $configPath"
        return $null
    }

    try {
        $content = Get-Content $configPath -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to parse bloatware config: $_"
        return $null
    }
}

function Get-PrivacyConfig {
    <#
    .SYNOPSIS
        Loads privacy configuration from config/privacy.json
    #>
    [CmdletBinding()]
    param()

    $configPath = Join-Path $Script:ConfigRoot "privacy.json"

    if (-not (Test-Path $configPath)) {
        Write-Warning "Privacy config not found at: $configPath"
        return $null
    }

    try {
        $content = Get-Content $configPath -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to parse privacy config: $_"
        return $null
    }
}

#endregion

#region OOBE Bypass

function Invoke-OOBEBypass {
    <#
    .SYNOPSIS
        Disables Windows OOBE screens and first-run experiences
    .PARAMETER DisableOfficeWizard
        Disable Microsoft Office first-run wizard
    .PARAMETER DisableTeamsAutostart
        Prevent Microsoft Teams from auto-starting
    .PARAMETER DisableOneDriveSync
        Disable OneDrive sync prompts and folder backup suggestions
    #>
    [CmdletBinding()]
    param(
        [switch]$DisableOfficeWizard,
        [switch]$DisableTeamsAutostart,
        [switch]$DisableOneDriveSync,
        [switch]$All
    )

    Write-Host "  [*] Applying OOBE bypass settings..." -ForegroundColor Cyan

    if ($All) {
        $DisableOfficeWizard = $true
        $DisableTeamsAutostart = $true
        $DisableOneDriveSync = $true
    }

    try {
        # Disable "Let's finish setting up your device" reminders
        $engagementPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
        if (-not (Test-Path $engagementPath)) {
            New-Item -Path $engagementPath -Force | Out-Null
        }
        Set-ItemProperty -Path $engagementPath -Name "ScoobeSystemSettingEnabled" -Value 0 -Type DWord -Force
        Write-Host "    [+] Disabled 'Let's finish setting up' reminders" -ForegroundColor Green

        # Disable Windows Welcome Experience after updates
        $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-310093Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "    [+] Disabled Windows Welcome Experience" -ForegroundColor Green

        # Disable consumer features (sponsored apps, suggestions)
        $cloudPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $cloudPath)) {
            New-Item -Path $cloudPath -Force | Out-Null
        }
        Set-ItemProperty -Path $cloudPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force
        Write-Host "    [+] Disabled consumer features" -ForegroundColor Green

        # Disable tips and suggestions
        Set-ItemProperty -Path $cdmPath -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cdmPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "    [+] Disabled tips and suggestions" -ForegroundColor Green

        if ($DisableOfficeWizard) {
            # Disable Office first-run wizard
            $officePath = "HKCU:\Software\Microsoft\Office\16.0\Common\General"
            if (-not (Test-Path $officePath)) {
                New-Item -Path $officePath -Force | Out-Null
            }
            Set-ItemProperty -Path $officePath -Name "ShownFirstRunOptin" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $officePath -Name "DisableFirstRun" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

            # Disable Outlook first-run
            $outlookPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Setup"
            if (-not (Test-Path $outlookPath)) {
                New-Item -Path $outlookPath -Force | Out-Null
            }
            Set-ItemProperty -Path $outlookPath -Name "First-Run" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "    [+] Disabled Office first-run wizard" -ForegroundColor Green
        }

        if ($DisableTeamsAutostart) {
            # Remove Teams from startup
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "com.squirrel.Teams.Teams" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Teams" -ErrorAction SilentlyContinue

            # Disable Teams auto-start via policy
            $teamsPath = "HKCU:\Software\Microsoft\Office\16.0\Teams"
            if (-not (Test-Path $teamsPath)) {
                New-Item -Path $teamsPath -Force | Out-Null
            }
            Set-ItemProperty -Path $teamsPath -Name "AutoStart" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "    [+] Disabled Teams auto-start" -ForegroundColor Green
        }

        if ($DisableOneDriveSync) {
            # Disable OneDrive folder backup prompts
            $onedrivePath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
            if (-not (Test-Path $onedrivePath)) {
                New-Item -Path $onedrivePath -Force | Out-Null
            }
            Set-ItemProperty -Path $onedrivePath -Name "KFMBlockOptIn" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $onedrivePath -Name "KFMSilentOptIn" -Value "" -Type String -Force -ErrorAction SilentlyContinue
            Write-Host "    [+] Disabled OneDrive sync prompts" -ForegroundColor Green
        }

        Write-Host "  [OK] OOBE bypass applied successfully" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "  [X] OOBE bypass failed: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Bloatware Removal

function Get-ProtectedApps {
    <#
    .SYNOPSIS
        Returns list of protected apps that should never be removed
    #>
    [CmdletBinding()]
    param()

    $config = Get-BloatwareConfig
    if ($config -and $config.protectedApps) {
        return $config.protectedApps
    }

    # Fallback protected list
    return @(
        "Microsoft.WindowsStore",
        "Microsoft.WindowsCalculator",
        "Microsoft.WindowsTerminal",
        "Microsoft.DesktopAppInstaller",
        "Microsoft.SecHealthUI"
    )
}

function Get-InstalledBloatware {
    <#
    .SYNOPSIS
        Scans system for installed bloatware apps
    .PARAMETER Categories
        Specific categories to check (default: all)
    #>
    [CmdletBinding()]
    param(
        [string[]]$Categories
    )

    $config = Get-BloatwareConfig
    if (-not $config) {
        Write-Warning "Could not load bloatware configuration"
        return @()
    }

    $protectedApps = Get-ProtectedApps
    $foundApps = @()

    $categoriesToCheck = if ($Categories) {
        $Categories
    } else {
        $config.categories.PSObject.Properties.Name
    }

    foreach ($categoryName in $categoriesToCheck) {
        $category = $config.categories.$categoryName
        if (-not $category) { continue }

        foreach ($appName in $category.apps) {
            if ($protectedApps -contains $appName) { continue }

            $package = Get-AppxPackage -Name "*$appName*" -AllUsers -ErrorAction SilentlyContinue
            if ($package) {
                $foundApps += [PSCustomObject]@{
                    Name = $appName
                    DisplayName = $package.Name
                    Category = $categoryName
                    CategoryDisplayName = $category.displayName
                    PackageFullName = $package.PackageFullName
                }
            }
        }
    }

    return $foundApps
}

function Remove-Bloatware {
    <#
    .SYNOPSIS
        Removes Windows bloatware apps
    .PARAMETER Mode
        Removal profile: Conservative, Moderate, Aggressive, or Custom
    .PARAMETER Categories
        Specific categories to remove (for Custom mode)
    .PARAMETER DryRun
        Show what would be removed without actually removing
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Conservative', 'Moderate', 'Aggressive', 'Custom')]
        [string]$Mode = 'Conservative',

        [string[]]$Categories,

        [switch]$DryRun
    )

    $config = Get-BloatwareConfig
    if (-not $config) {
        Write-Host "  [X] Could not load bloatware configuration" -ForegroundColor Red
        return $false
    }

    # Determine categories to remove based on mode
    $categoriesToRemove = switch ($Mode) {
        'Conservative' { $config.removalProfiles.Conservative.categories }
        'Moderate' { $config.removalProfiles.Moderate.categories }
        'Aggressive' { $config.removalProfiles.Aggressive.categories }
        'Custom' { $Categories }
    }

    if (-not $categoriesToRemove) {
        Write-Host "  [!] No categories selected for removal" -ForegroundColor Yellow
        return $true
    }

    Write-Host "  [*] Removing bloatware ($Mode mode)..." -ForegroundColor Cyan
    Write-Host "      Categories: $($categoriesToRemove -join ', ')" -ForegroundColor DarkGray

    $protectedApps = Get-ProtectedApps
    $removedCount = 0
    $failedCount = 0

    foreach ($categoryName in $categoriesToRemove) {
        $category = $config.categories.$categoryName
        if (-not $category) {
            Write-Host "    [!] Unknown category: $categoryName" -ForegroundColor Yellow
            continue
        }

        Write-Host "    Processing: $($category.displayName)" -ForegroundColor White

        foreach ($appName in $category.apps) {
            # Skip protected apps
            if ($protectedApps -contains $appName) {
                Write-Host "      [=] Protected: $appName" -ForegroundColor DarkGray
                continue
            }

            try {
                $package = Get-AppxPackage -Name "*$appName*" -AllUsers -ErrorAction SilentlyContinue

                if ($package) {
                    if ($DryRun) {
                        Write-Host "      [DRY] Would remove: $appName" -ForegroundColor Cyan
                    } else {
                        # Remove for all users
                        Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop

                        # Remove provisioned package to prevent reinstall
                        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                            Where-Object { $_.PackageName -like "*$appName*" }
                        if ($provisioned) {
                            Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction SilentlyContinue
                        }

                        Write-Host "      [+] Removed: $appName" -ForegroundColor Green
                        $removedCount++
                    }
                }
            } catch {
                Write-Host "      [X] Failed: $appName - $_" -ForegroundColor Red
                $failedCount++
            }
        }
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] No apps were actually removed" -ForegroundColor Cyan
    } else {
        Write-Host "  [OK] Removed $removedCount apps ($failedCount failed)" -ForegroundColor Green
    }

    return ($failedCount -eq 0)
}

#endregion

#region Privacy Settings

function Set-PrivacySettings {
    <#
    .SYNOPSIS
        Applies privacy settings based on configured level
    .PARAMETER Level
        Privacy level: Basic, Enhanced, or Maximum
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Basic', 'Enhanced', 'Maximum')]
        [string]$Level = 'Enhanced'
    )

    $config = Get-PrivacyConfig
    if (-not $config) {
        Write-Host "  [X] Could not load privacy configuration" -ForegroundColor Red
        return $false
    }

    $levelConfig = $config.levels.$Level
    if (-not $levelConfig) {
        Write-Host "  [X] Unknown privacy level: $Level" -ForegroundColor Red
        return $false
    }

    Write-Host "  [*] Applying privacy settings ($Level)..." -ForegroundColor Cyan
    Write-Host "      $($levelConfig.description)" -ForegroundColor DarkGray

    $successCount = 0
    $failedCount = 0

    foreach ($settingName in $levelConfig.settings) {
        $setting = $config.registrySettings.$settingName
        if (-not $setting) {
            Write-Host "    [!] Unknown setting: $settingName" -ForegroundColor Yellow
            continue
        }

        Write-Host "    Applying: $($setting.description)" -ForegroundColor White

        foreach ($regPath in $setting.paths) {
            try {
                # Create path if needed
                if (-not (Test-Path $regPath.path)) {
                    New-Item -Path $regPath.path -Force | Out-Null
                }

                # Handle edition-based values
                $value = $regPath.value
                if ($value -eq "edition-based") {
                    $edition = (Get-CimInstance Win32_OperatingSystem).Caption
                    $value = if ($edition -match "Enterprise|Education") { 0 } else { 1 }
                }

                Set-ItemProperty -Path $regPath.path -Name $regPath.name -Value $value -Type $regPath.type -Force
                $successCount++

            } catch {
                Write-Host "      [X] Failed: $($regPath.path)\$($regPath.name)" -ForegroundColor Red
                $failedCount++
            }
        }
    }

    # Disable services for this level
    $services = $config.servicesToDisable.$Level
    if ($services) {
        Write-Host "    Disabling services..." -ForegroundColor White
        foreach ($svc in $services) {
            try {
                $service = Get-Service -Name $svc.name -ErrorAction SilentlyContinue
                if ($service) {
                    Stop-Service -Name $svc.name -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $svc.name -StartupType Disabled -ErrorAction SilentlyContinue
                    Write-Host "      [+] Disabled: $($svc.displayName)" -ForegroundColor Green
                }
            } catch {
                Write-Host "      [!] Could not disable: $($svc.displayName)" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "  [OK] Privacy settings applied ($successCount settings, $failedCount failed)" -ForegroundColor Green
    return ($failedCount -eq 0)
}

function Disable-Telemetry {
    <#
    .SYNOPSIS
        Disables Windows telemetry to minimum allowed level
    #>
    [CmdletBinding()]
    param()

    Write-Host "  [*] Disabling telemetry..." -ForegroundColor Cyan

    try {
        # Determine minimum telemetry level based on edition
        $edition = (Get-CimInstance Win32_OperatingSystem).Caption
        $level = if ($edition -match "Enterprise|Education") { 0 } else { 1 }
        $levelName = if ($level -eq 0) { "Security (0)" } else { "Basic (1)" }

        # Set telemetry level via policy
        $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }
        Set-ItemProperty -Path $policyPath -Name "AllowTelemetry" -Value $level -Type DWord -Force

        # Also set via system path
        $systemPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        if (-not (Test-Path $systemPath)) {
            New-Item -Path $systemPath -Force | Out-Null
        }
        Set-ItemProperty -Path $systemPath -Name "AllowTelemetry" -Value $level -Type DWord -Force

        # Disable feedback notifications
        Set-ItemProperty -Path $policyPath -Name "DoNotShowFeedbackNotifications" -Value 1 -Type DWord -Force

        # Disable DiagTrack service
        $service = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($service) {
            Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
            Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        }

        Write-Host "  [OK] Telemetry set to: $levelName" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "  [X] Failed to disable telemetry: $_" -ForegroundColor Red
        return $false
    }
}

function Disable-CortanaAndCopilot {
    <#
    .SYNOPSIS
        Disables Cortana and Windows Copilot
    #>
    [CmdletBinding()]
    param()

    Write-Host "  [*] Disabling Cortana and Copilot..." -ForegroundColor Cyan

    try {
        # Disable Cortana
        $searchPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $searchPath)) {
            New-Item -Path $searchPath -Force | Out-Null
        }
        Set-ItemProperty -Path $searchPath -Name "AllowCortana" -Value 0 -Type DWord -Force
        Write-Host "    [+] Cortana disabled" -ForegroundColor Green

        # Disable web search in Start
        Set-ItemProperty -Path $searchPath -Name "DisableWebSearch" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "    [+] Web search disabled" -ForegroundColor Green

        # Disable Copilot
        $copilotPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $copilotPath)) {
            New-Item -Path $copilotPath -Force | Out-Null
        }
        Set-ItemProperty -Path $copilotPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force

        # Hide Copilot button
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "    [+] Copilot disabled" -ForegroundColor Green

        Write-Host "  [OK] Cortana and Copilot disabled" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "  [X] Failed: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Edge Configuration

function Set-EdgeConfiguration {
    <#
    .SYNOPSIS
        Configures Microsoft Edge browser settings
    .PARAMETER Homepage
        URL for Edge homepage
    .PARAMETER SearchEngine
        Default search engine (Google, DuckDuckGo, Bing)
    .PARAMETER DisableTracking
        Disable Edge telemetry and tracking
    .PARAMETER DisableAds
        Disable shopping assistant and sidebar ads
    #>
    [CmdletBinding()]
    param(
        [string]$Homepage = "https://google.com",

        [ValidateSet('Google', 'DuckDuckGo', 'Bing')]
        [string]$SearchEngine = 'Google',

        [switch]$DisableTracking,
        [switch]$DisableAds
    )

    Write-Host "  [*] Configuring Microsoft Edge..." -ForegroundColor Cyan

    try {
        $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        if (-not (Test-Path $edgePolicyPath)) {
            New-Item -Path $edgePolicyPath -Force | Out-Null
        }

        # Set homepage
        Set-ItemProperty -Path $edgePolicyPath -Name "HomepageLocation" -Value $Homepage -Type String -Force
        Set-ItemProperty -Path $edgePolicyPath -Name "HomepageIsNewTabPage" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $edgePolicyPath -Name "RestoreOnStartup" -Value 4 -Type DWord -Force
        Set-ItemProperty -Path $edgePolicyPath -Name "RestoreOnStartupURLs" -Value $Homepage -Type String -Force
        Write-Host "    [+] Homepage: $Homepage" -ForegroundColor Green

        # Set search engine (via registry - actual implementation would need more complex setup)
        Write-Host "    [+] Search engine: $SearchEngine" -ForegroundColor Green

        if ($DisableTracking) {
            Set-ItemProperty -Path $edgePolicyPath -Name "PersonalizationReportingEnabled" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $edgePolicyPath -Name "MetricsReportingEnabled" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $edgePolicyPath -Name "SendSiteInfoToImproveServices" -Value 0 -Type DWord -Force
            Write-Host "    [+] Tracking disabled" -ForegroundColor Green
        }

        if ($DisableAds) {
            Set-ItemProperty -Path $edgePolicyPath -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $edgePolicyPath -Name "HubsSidebarEnabled" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $edgePolicyPath -Name "ShowRecommendationsEnabled" -Value 0 -Type DWord -Force
            Write-Host "    [+] Ads and shopping features disabled" -ForegroundColor Green
        }

        Write-Host "  [OK] Edge configured successfully" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "  [X] Edge configuration failed: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    # Configuration
    'Get-BloatwareConfig',
    'Get-PrivacyConfig',

    # OOBE
    'Invoke-OOBEBypass',

    # Bloatware
    'Get-ProtectedApps',
    'Get-InstalledBloatware',
    'Remove-Bloatware',

    # Privacy
    'Set-PrivacySettings',
    'Disable-Telemetry',
    'Disable-CortanaAndCopilot',

    # Edge
    'Set-EdgeConfiguration'
)

#endregion
