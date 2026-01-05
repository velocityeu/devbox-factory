<#
.SYNOPSIS
    Download helper functions with progress indicators for DevBox Factory

.DESCRIPTION
    Provides reusable functions for downloading files with visual progress:
    - Show-DownloadProgress: Percentage bar for known sizes
    - Show-DownloadSpinner: Animated spinner for unknown sizes
    - Start-DownloadWithProgress: Unified download with automatic progress selection
    - Test-FileChecksum: SHA256 verification
    - Get-DependencyManifest: Load and parse manifest.json
    - Get-DependencyStatus: Check download/verification status
    - Install-FromDependency: Install from local file with WinGet fallback

.NOTES
    DevBox Factory v3.0.2
    Requires PowerShell 5.1+
#>

#Requires -Version 5.1

# Progress bar characters (Unicode blocks)
$Script:ProgressChars = @{
    Filled = [char]0x2588  # Full block
    Empty  = [char]0x2591  # Light shade
}

# Spinner animation frames
$Script:SpinnerFrames = @('|', '/', '-', '\')
$Script:SpinnerIndex = 0

# State for progress tracking
$Script:LastProgressUpdate = [DateTime]::MinValue
$Script:ProgressUpdateInterval = 100  # milliseconds

function Show-DownloadProgress {
    <#
    .SYNOPSIS
        Displays a progress bar with percentage and byte counts
    .EXAMPLE
        Show-DownloadProgress -Activity "Downloading Git" -PercentComplete 67 -BytesReceived 45000000 -TotalBytes 67000000
        # Output: [████████░░░░]  67% (45MB/67MB) - Downloading Git...
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Activity,

        [Parameter(Mandatory)]
        [int]$PercentComplete,

        [Parameter(Mandatory)]
        [long]$BytesReceived,

        [Parameter(Mandatory)]
        [long]$TotalBytes,

        [int]$BarWidth = 12
    )

    # Clamp percentage
    $percent = [Math]::Max(0, [Math]::Min(100, $PercentComplete))

    $filledCount = [Math]::Floor($BarWidth * ($percent / 100))
    $emptyCount = $BarWidth - $filledCount

    $filled = $Script:ProgressChars.Filled * $filledCount
    $empty = $Script:ProgressChars.Empty * $emptyCount

    # Format bytes as MB
    $receivedMB = [Math]::Round($BytesReceived / 1MB, 0)
    $totalMB = [Math]::Round($TotalBytes / 1MB, 0)

    # Build line with consistent width
    $percentStr = $percent.ToString().PadLeft(3)
    $line = "  [$filled$empty] $percentStr% (${receivedMB}MB/${totalMB}MB) - $Activity..."

    # Pad to overwrite previous content
    $line = $line.PadRight(80)

    Write-Host "`r$line" -NoNewline
}

function Show-DownloadSpinner {
    <#
    .SYNOPSIS
        Displays animated spinner for operations with unknown duration/size
    .EXAMPLE
        Show-DownloadSpinner -Activity "Downloading (size unknown)" -BytesReceived 15000000
        # Output:   / Downloading (size unknown)... (15MB received)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Activity,

        [long]$BytesReceived = 0
    )

    $spinner = $Script:SpinnerFrames[$Script:SpinnerIndex % 4]
    $Script:SpinnerIndex++

    # Format bytes
    $bytesStr = ""
    if ($BytesReceived -gt 0) {
        $receivedMB = [Math]::Round($BytesReceived / 1MB, 1)
        $bytesStr = " (${receivedMB}MB received)"
    }

    $line = "  $spinner $Activity...$bytesStr"
    $line = $line.PadRight(80)

    Write-Host "`r$line" -NoNewline
}

function Show-DownloadComplete {
    <#
    .SYNOPSIS
        Shows download completion message
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Activity,

        [long]$TotalBytes = 0,

        [switch]$Success,

        [string]$ErrorMessage
    )

    Write-Host ""  # New line after progress

    if ($Success) {
        $sizeStr = ""
        if ($TotalBytes -gt 0) {
            $sizeMB = [Math]::Round($TotalBytes / 1MB, 1)
            $sizeStr = " (${sizeMB}MB)"
        }
        Write-Host "  [+] $Activity completed$sizeStr" -ForegroundColor Green
    } else {
        Write-Host "  [X] $Activity failed: $ErrorMessage" -ForegroundColor Red
    }
}

