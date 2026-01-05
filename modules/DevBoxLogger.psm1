<#
.SYNOPSIS
    DevBox Factory centralized logging module

.DESCRIPTION
    Provides consistent logging functionality across all DevBox Factory scripts.
    Creates timestamped log files in the log/ folder.

.NOTES
    DevBox Factory v3.1.1
#>

# Module-level variables
$Script:LogFolder = $null
$Script:TempFolder = $null
$Script:CurrentLogFile = $null
$Script:LogPrefix = "devbox"

function Initialize-DevBoxPaths {
    <#
    .SYNOPSIS
        Initialize the log and temp folder paths
    #>
    param(
        [string]$ScriptRoot,
        [string]$LogPrefix = "devbox"
    )

    # Find project root (parent of modules folder)
    if ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = $PSScriptRoot
    }

    # Navigate to project root
    $projectRoot = Split-Path $ScriptRoot -Parent
    if ($ScriptRoot -match "modules$") {
        $projectRoot = Split-Path $ScriptRoot -Parent
    } elseif ($ScriptRoot -match "(templates|vms|utils)$") {
        $projectRoot = Split-Path $ScriptRoot -Parent
    } else {
        $projectRoot = $ScriptRoot
    }

    $Script:LogFolder = Join-Path $projectRoot "log"
    $Script:TempFolder = Join-Path $projectRoot "temp"
    $Script:LogPrefix = $LogPrefix

    # Ensure folders exist
    if (-not (Test-Path $Script:LogFolder)) {
        New-Item -Path $Script:LogFolder -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $Script:TempFolder)) {
        New-Item -Path $Script:TempFolder -ItemType Directory -Force | Out-Null
    }

    # Create log file for this session
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Script:CurrentLogFile = Join-Path $Script:LogFolder "$LogPrefix-$timestamp.log"

    return @{
        LogFolder = $Script:LogFolder
        TempFolder = $Script:TempFolder
        LogFile = $Script:CurrentLogFile
    }
}

function Get-DevBoxLogFolder {
    <#
    .SYNOPSIS
        Get the log folder path
    #>
    if ($null -eq $Script:LogFolder) {
        Initialize-DevBoxPaths | Out-Null
    }
    return $Script:LogFolder
}

function Get-DevBoxTempFolder {
    <#
    .SYNOPSIS
        Get the temp folder path
    #>
    if ($null -eq $Script:TempFolder) {
        Initialize-DevBoxPaths | Out-Null
    }
    return $Script:TempFolder
}

function Get-DevBoxLogFile {
    <#
    .SYNOPSIS
        Get the current log file path
    #>
    if ($null -eq $Script:CurrentLogFile) {
        Initialize-DevBoxPaths | Out-Null
    }
    return $Script:CurrentLogFile
}

function Write-DevBoxLog {
    <#
    .SYNOPSIS
        Write a log entry to the current log file and console

    .PARAMETER Message
        The message to log

    .PARAMETER Level
        Log level: Info, Success, Warning, Error, Header

    .PARAMETER NoConsole
        Suppress console output
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("Info", "Success", "Warning", "Error", "Header")]
        [string]$Level = "Info",

        [switch]$NoConsole
    )

    # Ensure log file is initialized
    if ($null -eq $Script:CurrentLogFile) {
        Initialize-DevBoxPaths | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "Info"    { "[INFO]   " }
        "Success" { "[OK]     " }
        "Warning" { "[WARN]   " }
        "Error"   { "[ERROR]  " }
        "Header"  { "[======] " }
    }

    $logMessage = "$timestamp $prefix$Message"

    # Write to log file
    try {
        Add-Content -Path $Script:CurrentLogFile -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if log write fails
    }

    # Write to console
    if (-not $NoConsole) {
        $color = switch ($Level) {
            "Info"    { "White" }
            "Success" { "Green" }
            "Warning" { "Yellow" }
            "Error"   { "Red" }
            "Header"  { "Cyan" }
        }

        if ($Level -eq "Header") {
            Write-Host ""
            Write-Host ("=" * 60) -ForegroundColor $color
            Write-Host $Message -ForegroundColor $color
            Write-Host ("=" * 60) -ForegroundColor $color
        } else {
            Write-Host "$prefix$Message" -ForegroundColor $color
        }
    }
}

function Get-DevBoxTempFiles {
    <#
    .SYNOPSIS
        Get list of temporary files in the temp folder

    .PARAMETER IncludeSize
        Include file sizes in output
    #>
    param(
        [switch]$IncludeSize
    )

    if ($null -eq $Script:TempFolder) {
        Initialize-DevBoxPaths | Out-Null
    }

    $files = Get-ChildItem -Path $Script:TempFolder -File -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -ne "README.md" }

    if ($IncludeSize) {
        return $files | Select-Object Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB, 2)}}, LastWriteTime
    }
    return $files
}

