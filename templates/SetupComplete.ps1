<#
.SYNOPSIS
    Post-installation configuration script for DevBox Windows 11 template.

.DESCRIPTION
    This script runs after Windows installation to:
    - Configure Windows for development
    - Enable required features (WSL2, Hyper-V containers)
    - Disable unnecessary services
    - Set developer-friendly defaults
    - Create template marker file

.NOTES
    This script is automatically invoked by SetupComplete.cmd
    Runs with SYSTEM privileges during first logon
#>

$ErrorActionPreference = "Continue"
$logPath = "C:\Windows\Temp\SetupComplete.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logPath -Value $logMessage
    Write-Host $logMessage
}

Write-Log "DevBox SetupComplete.ps1 started"

#region Developer Configuration

Write-Log "Configuring Windows for development..."

# Enable Developer Mode
try {
    $devModeKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path $devModeKey)) {
        New-Item -Path $devModeKey -Force | Out-Null
    }
    Set-ItemProperty -Path $devModeKey -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord
    Set-ItemProperty -Path $devModeKey -Name AllowAllTrustedApps -Value 1 -Type DWord
    Write-Log "Developer Mode enabled"
} catch {
    Write-Log "Warning: Could not enable Developer Mode: $_"
}

# Show file extensions for all users
try {
    $explorerKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $explorerKey)) {
        New-Item -Path $explorerKey -Force | Out-Null
    }
    Set-ItemProperty -Path $explorerKey -Name HideFileExt -Value 0 -Type DWord
    Write-Log "File extensions visible"
} catch {
    Write-Log "Warning: Could not set file extension visibility: $_"
}

# Show hidden files
try {
    $explorerKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $explorerKey -Name Hidden -Value 1 -Type DWord
    Write-Log "Hidden files visible"
} catch {
    Write-Log "Warning: Could not set hidden files visibility: $_"
}

# Disable Cortana
try {
    $cortanaKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $cortanaKey)) {
        New-Item -Path $cortanaKey -Force | Out-Null
    }
    Set-ItemProperty -Path $cortanaKey -Name AllowCortana -Value 0 -Type DWord
    Write-Log "Cortana disabled"
} catch {
    Write-Log "Warning: Could not disable Cortana: $_"
}

# Disable web search in Start Menu
try {
    $searchKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $searchKey)) {
        New-Item -Path $searchKey -Force | Out-Null
    }
    Set-ItemProperty -Path $searchKey -Name DisableWebSearch -Value 1 -Type DWord
    Set-ItemProperty -Path $searchKey -Name ConnectedSearchUseWeb -Value 0 -Type DWord
    Write-Log "Web search in Start Menu disabled"
} catch {
    Write-Log "Warning: Could not disable web search: $_"
}

#endregion

#region OOBE Bypass

Write-Log "Disabling OOBE and first-run experiences..."

# Disable "Let's finish setting up your device" reminders
try {
    $engagementPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
    if (-not (Test-Path $engagementPath)) {
        New-Item -Path $engagementPath -Force | Out-Null
    }
    Set-ItemProperty -Path $engagementPath -Name ScoobeSystemSettingEnabled -Value 0 -Type DWord
    Write-Log "Disabled 'Let's finish setting up' reminders"
} catch {
    Write-Log "Warning: Could not disable OOBE reminders: $_"
}

# Disable Windows Welcome Experience after updates
try {
    $cdmPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (-not (Test-Path $cdmPath)) {
        New-Item -Path $cdmPath -Force | Out-Null
    }
    Set-ItemProperty -Path $cdmPath -Name SubscribedContent-310093Enabled -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name SubscribedContent-338389Enabled -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name SoftLandingEnabled -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name SystemPaneSuggestionsEnabled -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Disabled Windows Welcome Experience and suggestions"
} catch {
    Write-Log "Warning: Could not disable Welcome Experience: $_"
}

# Disable consumer features (sponsored apps, Start menu suggestions)
try {
    $cloudPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $cloudPath)) {
        New-Item -Path $cloudPath -Force | Out-Null
    }
    Set-ItemProperty -Path $cloudPath -Name DisableWindowsConsumerFeatures -Value 1 -Type DWord
    Write-Log "Disabled consumer features"
} catch {
    Write-Log "Warning: Could not disable consumer features: $_"
}

# Disable Office first-run wizard
try {
    $officePath = "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\General"
    if (-not (Test-Path $officePath)) {
        New-Item -Path $officePath -Force | Out-Null
    }
    Set-ItemProperty -Path $officePath -Name ShownFirstRunOptin -Value 1 -Type DWord
    Set-ItemProperty -Path $officePath -Name DisableFirstRun -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Disabled Office first-run wizard"
} catch {
    Write-Log "Warning: Could not configure Office: $_"
}

