<#
.SYNOPSIS
    DevBox Factory - Bootstrap installer for vanilla Windows 11

.DESCRIPTION
    Self-contained bootstrapper that:
    1. Verifies Windows 11 22H2+ and administrator privileges
    2. Checks network connectivity to GitHub
    3. Checks for updates and offers to update if newer version available
    4. Prompts for installation directory
    5. Downloads all DevBox Factory scripts from GitHub
    6. Validates downloads
    7. Optionally runs Install-DevBox.ps1

.EXAMPLE
    irm https://raw.githubusercontent.com/velocityeu/devbox-factory/main/Initialize-DevBox.ps1 | iex

.NOTES
    Version: 3.0.0
    Build: 20260104.1800
    DevBox Factory - https://github.com/velocityeu/devbox-factory
#>

#Requires -Version 5.1

$Script:DevBoxVersion = @{
    Major       = 3
    Minor       = 0
    Patch       = 0
    Build       = "20260104.1800"
    BuildDate   = "2026-01-04 18:00"
}

$Script:GitHubBaseUrl = "https://raw.githubusercontent.com/velocityeu/devbox-factory/main"
$Script:RequiredFiles = @(
    @{ Path = "Install-DevBox.ps1"; Required = $true },
    @{ Path = "devbox.ps1"; Required = $true },
    @{ Path = "README.md"; Required = $false },
    @{ Path = "config/presets.json"; Required = $true },
    @{ Path = "templates/New-DevBoxTemplate.ps1"; Required = $true },
    @{ Path = "templates/SetupComplete.ps1"; Required = $true },
    @{ Path = "templates/autounattend.xml"; Required = $true },
    @{ Path = "vms/New-DevBoxVM.ps1"; Required = $true },
    @{ Path = "utils/Test-DevBoxHealth.ps1"; Required = $false },
    @{ Path = "iso/README.md"; Required = $false }
)

# Minimum requirements
$Script:MinDiskSpaceGB = 100
$Script:ISOSearchPaths = @(
    ".\iso",
    "$env:USERPROFILE\Downloads",
    "C:\ISOs",
    "D:\ISOs"
)

#region Banner and UI

function Get-VersionString {
    return "v$($Script:DevBoxVersion.Major).$($Script:DevBoxVersion.Minor).$($Script:DevBoxVersion.Patch)"
}

function Show-Banner {
    Clear-Host
    $version = Get-VersionString
    $build = $Script:DevBoxVersion.Build

    Write-Host ""
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host "  |  ____  ______      ______   ____  __  __                            |" -ForegroundColor Cyan
    Write-Host "  | |  _ \| ____\ \   / /  _ \ / __ \ \ \/ /                            |" -ForegroundColor Cyan
    Write-Host "  | | | | |  _|  \ \ / /| |_) | |  | | \  /                             |" -ForegroundColor Cyan
    Write-Host "  | | |_| | |___  \ V / |  _ <| |  | | /  \                             |" -ForegroundColor Cyan
    Write-Host "  | |____/|_____|  \_/  |_| \_\ \__/ /_/\_\                             |" -ForegroundColor Cyan
    Write-Host "  |                                                                     |" -ForegroundColor DarkCyan
    Write-Host "  |                      F A C T O R Y                                  |" -ForegroundColor Yellow
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host "  |  BOOTSTRAP INSTALLER                                                |" -ForegroundColor White
    Write-Host "  |  One command. Identical dev environments. Every time.               |" -ForegroundColor Gray
    Write-Host "  |  by Velocity EU                           $version build $build  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Message {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header")]
        [string]$Level = "Info"
    )

    $prefix = switch ($Level) {
        "Info"    { "  [*]" }
        "Success" { "  [+]" }
        "Warning" { "  [!]" }
        "Error"   { "  [X]" }
        "Header"  { "  ==>" }
    }

    $color = switch ($Level) {
        "Info"    { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Header"  { "Cyan" }
    }

    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Show-ErrorWithRemediation {
    param(
        [string]$ErrorCode,
        [string]$Message,
        [string[]]$Steps
    )

    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Red
    Write-Host "  |                        ERROR                               |" -ForegroundColor Red
    Write-Host "  +===========================================================+" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Error Code: $ErrorCode" -ForegroundColor Red
    Write-Host "  $Message" -ForegroundColor White
    Write-Host ""

    if ($Steps.Count -gt 0) {
        Write-Host "  How to fix:" -ForegroundColor Yellow
        $stepNum = 1
        foreach ($step in $Steps) {
            Write-Host "    $stepNum. $step" -ForegroundColor White
            $stepNum++
        }
    }
    Write-Host ""
}

#endregion

#region Version Check and Update

function Get-RemoteVersion {
    <#
    .SYNOPSIS
        Fetches the latest version info from GitHub
    #>
    try {
        $versionUrl = "$Script:GitHubBaseUrl/Initialize-DevBox.ps1"
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "DevBox-Factory/$($Script:DevBoxVersion.Major).$($Script:DevBoxVersion.Minor)")
        $content = $webClient.DownloadString($versionUrl)

        # Parse version from the remote script
        if ($content -match 'Major\s*=\s*(\d+)') { $major = [int]$matches[1] } else { return $null }
        if ($content -match 'Minor\s*=\s*(\d+)') { $minor = [int]$matches[1] } else { return $null }
        if ($content -match 'Patch\s*=\s*(\d+)') { $patch = [int]$matches[1] } else { return $null }
        if ($content -match 'Build\s*=\s*"([^"]+)"') { $build = $matches[1] } else { $build = "unknown" }
        if ($content -match 'BuildDate\s*=\s*"([^"]+)"') { $buildDate = $matches[1] } else { $buildDate = "unknown" }

        return @{
            Major     = $major
            Minor     = $minor
            Patch     = $patch
            Build     = $build
            BuildDate = $buildDate
            Version   = "$major.$minor.$patch"
        }
    } catch {
        return $null
    }
}