function Clear-DevBoxTempFiles {
    <#
    .SYNOPSIS
        Remove all temporary files from the temp folder

    .PARAMETER Force
        Skip confirmation prompt

    .PARAMETER WhatIf
        Show what would be deleted without actually deleting
    #>
    param(
        [switch]$Force,
        [switch]$WhatIf
    )

    if ($null -eq $Script:TempFolder) {
        Initialize-DevBoxPaths | Out-Null
    }

    $files = Get-DevBoxTempFiles

    if ($files.Count -eq 0) {
        Write-DevBoxLog "No temporary files to clean" -Level Info
        return @{ Removed = 0; SizeMB = 0 }
    }

    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    $totalMB = [math]::Round($totalSize / 1MB, 2)

    if ($WhatIf) {
        Write-DevBoxLog "Would remove $($files.Count) files (${totalMB}MB)" -Level Info
        foreach ($file in $files) {
            Write-DevBoxLog "  Would remove: $($file.Name)" -Level Info
        }
        return @{ Removed = 0; SizeMB = 0; WouldRemove = $files.Count }
    }

    $removed = 0
    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force -ErrorAction Stop
            $removed++
            Write-DevBoxLog "Removed: $($file.Name)" -Level Success -NoConsole
        } catch {
            Write-DevBoxLog "Failed to remove: $($file.Name) - $_" -Level Warning
        }
    }

    Write-DevBoxLog "Cleaned $removed temporary files (${totalMB}MB freed)" -Level Success
    return @{ Removed = $removed; SizeMB = $totalMB }
}

function Get-DevBoxLogFiles {
    <#
    .SYNOPSIS
        Get list of log files

    .PARAMETER DaysOld
        Only return logs older than this many days
    #>
    param(
        [int]$DaysOld = 0
    )

    if ($null -eq $Script:LogFolder) {
        Initialize-DevBoxPaths | Out-Null
    }

    $cutoffDate = if ($DaysOld -gt 0) { (Get-Date).AddDays(-$DaysOld) } else { [DateTime]::MinValue }

    return Get-ChildItem -Path $Script:LogFolder -Filter "*.log" -ErrorAction SilentlyContinue |
           Where-Object { $_.LastWriteTime -lt $cutoffDate -or $DaysOld -eq 0 } |
           Select-Object Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB, 2)}}, LastWriteTime
}

function Clear-DevBoxLogFiles {
    <#
    .SYNOPSIS
        Remove old log files

    .PARAMETER DaysOld
        Remove logs older than this many days (default: 30)

    .PARAMETER Force
        Skip confirmation
    #>
    param(
        [int]$DaysOld = 30,
        [switch]$Force
    )

    if ($null -eq $Script:LogFolder) {
        Initialize-DevBoxPaths | Out-Null
    }

    $oldLogs = Get-ChildItem -Path $Script:LogFolder -Filter "*.log" -ErrorAction SilentlyContinue |
               Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOld) }

    if ($oldLogs.Count -eq 0) {
        Write-DevBoxLog "No log files older than $DaysOld days" -Level Info
        return @{ Removed = 0 }
    }

    $removed = 0
    foreach ($log in $oldLogs) {
        try {
            Remove-Item $log.FullName -Force -ErrorAction Stop
            $removed++
        } catch {
            Write-DevBoxLog "Failed to remove: $($log.Name)" -Level Warning
        }
    }

    Write-DevBoxLog "Removed $removed old log files" -Level Success
    return @{ Removed = $removed }
}

function Show-TempCleanupPrompt {
    <#
    .SYNOPSIS
        Show prompt to clean temp files if any exist

    .DESCRIPTION
        Called at startup to offer cleanup of stale temp files
    #>
    param(
        [switch]$Silent
    )

    if ($null -eq $Script:TempFolder) {
        Initialize-DevBoxPaths | Out-Null
    }

    $tempFiles = Get-DevBoxTempFiles -IncludeSize

    if ($tempFiles.Count -eq 0) {
        return $false
    }

    $totalSize = ($tempFiles | Measure-Object -Property SizeMB -Sum).Sum

    if ($Silent) {
        # In silent mode, just report but don't prompt
        Write-DevBoxLog "Found $($tempFiles.Count) temp files (${totalSize}MB) in temp folder" -Level Warning
        return $false
    }

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |              TEMPORARY FILES DETECTED                      |" -ForegroundColor Yellow
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Found $($tempFiles.Count) temporary file(s) from previous runs:" -ForegroundColor White
    Write-Host ""

    foreach ($file in $tempFiles | Select-Object -First 5) {
        Write-Host "    - $($file.Name) ($($file.SizeMB)MB)" -ForegroundColor Gray
    }
    if ($tempFiles.Count -gt 5) {
        Write-Host "    ... and $($tempFiles.Count - 5) more" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Total size: ${totalSize}MB" -ForegroundColor White
    Write-Host ""
    Write-Host "  These files may cause issues if left from failed operations." -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "  Clean temp files now? (Y/n)"

    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq 'Y' -or $choice -eq 'y') {
        Clear-DevBoxTempFiles -Force | Out-Null
        return $true
    }

    Write-Host "  Skipping cleanup. Run '.\devbox cleanup -Temp' to clean later." -ForegroundColor DarkGray
    Write-Host ""
    return $false
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-DevBoxPaths',
    'Get-DevBoxLogFolder',
    'Get-DevBoxTempFolder',
    'Get-DevBoxLogFile',
    'Write-DevBoxLog',
    'Get-DevBoxTempFiles',
    'Clear-DevBoxTempFiles',
    'Get-DevBoxLogFiles',
    'Clear-DevBoxLogFiles',
    'Show-TempCleanupPrompt'
)
