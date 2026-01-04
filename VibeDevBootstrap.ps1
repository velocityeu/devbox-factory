<#
.SYNOPSIS
    VibeDev Bootstrap - Downloads and sets up VibeDev scripts on vanilla Windows 11

.DESCRIPTION
    Self-contained bootstrapper that:
    1. Verifies Windows 11 22H2+ and administrator privileges
    2. Checks network connectivity to GitHub
    3. Prompts for installation directory
    4. Downloads all VibeDev scripts from GitHub
    5. Validates downloads
    6. Optionally runs Install-VibeDev.ps1

.EXAMPLE
    irm https://raw.githubusercontent.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra/main/VibeDevBootstrap.ps1 | iex

.NOTES
    Version: 2.0.0
    Build: 2026-01-04
    Author: VibeDev Team
#>

#Requires -Version 5.1

$Script:VibeDevVersion = @{
    Major       = 2
    Minor       = 0
    Patch       = 0
    BuildDate   = "2026-01-04"
    BuildNumber = "20260104.001"
}

$Script:GitHubBaseUrl = "https://raw.githubusercontent.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra/main"
$Script:RequiredFiles = @(
    @{ Path = "Install-VibeDev.ps1"; Required = $true },
    @{ Path = "README.md"; Required = $false },
    @{ Path = "HyperV/New-VibeDevTemplate.ps1"; Required = $true },
    @{ Path = "HyperV/New-VibeDevVM.ps1"; Required = $true },
    @{ Path = "HyperV/SetupComplete.ps1"; Required = $true },
    @{ Path = "HyperV/autounattend.xml"; Required = $true },
    @{ Path = "HyperV/Presets.json"; Required = $true },
    @{ Path = "HyperV/README.md"; Required = $false }
)

#region Banner and UI

function Get-VersionString {
    return "v$($Script:VibeDevVersion.Major).$($Script:VibeDevVersion.Minor).$($Script:VibeDevVersion.Patch)"
}