function Compare-Versions {
    <#
    .SYNOPSIS
        Compares local and remote versions
    .RETURNS
        -1 if local < remote (update available)
         0 if local = remote (up to date)
         1 if local > remote (local is newer)
    #>
    param(
        [hashtable]$Local,
        [hashtable]$Remote
    )

    if ($Local.Major -lt $Remote.Major) { return -1 }
    if ($Local.Major -gt $Remote.Major) { return 1 }

    if ($Local.Minor -lt $Remote.Minor) { return -1 }
    if ($Local.Minor -gt $Remote.Minor) { return 1 }

    if ($Local.Patch -lt $Remote.Patch) { return -1 }
    if ($Local.Patch -gt $Remote.Patch) { return 1 }

    # Same version, check build number
    if ($Local.Build -lt $Remote.Build) { return -1 }
    if ($Local.Build -gt $Remote.Build) { return 1 }

    return 0
}

function Test-ForUpdates {
    <#
    .SYNOPSIS
        Checks for updates and prompts user to update if available
    .RETURNS
        $true if should continue, $false if user wants to update first
    #>
    param(
        [string]$ExistingInstallPath = $null
    )

    # Only check for updates if we have an existing installation
    if (-not $ExistingInstallPath -or -not (Test-Path $ExistingInstallPath)) {
        return @{ Continue = $true; UpdateAvailable = $false }
    }

    Show-Message "Checking for updates..." -Level Info

    $remoteVersion = Get-RemoteVersion
    if (-not $remoteVersion) {
        Show-Message "Could not check for updates (offline?)" -Level Warning
        return @{ Continue = $true; UpdateAvailable = $false }
    }

    $comparison = Compare-Versions -Local $Script:DevBoxVersion -Remote $remoteVersion
    $localVer = "v$($Script:DevBoxVersion.Major).$($Script:DevBoxVersion.Minor).$($Script:DevBoxVersion.Patch)"
    $remoteVer = "v$($remoteVersion.Version)"

    if ($comparison -lt 0) {
        # Update available
        Write-Host ""
        Write-Host "  +===========================================================+" -ForegroundColor Yellow
        Write-Host "  |                   UPDATE AVAILABLE                         |" -ForegroundColor Yellow
        Write-Host "  +===========================================================+" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Installed: $localVer (build $($Script:DevBoxVersion.Build))" -ForegroundColor White
        Write-Host "  Available: $remoteVer (build $($remoteVersion.Build))" -ForegroundColor Green
        Write-Host "  Released:  $($remoteVersion.BuildDate)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   [1] Update now (Recommended)" -ForegroundColor White
        Write-Host "       Download latest version to: $ExistingInstallPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   [2] Skip update" -ForegroundColor White
        Write-Host "       Continue with current version" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

        $choice = Read-Host "  Enter choice [1]"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

        if ($choice -eq "1") {
            return @{ Continue = $true; UpdateAvailable = $true; UpdateNow = $true; InstallPath = $ExistingInstallPath }
        } else {
            Show-Message "Skipping update, continuing with $localVer" -Level Info
            return @{ Continue = $true; UpdateAvailable = $true; UpdateNow = $false }
        }
    } elseif ($comparison -eq 0) {
        Show-Message "You have the latest version ($localVer)" -Level Success
        return @{ Continue = $true; UpdateAvailable = $false }
    } else {
        Show-Message "Local version ($localVer) is newer than remote ($remoteVer)" -Level Info
        return @{ Continue = $true; UpdateAvailable = $false }
    }
}