# Disable OneDrive folder backup prompts
try {
    $onedrivePath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
    if (-not (Test-Path $onedrivePath)) {
        New-Item -Path $onedrivePath -Force | Out-Null
    }
    Set-ItemProperty -Path $onedrivePath -Name KFMBlockOptIn -Value 1 -Type DWord
    Write-Log "Disabled OneDrive sync prompts"
} catch {
    Write-Log "Warning: Could not configure OneDrive: $_"
}

#endregion

#region Privacy Settings

Write-Log "Applying privacy settings..."

# Disable Advertising ID
try {
    $adInfoPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
    if (-not (Test-Path $adInfoPath)) {
        New-Item -Path $adInfoPath -Force | Out-Null
    }
    Set-ItemProperty -Path $adInfoPath -Name DisabledByGroupPolicy -Value 1 -Type DWord
    Write-Log "Advertising ID disabled"
} catch {
    Write-Log "Warning: Could not disable Advertising ID: $_"
}

# Disable Activity History
try {
    $systemPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (-not (Test-Path $systemPath)) {
        New-Item -Path $systemPath -Force | Out-Null
    }
    Set-ItemProperty -Path $systemPath -Name EnableActivityFeed -Value 0 -Type DWord
    Set-ItemProperty -Path $systemPath -Name PublishUserActivities -Value 0 -Type DWord
    Set-ItemProperty -Path $systemPath -Name UploadUserActivities -Value 0 -Type DWord
    Write-Log "Activity History disabled"
} catch {
    Write-Log "Warning: Could not disable Activity History: $_"
}

# Set telemetry to minimum based on edition
try {
    $edition = (Get-CimInstance Win32_OperatingSystem).Caption
    $telemetryLevel = if ($edition -match "Enterprise|Education") { 0 } else { 1 }
    $telemetryLevelName = if ($telemetryLevel -eq 0) { "Security" } else { "Basic" }

    $dataCollectionPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $dataCollectionPath)) {
        New-Item -Path $dataCollectionPath -Force | Out-Null
    }
    Set-ItemProperty -Path $dataCollectionPath -Name AllowTelemetry -Value $telemetryLevel -Type DWord
    Set-ItemProperty -Path $dataCollectionPath -Name DoNotShowFeedbackNotifications -Value 1 -Type DWord
    Write-Log "Telemetry set to $telemetryLevelName level"
} catch {
    Write-Log "Warning: Could not configure telemetry: $_"
}

# Disable Windows Copilot
try {
    $copilotPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $copilotPath)) {
        New-Item -Path $copilotPath -Force | Out-Null
    }
    Set-ItemProperty -Path $copilotPath -Name TurnOffWindowsCopilot -Value 1 -Type DWord
    Write-Log "Windows Copilot disabled"
} catch {
    Write-Log "Warning: Could not disable Copilot: $_"
}

#endregion

#region Disable Unnecessary Services

Write-Log "Configuring services..."

$servicesToDisable = @(
    "DiagTrack",           # Connected User Experiences and Telemetry
    "dmwappushservice",    # WAP Push Message Routing Service
    "MapsBroker",          # Downloaded Maps Manager
    "lfsvc",               # Geolocation Service
    "SharedAccess",        # Internet Connection Sharing
    "RemoteRegistry"       # Remote Registry
)

foreach ($service in $servicesToDisable) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($null -ne $svc) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled
            Write-Log "Disabled service: $service"
        }
    } catch {
        Write-Log "Warning: Could not disable service $service : $_"
    }
}

#endregion

#region Enable Optional Features

Write-Log "Enabling optional Windows features..."

# Enable WSL
try {
    $wsl = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
    if ($null -ne $wsl -and $wsl.State -ne 'Enabled') {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -All
        Write-Log "WSL enabled"
    } else {
        Write-Log "WSL already enabled or not available"
    }
} catch {
    Write-Log "Warning: Could not enable WSL: $_"
}

# Enable Virtual Machine Platform (for WSL2)
try {
    $vmp = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
    if ($null -ne $vmp -and $vmp.State -ne 'Enabled') {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -All
        Write-Log "Virtual Machine Platform enabled"
    } else {
        Write-Log "Virtual Machine Platform already enabled or not available"
    }
} catch {
    Write-Log "Warning: Could not enable Virtual Machine Platform: $_"
}

# Enable Windows Sandbox (if Pro/Enterprise)
try {
    $sandbox = Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction SilentlyContinue
    if ($null -ne $sandbox -and $sandbox.State -ne 'Enabled') {
        Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -NoRestart -All
        Write-Log "Windows Sandbox enabled"
    }
} catch {
    Write-Log "Note: Windows Sandbox not available on this edition"
}

