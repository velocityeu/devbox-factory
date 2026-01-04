#Requires -Version 5.1

<#
.SYNOPSIS
    Install-VibeDev.ps1 - Ultimate Windows 11 Vibe Development Environment Setup

.DESCRIPTION
    Sets up a complete "vibe development" environment on Windows 11 22H2+ with:
    - Package managers: WinGet (primary) + Chocolatey (fallback)
    - Runtimes: Node.js (via NVM), Python 3.12+
    - JS Package Managers: npm, pnpm, yarn, bun
    - AI Coding Tools: Claude Code, Cursor, VS Code + extensions
    - Databases: PostgreSQL, MongoDB, Redis
    - Containerization: WSL2, Docker Desktop

.PARAMETER Silent
    Run in non-interactive mode (auto-accept all prompts)

.PARAMETER SkipNodeJS
    Skip Node.js and NVM installation

.PARAMETER SkipPython
    Skip Python installation

.PARAMETER SkipDocker
    Skip Docker Desktop and WSL2 setup

.PARAMETER SkipDatabases
    Skip PostgreSQL, MongoDB, and Redis installation

.PARAMETER SkipAITools
    Skip Claude Code, Cursor, and VS Code installation

.PARAMETER SkipVSCodeExtensions
    Skip VS Code extension installation

.PARAMETER NoReboot
    Don't prompt for reboot even if required

.PARAMETER LogPath
    Custom path for log file (default: $env:USERPROFILE\VibeDev-Install.log)

.EXAMPLE
    .\Install-VibeDev.ps1
    Full interactive installation

.EXAMPLE
    .\Install-VibeDev.ps1 -Silent
    Silent mode for automation

.EXAMPLE
    .\Install-VibeDev.ps1 -SkipDatabases -SkipDocker
    Install only AI tools and runtimes
#>