function Find-ExistingInstallation {
    <#
    .SYNOPSIS
        Looks for existing DevBox Factory installation
    #>
    $commonPaths = @(
        "C:\DevBox",
        "$env:USERPROFILE\DevBox"
    )

    # Add $PSScriptRoot only if it's not empty (empty when running via irm | iex)
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $commonPaths += $PSScriptRoot
    }

    foreach ($path in $commonPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path (Join-Path $path "devbox.ps1"))) {
            return $path
        }
    }

    return $null
}

#endregion

#region Prerequisites

function Test-Prerequisites {
    $checks = @()

    # Check Windows version (Win11 22H2+ or Server 2025)
    Show-Message "Checking Windows version..." -Level Header
    $os = Get-CimInstance Win32_OperatingSystem
    $buildNumber = [int]$os.BuildNumber
    $isWin11 = $buildNumber -ge 22000
    $is22H2Plus = $buildNumber -ge 22621
    $isServer2025 = $os.Caption -match "Server" -and $buildNumber -ge 26100

    $validOS = $is22H2Plus -or $isServer2025
    $osMessage = if ($isServer2025) {
        "Windows Server 2025 (Build $buildNumber)"
    } elseif ($is22H2Plus) {
        "Windows 11 Build $buildNumber"
    } elseif ($isWin11) {
        "Windows 11 Build $buildNumber - needs 22H2+ (22621+)"
    } else {
        "Windows $buildNumber - requires Windows 11 or Server 2025"
    }

    $checks += @{
        Name = "Windows 11 22H2+ or Server 2025"
        Passed = $validOS
        Message = $osMessage
        Critical = $true
    }

    # Check admin privileges
    Show-Message "Checking administrator privileges..." -Level Header
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $checks += @{
        Name = "Administrator privileges"
        Passed = $isAdmin
        Message = if ($isAdmin) { "Running as Administrator" } else { "Not running as Administrator" }
        Critical = $true
    }

    # Check network connectivity
    Show-Message "Checking network connectivity..." -Level Header
    $canReachGitHub = $false
    try {
        $response = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        $canReachGitHub = $response.StatusCode -eq 200
    } catch {
        $canReachGitHub = $false
    }

    $checks += @{
        Name = "Network connectivity"
        Passed = $canReachGitHub
        Message = if ($canReachGitHub) { "GitHub reachable" } else { "Cannot reach GitHub" }
        Critical = $true
    }

    return $checks
}

