<#
.SYNOPSIS
    Downloads DevBox Factory dependencies for offline installation

.DESCRIPTION
    Pre-downloads all or selected dependencies to the dependencies/ folder
    for offline installation capability. Downloads include progress indicators
    and checksum verification.

.PARAMETER All
    Download all dependencies defined in manifest.json

.PARAMETER Category
    Download dependencies from specific categories (core, runtime, vm-tools, containers, cloud)

.PARAMETER Dependencies
    Download specific dependencies by ID (git, vscode, nodejs-lts, etc.)

.PARAMETER Profile
    Download dependencies for a specific installation profile (Full, AICoder, WebDev, Azure, Minimal)

.PARAMETER Status
    Show status of all dependencies (downloaded, verified, missing)

.PARAMETER Force
    Re-download even if files already exist

.PARAMETER Clean
    Remove all downloaded dependencies

.EXAMPLE
    .\Download-Dependencies.ps1 -All
    # Downloads all dependencies (~1.5 GB)

.EXAMPLE
    .\Download-Dependencies.ps1 -Category core,runtime
    # Downloads core tools and runtimes

.EXAMPLE
    .\Download-Dependencies.ps1 -Dependencies git,vscode,nodejs-lts
    # Downloads specific dependencies

.EXAMPLE
    .\Download-Dependencies.ps1 -Profile AICoder
    # Downloads dependencies for AI Coder profile

.EXAMPLE
    .\Download-Dependencies.ps1 -Status
    # Shows download status of all dependencies

.NOTES
    DevBox Factory v3.0.2
    https://github.com/velocityeu/devbox-factory
#>

[CmdletBinding(DefaultParameterSetName = 'Status')]
param(
    [Parameter(ParameterSetName = 'All')]
    [switch]$All,

    [Parameter(ParameterSetName = 'Category')]
    [ValidateSet('core', 'runtime', 'vm-tools', 'containers', 'cloud')]
    [string[]]$Category,

    [Parameter(ParameterSetName = 'Dependencies')]
    [string[]]$Dependencies,

    [Parameter(ParameterSetName = 'Profile')]
    [ValidateSet('Full', 'AICoder', 'WebDev', 'Azure', 'Minimal')]
    [string]$Profile,

    [Parameter(ParameterSetName = 'Status')]
    [switch]$Status,

    [switch]$Force,

    [switch]$Clean
)

$Script:Version = "3.0.2"
$Script:Build = "20260105.0300"
$Script:DependenciesPath = Join-Path $PSScriptRoot "dependencies"
$Script:ManifestPath = Join-Path $Script:DependenciesPath "manifest.json"
$Script:ModulesPath = Join-Path $PSScriptRoot "modules"

# Import logger module if available
$loggerModule = Join-Path $Script:ModulesPath "DevBoxLogger.psm1"
if (Test-Path $loggerModule) {
    try {
        Import-Module $loggerModule -Force -ErrorAction Stop
        $Script:Paths = Initialize-DevBoxPaths -ScriptRoot $PSScriptRoot -LogPrefix "deps"
    } catch {
        # Continue without centralized logging
    }
}

# Import download helpers
$helperModule = Join-Path $Script:ModulesPath "DownloadHelpers.psm1"
if (Test-Path $helperModule) {
    Import-Module $helperModule -Force
} else {
    Write-Host "  [X] DownloadHelpers.psm1 not found at: $helperModule" -ForegroundColor Red
    exit 1
}

