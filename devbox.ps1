<#
.SYNOPSIS
    DevBox Factory - Human-friendly command wrapper

.DESCRIPTION
    Provides simple aliases for DevBox Factory commands.
    Usage: .\devbox <command> [arguments]

.EXAMPLE
    .\devbox init          # Initialize DevBox (download/setup)
    .\devbox install       # Install development tools
    .\devbox template      # Create VM template from ISO
    .\devbox vm            # Create VM from template
    .\devbox deps          # Manage offline dependencies
    .\devbox test          # Run health checks
    .\devbox cleanup       # Clean temp files and old logs
    .\devbox reset         # Remove VMs, templates (factory reset)
    .\devbox help          # Show this help

.NOTES
    DevBox Factory v3.1.0
    Build: 20260105.0500
    https://github.com/velocityeu/devbox-factory
#>

param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$Script:Version = "3.1.0"
$Script:Build = "20260105.0500"
$Script:BuildDate = "2026-01-05 05:00"

# Import logger module
$loggerModule = Join-Path $PSScriptRoot "modules\DevBoxLogger.psm1"
if (Test-Path $loggerModule) {
    Import-Module $loggerModule -Force -ErrorAction SilentlyContinue
    $paths = Initialize-DevBoxPaths -ScriptRoot $PSScriptRoot -LogPrefix "devbox"
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
    Write-Host "  |  One command. Identical dev environments. Every time.               |" -ForegroundColor White
    Write-Host "  |  by Velocity EU                           v$Script:Version build $Script:Build  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Help {
    Show-Banner
    Write-Host "  USAGE: " -ForegroundColor Cyan -NoNewline
    Write-Host '.\devbox <command> [arguments]' -ForegroundColor White
    Write-Host ""
    Write-Host "  COMMANDS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    init" -ForegroundColor Yellow -NoNewline
    Write-Host "        Download and initialize DevBox Factory" -ForegroundColor White
    Write-Host "    install" -ForegroundColor Yellow -NoNewline
    Write-Host "     Install development tools (interactive menu)" -ForegroundColor White
    Write-Host "    template" -ForegroundColor Yellow -NoNewline
    Write-Host "    Create VM template from Windows ISO" -ForegroundColor White
    Write-Host "    vm" -ForegroundColor Yellow -NoNewline
    Write-Host "          Create development VM from template" -ForegroundColor White
    Write-Host "    deps" -ForegroundColor Yellow -NoNewline
    Write-Host "        Manage offline dependencies (download/status)" -ForegroundColor White
    Write-Host "    test" -ForegroundColor Yellow -NoNewline
    Write-Host "        Run health checks and verify installation" -ForegroundColor White
    Write-Host "    cleanup" -ForegroundColor Yellow -NoNewline
    Write-Host "     Clean temp files and old logs" -ForegroundColor White
    Write-Host "    reset" -ForegroundColor Yellow -NoNewline
    Write-Host "       Remove VMs, templates, factory reset" -ForegroundColor White
    Write-Host "    help" -ForegroundColor Yellow -NoNewline
    Write-Host "        Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "  CLEANUP OPTIONS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host '    .\devbox cleanup -Temp' -ForegroundColor DarkGray -NoNewline
    Write-Host "      Remove temporary files" -ForegroundColor Gray
    Write-Host '    .\devbox cleanup -Logs' -ForegroundColor DarkGray -NoNewline
    Write-Host "      Remove logs older than 30 days" -ForegroundColor Gray
    Write-Host '    .\devbox cleanup -All' -ForegroundColor DarkGray -NoNewline
    Write-Host "       Clean both temp and old logs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RESET OPTIONS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host '    .\devbox reset' -ForegroundColor DarkGray -NoNewline
    Write-Host "           Interactive cleanup menu" -ForegroundColor Gray
    Write-Host '    .\devbox reset -DryRun' -ForegroundColor DarkGray -NoNewline
    Write-Host "    Preview what would be deleted" -ForegroundColor Gray
    Write-Host '    .\devbox reset -KeepTemplates' -ForegroundColor DarkGray -NoNewline
    Write-Host " Factory reset but preserve templates" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  EXAMPLES:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host '    .\devbox install' -ForegroundColor DarkGray
    Write-Host '    .\devbox template -ISOPath C:\ISOs\Win11.iso' -ForegroundColor DarkGray
    Write-Host '    .\devbox vm -VMName DevVM-01 -StartVM' -ForegroundColor DarkGray
    Write-Host '    .\devbox cleanup -All' -ForegroundColor DarkGray
    Write-Host '    .\devbox reset' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  DEFAULT VM CREDENTIALS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Username: " -ForegroundColor White -NoNewline
    Write-Host "Admin" -ForegroundColor Green
    Write-Host "    Password: " -ForegroundColor White -NoNewline
    Write-Host "VibeDev123!" -ForegroundColor Green
    Write-Host ""
    Write-Host "    Note: NOT 'Administrator' - the local account is 'Admin'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  MORE INFO:" -ForegroundColor Cyan
    Write-Host "    https://github.com/velocityeu/devbox-factory" -ForegroundColor Blue
    Write-Host ""
}

function Invoke-DevBoxCommand {
    param(
        [string]$ScriptPath,
        [string[]]$Args
    )

    if (-not (Test-Path $ScriptPath)) {
        Write-Host "  [ERROR] Script not found: $ScriptPath" -ForegroundColor Red
        Write-Host "  Run '.\devbox init' to download all components." -ForegroundColor Yellow
        return
    }

    & $ScriptPath @Args
}

