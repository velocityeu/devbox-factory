#Requires -Version 5.1

<#
.SYNOPSIS
    Install-DevBox.ps1 - DevBox Factory Windows 11 Development Environment Setup

.DESCRIPTION
    Sets up a complete "vibe development" environment on Windows 11 22H2+ with:
    - Interactive menu for easy installation (no parameters needed)
    - Package managers: WinGet (primary) + Chocolatey (fallback)
    - Runtimes: Node.js (via NVM), Python 3.12+, .NET SDK
    - JS Package Managers: npm, pnpm, yarn, bun
    - AI Coding Tools: Claude Code, Cursor, VS Code + extensions
    - Databases: PostgreSQL, MongoDB, Redis
    - Containerization: WSL2, Docker Desktop
    - Azure Development: Azure CLI, Functions, Bicep, Terraform

.PARAMETER Silent
    Run in non-interactive mode (requires Profile parameter or defaults to Full)

.PARAMETER Profile
    Installation profile for automation: Full, AICoder, WebDev, Azure, Minimal

.PARAMETER SkipNodeJS
    Skip Node.js and NVM installation

.PARAMETER SkipPython
    Skip Python installation

.PARAMETER SkipDotNet
    Skip .NET SDK installation

.PARAMETER SkipDocker
    Skip Docker Desktop and WSL2 setup

.PARAMETER SkipDatabases
    Skip PostgreSQL, MongoDB, and Redis installation

.PARAMETER SkipAITools
    Skip Claude Code, Cursor, and VS Code installation

.PARAMETER SkipAzure
    Skip Azure development tools

.PARAMETER SkipVSCodeExtensions
    Skip VS Code extension installation

.PARAMETER NoReboot
    Don't prompt for reboot even if required

.PARAMETER LogPath
    Custom path for log file (default: $env:USERPROFILE\DevBox-Install.log)

.EXAMPLE
    .\Install-DevBox.ps1
    Launch interactive menu

.EXAMPLE
    .\Install-DevBox.ps1 -Silent -Profile Full
    Full installation without prompts

.EXAMPLE
    .\Install-DevBox.ps1 -Silent -Profile AICoder
    AI development tools only

.EXAMPLE
    .\Install-DevBox.ps1 -Silent -Profile Azure
    Azure developer environment

.EXAMPLE
    .\Install-DevBox.ps1 -SkipDatabases -SkipDocker
    Custom install skipping specific components
#>

