<#
.SYNOPSIS
    DevBox Factory Health Check - Verify installation and environment

.DESCRIPTION
    Runs comprehensive health checks to verify:
    - Core tools installation (Git, VS Code, Terminal)
    - AI tools (Claude Code, Cursor)
    - Development runtimes (Node.js, Python, .NET)
    - Containerization (Docker, WSL2)
    - Hyper-V and VM capabilities
    - Network connectivity

.EXAMPLE
    .\Test-DevBoxHealth.ps1
    .\Test-DevBoxHealth.ps1 -Verbose
    .\Test-DevBoxHealth.ps1 -Category Core,AI

.NOTES
    DevBox Factory v2.0.0
    https://github.com/velocityeu/devbox-factory
#>

[CmdletBinding()]
param(
    [ValidateSet('All', 'Core', 'AI', 'Runtimes', 'Docker', 'HyperV', 'Network')]
    [string[]]$Category = @('All')
)

$Script:Version = "2.0.0"
$Script:Build = "20260104.002"
$Script:PassCount = 0
$Script:FailCount = 0
$Script:WarnCount = 0

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
    Write-Host "  |  HEALTH CHECK            Verify Installation and Environment        |" -ForegroundColor White
    Write-Host "  |  by Velocity EU                           v$Script:Version build $Script:Build  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Test-Command {
    param(
        [string]$Name,
        [string]$Command,
        [string]$MinVersion = $null
    )

    Write-Host "  Checking $Name... " -NoNewline

    try {
        $result = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            $version = if ($result -match '[\d]+\.[\d]+\.?[\d]*') { $Matches[0] } else { "OK" }
            Write-Host "[PASS] " -ForegroundColor Green -NoNewline
            Write-Host $version -ForegroundColor DarkGray
            $Script:PassCount++
            return $true
        } else {
            Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
            Write-Host "Command failed" -ForegroundColor DarkGray
            $Script:FailCount++
            return $false
        }
    } catch {
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
        Write-Host "Not found" -ForegroundColor DarkGray
        $Script:FailCount++
        return $false
    }
}

function Test-Path-Exists {
    param(
        [string]$Name,
        [string]$Path
    )

    Write-Host "  Checking $Name... " -NoNewline

    if (Test-Path $Path) {
        Write-Host "[PASS] " -ForegroundColor Green -NoNewline
        Write-Host $Path -ForegroundColor DarkGray
        $Script:PassCount++
        return $true
    } else {
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
        Write-Host "Not found" -ForegroundColor DarkGray
        $Script:FailCount++
        return $false
    }
}

function Test-Service {
    param(
        [string]$Name,
        [string]$ServiceName
    )

    Write-Host "  Checking $Name... " -NoNewline

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-Host "[PASS] " -ForegroundColor Green -NoNewline
            Write-Host "Running" -ForegroundColor DarkGray
            $Script:PassCount++
            return $true
        } elseif ($service) {
            Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
            Write-Host $service.Status -ForegroundColor DarkGray
            $Script:WarnCount++
            return $true
        } else {
            Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
            Write-Host "Not installed" -ForegroundColor DarkGray
            $Script:FailCount++
            return $false
        }
    } catch {
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
        Write-Host "Error checking service" -ForegroundColor DarkGray
        $Script:FailCount++
        return $false
    }
}

function Test-CoreTools {
    Write-Host ""
    Write-Host "  CORE TOOLS" -ForegroundColor Cyan
    Write-Host "  ----------" -ForegroundColor DarkGray

    $null = Test-Command -Name "Git" -Command "git --version"
    $null = Test-Command -Name "VS Code" -Command "code --version"
    $null = Test-Path-Exists -Name "Windows Terminal" -Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
    $null = Test-Command -Name "PowerShell 7" -Command "pwsh --version"
}

function Test-AITools {
    Write-Host ""
    Write-Host "  AI CODING TOOLS" -ForegroundColor Cyan
    Write-Host "  ----------------" -ForegroundColor DarkGray

    $null = Test-Command -Name "Claude Code" -Command "claude --version"
    $null = Test-Path-Exists -Name "Cursor IDE" -Path "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe"

    # Check VS Code extensions
    Write-Host "  Checking VS Code AI extensions... " -NoNewline
    try {
        $extensions = code --list-extensions 2>&1
        $aiExtensions = @('github.copilot', 'continue.continue', 'saoudrizwan.claude-dev')
        $found = ($aiExtensions | Where-Object { $extensions -match $_ }).Count
        if ($found -gt 0) {
            Write-Host "[PASS] " -ForegroundColor Green -NoNewline
            Write-Host "$found AI extension(s)" -ForegroundColor DarkGray
            $Script:PassCount++
        } else {
            Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
            Write-Host "No AI extensions" -ForegroundColor DarkGray
            $Script:WarnCount++
        }
    } catch {
        Write-Host "[SKIP] " -ForegroundColor DarkGray -NoNewline
        Write-Host "VS Code not available" -ForegroundColor DarkGray
    }
}