function Start-DownloadWithProgress {
    <#
    .SYNOPSIS
        Downloads a file with automatic progress indicator selection
    .DESCRIPTION
        Uses percentage bar if content length is known, spinner otherwise.
        Supports resume detection and checksum verification.
    .OUTPUTS
        Hashtable with Success, Path, BytesDownloaded, Error properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [string]$DisplayName = "file",

        [long]$ExpectedSizeBytes = 0,

        [string]$ExpectedChecksum = "",

        [int]$TimeoutSeconds = 600
    )

    $result = @{
        Success         = $false
        Path            = $DestinationPath
        BytesDownloaded = 0
        Error           = $null
    }

    try {
        # Ensure destination directory exists
        $destDir = Split-Path $DestinationPath -Parent
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        # Check if file already exists and is valid
        if ((Test-Path $DestinationPath) -and $ExpectedChecksum) {
            if (Test-FileChecksum -FilePath $DestinationPath -ExpectedHash $ExpectedChecksum) {
                Write-Host "  [=] $DisplayName already downloaded and verified" -ForegroundColor DarkGray
                $result.Success = $true
                $result.BytesDownloaded = (Get-Item $DestinationPath).Length
                return $result
            }
        }

        # Try to get content length with HEAD request
        $contentLength = 0
        try {
            $headRequest = [System.Net.HttpWebRequest]::Create($Url)
            $headRequest.Method = "HEAD"
            $headRequest.Timeout = 30000
            $headRequest.UserAgent = "DevBox-Factory/3.0"
            $headRequest.AllowAutoRedirect = $true

            $headResponse = $headRequest.GetResponse()
            $contentLength = $headResponse.ContentLength
            $headResponse.Close()
        } catch {
            # HEAD failed, use expected size if available
            $contentLength = $ExpectedSizeBytes
        }

        # Use expected size as fallback
        if ($contentLength -le 0 -and $ExpectedSizeBytes -gt 0) {
            $contentLength = $ExpectedSizeBytes
        }

        $useProgressBar = $contentLength -gt 0

        # Create WebClient for download
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "DevBox-Factory/3.0")

        # Set up progress tracking
        $Script:SpinnerIndex = 0
        $Script:LastProgressUpdate = [DateTime]::Now
        $Script:DownloadDisplayName = $DisplayName
        $Script:DownloadContentLength = $contentLength
        $Script:UseProgressBar = $useProgressBar

        # Register progress event
        $progressAction = {
            $now = [DateTime]::Now
            if (($now - $Script:LastProgressUpdate).TotalMilliseconds -lt $Script:ProgressUpdateInterval) {
                return
            }
            $Script:LastProgressUpdate = $now

            if ($Script:UseProgressBar -and $EventArgs.TotalBytesToReceive -gt 0) {
                Show-DownloadProgress -Activity $Script:DownloadDisplayName `
                    -PercentComplete $EventArgs.ProgressPercentage `
                    -BytesReceived $EventArgs.BytesReceived `
                    -TotalBytes $EventArgs.TotalBytesToReceive
            } elseif ($Script:DownloadContentLength -gt 0) {
                $percent = [Math]::Floor(($EventArgs.BytesReceived / $Script:DownloadContentLength) * 100)
                Show-DownloadProgress -Activity $Script:DownloadDisplayName `
                    -PercentComplete $percent `
                    -BytesReceived $EventArgs.BytesReceived `
                    -TotalBytes $Script:DownloadContentLength
            } else {
                Show-DownloadSpinner -Activity $Script:DownloadDisplayName `
                    -BytesReceived $EventArgs.BytesReceived
            }
        }

        $eventSubscription = Register-ObjectEvent -InputObject $webClient `
            -EventName DownloadProgressChanged `
            -Action $progressAction

        # Perform download
        try {
            $webClient.DownloadFile($Url, $DestinationPath)

            if (Test-Path $DestinationPath) {
                $fileSize = (Get-Item $DestinationPath).Length
                $result.BytesDownloaded = $fileSize

                # Verify checksum if provided
                if ($ExpectedChecksum) {
                    if (Test-FileChecksum -FilePath $DestinationPath -ExpectedHash $ExpectedChecksum) {
                        $result.Success = $true
                        Show-DownloadComplete -Activity $DisplayName -TotalBytes $fileSize -Success
                    } else {
                        $result.Error = "Checksum verification failed"
                        Show-DownloadComplete -Activity $DisplayName -ErrorMessage $result.Error
                        Remove-Item $DestinationPath -Force -ErrorAction SilentlyContinue
                    }
                } elseif ($fileSize -gt 0) {
                    $result.Success = $true
                    Show-DownloadComplete -Activity $DisplayName -TotalBytes $fileSize -Success
                } else {
                    $result.Error = "Downloaded file is empty"
                    Show-DownloadComplete -Activity $DisplayName -ErrorMessage $result.Error
                }
            } else {
                $result.Error = "File not created"
                Show-DownloadComplete -Activity $DisplayName -ErrorMessage $result.Error
            }
        } finally {
            Unregister-Event -SubscriptionId $eventSubscription.Id -ErrorAction SilentlyContinue
            Remove-Job -Id $eventSubscription.Id -Force -ErrorAction SilentlyContinue
        }

    } catch {
        $result.Error = $_.Exception.Message
        Write-Host ""
        Show-DownloadComplete -Activity $DisplayName -ErrorMessage $result.Error
    } finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }

    return $result
}

function Test-FileChecksum {
    <#
    .SYNOPSIS
        Verifies file SHA256 checksum
    .OUTPUTS
        $true if checksum matches, $false otherwise
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$ExpectedHash
    )

    if (-not (Test-Path $FilePath)) {
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($ExpectedHash)) {
        return $true  # No hash to verify
    }

    try {
        $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
        return $actualHash -eq $ExpectedHash.ToUpper()
    } catch {
        return $false
    }
}

function Get-DependencyManifest {
    <#
    .SYNOPSIS
        Loads and parses the dependency manifest JSON file
    #>
    [CmdletBinding()]
    param(
        [string]$ManifestPath
    )

    # Try to find manifest in common locations
    $searchPaths = @(
        $ManifestPath,
        ".\dependencies\manifest.json",
        "$PSScriptRoot\..\dependencies\manifest.json",
        "$PSScriptRoot\dependencies\manifest.json"
    )

    foreach ($path in $searchPaths) {
        if ($path -and (Test-Path $path)) {
            try {
                $content = Get-Content $path -Raw -ErrorAction Stop
                return $content | ConvertFrom-Json
            } catch {
                Write-Warning "Failed to parse manifest at $path : $_"
            }
        }
    }

    return $null
}

function Get-DependencyStatus {
    <#
    .SYNOPSIS
        Checks status of all dependencies (downloaded, verified, missing)
    .OUTPUTS
        Array of dependency status objects
    #>
    [CmdletBinding()]
    param(
        [string]$DependenciesPath = ".\dependencies",
        [string]$ManifestPath
    )

    if (-not $ManifestPath) {
        $ManifestPath = Join-Path $DependenciesPath "manifest.json"
    }

    $manifest = Get-DependencyManifest -ManifestPath $ManifestPath
    if (-not $manifest) {
        Write-Warning "No dependency manifest found"
        return @()
    }

    $status = @()

    foreach ($dep in $manifest.dependencies.PSObject.Properties) {
        $info = $dep.Value
        $filePath = Join-Path $DependenciesPath $info.fileName

        $statusItem = [PSCustomObject]@{
            Id           = $dep.Name
            DisplayName  = $info.displayName
            Version      = $info.version
            FileName     = $info.fileName
            FilePath     = $filePath
            ExpectedSize = $info.expectedSizeBytes
            Checksum     = $info.checksumSha256
            WinGetId     = $info.wingetId
            ChocoId      = $info.chocoId
            Required     = $info.required
            Category     = $info.category
            Status       = "missing"
            ActualSize   = 0
        }

        if ($info.fileName -and (Test-Path $filePath)) {
            $actualSize = (Get-Item $filePath).Length
            $statusItem.ActualSize = $actualSize

            if ($info.checksumSha256 -and (Test-FileChecksum -FilePath $filePath -ExpectedHash $info.checksumSha256)) {
                $statusItem.Status = "verified"
            } elseif (-not $info.checksumSha256 -and $actualSize -gt 0) {
                $statusItem.Status = "downloaded"
            } elseif ($info.expectedSizeBytes -gt 0 -and $actualSize -ge ($info.expectedSizeBytes * 0.9)) {
                # Within 10% of expected size, probably OK
                $statusItem.Status = "downloaded"
            } else {
                $statusItem.Status = "corrupt"
            }
        } elseif (-not $info.fileName) {
            $statusItem.Status = "winget-only"
        }

        $status += $statusItem
    }

    return $status
}

function Install-FromDependency {
    <#
    .SYNOPSIS
        Installs a tool from pre-downloaded dependency or falls back to WinGet
    .OUTPUTS
        $true if installation succeeded, $false otherwise
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DependencyId,

        [string]$DependenciesPath = ".\dependencies",

        [string]$ManifestPath,

        [switch]$Force
    )

    if (-not $ManifestPath) {
        $ManifestPath = Join-Path $DependenciesPath "manifest.json"
    }

    $manifest = Get-DependencyManifest -ManifestPath $ManifestPath
    if (-not $manifest) {
        Write-Host "  [!] No dependency manifest found" -ForegroundColor Yellow
        return $false
    }

    $dep = $manifest.dependencies.$DependencyId
    if (-not $dep) {
        Write-Host "  [!] Dependency '$DependencyId' not found in manifest" -ForegroundColor Yellow
        return $false
    }

    # Check for local file first
    if ($dep.fileName) {
        $localPath = Join-Path $DependenciesPath $dep.fileName

        if ((Test-Path $localPath) -and -not $Force) {
            # Verify checksum if available
            $isValid = $true
            if ($dep.checksumSha256) {
                $isValid = Test-FileChecksum -FilePath $localPath -ExpectedHash $dep.checksumSha256
            }

            if ($isValid) {
                Write-Host "  [*] Installing $($dep.displayName) from local cache..." -ForegroundColor Cyan

                try {
                    $installArgs = $dep.installArgs
                    if ($localPath -match '\.msi$') {
                        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$localPath`" $installArgs" -Wait -PassThru -NoNewWindow
                    } else {
                        $process = Start-Process -FilePath $localPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
                    }

                    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                        Write-Host "  [+] $($dep.displayName) installed successfully (offline)" -ForegroundColor Green
                        return $true
                    } else {
                        Write-Host "  [!] Installation returned exit code: $($process.ExitCode)" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "  [!] Local installation failed: $_" -ForegroundColor Yellow
                }
            }
        }
    }

    # Fallback to WinGet
    if ($dep.wingetId) {
        Write-Host "  [*] Installing $($dep.displayName) via WinGet..." -ForegroundColor Cyan

        try {
            $wingetArgs = @(
                "install",
                "--id", $dep.wingetId,
                "--exact",
                "--accept-source-agreements",
                "--accept-package-agreements",
                "--silent"
            )

            $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "NUL"

            if ($process.ExitCode -eq 0) {
                Write-Host "  [+] $($dep.displayName) installed via WinGet" -ForegroundColor Green
                return $true
            }
        } catch {
            Write-Host "  [!] WinGet installation failed: $_" -ForegroundColor Yellow
        }
    }

    # Fallback to Chocolatey
    if ($dep.chocoId) {
        Write-Host "  [*] Trying Chocolatey for $($dep.displayName)..." -ForegroundColor Cyan

        try {
            $chocoProcess = Start-Process -FilePath "choco" -ArgumentList "install", $dep.chocoId, "-y", "--no-progress" -Wait -PassThru -NoNewWindow

            if ($chocoProcess.ExitCode -eq 0) {
                Write-Host "  [+] $($dep.displayName) installed via Chocolatey" -ForegroundColor Green
                return $true
            }
        } catch {
            # Chocolatey not available
        }
    }

    Write-Host "  [X] Failed to install $($dep.displayName)" -ForegroundColor Red
    return $false
}

# Export module members
Export-ModuleMember -Function @(
    'Show-DownloadProgress',
    'Show-DownloadSpinner',
    'Show-DownloadComplete',
    'Start-DownloadWithProgress',
    'Test-FileChecksum',
    'Get-DependencyManifest',
    'Get-DependencyStatus',
    'Install-FromDependency'
)