[CmdletBinding()]
param(
    [switch]$Silent,
    [ValidateSet('Full', 'AICoder', 'WebDev', 'Azure', 'Minimal')]
    [string]$Profile,
    [switch]$SkipNodeJS,
    [switch]$SkipPython,
    [switch]$SkipDotNet,
    [switch]$SkipDocker,
    [switch]$SkipDatabases,
    [switch]$SkipAITools,
    [switch]$SkipAzure,
    [switch]$SkipVSCodeExtensions,
    [switch]$NoReboot,
    [string]$LogPath = "$env:USERPROFILE\DevBox-Install.log"
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:Config = @{
    # WinGet Package IDs
    Packages = @{
        # Package Managers
        Chocolatey      = "Chocolatey.Chocolatey"

        # Core Tools
        Git             = "Git.Git"
        WindowsTerminal = "Microsoft.WindowsTerminal"

        # Runtimes
        Python          = "Python.Python.3.12"
        NVMWindows      = "CoreyButler.NVMforWindows"
        NodeLTS         = "OpenJS.NodeJS.LTS"
        DotNetSDK       = "Microsoft.DotNet.SDK.8"

        # IDEs & Editors
        VSCode          = "Microsoft.VisualStudioCode"
        Cursor          = "Anysphere.Cursor"

        # Containers
        Docker          = "Docker.DockerDesktop"

        # Databases
        PostgreSQL      = "PostgreSQL.PostgreSQL.16"
        MongoDB         = "MongoDB.Server"

        # Azure Tools
        AzureCLI        = "Microsoft.AzureCLI"
        AzureFunctions  = "Microsoft.Azure.FunctionsCoreTools"
        AzureDevCLI     = "Microsoft.Azd"
        AzureDataStudio = "Microsoft.AzureDataStudio"
        Bicep           = "Microsoft.Bicep"
        Terraform       = "Hashicorp.Terraform"
        AzureStorageExplorer = "Microsoft.Azure.StorageExplorer"
    }

    # Chocolatey fallback package names
    ChocoFallback = @{
        Git             = "git"
        Python          = "python312"
        NodeLTS         = "nodejs-lts"
        DotNetSDK       = "dotnet-sdk"
        VSCode          = "vscode"
        Docker          = "docker-desktop"
        PostgreSQL      = "postgresql16"
        MongoDB         = "mongodb"
        Redis           = "redis-64"
        AzureCLI        = "azure-cli"
        AzureFunctions  = "azure-functions-core-tools"
        Terraform       = "terraform"
    }

    # VS Code Extension IDs - Base
    VSCodeExtensionsBase = @(
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "eamodio.gitlens"
        "ms-vscode.powershell"
    )

    # VS Code Extension IDs - AI
    VSCodeExtensionsAI = @(
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "anthropic.claude-code"
        "Continue.continue"
        "saoudrizwan.claude-dev"
    )

    # VS Code Extension IDs - Web Development
    VSCodeExtensionsWeb = @(
        "ms-python.python"
        "ms-python.vscode-pylance"
        "bradlc.vscode-tailwindcss"
        "dsznajder.es7-react-js-snippets"
        "Prisma.prisma"
    )

    # VS Code Extension IDs - Azure
    VSCodeExtensionsAzure = @(
        "ms-azuretools.vscode-azurefunctions"
        "ms-azuretools.vscode-azureresourcegroups"
        "ms-azuretools.vscode-azurestorage"
        "ms-azuretools.vscode-cosmosdb"
        "ms-azuretools.vscode-docker"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "ms-vscode.azure-account"
        "hashicorp.terraform"
    )

    # Installation tracking
    InstalledItems  = [System.Collections.ArrayList]::new()
    SkippedItems    = [System.Collections.ArrayList]::new()
    FailedItems     = [System.Collections.ArrayList]::new()
    RequiresReboot  = $false

    # Selected components (set by menu or parameters)
    InstallAI       = $true
    InstallWeb      = $true
    InstallAzure    = $false
    InstallDocker   = $true
    InstallDatabases = $true
}

# Version Information
$Script:Version = "3.0.0"
$Script:Build = "20260104.1800"
$Script:BuildDate = "2026-01-04 18:00"

# ============================================================================
# MENU SYSTEM
# ============================================================================

function Show-Banner {
    Clear-Host
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
    Write-Host "  |  TOOL INSTALLER          Windows 11 Development Environment         |" -ForegroundColor White
    Write-Host "  |  by Velocity EU                           v$Script:Version build $Script:Build  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-MainMenu {
    Show-Banner

    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                    SELECT INSTALLATION                        |" -ForegroundColor Cyan
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Full Installation" -ForegroundColor White -NoNewline
    Write-Host " (Recommended)" -ForegroundColor Green
    Write-Host "       Everything: AI tools, Web dev, Docker, Databases" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "AI Vibe Coder" -ForegroundColor White
    Write-Host "       Claude Code, Cursor, VS Code + AI extensions, Node.js, Python" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Full-Stack Web Developer" -ForegroundColor White
    Write-Host "       Node.js, Python, Docker, PostgreSQL, MongoDB, Redis" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [4] " -ForegroundColor Yellow -NoNewline
    Write-Host "Azure Cloud Developer" -ForegroundColor White
    Write-Host "       Azure CLI, Functions, .NET SDK, Terraform, Bicep, Docker" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [5] " -ForegroundColor Yellow -NoNewline
    Write-Host "Custom Installation" -ForegroundColor White
    Write-Host "       Choose exactly what to install" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [6] " -ForegroundColor Yellow -NoNewline
    Write-Host "Minimal (Core Only)" -ForegroundColor White
    Write-Host "       Git, Windows Terminal, VS Code" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [Q] " -ForegroundColor Red -NoNewline
    Write-Host "Quit" -ForegroundColor White
    Write-Host ""
    Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter your choice"
    return $choice
}

function Show-CustomMenu {
    Show-Banner

    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                   CUSTOM INSTALLATION                         |" -ForegroundColor Cyan
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Select components to install (enter numbers separated by commas)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Core Tools" -ForegroundColor White -NoNewline
    Write-Host " - Git, Windows Terminal, VS Code" -ForegroundColor Gray
    Write-Host "       " -NoNewline
    Write-Host "(Always included)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "AI Coding Tools" -ForegroundColor White -NoNewline
    Write-Host " - Claude Code, Cursor, AI extensions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Node.js Environment" -ForegroundColor White -NoNewline
    Write-Host " - NVM, Node.js, npm, pnpm, yarn, bun" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [4] " -ForegroundColor Yellow -NoNewline
    Write-Host "Python" -ForegroundColor White -NoNewline
    Write-Host " - Python 3.12 with pip" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [5] " -ForegroundColor Yellow -NoNewline
    Write-Host "Docker & Containers" -ForegroundColor White -NoNewline
    Write-Host " - WSL2, Docker Desktop" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [6] " -ForegroundColor Yellow -NoNewline
    Write-Host "Databases" -ForegroundColor White -NoNewline
    Write-Host " - PostgreSQL, MongoDB, Redis" -ForegroundColor Gray
    Write-Host "       " -NoNewline
    Write-Host "(Requires Docker or standalone install)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [7] " -ForegroundColor Yellow -NoNewline
    Write-Host "Azure Development" -ForegroundColor White -NoNewline
    Write-Host " - Azure CLI, Functions, .NET, Terraform" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Example: " -ForegroundColor Gray -NoNewline
    Write-Host "2,3,4" -ForegroundColor Cyan -NoNewline
    Write-Host " (AI tools + Node.js + Python)" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "  Enter components (e.g., 2,3,5)"
    return $choice
}

function Set-ProfileConfiguration {
    param([string]$SelectedProfile)

    switch ($SelectedProfile) {
        'Full' {
            $Script:Config.InstallAI = $true
            $Script:Config.InstallWeb = $true
            $Script:Config.InstallAzure = $true
            $Script:Config.InstallDocker = $true
            $Script:Config.InstallDatabases = $true
            $script:SkipNodeJS = $false
            $script:SkipPython = $false
            $script:SkipDotNet = $false
            $script:SkipDocker = $false
            $script:SkipDatabases = $false
            $script:SkipAITools = $false
            $script:SkipAzure = $false
        }
        'AICoder' {
            $Script:Config.InstallAI = $true
            $Script:Config.InstallWeb = $true
            $Script:Config.InstallAzure = $false
            $Script:Config.InstallDocker = $false
            $Script:Config.InstallDatabases = $false
            $script:SkipNodeJS = $false
            $script:SkipPython = $false
            $script:SkipDotNet = $true
            $script:SkipDocker = $true
            $script:SkipDatabases = $true
            $script:SkipAITools = $false
            $script:SkipAzure = $true
        }
        'WebDev' {
            $Script:Config.InstallAI = $false
            $Script:Config.InstallWeb = $true
            $Script:Config.InstallAzure = $false
            $Script:Config.InstallDocker = $true
            $Script:Config.InstallDatabases = $true
            $script:SkipNodeJS = $false
            $script:SkipPython = $false
            $script:SkipDotNet = $true
            $script:SkipDocker = $false
            $script:SkipDatabases = $false
            $script:SkipAITools = $true
            $script:SkipAzure = $true
        }
        'Azure' {
            $Script:Config.InstallAI = $true
            $Script:Config.InstallWeb = $false
            $Script:Config.InstallAzure = $true
            $Script:Config.InstallDocker = $true
            $Script:Config.InstallDatabases = $false
            $script:SkipNodeJS = $false
            $script:SkipPython = $false
            $script:SkipDotNet = $false
            $script:SkipDocker = $false
            $script:SkipDatabases = $true
            $script:SkipAITools = $false
            $script:SkipAzure = $false
        }
        'Minimal' {
            $Script:Config.InstallAI = $false
            $Script:Config.InstallWeb = $false
            $Script:Config.InstallAzure = $false
            $Script:Config.InstallDocker = $false
            $Script:Config.InstallDatabases = $false
            $script:SkipNodeJS = $true
            $script:SkipPython = $true
            $script:SkipDotNet = $true
            $script:SkipDocker = $true
            $script:SkipDatabases = $true
            $script:SkipAITools = $false  # Still install VS Code
            $script:SkipAzure = $true
            $script:SkipVSCodeExtensions = $true
        }
    }
}

function Set-CustomConfiguration {
    param([string]$Choices)

    # Start with minimal
    $Script:Config.InstallAI = $false
    $Script:Config.InstallWeb = $false
    $Script:Config.InstallAzure = $false
    $Script:Config.InstallDocker = $false
    $Script:Config.InstallDatabases = $false
    $script:SkipNodeJS = $true
    $script:SkipPython = $true
    $script:SkipDotNet = $true
    $script:SkipDocker = $true
    $script:SkipDatabases = $true
    $script:SkipAITools = $true
    $script:SkipAzure = $true

    $selected = $Choices -split ',' | ForEach-Object { $_.Trim() }

    foreach ($choice in $selected) {
        switch ($choice) {
            '1' { } # Core always included
            '2' {
                $Script:Config.InstallAI = $true
                $script:SkipAITools = $false
            }
            '3' {
                $Script:Config.InstallWeb = $true
                $script:SkipNodeJS = $false
            }
            '4' {
                $script:SkipPython = $false
            }
            '5' {
                $Script:Config.InstallDocker = $true
                $script:SkipDocker = $false
            }
            '6' {
                $Script:Config.InstallDatabases = $true
                $script:SkipDatabases = $false
            }
            '7' {
                $Script:Config.InstallAzure = $true
                $script:SkipAzure = $false
                $script:SkipDotNet = $false
            }
        }
    }

    # VS Code is always installed (part of core)
    $script:SkipAITools = $script:SkipAITools -and (-not $Script:Config.InstallAI)
}

function Show-SelectedComponents {
    Write-Host ""
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host "  |                 COMPONENTS TO INSTALL                         |" -ForegroundColor Green
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""

    Write-Host "   [*] Core: Git, Windows Terminal, VS Code" -ForegroundColor White

    if (-not $script:SkipAITools -and $Script:Config.InstallAI) {
        Write-Host "   [*] AI Tools: Claude Code, Cursor, AI Extensions" -ForegroundColor White
    }
    if (-not $script:SkipNodeJS) {
        Write-Host "   [*] Node.js: NVM, Node.js LTS, npm, pnpm, yarn, bun" -ForegroundColor White
    }
    if (-not $script:SkipPython) {
        Write-Host "   [*] Python 3.12" -ForegroundColor White
    }
    if (-not $script:SkipDotNet) {
        Write-Host "   [*] .NET SDK 8" -ForegroundColor White
    }
    if (-not $script:SkipDocker) {
        Write-Host "   [*] Docker: WSL2, Docker Desktop" -ForegroundColor White
    }
    if (-not $script:SkipDatabases) {
        Write-Host "   [*] Databases: PostgreSQL, MongoDB, Redis" -ForegroundColor White
    }
    if (-not $script:SkipAzure) {
        Write-Host "   [*] Azure: CLI, Functions, Bicep, Terraform, Storage Explorer" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-MenuSelection {
    while ($true) {
        $choice = Show-MainMenu

        switch ($choice.ToUpper()) {
            '1' {
                Set-ProfileConfiguration -SelectedProfile 'Full'
                Show-SelectedComponents
                if (Get-UserConfirmation "  Proceed with installation?") { return $true }
            }
            '2' {
                Set-ProfileConfiguration -SelectedProfile 'AICoder'
                Show-SelectedComponents
                if (Get-UserConfirmation "  Proceed with installation?") { return $true }
            }
            '3' {
                Set-ProfileConfiguration -SelectedProfile 'WebDev'
                Show-SelectedComponents
                if (Get-UserConfirmation "  Proceed with installation?") { return $true }
            }
            '4' {
                Set-ProfileConfiguration -SelectedProfile 'Azure'
                Show-SelectedComponents
                if (Get-UserConfirmation "  Proceed with installation?") { return $true }
            }
            '5' {
                $customChoice = Show-CustomMenu
                if ($customChoice -and $customChoice -ne '') {
                    Set-CustomConfiguration -Choices $customChoice
                    Show-SelectedComponents
                    if (Get-UserConfirmation "  Proceed with installation?") { return $true }
                }
            }
            '6' {
                Set-ProfileConfiguration -SelectedProfile 'Minimal'
                Show-SelectedComponents
                if (Get-UserConfirmation "  Proceed with installation?") { return $true }
            }
            'Q' {
                Write-Host ""
                Write-Host "  Installation cancelled." -ForegroundColor Yellow
                Write-Host ""
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "  Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Header')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
        'Header'  { 'Magenta' }
    }

    if (-not $Silent) {
        if ($Level -eq 'Header') {
            Write-Host ""
            Write-Host $Message -ForegroundColor $color
            Write-Host ("=" * $Message.Length) -ForegroundColor $color
        } else {
            Write-Host $logEntry -ForegroundColor $color
        }
    }

    Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-AdminElevation {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WindowsVersion {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $buildNumber = [int]$osInfo.BuildNumber

    Write-Log "Detected Windows Build: $buildNumber" -Level Info

    if ($buildNumber -lt 22621) {
        Write-Log "Warning: This script is optimized for Windows 11 22H2 (Build 22621+)" -Level Warning
        if (-not $Silent) {
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne 'y' -and $continue -ne 'Y') {
                Write-Log "Installation cancelled by user." -Level Info
                exit 0
            }
        }
    } else {
        Write-Log "Windows version check passed." -Level Success
    }

    return $true
}

function Update-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    Write-Log "PATH environment refreshed." -Level Info
}

function Get-UserConfirmation {
    param([string]$Message)

    if ($Silent) { return $true }

    $response = Read-Host "$Message (Y/n)"
    return ($response -eq '' -or $response -eq 'y' -or $response -eq 'Y')
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

function Install-Package {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,

        [string]$DisplayName,
        [string]$ChocolateyFallback
    )

    $name = if ($DisplayName) { $DisplayName } else { $PackageId }

    Write-Log "Checking $name..." -Level Info

    $installed = winget list --id $PackageId --exact 2>$null | Out-String
    if ($installed -and $installed -notmatch "No installed package") {
        Write-Log "$name is already installed. Skipping." -Level Info
        [void]$Script:Config.SkippedItems.Add($name)
        return $true
    }

    Write-Log "Installing $name via WinGet..." -Level Info

    try {
        $result = winget install --id $PackageId --exact --accept-source-agreements --accept-package-agreements --silent 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$name installed successfully." -Level Success
            [void]$Script:Config.InstalledItems.Add($name)
            return $true
        }
    }
    catch {
        Write-Log "WinGet installation failed for $name" -Level Warning
    }

    if ($ChocolateyFallback -and (Test-CommandExists "choco")) {
        Write-Log "Trying Chocolatey fallback for $name..." -Level Warning

        try {
            choco install $ChocolateyFallback -y --no-progress 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Log "$name installed via Chocolatey." -Level Success
                [void]$Script:Config.InstalledItems.Add("$name (Chocolatey)")
                return $true
            }
        }
        catch {
            Write-Log "Chocolatey installation also failed for $name" -Level Error
        }
    }

    Write-Log "Failed to install $name" -Level Error
    [void]$Script:Config.FailedItems.Add($name)
    return $false
}

function Install-Chocolatey {
    Write-Log "Setting up Chocolatey..." -Level Header

    if (Test-CommandExists "choco") {
        Write-Log "Chocolatey is already installed." -Level Info
        [void]$Script:Config.SkippedItems.Add("Chocolatey")
        return $true
    }

    Write-Log "Installing Chocolatey via WinGet..." -Level Info

    try {
        winget install --id Chocolatey.Chocolatey --exact --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Update-PathEnvironment
            if (Test-CommandExists "choco") {
                Write-Log "Chocolatey installed via WinGet." -Level Success
                [void]$Script:Config.InstalledItems.Add("Chocolatey")
                return $true
            }
        }
    }
    catch {
        Write-Log "WinGet installation of Chocolatey failed." -Level Warning
    }

    Write-Log "Using official Chocolatey installer..." -Level Info

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        Update-PathEnvironment

        if (Test-CommandExists "choco") {
            Write-Log "Chocolatey installed via official installer." -Level Success
            [void]$Script:Config.InstalledItems.Add("Chocolatey")
            return $true
        }
    }
    catch {
        Write-Log "Failed to install Chocolatey: $_" -Level Error
        [void]$Script:Config.FailedItems.Add("Chocolatey")
        return $false
    }

    return $false
}

function Enable-WSL2 {
    Write-Log "Configuring WSL2..." -Level Header

    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue

    if ($wslFeature.State -eq 'Enabled' -and $vmFeature.State -eq 'Enabled') {
        Write-Log "WSL2 is already enabled." -Level Info
        [void]$Script:Config.SkippedItems.Add("WSL2")
        return $true
    }

    Write-Log "Enabling WSL2 features..." -Level Info

    try {
        if ($wslFeature.State -ne 'Enabled') {
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
            Write-Log "WSL feature enabled." -Level Success
        }

        if ($vmFeature.State -ne 'Enabled') {
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
            Write-Log "Virtual Machine Platform enabled." -Level Success
        }

        wsl --set-default-version 2 2>$null

        Write-Log "WSL2 configured. Reboot required." -Level Success
        $Script:Config.RequiresReboot = $true
        [void]$Script:Config.InstalledItems.Add("WSL2")
        return $true
    }
    catch {
        Write-Log "Failed to enable WSL2: $_" -Level Error
        [void]$Script:Config.FailedItems.Add("WSL2")
        return $false
    }
}

function Install-NodeJS {
    Write-Log "Installing Node.js Environment..." -Level Header

    if ($script:SkipNodeJS) {
        Write-Log "Skipping Node.js (user requested)." -Level Info
        return $true
    }

    Write-Log "Installing NVM for Windows..." -Level Info

    $nvmInstalled = Install-Package -PackageId $Script:Config.Packages.NVMWindows -DisplayName "NVM for Windows"

    Update-PathEnvironment

    if ($nvmInstalled -and (Test-CommandExists "nvm")) {
        Write-Log "Installing Node.js LTS via NVM..." -Level Info

        try {
            nvm install lts 2>&1 | Out-Null
            nvm use lts 2>&1 | Out-Null

            Update-PathEnvironment

            if (Test-CommandExists "node") {
                $nodeVersion = node --version
                Write-Log "Node.js $nodeVersion installed via NVM." -Level Success
                [void]$Script:Config.InstalledItems.Add("Node.js LTS (via NVM)")
            } else {
                Write-Log "Node.js installed but requires new terminal session." -Level Warning
                [void]$Script:Config.InstalledItems.Add("Node.js LTS (restart terminal)")
            }
            return $true
        }
        catch {
            Write-Log "NVM commands failed. May need terminal restart." -Level Warning
        }
    }

    Write-Log "Falling back to direct Node.js installation..." -Level Warning
    return Install-Package -PackageId $Script:Config.Packages.NodeLTS -DisplayName "Node.js LTS" -ChocolateyFallback $Script:Config.ChocoFallback.NodeLTS
}

function Install-JSPackageManagers {
    Write-Log "Installing JS Package Managers..." -Level Header

    if ($script:SkipNodeJS) {
        Write-Log "Skipping JS package managers (Node.js skipped)." -Level Info
        return $true
    }

    Update-PathEnvironment

    if (-not (Test-CommandExists "npm")) {
        Write-Log "npm not found. Ensure Node.js is installed and restart terminal." -Level Warning
        return $false
    }

    # pnpm
    Write-Log "Installing pnpm..." -Level Info
    if (Test-CommandExists "pnpm") {
        Write-Log "pnpm already installed." -Level Info
        [void]$Script:Config.SkippedItems.Add("pnpm")
    } else {
        try {
            npm install -g pnpm 2>&1 | Out-Null
            Write-Log "pnpm installed." -Level Success
            [void]$Script:Config.InstalledItems.Add("pnpm")
        }
        catch {
            Write-Log "Failed to install pnpm." -Level Error
            [void]$Script:Config.FailedItems.Add("pnpm")
        }
    }

    # yarn
    Write-Log "Installing yarn..." -Level Info
    if (Test-CommandExists "yarn") {
        Write-Log "yarn already installed." -Level Info
        [void]$Script:Config.SkippedItems.Add("yarn")
    } else {
        try {
            npm install -g yarn 2>&1 | Out-Null
            Write-Log "yarn installed." -Level Success
            [void]$Script:Config.InstalledItems.Add("yarn")
        }
        catch {
            Write-Log "Failed to install yarn." -Level Error
            [void]$Script:Config.FailedItems.Add("yarn")
        }
    }

    # bun
    Write-Log "Installing bun..." -Level Info
    if (Test-CommandExists "bun") {
        Write-Log "bun already installed." -Level Info
        [void]$Script:Config.SkippedItems.Add("bun")
    } else {
        try {
            irm bun.sh/install.ps1 | iex 2>&1 | Out-Null
            Write-Log "bun installed." -Level Success
            [void]$Script:Config.InstalledItems.Add("bun")
        }
        catch {
            Write-Log "Failed to install bun." -Level Error
            [void]$Script:Config.FailedItems.Add("bun")
        }
    }

    return $true
}

function Install-VSCodeExtensions {
    Write-Log "Installing VS Code Extensions..." -Level Header

    if ($script:SkipVSCodeExtensions) {
        Write-Log "Skipping VS Code extensions (user requested)." -Level Info
        return $true
    }

    Update-PathEnvironment

    if (-not (Test-CommandExists "code")) {
        Write-Log "VS Code CLI not found. Extensions will need manual installation." -Level Warning
        return $false
    }

    # Build extension list based on configuration
    $extensions = $Script:Config.VSCodeExtensionsBase.Clone()

    if ($Script:Config.InstallAI) {
        $extensions += $Script:Config.VSCodeExtensionsAI
    }
    if ($Script:Config.InstallWeb -or (-not $script:SkipNodeJS) -or (-not $script:SkipPython)) {
        $extensions += $Script:Config.VSCodeExtensionsWeb
    }
    if ($Script:Config.InstallAzure) {
        $extensions += $Script:Config.VSCodeExtensionsAzure
    }

    foreach ($extensionId in $extensions) {
        Write-Log "Installing: $extensionId" -Level Info

        try {
            $result = code --install-extension $extensionId --force 2>&1

            if ($LASTEXITCODE -eq 0 -or $result -match "already installed") {
                Write-Log "$extensionId installed." -Level Success
                [void]$Script:Config.InstalledItems.Add("VSCode: $extensionId")
            } else {
                Write-Log "Failed to install $extensionId" -Level Warning
                [void]$Script:Config.FailedItems.Add("VSCode: $extensionId")
            }
        }
        catch {
            Write-Log "Error installing $extensionId" -Level Error
            [void]$Script:Config.FailedItems.Add("VSCode: $extensionId")
        }
    }

    return $true
}

function Install-ClaudeCode {
    Write-Log "Installing Claude Code..." -Level Header

    if ($script:SkipAITools -or -not $Script:Config.InstallAI) {
        Write-Log "Skipping Claude Code." -Level Info
        return $true
    }

    if (Test-CommandExists "claude") {
        Write-Log "Claude Code is already installed." -Level Info
        [void]$Script:Config.SkippedItems.Add("Claude Code")
        return $true
    }

    Write-Log "Running Claude Code installer..." -Level Info

    try {
        irm https://claude.ai/install.ps1 | iex

        Update-PathEnvironment

        if (Test-CommandExists "claude") {
            Write-Log "Claude Code installed successfully." -Level Success
            [void]$Script:Config.InstalledItems.Add("Claude Code")
            return $true
        } else {
            Write-Log "Claude Code installed (restart terminal to use)." -Level Success
            [void]$Script:Config.InstalledItems.Add("Claude Code (restart terminal)")
            return $true
        }
    }
    catch {
        Write-Log "Native installer failed. Trying npm..." -Level Warning

        if (Test-CommandExists "npm") {
            try {
                npm install -g @anthropic-ai/claude-code 2>&1 | Out-Null
                Write-Log "Claude Code installed via npm." -Level Success
                [void]$Script:Config.InstalledItems.Add("Claude Code (npm)")
                return $true
            }
            catch {
                Write-Log "npm installation also failed." -Level Error
            }
        }

        Write-Log "Failed to install Claude Code." -Level Error
        [void]$Script:Config.FailedItems.Add("Claude Code")
        return $false
    }
}

function Install-Redis {
    Write-Log "Installing Redis..." -Level Info

    if ((Test-CommandExists "docker") -and -not $script:SkipDocker) {
        Write-Log "Setting up Redis via Docker..." -Level Info

        try {
            docker pull redis:latest 2>&1 | Out-Null
            docker volume create redis-data 2>$null | Out-Null

            Write-Log "Redis Docker image ready." -Level Success
            Write-Log "  Run: docker run -d -p 6379:6379 -v redis-data:/data --name redis redis:latest" -Level Info
            [void]$Script:Config.InstalledItems.Add("Redis (Docker)")
            return $true
        }
        catch {
            Write-Log "Docker Redis setup failed. Trying Chocolatey..." -Level Warning
        }
    }

    if (Test-CommandExists "choco") {
        try {
            choco install redis-64 -y --no-progress 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Log "Redis installed via Chocolatey." -Level Success
                [void]$Script:Config.InstalledItems.Add("Redis (Chocolatey)")
                return $true
            }
        }
        catch {
            Write-Log "Failed to install Redis." -Level Error
        }
    }

    [void]$Script:Config.FailedItems.Add("Redis")
    return $false
}