function Show-Banner {
    Clear-Host
    $version = Get-VersionString
    $build = $Script:VibeDevVersion.BuildDate

    Write-Host ""
    Write-Host "  +===============================================================+" -ForegroundColor Magenta
    Write-Host "  |                                                               |" -ForegroundColor Magenta
    Write-Host "  |   ██╗   ██╗██╗██████╗ ███████╗    ██████╗ ███████╗██╗   ██╗   |" -ForegroundColor Magenta
    Write-Host "  |   ██║   ██║██║██╔══██╗██╔════╝    ██╔══██╗██╔════╝██║   ██║   |" -ForegroundColor Magenta
    Write-Host "  |   ██║   ██║██║██████╔╝█████╗      ██║  ██║█████╗  ██║   ██║   |" -ForegroundColor Magenta
    Write-Host "  |   ╚██╗ ██╔╝██║██╔══██╗██╔══╝      ██║  ██║██╔══╝  ╚██╗ ██╔╝   |" -ForegroundColor Magenta
    Write-Host "  |    ╚████╔╝ ██║██████╔╝███████╗    ██████╔╝███████╗ ╚████╔╝    |" -ForegroundColor Magenta
    Write-Host "  |     ╚═══╝  ╚═╝╚═════╝ ╚══════╝    ╚═════╝ ╚══════╝  ╚═══╝     |" -ForegroundColor Magenta
    Write-Host "  |                                                               |" -ForegroundColor Magenta
    Write-Host "  +===============================================================+" -ForegroundColor Magenta
    Write-Host "  |              BOOTSTRAP INSTALLER                              |" -ForegroundColor Cyan
    Write-Host "  |                                                               |" -ForegroundColor Cyan
    Write-Host "  |   Version: $version                        Build: $build   |" -ForegroundColor Cyan
    Write-Host "  +===============================================================+" -ForegroundColor Magenta
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

#region Prerequisites

function Test-Prerequisites {
    $checks = @()

    # Check Windows version
    Show-Message "Checking Windows version..." -Level Header
    $os = Get-CimInstance Win32_OperatingSystem
    $buildNumber = [int]$os.BuildNumber
    $isWin11 = $buildNumber -ge 22000
    $is22H2Plus = $buildNumber -ge 22621

    $checks += @{
        Name = "Windows 11 22H2+"
        Passed = $is22H2Plus
        Message = if ($is22H2Plus) {
            "Windows 11 Build $buildNumber"
        } elseif ($isWin11) {
            "Windows 11 Build $buildNumber - needs 22H2+ (22621+)"
        } else {
            "Windows $buildNumber - requires Windows 11"
        }
    }

    # Check admin privileges
    Show-Message "Checking administrator privileges..." -Level Header
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $checks += @{
        Name = "Administrator privileges"
        Passed = $isAdmin
        Message = if ($isAdmin) { "Running as Administrator" } else { "Not running as Administrator" }
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
    }

    return $checks
}

function Show-PrerequisiteResults {
    param([array]$Checks)

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                 PREREQUISITES CHECK                        |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $allPassed = $true
    foreach ($check in $Checks) {
        $icon = if ($check.Passed) { "[+]" } else { "[X]" }
        $color = if ($check.Passed) { "Green" } else { "Red" }
        Write-Host "  $icon $($check.Name)" -ForegroundColor $color
        Write-Host "      $($check.Message)" -ForegroundColor Gray

        if (-not $check.Passed) { $allPassed = $false }
    }

    Write-Host ""
    return $allPassed
}

#endregion

#region Directory Selection

function Get-InstallationDirectory {
    $defaultPath = "C:\VibeDev"

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
            $dialog.Description = "Select VibeDev installation folder"
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

function Download-VibeDevFiles {
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
            $webClient.Headers.Add("User-Agent", "VibeDev-Bootstrap/2.0")
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
    param([string]$InstallPath)

    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Green
    Write-Host "  |              BOOTSTRAP COMPLETE                            |" -ForegroundColor Green
    Write-Host "  +===========================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  All VibeDev scripts have been downloaded successfully!" -ForegroundColor White
    Write-Host ""
    Write-Host "  Next Steps:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Install VibeDev tools on this PC:" -ForegroundColor White
    Write-Host "     cd `"$InstallPath`"" -ForegroundColor Yellow
    Write-Host "     .\Install-VibeDev.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2. Create Hyper-V template (requires Hyper-V host):" -ForegroundColor White
    Write-Host "     .\HyperV\New-VibeDevTemplate.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  3. Create development VMs from template:" -ForegroundColor White
    Write-Host "     .\HyperV\New-VibeDevVM.ps1" -ForegroundColor Yellow
    Write-Host ""
}

function Show-PostBootstrapMenu {
    param([string]$InstallPath)

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                   WHAT NEXT?                               |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] Run Install-VibeDev.ps1 now" -ForegroundColor White
    Write-Host "       Install development tools on this PC (Recommended)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] Open installation folder" -ForegroundColor White
    Write-Host "       View downloaded scripts in Explorer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] Exit" -ForegroundColor White
    Write-Host "       Run scripts manually later" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter choice [1]"

    switch ($choice) {
        '' {
            $scriptPath = Join-Path $InstallPath "Install-VibeDev.ps1"
            if (Test-Path $scriptPath) {
                Set-Location $InstallPath
                & $scriptPath
            } else {
                Show-Message "Install-VibeDev.ps1 not found!" -Level Error
            }
        }
        '1' {
            $scriptPath = Join-Path $InstallPath "Install-VibeDev.ps1"
            if (Test-Path $scriptPath) {
                Set-Location $InstallPath
                & $scriptPath
            } else {
                Show-Message "Install-VibeDev.ps1 not found!" -Level Error
            }
        }
        '2' {
            explorer.exe $InstallPath
            Show-Message "Opened folder: $InstallPath" -Level Success
        }
        '3' {
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

    # Prerequisites check
    $checks = Test-Prerequisites
    $allPassed = Show-PrerequisiteResults -Checks $checks

    if (-not $allPassed) {
        $failedChecks = $checks | Where-Object { -not $_.Passed }

        foreach ($check in $failedChecks) {
            switch ($check.Name) {
                "Windows 11 22H2+" {
                    Show-ErrorWithRemediation -ErrorCode "WIN11_REQUIRED" `
                        -Message "Windows 11 version 22H2 or later is required." `
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

    # Get installation directory
    $installPath = Get-InstallationDirectory

    # Download files
    $downloadResults = Download-VibeDevFiles -DestinationPath $installPath
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
                "https://github.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra"
            )
        return
    }

    # Success - show next steps
    Show-NextSteps -InstallPath $installPath
    Show-PostBootstrapMenu -InstallPath $installPath
}

# Run bootstrap
Main