function Test-HyperVPrerequisites {
    $checks = @()

    # Check CPU virtualization support
    Show-Message "Checking CPU virtualization support..." -Level Header
    $cpuVirt = $false
    try {
        $cpu = Get-CimInstance Win32_Processor
        $vmFirmware = Get-CimInstance Win32_ComputerSystem
        $cpuVirt = $vmFirmware.HypervisorPresent -or ($cpu.VirtualizationFirmwareEnabled -eq $true)

        # Alternative check via systeminfo
        if (-not $cpuVirt) {
            $sysinfo = systeminfo /fo csv | ConvertFrom-Csv
            $cpuVirt = $sysinfo.'Hyper-V Requirements' -notmatch "No"
        }
    } catch {
        $cpuVirt = $true  # Assume supported if can't detect
    }

    $checks += @{
        Name = "CPU Virtualization (VT-x/AMD-V)"
        Passed = $cpuVirt
        Message = if ($cpuVirt) { "Virtualization supported" } else { "Enable VT-x/AMD-V in BIOS" }
        Critical = $false
        CanFix = $false
    }

    # Check Hyper-V feature
    Show-Message "Checking Hyper-V feature..." -Level Header
    $hypervEnabled = $false
    $hypervAvailable = $false

    try {
        # Check Windows client
        $hypervFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
        if ($null -ne $hypervFeature) {
            $hypervAvailable = $true
            $hypervEnabled = $hypervFeature.State -eq 'Enabled'
        }

        # Check Windows Server
        if (-not $hypervAvailable) {
            $hypervRole = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue
            if ($null -ne $hypervRole) {
                $hypervAvailable = $true
                $hypervEnabled = $hypervRole.InstallState -eq 'Installed'
            }
        }
    } catch {
        $hypervAvailable = $false
    }

    $hypervMessage = if ($hypervEnabled) {
        "Hyper-V is enabled"
    } elseif ($hypervAvailable) {
        "Hyper-V available but not enabled"
    } else {
        "Hyper-V not available (requires Pro/Enterprise/Server)"
    }

    $checks += @{
        Name = "Hyper-V Feature"
        Passed = $hypervEnabled
        Message = $hypervMessage
        Critical = $false
        CanFix = $hypervAvailable -and (-not $hypervEnabled)
    }

    # Check disk space
    Show-Message "Checking disk space..." -Level Header
    $systemDrive = $env:SystemDrive
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 0)
    $hasDiskSpace = $freeGB -ge $Script:MinDiskSpaceGB

    $checks += @{
        Name = "Disk Space (min $($Script:MinDiskSpaceGB)GB)"
        Passed = $hasDiskSpace
        Message = "${freeGB}GB free on $systemDrive"
        Critical = $false
        CanFix = $false
    }

    return $checks
}

function Find-WindowsISO {
    param([string]$BasePath = ".")

    $isoFiles = @()

    foreach ($searchPath in $Script:ISOSearchPaths) {
        $fullPath = if ([System.IO.Path]::IsPathRooted($searchPath)) {
            $searchPath
        } else {
            Join-Path $BasePath $searchPath
        }

        if (Test-Path $fullPath) {
            $files = Get-ChildItem -Path $fullPath -Filter "*.iso" -ErrorAction SilentlyContinue |
                     Where-Object { $_.Length -gt 3GB } |
                     Select-Object FullName, Name, @{N='SizeGB';E={[math]::Round($_.Length/1GB,2)}}, LastWriteTime
            $isoFiles += $files
        }
    }

    return $isoFiles | Sort-Object LastWriteTime -Descending
}

function Test-ISOAvailability {
    param([string]$BasePath = ".")

    Show-Message "Checking for Windows ISO files..." -Level Header
    $isoFiles = Find-WindowsISO -BasePath $BasePath

    $hasISO = $isoFiles.Count -gt 0
    $isoMessage = if ($hasISO) {
        "Found $($isoFiles.Count) ISO file(s)"
    } else {
        "No ISO files found in iso/ folder"
    }

    return @{
        Name = "Windows ISO File"
        Passed = $hasISO
        Message = $isoMessage
        Critical = $false
        CanFix = $false
        ISOFiles = $isoFiles
    }
}