function Install-AzureTools {
    Write-Log "Installing Azure Development Tools..." -Level Header

    if ($script:SkipAzure) {
        Write-Log "Skipping Azure tools (user requested)." -Level Info
        return $true
    }

    # Azure CLI
    Install-Package -PackageId $Script:Config.Packages.AzureCLI -DisplayName "Azure CLI" -ChocolateyFallback $Script:Config.ChocoFallback.AzureCLI

    # Azure Functions Core Tools
    Install-Package -PackageId $Script:Config.Packages.AzureFunctions -DisplayName "Azure Functions Core Tools" -ChocolateyFallback $Script:Config.ChocoFallback.AzureFunctions

    # Azure Developer CLI (azd)
    Install-Package -PackageId $Script:Config.Packages.AzureDevCLI -DisplayName "Azure Developer CLI"

    # Azure Data Studio
    Install-Package -PackageId $Script:Config.Packages.AzureDataStudio -DisplayName "Azure Data Studio"

    # Azure Storage Explorer
    Install-Package -PackageId $Script:Config.Packages.AzureStorageExplorer -DisplayName "Azure Storage Explorer"

    # Bicep CLI
    Install-Package -PackageId $Script:Config.Packages.Bicep -DisplayName "Bicep CLI"

    # Terraform
    Install-Package -PackageId $Script:Config.Packages.Terraform -DisplayName "Terraform" -ChocolateyFallback $Script:Config.ChocoFallback.Terraform

    # Install Az PowerShell module
    Write-Log "Installing Az PowerShell module..." -Level Info
    try {
        if (-not (Get-Module -ListAvailable -Name Az -ErrorAction SilentlyContinue)) {
            Install-Module -Name Az -Repository PSGallery -Force -AllowClobber -Scope CurrentUser 2>&1 | Out-Null
            Write-Log "Az PowerShell module installed." -Level Success
            [void]$Script:Config.InstalledItems.Add("Az PowerShell Module")
        } else {
            Write-Log "Az PowerShell module already installed." -Level Info
            [void]$Script:Config.SkippedItems.Add("Az PowerShell Module")
        }
    }
    catch {
        Write-Log "Failed to install Az PowerShell module." -Level Warning
        [void]$Script:Config.FailedItems.Add("Az PowerShell Module")
    }

    return $true
}