function Show-Banner {
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
    Write-Host "  |  DEPENDENCY DOWNLOADER       Pre-download for offline installation  |" -ForegroundColor White
    Write-Host "  |  by Velocity EU                                         v$Script:Version  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-DependencyStatus {
    Write-Host "  DEPENDENCY STATUS" -ForegroundColor Cyan
    Write-Host "  =================" -ForegroundColor DarkGray
    Write-Host ""

    $status = Get-DependencyStatus -DependenciesPath $Script:DependenciesPath -ManifestPath $Script:ManifestPath

    if ($status.Count -eq 0) {
        Write-Host "  No dependencies found in manifest" -ForegroundColor Yellow
        return
    }

    # Group by category
    $categories = $status | Group-Object -Property Category

    foreach ($cat in $categories | Sort-Object { $_.Name }) {
        $catName = switch ($cat.Name) {
            "core" { "Core Tools" }
            "runtime" { "Runtimes & SDKs" }
            "vm-tools" { "VM Creation Tools" }
            "containers" { "Containerization" }
            "cloud" { "Cloud Tools" }
            default { $cat.Name }
        }

        Write-Host "  $catName" -ForegroundColor Yellow
        Write-Host "  $('-' * $catName.Length)" -ForegroundColor DarkGray

        foreach ($dep in $cat.Group | Sort-Object { $_.DisplayName }) {
            $icon = switch ($dep.Status) {
                "verified"    { "[+]"; $color = "Green" }
                "downloaded"  { "[+]"; $color = "Green" }
                "corrupt"     { "[!]"; $color = "Yellow" }
                "missing"     { "[-]"; $color = "DarkGray" }
                "winget-only" { "[~]"; $color = "Cyan" }
                default       { "[?]"; $color = "Gray" }
            }

            $sizeStr = ""
            if ($dep.ActualSize -gt 0) {
                $sizeMB = [Math]::Round($dep.ActualSize / 1MB, 1)
                $sizeStr = " (${sizeMB}MB)"
            } elseif ($dep.ExpectedSize -gt 0) {
                $sizeMB = [Math]::Round($dep.ExpectedSize / 1MB, 1)
                $sizeStr = " (~${sizeMB}MB)"
            }

            Write-Host "    $icon " -ForegroundColor $color -NoNewline
            Write-Host "$($dep.DisplayName)$sizeStr" -ForegroundColor White -NoNewline
            Write-Host " - $($dep.Status)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    # Summary
    $verified = ($status | Where-Object { $_.Status -eq "verified" }).Count
    $downloaded = ($status | Where-Object { $_.Status -eq "downloaded" }).Count
    $missing = ($status | Where-Object { $_.Status -eq "missing" }).Count
    $corrupt = ($status | Where-Object { $_.Status -eq "corrupt" }).Count
    $wingetOnly = ($status | Where-Object { $_.Status -eq "winget-only" }).Count

    Write-Host "  SUMMARY" -ForegroundColor Cyan
    Write-Host "  -------" -ForegroundColor DarkGray
    Write-Host "    Verified:    $verified" -ForegroundColor Green
    Write-Host "    Downloaded:  $downloaded" -ForegroundColor Green
    Write-Host "    Missing:     $missing" -ForegroundColor $(if ($missing -gt 0) { "Yellow" } else { "DarkGray" })
    Write-Host "    Corrupt:     $corrupt" -ForegroundColor $(if ($corrupt -gt 0) { "Red" } else { "DarkGray" })
    Write-Host "    WinGet-only: $wingetOnly" -ForegroundColor Cyan
    Write-Host ""
}

function Get-DependenciesToDownload {
    param(
        [string[]]$CategoryFilter,
        [string[]]$DependencyIds,
        [string]$ProfileName
    )

    $manifest = Get-DependencyManifest -ManifestPath $Script:ManifestPath
    if (-not $manifest) {
        Write-Host "  [X] Could not load manifest.json" -ForegroundColor Red
        return @()
    }

    $toDownload = @()

    foreach ($dep in $manifest.dependencies.PSObject.Properties) {
        $info = $dep.Value

        # Skip if no downloadable file
        if (-not $info.fileName -or -not $info.downloadUrl) {
            continue
        }

        $include = $false

        # Filter by category
        if ($CategoryFilter -and $info.category -in $CategoryFilter) {
            $include = $true
        }

        # Filter by dependency ID
        if ($DependencyIds -and $dep.Name -in $DependencyIds) {
            $include = $true
        }

        # Filter by profile
        if ($ProfileName -and $manifest.profiles.$ProfileName) {
            if ($dep.Name -in $manifest.profiles.$ProfileName.dependencies) {
                $include = $true
            }
        }

        # Include all if no filters
        if (-not $CategoryFilter -and -not $DependencyIds -and -not $ProfileName) {
            $include = $true
        }

        if ($include) {
            $toDownload += [PSCustomObject]@{
                Id           = $dep.Name
                DisplayName  = $info.displayName
                Url          = $info.downloadUrl
                FileName     = $info.fileName
                ExpectedSize = $info.expectedSizeBytes
                Checksum     = $info.checksumSha256
                Category     = $info.category
            }
        }
    }

    return $toDownload
}

function Start-DependencyDownloads {
    param(
        [array]$Dependencies
    )

    if ($Dependencies.Count -eq 0) {
        Write-Host "  No dependencies to download" -ForegroundColor Yellow
        return
    }

    Write-Host "  DOWNLOADING DEPENDENCIES" -ForegroundColor Cyan
    Write-Host "  ========================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Dependencies to download: $($Dependencies.Count)" -ForegroundColor White

    # Calculate total size
    $totalSize = ($Dependencies | Measure-Object -Property ExpectedSize -Sum).Sum
    if ($totalSize -gt 0) {
        $totalMB = [Math]::Round($totalSize / 1MB, 0)
        Write-Host "  Estimated total size: ${totalMB}MB" -ForegroundColor White
    }
    Write-Host ""

    $successCount = 0
    $failCount = 0

    foreach ($dep in $Dependencies) {
        $destPath = Join-Path $Script:DependenciesPath $dep.FileName

        # Check if already exists
        if ((Test-Path $destPath) -and -not $Force) {
            if ($dep.Checksum) {
                if (Test-FileChecksum -FilePath $destPath -ExpectedHash $dep.Checksum) {
                    Write-Host "  [=] $($dep.DisplayName) already downloaded and verified" -ForegroundColor DarkGray
                    $successCount++
                    continue
                }
            } else {
                $existingSize = (Get-Item $destPath).Length
                if ($existingSize -gt 0) {
                    Write-Host "  [=] $($dep.DisplayName) already downloaded" -ForegroundColor DarkGray
                    $successCount++
                    continue
                }
            }
        }

        # Download
        $result = Start-DownloadWithProgress -Url $dep.Url `
            -DestinationPath $destPath `
            -DisplayName $dep.DisplayName `
            -ExpectedSizeBytes $dep.ExpectedSize `
            -ExpectedChecksum $dep.Checksum

        if ($result.Success) {
            $successCount++
        } else {
            $failCount++
        }
    }

    # Summary
    Write-Host ""
    Write-Host "  DOWNLOAD SUMMARY" -ForegroundColor Cyan
    Write-Host "  ----------------" -ForegroundColor DarkGray
    Write-Host "    Successful: $successCount" -ForegroundColor Green
    Write-Host "    Failed:     $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "DarkGray" })
    Write-Host ""
}

function Remove-AllDependencies {
    Write-Host "  CLEANING DEPENDENCIES" -ForegroundColor Cyan
    Write-Host "  =====================" -ForegroundColor DarkGray
    Write-Host ""

    $files = Get-ChildItem -Path $Script:DependenciesPath -Include "*.exe", "*.msi", "*.zip" -File -ErrorAction SilentlyContinue

    if ($files.Count -eq 0) {
        Write-Host "  No downloaded files to remove" -ForegroundColor DarkGray
        return
    }

    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    $totalMB = [Math]::Round($totalSize / 1MB, 1)

    Write-Host "  Files to remove: $($files.Count) (${totalMB}MB)" -ForegroundColor White
    Write-Host ""

    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force
            Write-Host "  [+] Removed: $($file.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  [X] Failed to remove: $($file.Name)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "  Cleanup complete" -ForegroundColor Green
    Write-Host ""
}

# Main execution
Show-Banner

# Handle Clean first
if ($Clean) {
    Remove-AllDependencies
    exit 0
}

# Ensure dependencies folder exists
if (-not (Test-Path $Script:DependenciesPath)) {
    New-Item -ItemType Directory -Path $Script:DependenciesPath -Force | Out-Null
}

# Handle Status
if ($Status -or $PSCmdlet.ParameterSetName -eq 'Status') {
    Show-DependencyStatus
    exit 0
}

# Get dependencies to download based on parameters
$toDownload = @()

if ($All) {
    $toDownload = Get-DependenciesToDownload
} elseif ($Category) {
    $toDownload = Get-DependenciesToDownload -CategoryFilter $Category
} elseif ($Dependencies) {
    $toDownload = Get-DependenciesToDownload -DependencyIds $Dependencies
} elseif ($Profile) {
    $toDownload = Get-DependenciesToDownload -ProfileName $Profile
}

if ($toDownload.Count -gt 0) {
    Start-DependencyDownloads -Dependencies $toDownload
} else {
    Write-Host "  No dependencies matched the specified criteria" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Usage examples:" -ForegroundColor Cyan
    Write-Host "    .\Download-Dependencies.ps1 -All" -ForegroundColor White
    Write-Host "    .\Download-Dependencies.ps1 -Category core,runtime" -ForegroundColor White
    Write-Host "    .\Download-Dependencies.ps1 -Dependencies git,vscode" -ForegroundColor White
    Write-Host "    .\Download-Dependencies.ps1 -Profile AICoder" -ForegroundColor White
    Write-Host "    .\Download-Dependencies.ps1 -Status" -ForegroundColor White
    Write-Host ""
}