function Enable-HyperVFeature {
    Show-Message "Enabling Hyper-V feature..." -Level Header

    try {
        # Try Windows client method
        $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -All -ErrorAction Stop
        if ($result.RestartNeeded) {
            return @{ Success = $true; RebootRequired = $true }
        }
        return @{ Success = $true; RebootRequired = $false }
    } catch {
        # Try Windows Server method
        try {
            Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart:$false -ErrorAction Stop
            return @{ Success = $true; RebootRequired = $true }
        } catch {
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    }
}

function Show-PrerequisiteResults {
    param(
        [array]$Checks,
        [string]$Title = "PREREQUISITES CHECK"
    )

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                 $($Title.PadRight(40))|" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $allPassed = $true
    $criticalFailed = $false

    foreach ($check in $Checks) {
        $icon = if ($check.Passed) { "[+]" } else { "[X]" }
        $color = if ($check.Passed) { "Green" } else { "Red" }

        # Show fixable indicator
        $fixable = ""
        if (-not $check.Passed -and $check.CanFix) {
            $fixable = " (can be installed)"
            $color = "Yellow"
            $icon = "[!]"
        }

        Write-Host "  $icon $($check.Name)$fixable" -ForegroundColor $color
        Write-Host "      $($check.Message)" -ForegroundColor Gray

        if (-not $check.Passed) {
            $allPassed = $false
            if ($check.Critical) { $criticalFailed = $true }
        }
    }

    Write-Host ""
    return @{ AllPassed = $allPassed; CriticalFailed = $criticalFailed }
}

function Show-HyperVPrerequisiteResults {
    param(
        [array]$Checks,
        [hashtable]$ISOCheck
    )

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |              HYPER-V VM PREREQUISITES                      |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    foreach ($check in $Checks) {
        $icon = if ($check.Passed) { "[+]" } else { "[X]" }
        $color = if ($check.Passed) { "Green" } else { "Red" }

        if (-not $check.Passed -and $check.CanFix) {
            $color = "Yellow"
            $icon = "[!]"
        }

        Write-Host "  $icon $($check.Name)" -ForegroundColor $color
        Write-Host "      $($check.Message)" -ForegroundColor Gray
    }

    # Show ISO check
    $isoIcon = if ($ISOCheck.Passed) { "[+]" } else { "[!]" }
    $isoColor = if ($ISOCheck.Passed) { "Green" } else { "Yellow" }
    Write-Host "  $isoIcon $($ISOCheck.Name)" -ForegroundColor $isoColor
    Write-Host "      $($ISOCheck.Message)" -ForegroundColor Gray

    if ($ISOCheck.Passed -and $ISOCheck.ISOFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "  Found ISO files:" -ForegroundColor Cyan
        foreach ($iso in $ISOCheck.ISOFiles | Select-Object -First 3) {
            Write-Host "    - $($iso.Name) ($($iso.SizeGB)GB)" -ForegroundColor White
        }
    }

    Write-Host ""
}

#endregion

#region Directory Selection

function Get-InstallationDirectory {
    $defaultPath = "C:\DevBox"

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                INSTALLATION DIRECTORY                      |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] Use default: $defaultPath" -ForegroundColor White
    Write-Host "       Recommended for most users" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] Enter custom path" -ForegroundColor White
    Write-Host "       Specify your own location" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] Browse for folder" -ForegroundColor White
    Write-Host "       Opens folder picker dialog" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter choice [1]"

    switch ($choice) {
        '' { return $defaultPath }
        '1' { return $defaultPath }
        '2' {
            Write-Host ""
            $customPath = Read-Host "  Enter installation path"
            if ([string]::IsNullOrWhiteSpace($customPath)) {
                return $defaultPath
            }
            return $customPath
        }
        '3' {
            Add-Type -AssemblyName System.Windows.Forms
            $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $dialog.Description = "Select DevBox Factory installation folder"
            $dialog.ShowNewFolderButton = $true
            $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer

            $result = $dialog.ShowDialog()
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                return $dialog.SelectedPath
            }
            Show-Message "No folder selected, using default" -Level Warning
            return $defaultPath
        }
        default { return $defaultPath }
    }
}

#endregion

#region Download