[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$SkipNodeJS,
    [switch]$SkipPython,
    [switch]$SkipDocker,
    [switch]$SkipDatabases,
    [switch]$SkipAITools,
    [switch]$SkipVSCodeExtensions,
    [switch]$NoReboot,
    [string]$LogPath = "$env:USERPROFILE\VibeDev-Install.log"
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:Config = @{
    # WinGet Package IDs
    Packages = @{
        Chocolatey      = "Chocolatey.Chocolatey"
        Git             = "Git.Git"
        WindowsTerminal = "Microsoft.WindowsTerminal"
        Python          = "Python.Python.3.12"
        NVMWindows      = "CoreyButler.NVMforWindows"
        NodeLTS         = "OpenJS.NodeJS.LTS"
        VSCode          = "Microsoft.VisualStudioCode"
        Cursor          = "Anysphere.Cursor"
        Docker          = "Docker.DockerDesktop"
        PostgreSQL      = "PostgreSQL.PostgreSQL.16"
        MongoDB         = "MongoDB.Server"
    }

    # Chocolatey fallback package names
    ChocoFallback = @{
        Git             = "git"
        Python          = "python312"
        NodeLTS         = "nodejs-lts"
        VSCode          = "vscode"
        Docker          = "docker-desktop"
        PostgreSQL      = "postgresql16"
        MongoDB         = "mongodb"
        Redis           = "redis-64"
    }

    # VS Code Extension IDs
    VSCodeExtensions = @(
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "anthropic.claude-code"
        "Continue.continue"
        "saoudrizwan.claude-dev"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "eamodio.gitlens"
        "ms-vscode.powershell"
        "ms-python.python"
    )

    # Installation tracking
    InstalledItems  = [System.Collections.ArrayList]::new()
    SkippedItems    = [System.Collections.ArrayList]::new()
    FailedItems     = [System.Collections.ArrayList]::new()
    RequiresReboot  = $false
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

    # Console output with colors
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

    # File logging
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

    # Windows 11 22H2 is build 22621
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

function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        try {
            $attempt++
            return & $ScriptBlock
        }
        catch {
            $lastError = $_
            if ($attempt -lt $MaxRetries) {
                Write-Log "Attempt $attempt failed. Retrying in $DelaySeconds seconds..." -Level Warning
                Start-Sleep -Seconds $DelaySeconds
                $DelaySeconds *= 2
            }
        }
    }

    throw $lastError
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

    # Check if already installed via winget
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

    # Fallback to Chocolatey
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

    # Try WinGet first
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

    # Official installer fallback
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

    # Check current state
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue

    if ($wslFeature.State -eq 'Enabled' -and $vmFeature.State -eq 'Enabled') {
        Write-Log "WSL2 is already enabled." -Level Info
        [void]$Script:Config.SkippedItems.Add("WSL2")
        return $true
    }

    Write-Log "Enabling WSL2 features..." -Level Info

    try {
        # Enable WSL
        if ($wslFeature.State -ne 'Enabled') {
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
            Write-Log "WSL feature enabled." -Level Success
        }

        # Enable Virtual Machine Platform
        if ($vmFeature.State -ne 'Enabled') {
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
            Write-Log "Virtual Machine Platform enabled." -Level Success
        }

        # Set WSL 2 as default
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

    if ($SkipNodeJS) {
        Write-Log "Skipping Node.js (user requested)." -Level Info
        return $true
    }

    # Install NVM for Windows
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

    # Fallback to direct Node.js installation
    Write-Log "Falling back to direct Node.js installation..." -Level Warning
    return Install-Package -PackageId $Script:Config.Packages.NodeLTS -DisplayName "Node.js LTS" -ChocolateyFallback $Script:Config.ChocoFallback.NodeLTS
}

function Install-JSPackageManagers {
    Write-Log "Installing JS Package Managers..." -Level Header

    if ($SkipNodeJS) {
        Write-Log "Skipping JS package managers (Node.js skipped)." -Level Info
        return $true
    }

    Update-PathEnvironment

    # Check if npm is available
    if (-not (Test-CommandExists "npm")) {
        Write-Log "npm not found. Ensure Node.js is installed and restart terminal." -Level Warning
        return $false
    }

    # Install pnpm
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

    # Install yarn
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

    # Install bun
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

    if ($SkipVSCodeExtensions) {
        Write-Log "Skipping VS Code extensions (user requested)." -Level Info
        return $true
    }

    Update-PathEnvironment

    if (-not (Test-CommandExists "code")) {
        Write-Log "VS Code CLI not found. Extensions will need manual installation." -Level Warning
        return $false
    }

    foreach ($extensionId in $Script:Config.VSCodeExtensions) {
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

    if ($SkipAITools) {
        Write-Log "Skipping Claude Code (user requested)." -Level Info
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

    # Check if Docker is available for Redis container
    if ((Test-CommandExists "docker") -and -not $SkipDocker) {
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

    # Chocolatey fallback
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

# ============================================================================
# SUMMARY AND REPORTING
# ============================================================================

function Show-Summary {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    VIBE DEV INSTALLATION SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    if ($Script:Config.InstalledItems.Count -gt 0) {
        Write-Host "INSTALLED ($($Script:Config.InstalledItems.Count)):" -ForegroundColor Green
        foreach ($item in $Script:Config.InstalledItems) {
            Write-Host "  [+] $item" -ForegroundColor Green
        }
        Write-Host ""
    }

    if ($Script:Config.SkippedItems.Count -gt 0) {
        Write-Host "ALREADY INSTALLED ($($Script:Config.SkippedItems.Count)):" -ForegroundColor Cyan
        foreach ($item in $Script:Config.SkippedItems) {
            Write-Host "  [=] $item" -ForegroundColor Cyan
        }
        Write-Host ""
    }

    if ($Script:Config.FailedItems.Count -gt 0) {
        Write-Host "FAILED ($($Script:Config.FailedItems.Count)):" -ForegroundColor Red
        foreach ($item in $Script:Config.FailedItems) {
            Write-Host "  [-] $item" -ForegroundColor Red
        }
        Write-Host ""
    }

    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Log file: $LogPath" -ForegroundColor Gray
    Write-Host ""

    if ($Script:Config.RequiresReboot) {
        Write-Host "IMPORTANT: A system reboot is required!" -ForegroundColor Yellow
        Write-Host ""

        if (-not $NoReboot -and -not $Silent) {
            $reboot = Read-Host "Reboot now? (y/N)"
            if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                Write-Host "Rebooting in 10 seconds... Press Ctrl+C to cancel." -ForegroundColor Yellow
                Start-Sleep -Seconds 10
                Restart-Computer -Force
            }
        }
    }

    Write-Host "Setup complete! Open a new terminal to use installed tools." -ForegroundColor Green
}

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

function Start-VibeDev-Installation {
    # Header
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "  ║                                                           ║" -ForegroundColor Magenta
    Write-Host "  ║   VIBE DEVELOPMENT ENVIRONMENT SETUP                      ║" -ForegroundColor Magenta
    Write-Host "  ║   Windows 11 22H2+ Ultimate Developer Toolkit             ║" -ForegroundColor Magenta
    Write-Host "  ║                                                           ║" -ForegroundColor Magenta
    Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""

    # Initialize log
    "=" * 60 | Out-File $LogPath
    "Vibe Dev Installation - $(Get-Date)" | Out-File $LogPath -Append
    "=" * 60 | Out-File $LogPath -Append

    # Phase 1: Prerequisites
    Write-Log "Phase 1: Checking Prerequisites" -Level Header

    if (-not (Test-AdminElevation)) {
        Write-Host ""
        Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        Write-Host "Then run this script again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    Write-Log "Administrator check passed." -Level Success

    Test-WindowsVersion

    # Check WinGet
    if (-not (Test-CommandExists "winget")) {
        Write-Log "WinGet not found. Please update Windows or install App Installer from Microsoft Store." -Level Error
        exit 1
    }
    Write-Log "WinGet is available." -Level Success

    # Phase 2: Package Managers
    Install-Chocolatey

    # Phase 3: Core Tools
    Write-Log "Phase 3: Core Development Tools" -Level Header
    Install-Package -PackageId $Script:Config.Packages.Git -DisplayName "Git" -ChocolateyFallback $Script:Config.ChocoFallback.Git
    Install-Package -PackageId $Script:Config.Packages.WindowsTerminal -DisplayName "Windows Terminal"

    # Phase 4: Runtime Environments
    Write-Log "Phase 4: Runtime Environments" -Level Header

    if (-not $SkipPython) {
        Install-Package -PackageId $Script:Config.Packages.Python -DisplayName "Python 3.12" -ChocolateyFallback $Script:Config.ChocoFallback.Python
    }

    Install-NodeJS
    Install-JSPackageManagers

    # Phase 5: Containerization & Databases
    if (-not $SkipDocker) {
        Write-Log "Phase 5: Docker & Containerization" -Level Header
        Enable-WSL2
        Install-Package -PackageId $Script:Config.Packages.Docker -DisplayName "Docker Desktop" -ChocolateyFallback $Script:Config.ChocoFallback.Docker
    }

    if (-not $SkipDatabases) {
        Write-Log "Phase 6: Databases" -Level Header
        Install-Package -PackageId $Script:Config.Packages.PostgreSQL -DisplayName "PostgreSQL 16" -ChocolateyFallback $Script:Config.ChocoFallback.PostgreSQL
        Install-Package -PackageId $Script:Config.Packages.MongoDB -DisplayName "MongoDB" -ChocolateyFallback $Script:Config.ChocoFallback.MongoDB
        Install-Redis
    }

    # Phase 6: AI Coding Tools
    if (-not $SkipAITools) {
        Write-Log "Phase 7: AI Coding Tools" -Level Header
        Install-Package -PackageId $Script:Config.Packages.VSCode -DisplayName "VS Code" -ChocolateyFallback $Script:Config.ChocoFallback.VSCode

        Update-PathEnvironment
        Start-Sleep -Seconds 2  # Give VS Code time to register

        Install-VSCodeExtensions
        Install-Package -PackageId $Script:Config.Packages.Cursor -DisplayName "Cursor IDE"
        Install-ClaudeCode
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
    Start-VibeDev-Installation
}
catch {
    Write-Host ""
    Write-Host "FATAL ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the log file: $LogPath" -ForegroundColor Yellow
    exit 1
}