# ============================================================================
# SUMMARY AND REPORTING
# ============================================================================

function Show-Summary {
    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Cyan
    Write-Host "  |             INSTALLATION SUMMARY                          |" -ForegroundColor Cyan
    Write-Host "  +===========================================================+" -ForegroundColor Cyan
    Write-Host ""

    if ($Script:Config.InstalledItems.Count -gt 0) {
        Write-Host "  INSTALLED ($($Script:Config.InstalledItems.Count)):" -ForegroundColor Green
        foreach ($item in $Script:Config.InstalledItems) {
            Write-Host "    [+] $item" -ForegroundColor Green
        }
        Write-Host ""
    }

    if ($Script:Config.SkippedItems.Count -gt 0) {
        Write-Host "  ALREADY INSTALLED ($($Script:Config.SkippedItems.Count)):" -ForegroundColor Cyan
        foreach ($item in $Script:Config.SkippedItems) {
            Write-Host "    [=] $item" -ForegroundColor Cyan
        }
        Write-Host ""
    }

    if ($Script:Config.FailedItems.Count -gt 0) {
        Write-Host "  FAILED ($($Script:Config.FailedItems.Count)):" -ForegroundColor Red
        foreach ($item in $Script:Config.FailedItems) {
            Write-Host "    [-] $item" -ForegroundColor Red
        }
        Write-Host ""
    }

    Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Log file: $LogPath" -ForegroundColor Gray
    Write-Host ""

    if ($Script:Config.RequiresReboot) {
        Write-Host "  IMPORTANT: A system reboot is required!" -ForegroundColor Yellow
        Write-Host ""

        if (-not $NoReboot -and -not $Silent) {
            $reboot = Read-Host "  Reboot now? (y/N)"
            if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                Write-Host "  Rebooting in 10 seconds... Press Ctrl+C to cancel." -ForegroundColor Yellow
                Start-Sleep -Seconds 10
                Restart-Computer -Force
            }
        }
    }

    Write-Host "  Setup complete! Open a new terminal to use installed tools." -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