function Download-DevBoxFiles {
    param(
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    $results = @{
        Downloaded = @()
        Failed = @()
        Skipped = @()
    }

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                 DOWNLOADING FILES                          |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    # Create directory structure
    Show-Message "Creating directory structure..." -Level Info
    try {
        New-Item -ItemType Directory -Path $DestinationPath -Force -ErrorAction Stop | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $DestinationPath "HyperV") -Force -ErrorAction Stop | Out-Null
        Show-Message "Directories created" -Level Success
    } catch {
        Show-Message "Failed to create directories: $_" -Level Error
        return $results
    }

    Write-Host ""
    $totalFiles = $Script:RequiredFiles.Count
    $current = 0

    foreach ($fileInfo in $Script:RequiredFiles) {
        $file = $fileInfo.Path
        $isRequired = $fileInfo.Required
        $current++

        $url = "$Script:GitHubBaseUrl/$file"
        $destFile = Join-Path $DestinationPath $file

        # Ensure parent directory exists
        $parentDir = Split-Path $destFile -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        $progressBar = "[" + ("=" * [math]::Floor(($current / $totalFiles) * 20)) + (" " * (20 - [math]::Floor(($current / $totalFiles) * 20))) + "]"
        Write-Host "  $progressBar $current/$totalFiles " -NoNewline

        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "DevBox-Factory/2.0")
            $webClient.DownloadFile($url, $destFile)

            if (Test-Path $destFile) {
                $fileSize = (Get-Item $destFile).Length
                if ($fileSize -gt 0) {
                    Write-Host "[+] $file" -ForegroundColor Green
                    $results.Downloaded += $file
                } else {
                    throw "Empty file downloaded"
                }
            } else {
                throw "File not created"
            }
        } catch {
            if ($isRequired) {
                Write-Host "[X] $file (REQUIRED)" -ForegroundColor Red
                $results.Failed += $file
            } else {
                Write-Host "[-] $file (optional, skipped)" -ForegroundColor Yellow
                $results.Skipped += $file
            }
        }
    }

    return $results
}