# Enable Hyper-V (nested virtualization - if supported)
try {
    $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
    if ($null -ne $hyperv -and $hyperv.State -ne 'Enabled') {
        # Only enable if we're not already in a VM without nested virtualization
        $vmProcessor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        if ($vmProcessor.Name -notmatch "Virtual") {
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -All
            Write-Log "Hyper-V enabled"
        } else {
            Write-Log "Skipping Hyper-V (running in VM)"
        }
    }
} catch {
    Write-Log "Note: Hyper-V not available or cannot be enabled"
}

#endregion

#region PowerShell Configuration

Write-Log "Configuring PowerShell..."

# Set execution policy
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
    Write-Log "PowerShell execution policy set to Bypass"
} catch {
    Write-Log "Warning: Could not set execution policy: $_"
}

# Update PowerShellGet
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Log "NuGet provider installed"
} catch {
    Write-Log "Warning: Could not install NuGet provider: $_"
}

# Install useful PowerShell modules
$modulesToInstall = @(
    "PSReadLine",
    "posh-git"
)

foreach ($module in $modulesToInstall) {
    try {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Install-Module -Name $module -Force -AllowClobber -Scope AllUsers -ErrorAction SilentlyContinue
            Write-Log "Installed PowerShell module: $module"
        }
    } catch {
        Write-Log "Warning: Could not install module $module : $_"
    }
}

#endregion

#region Windows Update Configuration

Write-Log "Configuring Windows Update..."

# Configure Windows Update for development
try {
    $wuKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (-not (Test-Path $wuKey)) {
        New-Item -Path $wuKey -Force | Out-Null
    }
    # Don't auto-restart
    Set-ItemProperty -Path $wuKey -Name NoAutoRebootWithLoggedOnUsers -Value 1 -Type DWord
    # Notify before download
    Set-ItemProperty -Path $wuKey -Name AUOptions -Value 2 -Type DWord
    Write-Log "Windows Update configured for developer workflow"
} catch {
    Write-Log "Warning: Could not configure Windows Update: $_"
}

#endregion

#region Create Template Marker

Write-Log "Creating template marker..."

try {
    $markerPath = "C:\DevBox"
    if (-not (Test-Path $markerPath)) {
        New-Item -Path $markerPath -ItemType Directory -Force | Out-Null
    }

    $markerContent = @{
        TemplateVersion = "1.0"
        CreatedDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        WindowsBuild = (Get-CimInstance Win32_OperatingSystem).BuildNumber
        TemplateName = "Win11-DevBox-Template"
    }

    $markerContent | ConvertTo-Json | Out-File -FilePath "$markerPath\template-info.json" -Encoding utf8 -Force
    Write-Log "Template marker created at $markerPath\template-info.json"
} catch {
    Write-Log "Warning: Could not create template marker: $_"
}

#endregion

#region Conservative Debloat

Write-Log "Removing third-party bloatware (conservative mode)..."

# Only remove obvious promotional/third-party apps
$bloatwareApps = @(
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushFriends",
    "king.com.FarmHeroesSaga",
    "BytedancePte.Ltd.TikTok",
    "FACEBOOK.317180B0BB486",
    "Facebook.Instagram",
    "5A894077.McAfeeSecurity",
    "AmazonVideo.PrimeVideo",
    "SpotifyAB.SpotifyMusic",
    "Disney.37853FC22B2CE",
    "4DF9E0F8.Netflix",
    "5319275A.WhatsAppDesktop",
    "22364Disney.ESPNBetaPWA",
    "Clipchamp.Clipchamp"
)

$removedCount = 0
foreach ($appName in $bloatwareApps) {
    try {
        $package = Get-AppxPackage -Name "*$appName*" -AllUsers -ErrorAction SilentlyContinue
        if ($package) {
            # Remove for all users
            Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction SilentlyContinue

            # Remove provisioned package to prevent reinstall on new users
            $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.PackageName -like "*$appName*" }
            if ($provisioned) {
                Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction SilentlyContinue
            }

            Write-Log "Removed bloatware: $appName"
            $removedCount++
        }
    } catch {
        Write-Log "Warning: Could not remove $appName : $_"
    }
}

Write-Log "Removed $removedCount bloatware apps"

#endregion

#region Cleanup

Write-Log "Performing cleanup..."

# Clear temp files
try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Temp files cleared"
} catch {
    Write-Log "Warning: Could not clear all temp files"
}

# Clear Windows Update cache
try {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Log "Windows Update cache cleared"
} catch {
    Write-Log "Warning: Could not clear Windows Update cache"
}

#endregion

Write-Log "DevBox SetupComplete.ps1 finished"
Write-Log "System may require a reboot to complete feature installation"

# Create flag file to indicate setup is complete
"SetupComplete" | Out-File -FilePath "C:\DevBox\.setup-complete" -Encoding ascii -Force

Write-Log "Setup complete flag created"