function Start-DevBox-Installation {
    # Initialize log
    "=" * 60 | Out-File $LogPath
    "Vibe Dev Installation - $(Get-Date)" | Out-File $LogPath -Append
    "=" * 60 | Out-File $LogPath -Append

    # Handle menu vs parameters
    if (-not $Silent -and -not $Profile -and -not ($SkipNodeJS -or $SkipPython -or $SkipDocker -or $SkipDatabases -or $SkipAITools -or $SkipAzure)) {
        # Show interactive menu
        Invoke-MenuSelection
    }
    elseif ($Profile) {
        # Use specified profile
        Set-ProfileConfiguration -SelectedProfile $Profile
    }

    Show-Banner
    Write-Host ""

    # Phase 1: Prerequisites
    Write-Log "Phase 1: Checking Prerequisites" -Level Header

    if (-not (Test-AdminElevation)) {
        Write-Host ""
        Write-Host "  ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        Write-Host "  Then run this script again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    Write-Log "Administrator check passed." -Level Success

    Test-WindowsVersion

    if (-not (Test-CommandExists "winget")) {
        Write-Log "WinGet not found. Please update Windows or install App Installer from Microsoft Store." -Level Error
        exit 1
    }
    Write-Log "WinGet is available." -Level Success

    # Phase 2: Package Managers
    Install-Chocolatey

    # Phase 3: Core Tools (always installed)
    Write-Log "Phase 3: Core Development Tools" -Level Header
    Install-Package -PackageId $Script:Config.Packages.Git -DisplayName "Git" -ChocolateyFallback $Script:Config.ChocoFallback.Git
    Install-Package -PackageId $Script:Config.Packages.WindowsTerminal -DisplayName "Windows Terminal"
    Install-Package -PackageId $Script:Config.Packages.VSCode -DisplayName "VS Code" -ChocolateyFallback $Script:Config.ChocoFallback.VSCode

    # Phase 4: VS Code Extensions
    Write-Log "Phase 4: VS Code Extensions" -Level Header
    Install-VSCodeExtensions

    # Phase 5: Runtime Environments
    Write-Log "Phase 5: Runtime Environments" -Level Header

    if (-not $script:SkipPython) {
        Install-Package -PackageId $Script:Config.Packages.Python -DisplayName "Python 3.12" -ChocolateyFallback $Script:Config.ChocoFallback.Python
    }

    if (-not $script:SkipDotNet) {
        Install-Package -PackageId $Script:Config.Packages.DotNetSDK -DisplayName ".NET SDK 8" -ChocolateyFallback $Script:Config.ChocoFallback.DotNetSDK
    }

    if (-not $script:SkipNodeJS) {
        Install-NodeJS
        Install-JSPackageManagers
    }

    # Phase 6: Containerization
    if (-not $script:SkipDocker) {
        Write-Log "Phase 5: Docker & Containerization" -Level Header
        Enable-WSL2
        Install-Package -PackageId $Script:Config.Packages.Docker -DisplayName "Docker Desktop" -ChocolateyFallback $Script:Config.ChocoFallback.Docker
    }

    # Phase 7: Databases
    if (-not $script:SkipDatabases) {
        Write-Log "Phase 6: Databases" -Level Header
        Install-Package -PackageId $Script:Config.Packages.PostgreSQL -DisplayName "PostgreSQL 16" -ChocolateyFallback $Script:Config.ChocoFallback.PostgreSQL
        Install-Package -PackageId $Script:Config.Packages.MongoDB -DisplayName "MongoDB" -ChocolateyFallback $Script:Config.ChocoFallback.MongoDB
        Install-Redis
    }

    # Phase 8: Azure Tools
    if (-not $script:SkipAzure) {
        Install-AzureTools
    }

    # Phase 9: AI Coding Tools
    if (-not $script:SkipAITools) {
        Write-Log "Phase 9: AI Coding Tools" -Level Header

        Update-PathEnvironment
        Start-Sleep -Seconds 2

        if ($Script:Config.InstallAI) {
            Install-Package -PackageId $Script:Config.Packages.Cursor -DisplayName "Cursor IDE"
            Install-ClaudeCode
        }
    }

    # Final PATH refresh
    Update-PathEnvironment

    # Summary
    Show-Summary
}

# ============================================================================
# ENTRY POINT
# ============================================================================

try {
    Start-DevBox-Installation
}
catch {
    Write-Host ""
    Write-Host "FATAL ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the log file: $LogPath" -ForegroundColor Yellow
    exit 1
}