function Invoke-Cleanup {
    param(
        [string[]]$Args
    )

    Show-Banner

    $cleanTemp = $false
    $cleanLogs = $false
    $daysOld = 30

    # Parse arguments
    foreach ($arg in $Args) {
        switch -Regex ($arg) {
            "^-?Temp$" { $cleanTemp = $true }
            "^-?Logs$" { $cleanLogs = $true }
            "^-?All$" { $cleanTemp = $true; $cleanLogs = $true }
            "^-?Days:?(\d+)$" { $daysOld = [int]$matches[1] }
        }
    }

    # If no specific option, show interactive menu
    if (-not $cleanTemp -and -not $cleanLogs) {
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |                    CLEANUP MENU                            |" -ForegroundColor Cyan
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""

        # Show temp files status
        $tempFolder = Get-DevBoxTempFolder
        $tempFiles = Get-DevBoxTempFiles -IncludeSize
        $tempCount = $tempFiles.Count
        $tempSize = if ($tempFiles.Count -gt 0) { ($tempFiles | Measure-Object -Property SizeMB -Sum).Sum } else { 0 }

        Write-Host "  Temp Files: " -ForegroundColor White -NoNewline
        if ($tempCount -gt 0) {
            Write-Host "$tempCount files (${tempSize}MB)" -ForegroundColor Yellow
        } else {
            Write-Host "Clean" -ForegroundColor Green
        }

        # Show log files status
        $logFolder = Get-DevBoxLogFolder
        $logFiles = Get-DevBoxLogFiles
        $logCount = $logFiles.Count
        $oldLogs = Get-DevBoxLogFiles -DaysOld $daysOld
        $oldLogCount = $oldLogs.Count

        Write-Host "  Log Files:  " -ForegroundColor White -NoNewline
        Write-Host "$logCount total" -ForegroundColor White -NoNewline
        if ($oldLogCount -gt 0) {
            Write-Host ", $oldLogCount older than $daysOld days" -ForegroundColor Yellow
        } else {
            Write-Host "" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "   [1] Clean temp files" -ForegroundColor White
        Write-Host "   [2] Clean old logs (>$daysOld days)" -ForegroundColor White
        Write-Host "   [3] Clean both" -ForegroundColor White
        Write-Host "   [Q] Cancel" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

        $choice = Read-Host "  Enter choice"

        switch ($choice) {
            '1' { $cleanTemp = $true }
            '2' { $cleanLogs = $true }
            '3' { $cleanTemp = $true; $cleanLogs = $true }
            default {
                Write-Host ""
                Write-Host "  Cleanup cancelled." -ForegroundColor DarkGray
                Write-Host ""
                return
            }
        }
    }

    Write-Host ""
    Write-Host "  CLEANUP RESULTS" -ForegroundColor Cyan
    Write-Host "  ===============" -ForegroundColor DarkGray
    Write-Host ""

    if ($cleanTemp) {
        $result = Clear-DevBoxTempFiles -Force
    }

    if ($cleanLogs) {
        $result = Clear-DevBoxLogFiles -DaysOld $daysOld -Force
    }

    Write-Host ""
}

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Command)) {
    ""
} else {
    $Command.ToLower()
}

# Check for temp files on startup (except for cleanup and help commands)
$skipCleanupCheck = @("cleanup", "help", "")
if ($normalizedCommand -notin $skipCleanupCheck) {
    if (Get-Command Show-TempCleanupPrompt -ErrorAction SilentlyContinue) {
        Show-TempCleanupPrompt | Out-Null
    }
}

# Log the command execution
if (Get-Command Write-DevBoxLog -ErrorAction SilentlyContinue) {
    if (-not [string]::IsNullOrWhiteSpace($normalizedCommand)) {
        Write-DevBoxLog "Executing: devbox $normalizedCommand $($Arguments -join ' ')" -Level Info -NoConsole
    }
}

# Main command router
switch ($normalizedCommand) {
    "init" {
        Invoke-DevBoxCommand -ScriptPath "$PSScriptRoot\Initialize-DevBox.ps1" -Args $Arguments
    }
    "install" {
        Invoke-DevBoxCommand -ScriptPath "$PSScriptRoot\Install-DevBox.ps1" -Args $Arguments
    }
    "template" {
        Invoke-DevBoxCommand -ScriptPath "$PSScriptRoot\templates\New-DevBoxTemplate.ps1" -Args $Arguments
    }
    "vm" {
        Invoke-DevBoxCommand -ScriptPath "$PSScriptRoot\vms\New-DevBoxVM.ps1" -Args $Arguments
    }
    "deps" {
        Invoke-DevBoxCommand -ScriptPath "$PSScriptRoot\Download-Dependencies.ps1" -Args $Arguments
    }
    "test" {
        Invoke-DevBoxCommand -ScriptPath "$PSScriptRoot\utils\Test-DevBoxHealth.ps1" -Args $Arguments
    }
    "cleanup" {
        Invoke-Cleanup -Args $Arguments
    }
    "reset" {
        Invoke-DevBoxCommand -ScriptPath "$PSScriptRoot\utils\Remove-DevBoxAssets.ps1" -Args $Arguments
    }
    "help" {
        Show-Help
    }
    "" {
        Show-Help
    }
    default {
        Write-Host ""
        Write-Host "  [ERROR] Unknown command: $Command" -ForegroundColor Red
        Write-Host "  Run '.\devbox help' for available commands." -ForegroundColor Yellow
        Write-Host ""
    }
}