function Show-DownloadSummary {
    param(
        [hashtable]$Results,
        [string]$InstallPath
    )

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  DOWNLOAD SUMMARY                          |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Downloaded: $($Results.Downloaded.Count) files" -ForegroundColor Green

    if ($Results.Skipped.Count -gt 0) {
        Write-Host "  Skipped:    $($Results.Skipped.Count) optional files" -ForegroundColor Yellow
    }

    if ($Results.Failed.Count -gt 0) {
        Write-Host "  Failed:     $($Results.Failed.Count) required files" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Failed files:" -ForegroundColor Red
        foreach ($f in $Results.Failed) {
            Write-Host "    - $f" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "  Installation path: $InstallPath" -ForegroundColor White
}

#endregion

#region Post-Bootstrap

function Show-NextSteps {
    param(
        [string]$InstallPath,
        [hashtable]$HyperVStatus = $null
    )

    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Green
    Write-Host "  |              BOOTSTRAP COMPLETE                            |" -ForegroundColor Green
    Write-Host "  +===========================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  All DevBox Factory scripts have been downloaded!" -ForegroundColor White
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  3-STAGE WORKFLOW                          |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  STAGE 0: Install tools on THIS PC (optional)" -ForegroundColor White
    Write-Host "     cd `"$InstallPath`"" -ForegroundColor Yellow
    Write-Host "     .\devbox install" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  STAGE 1: Create VM Template (one-time, ~45 min)" -ForegroundColor White
    Write-Host "     - Place Windows ISO in: $InstallPath\iso\" -ForegroundColor Gray
    Write-Host "     - Creates template with ALL dev tools pre-installed" -ForegroundColor Gray
    Write-Host "     .\devbox template" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  STAGE 2: Create VMs (instant, ~2-3 min each)" -ForegroundColor White
    Write-Host "     - Clone template to new VMs" -ForegroundColor Gray
    Write-Host "     - VMs are READY TO CODE immediately" -ForegroundColor Gray
    Write-Host "     .\devbox vm" -ForegroundColor Yellow
    Write-Host ""
}

function Show-PostBootstrapMenu {
    param(
        [string]$InstallPath,
        [bool]$HyperVReady = $false,
        [bool]$ISOFound = $false
    )

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                   WHAT NEXT?                               |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    # Show options based on system readiness
    if ($HyperVReady -and $ISOFound) {
        Write-Host "   [1] Create VM Template (Recommended)" -ForegroundColor White
        Write-Host "       Create template with dev tools pre-installed" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "   [2] Install tools on THIS PC" -ForegroundColor White
    Write-Host "       Setup this machine as a dev workstation" -ForegroundColor Gray
    Write-Host ""

    if (-not $HyperVReady) {
        Write-Host "   [3] Enable Hyper-V" -ForegroundColor Yellow
        Write-Host "       Required for VM template creation (needs reboot)" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "   [4] Open installation folder" -ForegroundColor White
    Write-Host "       View downloaded scripts in Explorer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [5] Run health check" -ForegroundColor White
    Write-Host "       Verify system readiness" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [Q] Exit" -ForegroundColor White
    Write-Host "       Run scripts manually later" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $defaultChoice = if ($HyperVReady -and $ISOFound) { "1" } else { "2" }
    $choice = Read-Host "  Enter choice [$defaultChoice]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = $defaultChoice }

    switch ($choice.ToUpper()) {
        '1' {
            if ($HyperVReady -and $ISOFound) {
                $scriptPath = Join-Path $InstallPath "templates\New-DevBoxTemplate.ps1"
                if (Test-Path $scriptPath) {
                    Set-Location $InstallPath
                    & $scriptPath
                } else {
                    Show-Message "New-DevBoxTemplate.ps1 not found!" -Level Error
                }
            } else {
                Show-Message "Hyper-V and ISO required for template creation" -Level Warning
            }
        }
        '2' {
            $scriptPath = Join-Path $InstallPath "Install-DevBox.ps1"
            if (Test-Path $scriptPath) {
                Set-Location $InstallPath
                & $scriptPath
            } else {
                Show-Message "Install-DevBox.ps1 not found!" -Level Error
            }
        }
        '3' {
            if (-not $HyperVReady) {
                $result = Enable-HyperVFeature
                if ($result.Success) {
                    if ($result.RebootRequired) {
                        Show-Message "Hyper-V enabled! Please REBOOT and run '.\devbox template'" -Level Success
                    } else {
                        Show-Message "Hyper-V enabled successfully!" -Level Success
                    }
                } else {
                    Show-Message "Failed to enable Hyper-V: $($result.Error)" -Level Error
                }
            }
        }
        '4' {
            explorer.exe $InstallPath
            Show-Message "Opened folder: $InstallPath" -Level Success
        }
        '5' {
            $scriptPath = Join-Path $InstallPath "utils\Test-DevBoxHealth.ps1"
            if (Test-Path $scriptPath) {
                Set-Location $InstallPath
                & $scriptPath
            } else {
                Show-Message "Test-DevBoxHealth.ps1 not found!" -Level Error
            }
        }
        'Q' {
            Write-Host ""
            Show-Message "Bootstrap complete. Run scripts from: $InstallPath" -Level Info
        }
        default {
            Write-Host ""
            Show-Message "Invalid choice. Exiting." -Level Warning
        }
    }
}

#endregion

#region Main

function Main {
    Show-Banner

    # Check for existing installation and updates
    $existingPath = Find-ExistingInstallation
    if ($existingPath) {
        Show-Message "Found existing installation: $existingPath" -Level Info
        $updateCheck = Test-ForUpdates -ExistingInstallPath $existingPath

        if ($updateCheck.UpdateAvailable -and $updateCheck.UpdateNow) {
            # User wants to update - proceed with download to existing path
            Show-Message "Updating installation at: $existingPath" -Level Header
            $installPath = $existingPath
        } elseif ($updateCheck.UpdateAvailable -and -not $updateCheck.UpdateNow) {
            # User skipped update - show post-bootstrap menu for existing install
            Show-NextSteps -InstallPath $existingPath
            $hypervChecks = Test-HyperVPrerequisites
            $isoCheck = Test-ISOAvailability -BasePath $existingPath
            $hypervReady = ($hypervChecks | Where-Object { $_.Name -eq "Hyper-V Feature" }).Passed
            $isoFound = $isoCheck.Passed
            Show-PostBootstrapMenu -InstallPath $existingPath -HyperVReady $hypervReady -ISOFound $isoFound
            return
        } else {
            # Already up to date - show post-bootstrap menu
            Show-NextSteps -InstallPath $existingPath
            $hypervChecks = Test-HyperVPrerequisites
            $isoCheck = Test-ISOAvailability -BasePath $existingPath
            $hypervReady = ($hypervChecks | Where-Object { $_.Name -eq "Hyper-V Feature" }).Passed
            $isoFound = $isoCheck.Passed
            Show-PostBootstrapMenu -InstallPath $existingPath -HyperVReady $hypervReady -ISOFound $isoFound
            return
        }
    }

    # Prerequisites check (critical)
    $checks = Test-Prerequisites
    $result = Show-PrerequisiteResults -Checks $checks -Title "CORE PREREQUISITES"

    if ($result.CriticalFailed) {
        $failedChecks = $checks | Where-Object { -not $_.Passed -and $_.Critical }

        foreach ($check in $failedChecks) {
            switch ($check.Name) {
                "Windows 11 22H2+ or Server 2025" {
                    Show-ErrorWithRemediation -ErrorCode "WIN11_REQUIRED" `
                        -Message "Windows 11 22H2+ or Windows Server 2025 is required." `
                        -Steps @(
                            "Update Windows to version 22H2 or later",
                            "Go to Settings > Windows Update > Check for updates",
                            "Install all available updates and restart"
                        )
                }
                "Administrator privileges" {
                    Show-ErrorWithRemediation -ErrorCode "ADMIN_REQUIRED" `
                        -Message "This script must be run as Administrator." `
                        -Steps @(
                            "Right-click PowerShell and select 'Run as Administrator'",
                            "Or run: Start-Process powershell -Verb RunAs",
                            "Then run the bootstrap command again"
                        )
                }
                "Network connectivity" {
                    Show-ErrorWithRemediation -ErrorCode "NETWORK_REQUIRED" `
                        -Message "Cannot connect to GitHub to download files." `
                        -Steps @(
                            "Check your internet connection",
                            "Ensure firewall allows HTTPS (port 443)",
                            "Try opening https://github.com in a browser",
                            "If using a proxy, configure system proxy settings"
                        )
                }
            }
        }

        Write-Host ""
        Write-Host "  Bootstrap cannot continue. Please fix the issues above." -ForegroundColor Red
        Write-Host ""
        return
    }

    # Get installation directory (skip if updating existing installation)
    if (-not $installPath) {
        $installPath = Get-InstallationDirectory
    }

    # Download files
    $downloadResults = Download-DevBoxFiles -DestinationPath $installPath
    Show-DownloadSummary -Results $downloadResults -InstallPath $installPath

    # Check for critical failures
    if ($downloadResults.Failed.Count -gt 0) {
        Write-Host ""
        Show-ErrorWithRemediation -ErrorCode "DOWNLOAD_FAILED" `
            -Message "Some required files failed to download." `
            -Steps @(
                "Check your internet connection",
                "Try running the bootstrap again",
                "If problem persists, download manually from:",
                "https://github.com/velocityeu/devbox-factory"
            )
        return
    }

    # Check Hyper-V prerequisites (non-blocking)
    Write-Host ""
    Write-Host "  Checking VM creation prerequisites..." -ForegroundColor Cyan
    $hypervChecks = Test-HyperVPrerequisites
    $isoCheck = Test-ISOAvailability -BasePath $installPath
    Show-HyperVPrerequisiteResults -Checks $hypervChecks -ISOCheck $isoCheck

    # Determine readiness
    $hypervReady = ($hypervChecks | Where-Object { $_.Name -eq "Hyper-V Feature" }).Passed
    $isoFound = $isoCheck.Passed

    # Show status summary
    if ($hypervReady -and $isoFound) {
        Write-Host "  [+] System ready for VM template creation!" -ForegroundColor Green
    } elseif (-not $hypervReady) {
        Write-Host "  [!] Hyper-V not enabled - enable it to create VM templates" -ForegroundColor Yellow
    }
    if (-not $isoFound) {
        Write-Host "  [!] No ISO found - place Windows ISO in: $installPath\iso\" -ForegroundColor Yellow
    }

    # Success - show next steps
    Show-NextSteps -InstallPath $installPath
    Show-PostBootstrapMenu -InstallPath $installPath -HyperVReady $hypervReady -ISOFound $isoFound
}

# Run bootstrap
Main
