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
    .\devbox test          # Run health checks
    .\devbox help          # Show this help

.NOTES
    DevBox Factory v2.0.0
    https://github.com/velocityeu/devbox-factory
#>

param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$Script:Version = "2.0.0"
$Script:Build = "20260104.002"

function Show-Banner {
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  ██████╗ ███████╗██╗   ██╗██████╗  ██████╗ ██╗  ██╗" -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  ██╔══██╗██╔════╝██║   ██║██╔══██╗██╔═══██╗╚██╗██╔╝" -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  ██║  ██║█████╗  ██║   ██║██████╔╝██║   ██║ ╚███╔╝ " -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══██╗██║   ██║ ██╔██╗ " -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  ██████╔╝███████╗ ╚████╔╝ ██████╔╝╚██████╔╝██╔╝ ██╗" -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  ╚═════╝ ╚══════╝  ╚═══╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝" -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "                     F A C T O R Y                  " -ForegroundColor Yellow -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  One command. Identical dev environments. Every time." -ForegroundColor White -NoNewline
    Write-Host "              ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  by Velocity EU" -ForegroundColor DarkGray -NoNewline
    Write-Host "                          v$Script:Version " -ForegroundColor DarkGray -NoNewline
    Write-Host "build $Script:Build" -ForegroundColor DarkYellow -NoNewline
    Write-Host "  ║" -ForegroundColor DarkCyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Help {
    Show-Banner
    Write-Host "  USAGE: " -ForegroundColor Cyan -NoNewline
    Write-Host ".\devbox <command> [arguments]" -ForegroundColor White
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
    Write-Host "    test" -ForegroundColor Yellow -NoNewline
    Write-Host "        Run health checks and verify installation" -ForegroundColor White
    Write-Host "    help" -ForegroundColor Yellow -NoNewline
    Write-Host "        Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "  EXAMPLES:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    .\devbox install" -ForegroundColor DarkGray
    Write-Host "    .\devbox template -ISOPath C:\ISOs\Win11.iso" -ForegroundColor DarkGray
    Write-Host "    .\devbox vm -VMName DevVM-01 -StartVM" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  MORE INFO:" -ForegroundColor Cyan
    Write-Host "    https://github.com/velocityeu/devbox-factory" -ForegroundColor Blue
    Write-Host ""
}

function Invoke-Command {
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

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Command)) {
    ""
} else {
    $Command.ToLower()
}

# Main command router
switch ($normalizedCommand) {
    "init" {
        Invoke-Command -ScriptPath "$PSScriptRoot\Initialize-DevBox.ps1" -Args $Arguments
    }
    "install" {
        Invoke-Command -ScriptPath "$PSScriptRoot\Install-DevBox.ps1" -Args $Arguments
    }
    "template" {
        Invoke-Command -ScriptPath "$PSScriptRoot\templates\New-DevBoxTemplate.ps1" -Args $Arguments
    }
    "vm" {
        Invoke-Command -ScriptPath "$PSScriptRoot\vms\New-DevBoxVM.ps1" -Args $Arguments
    }
    "test" {
        Invoke-Command -ScriptPath "$PSScriptRoot\utils\Test-DevBoxHealth.ps1" -Args $Arguments
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