function Test-Runtimes {
    Write-Host ""
    Write-Host "  DEVELOPMENT RUNTIMES" -ForegroundColor Cyan
    Write-Host "  ---------------------" -ForegroundColor DarkGray

    $null = Test-Command -Name "Node.js" -Command "node --version"
    $null = Test-Command -Name "npm" -Command "npm --version"
    $null = Test-Command -Name "Python" -Command "python --version"
    $null = Test-Command -Name "pip" -Command "pip --version"
    $null = Test-Command -Name ".NET SDK" -Command "dotnet --version"
    $null = Test-Command -Name "pnpm" -Command "pnpm --version"
}

function Test-Docker {
    Write-Host ""
    Write-Host "  CONTAINERIZATION" -ForegroundColor Cyan
    Write-Host "  -----------------" -ForegroundColor DarkGray

    $null = Test-Command -Name "Docker" -Command "docker --version"
    $null = Test-Command -Name "Docker Compose" -Command "docker compose version"
    $null = Test-Command -Name "WSL" -Command "wsl --version"
    $null = Test-Service -Name "Docker Desktop Service" -ServiceName "com.docker.service"
}

function Test-HyperV {
    Write-Host ""
    Write-Host "  HYPER-V / VM SUPPORT" -ForegroundColor Cyan
    Write-Host "  ---------------------" -ForegroundColor DarkGray

    # Check Hyper-V feature
    Write-Host "  Checking Hyper-V... " -NoNewline
    try {
        $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
        if ($hyperv -and $hyperv.State -eq 'Enabled') {
            Write-Host "[PASS] " -ForegroundColor Green -NoNewline
            Write-Host "Enabled" -ForegroundColor DarkGray
            $Script:PassCount++
        } else {
            Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
            Write-Host "Not enabled" -ForegroundColor DarkGray
            $Script:FailCount++
        }
    } catch {
        Write-Host "[SKIP] " -ForegroundColor DarkGray -NoNewline
        Write-Host "Requires admin" -ForegroundColor DarkGray
    }

    $null = Test-Service -Name "Hyper-V VM Management" -ServiceName "vmms"
    $null = Test-Path-Exists -Name "DevBox Templates" -Path "C:\HyperV\Templates"
    $null = Test-Path-Exists -Name "DevBox VMs" -Path "C:\HyperV\VMs"
}

function Test-Network {
    Write-Host ""
    Write-Host "  NETWORK CONNECTIVITY" -ForegroundColor Cyan
    Write-Host "  ---------------------" -ForegroundColor DarkGray

    # Test GitHub
    Write-Host "  Checking GitHub access... " -NoNewline
    try {
        $response = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "[PASS] " -ForegroundColor Green -NoNewline
            Write-Host "Connected" -ForegroundColor DarkGray
            $Script:PassCount++
        }
    } catch {
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
        Write-Host "Cannot reach GitHub" -ForegroundColor DarkGray
        $Script:FailCount++
    }

    # Test npm registry
    Write-Host "  Checking npm registry... " -NoNewline
    try {
        $response = Invoke-WebRequest -Uri "https://registry.npmjs.org" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "[PASS] " -ForegroundColor Green -NoNewline
            Write-Host "Connected" -ForegroundColor DarkGray
            $Script:PassCount++
        }
    } catch {
        Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
        Write-Host "Cannot reach npm" -ForegroundColor DarkGray
        $Script:WarnCount++
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "  +=================================================================+" -ForegroundColor Magenta
    Write-Host "  |                          SUMMARY                                |" -ForegroundColor Magenta
    Write-Host "  +=================================================================+" -ForegroundColor Magenta
    Write-Host ""

    $total = $Script:PassCount + $Script:FailCount + $Script:WarnCount

    Write-Host "  Results: " -NoNewline
    Write-Host "$Script:PassCount passed" -ForegroundColor Green -NoNewline
    Write-Host ", " -NoNewline
    Write-Host "$Script:WarnCount warnings" -ForegroundColor Yellow -NoNewline
    Write-Host ", " -NoNewline
    Write-Host "$Script:FailCount failed" -ForegroundColor Red -NoNewline
    Write-Host " (of $total checks)" -ForegroundColor DarkGray

    Write-Host ""
    if ($Script:FailCount -eq 0) {
        Write-Host "  [OK] " -ForegroundColor Green -NoNewline
        Write-Host "DevBox environment is healthy!" -ForegroundColor White
    } elseif ($Script:FailCount -le 3) {
        Write-Host "  [WARN] " -ForegroundColor Yellow -NoNewline
        Write-Host "Some components missing. Run '.\devbox install' to fix." -ForegroundColor White
    } else {
        Write-Host "  [ERROR] " -ForegroundColor Red -NoNewline
        Write-Host "Multiple issues detected. Run '.\devbox install' to setup." -ForegroundColor White
    }
    Write-Host ""
}

# Main
Show-Banner

$runAll = $Category -contains 'All'

if ($runAll -or $Category -contains 'Core') { Test-CoreTools }
if ($runAll -or $Category -contains 'AI') { Test-AITools }
if ($runAll -or $Category -contains 'Runtimes') { Test-Runtimes }
if ($runAll -or $Category -contains 'Docker') { Test-Docker }
if ($runAll -or $Category -contains 'HyperV') { Test-HyperV }
if ($runAll -or $Category -contains 'Network') { Test-Network }

Show-Summary
