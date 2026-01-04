<#
.SYNOPSIS
    Creates development VMs from the DevBox Windows 11 template.

.DESCRIPTION
    Stage 2 of DevBox VM automation. This script:
    1. Clones the sysprepped Windows 11 template VHDX
    2. Injects computer name and configuration
    3. Optionally copies DevBox installation scripts
    4. Creates a Gen2 VM with TPM and Secure Boot
    5. Starts the VM with chosen installation mode

.PARAMETER VMName
    Name for the new VM (required)

.PARAMETER TemplatePath
    Path to the template VHDX file. Default: C:\HyperV\Templates\Win11-DevBox-Template.vhdx

.PARAMETER VMPath
    Directory to store VM files. Default: C:\HyperV\VMs

.PARAMETER MemoryGB
    Memory allocation for VM. Default: 8

.PARAMETER ProcessorCount
    CPU cores for VM. Default: 4

.PARAMETER DiskSizeGB
    Expand disk to this size (must be >= template). Default: 127

.PARAMETER DynamicMemory
    Enable dynamic memory allocation

.PARAMETER SwitchName
    Hyper-V virtual switch name. Default: Default Switch

.PARAMETER InstallMode
    DevBox installation mode:
    - Automatic: Auto-login and run Install-DevBox.ps1 silently
    - SemiAutomatic: Auto-login with desktop shortcut for installer
    - Manual: Just create VM, no auto-install

.PARAMETER DevBoxProfile
    DevBox installation profile: Full, AICoder, WebDev, Azure, Minimal

.PARAMETER Count
    Number of VMs to create. Default: 1

.PARAMETER NamePattern
    Naming pattern for multiple VMs. Default: "-{0:D2}" (e.g., DevVM-01, DevVM-02)

.PARAMETER StartVM
    Start the VM after creation

.PARAMETER AdminPassword
    Secure password for local Admin account

.EXAMPLE
    .\New-DevBoxVM.ps1 -VMName "DevVM-01" -StartVM

.EXAMPLE
    .\New-DevBoxVM.ps1 -VMName "AI-Dev" -InstallMode Automatic -DevBoxProfile AICoder -StartVM

.EXAMPLE
    .\New-DevBoxVM.ps1 -VMName "TeamDev" -Count 5 -MemoryGB 16 -StartVM

.NOTES
    Requires: DevBox template created by New-DevBoxTemplate.ps1
    Author: DevBox Factory Team
    Version: 2.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VMName,

    [string]$TemplatePath = "C:\HyperV\Templates\Win11-DevBox-Template.vhdx",
    [string]$VMPath = "C:\HyperV\VMs",

    [ValidateRange(4, 64)]
    [int]$MemoryGB = 8,

    [ValidateRange(2, 32)]
    [int]$ProcessorCount = 4,

    [ValidateRange(40, 2048)]
    [int]$DiskSizeGB = 127,

    [switch]$DynamicMemory,

    [string]$SwitchName = "Default Switch",

    [ValidateSet("Automatic", "SemiAutomatic", "Manual")]
    [string]$InstallMode = "Automatic",

    [ValidateSet("Full", "AICoder", "WebDev", "Azure", "Minimal")]
    [string]$DevBoxProfile = "Full",

    [ValidateRange(1, 100)]
    [int]$Count = 1,

    [string]$NamePattern = "-{0:D2}",

    [switch]$StartVM,

    [SecureString]$AdminPassword
)

#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Version Information
$Script:DevBoxVersion = @{
    Major = 2
    Minor = 0
    Patch = 0
    BuildDate = "2026-01-04"
    BuildNumber = "20260104.002"
}

# Script-level variables
$Script:LogPath = Join-Path $env:USERPROFILE "DevBox-VM.log"
$Script:ScriptRoot = $PSScriptRoot
$Script:ParentRoot = Split-Path $PSScriptRoot -Parent
$Script:InstallDevBoxPath = Join-Path $Script:ParentRoot "Install-DevBox.ps1"
$Script:PresetsPath = Join-Path $PSScriptRoot "Presets.json"
$Script:CreatedVMs = @()
$Script:Presets = $null

# Load presets if available
if (Test-Path $Script:PresetsPath) {
    try {
        $Script:Presets = Get-Content $Script:PresetsPath -Raw | ConvertFrom-Json
    } catch {
        $Script:Presets = $null
    }
}

function Get-VersionString {
    return "v$($Script:DevBoxVersion.Major).$($Script:DevBoxVersion.Minor).$($Script:DevBoxVersion.Patch)"
}

#region Logging Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "Info"    { "[INFO]   " }
        "Success" { "[OK]     " }
        "Warning" { "[WARN]   " }
        "Error"   { "[ERROR]  " }
        "Header"  { "[======] " }
    }

    $logMessage = "$timestamp $prefix$Message"
    Add-Content -Path $Script:LogPath -Value $logMessage

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

function Show-Banner {
    $version = Get-VersionString
    $build = $Script:DevBoxVersion.BuildNumber
    Clear-Host
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
    Write-Host "  VM CREATOR" -ForegroundColor White -NoNewline
    Write-Host "              Create Dev VMs from Template - Stage 2" -ForegroundColor DarkGray -NoNewline
    Write-Host "  ║" -ForegroundColor DarkCyan
    Write-Host "  ║" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  by Velocity EU" -ForegroundColor DarkGray -NoNewline
    Write-Host "                            $version " -ForegroundColor DarkGray -NoNewline
    Write-Host "build $build" -ForegroundColor DarkYellow -NoNewline
    Write-Host "  ║" -ForegroundColor DarkCyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
}

#endregion

#region Interactive Menus

Add-Type -AssemblyName System.Windows.Forms

function Show-VHDXFilePicker {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "VHDX Files (*.vhdx)|*.vhdx|All Files (*.*)|*.*"
    $dialog.Title = "Select DevBox Template VHDX"
    $dialog.InitialDirectory = "C:\HyperV\Templates"

    if (Test-Path "C:\HyperV\Templates") {
        $dialog.InitialDirectory = "C:\HyperV\Templates"
    } elseif (Test-Path $env:USERPROFILE) {
        $dialog.InitialDirectory = $env:USERPROFILE
    }

    if ($dialog.ShowDialog() -eq 'OK') {
        return $dialog.FileName
    }
    return $null
}

function Show-FolderPicker {
    param([string]$Description = "Select folder")
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq 'OK') {
        return $dialog.SelectedPath
    }
    return $null
}

function Find-TemplateFiles {
    param([string[]]$SearchPaths = @("C:\HyperV\Templates", "D:\HyperV\Templates", "E:\HyperV\Templates"))

    $templates = @()
    foreach ($path in $SearchPaths) {
        if (Test-Path $path) {
            $vhdxFiles = Get-ChildItem -Path $path -Filter "*.vhdx" -File -ErrorAction SilentlyContinue
            foreach ($file in $vhdxFiles) {
                $vhd = Get-VHD -Path $file.FullName -ErrorAction SilentlyContinue
                $templates += @{
                    Path = $file.FullName
                    Name = $file.Name
                    SizeGB = [math]::Round($file.Length / 1GB, 2)
                    Created = $file.CreationTime
                    VirtualSizeGB = if ($vhd) { [math]::Round($vhd.Size / 1GB, 0) } else { 0 }
                }
            }
        }
    }
    return $templates
}

function Test-TemplateFile {
    param([string]$Path)

    $result = @{
        IsValid = $false
        Path = $Path
        Exists = $false
        SizeGB = 0
        VirtualSizeGB = 0
        Errors = @()
    }

    # Check file exists
    if (-not (Test-Path $Path)) {
        $result.Errors += "File does not exist"
        return $result
    }
    $result.Exists = $true

    # Check extension
    if (-not $Path.ToLower().EndsWith(".vhdx")) {
        $result.Errors += "File is not a VHDX file"
        return $result
    }

    # Check file size
    $fileInfo = Get-Item $Path
    $result.SizeGB = [math]::Round($fileInfo.Length / 1GB, 2)

    if ($fileInfo.Length -lt 5GB) {
        $result.Errors += "File seems too small for a Windows template (< 5GB)"
    }

    # Try to get VHD info
    try {
        $vhd = Get-VHD -Path $Path -ErrorAction Stop
        $result.VirtualSizeGB = [math]::Round($vhd.Size / 1GB, 0)
    } catch {
        $result.Errors += "Unable to read VHDX properties"
        return $result
    }

    if ($result.Errors.Count -eq 0) {
        $result.IsValid = $true
    }

    return $result
}

function Show-TemplateValidation {
    param($ValidationResult)

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  TEMPLATE VALIDATION                      |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $fileName = Split-Path $ValidationResult.Path -Leaf
    Write-Host "   File: " -NoNewline -ForegroundColor White
    Write-Host $fileName -ForegroundColor Yellow
    Write-Host "   Size: " -NoNewline -ForegroundColor White
    Write-Host "$($ValidationResult.SizeGB) GB (actual) / $($ValidationResult.VirtualSizeGB) GB (virtual)" -ForegroundColor Yellow
    Write-Host "   Path: " -NoNewline -ForegroundColor White
    Write-Host $ValidationResult.Path -ForegroundColor DarkGray
    Write-Host ""

    if ($ValidationResult.Exists) {
        Write-Host "   [+] File exists" -ForegroundColor Green
    } else {
        Write-Host "   [-] File does not exist" -ForegroundColor Red
    }

    if ($ValidationResult.SizeGB -ge 5) {
        Write-Host "   [+] Size appropriate for Windows template" -ForegroundColor Green
    } else {
        Write-Host "   [-] File seems too small" -ForegroundColor Red
    }

    if ($ValidationResult.VirtualSizeGB -gt 0) {
        Write-Host "   [+] Valid VHDX format" -ForegroundColor Green
    } else {
        Write-Host "   [-] Unable to read VHDX properties" -ForegroundColor Red
    }

    Write-Host ""
    if ($ValidationResult.IsValid) {
        Write-Host "   Template validated successfully!" -ForegroundColor Green
    } else {
        Write-Host "   Template validation failed:" -ForegroundColor Red
        foreach ($err in $ValidationResult.Errors) {
            Write-Host "     - $err" -ForegroundColor Red
        }
    }

    Write-Host ""
    Read-Host "  Press Enter to continue"
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                    MAIN MENU                              |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Quick Create (Single VM)" -ForegroundColor White
    Write-Host "       Fast VM creation with defaults" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Batch Create (Multiple VMs)" -ForegroundColor White
    Write-Host "       Create team/lab VMs with naming pattern" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Custom Configuration" -ForegroundColor White
    Write-Host "       Full control over all settings" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [4] " -ForegroundColor Yellow -NoNewline
    Write-Host "List Existing VMs" -ForegroundColor White
    Write-Host "       View and manage DevBox VMs" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [Q] " -ForegroundColor Red -NoNewline
    Write-Host "Quit" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Enter your choice"
    return $choice
}

function Show-TemplateSelectionMenu {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                 TEMPLATE SELECTION                        |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Browse for template file (Opens file picker)" -ForegroundColor White
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Enter path manually" -ForegroundColor White
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Scan for templates" -ForegroundColor White
    Write-Host "       Searches: C:\HyperV\Templates, D:\, E:\" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [B] " -ForegroundColor DarkYellow -NoNewline
    Write-Host "Back to main menu" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Enter your choice"
    return $choice
}

function Show-TemplateScanResults {
    param($Templates)

    if ($Templates.Count -eq 0) {
        Write-Host ""
        Write-Host "  No VHDX templates found in common locations." -ForegroundColor Yellow
        Write-Host "  Run New-DevBoxTemplate.ps1 to create one first." -ForegroundColor DarkGray
        Write-Host ""
        Read-Host "  Press Enter to continue"
        return $null
    }

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                   FOUND TEMPLATES                         |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $i = 1
    foreach ($template in $Templates) {
        $sizeStr = "$($template.SizeGB) GB"
        $dateStr = $template.Created.ToString("yyyy-MM-dd")
        Write-Host "   [$i] " -ForegroundColor Yellow -NoNewline
        Write-Host $template.Name -ForegroundColor White
        Write-Host "       Created: $dateStr | Size: $sizeStr | Virtual: $($template.VirtualSizeGB) GB" -ForegroundColor DarkGray
        Write-Host ""
        $i++
    }

    Write-Host "   [B] " -ForegroundColor DarkYellow -NoNewline
    Write-Host "Back" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Select template"

    if ($choice.ToUpper() -eq 'B') { return $null }

    $index = 0
    if ([int]::TryParse($choice, [ref]$index) -and $index -ge 1 -and $index -le $Templates.Count) {
        return $Templates[$index - 1].Path
    }

    return $null
}

function Show-ProfileSelectionMenu {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  VIBEDEV PROFILE                          |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Full Installation              " -ForegroundColor White -NoNewline
    Write-Host "* Recommended" -ForegroundColor Green
    Write-Host "       AI tools, Web dev, Azure, Docker, Databases" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "AI Vibe Coder" -ForegroundColor White
    Write-Host "       Claude Code, Cursor, VS Code + AI, Node.js, Python" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Full-Stack Web Developer" -ForegroundColor White
    Write-Host "       Node.js, Python, Docker, PostgreSQL, MongoDB, Redis" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [4] " -ForegroundColor Yellow -NoNewline
    Write-Host "Azure Cloud Developer" -ForegroundColor White
    Write-Host "       Azure CLI, Functions, .NET, Terraform, Bicep" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [5] " -ForegroundColor Yellow -NoNewline
    Write-Host "Minimal" -ForegroundColor White
    Write-Host "       Git, Windows Terminal, VS Code only" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [N] " -ForegroundColor DarkYellow -NoNewline
    Write-Host "None - skip DevBox installation" -ForegroundColor White
    Write-Host ""
    Write-Host "   [B] " -ForegroundColor DarkYellow -NoNewline
    Write-Host "Back" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Enter choice [1]"
    if ([string]::IsNullOrEmpty($choice)) { $choice = "1" }
    return $choice
}

function Show-InstallModeMenu {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  INSTALL MODE                             |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Automatic                      " -ForegroundColor White -NoNewline
    Write-Host "* Recommended" -ForegroundColor Green
    Write-Host "       Auto-login and install DevBox silently on first boot" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Semi-Automatic" -ForegroundColor White
    Write-Host "       Auto-login with desktop shortcut for installer" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Manual" -ForegroundColor White
    Write-Host "       Just create VM, no auto-install" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [B] " -ForegroundColor DarkYellow -NoNewline
    Write-Host "Back" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Enter choice [1]"
    if ([string]::IsNullOrEmpty($choice)) { $choice = "1" }
    return $choice
}

function Show-VMPresetMenu {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  VM SPECIFICATIONS                        |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Lightweight    4GB RAM,  2 CPUs,  80GB disk" -ForegroundColor White
    Write-Host "       Basic development, minimal resources" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Standard       8GB RAM,  4 CPUs, 127GB disk  " -ForegroundColor White -NoNewline
    Write-Host "* Default" -ForegroundColor Green
    Write-Host "       Typical development workload" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Performance   16GB RAM,  8 CPUs, 256GB disk" -ForegroundColor White
    Write-Host "       Heavy workloads, multiple IDEs" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [4] " -ForegroundColor Yellow -NoNewline
    Write-Host "Server-class  32GB RAM, 16 CPUs, 512GB disk" -ForegroundColor White
    Write-Host "       Database servers, enterprise apps" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [C] " -ForegroundColor Yellow -NoNewline
    Write-Host "Custom - enter your own values" -ForegroundColor White
    Write-Host ""
    Write-Host "   [B] " -ForegroundColor DarkYellow -NoNewline
    Write-Host "Back" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Enter choice [2]"
    if ([string]::IsNullOrEmpty($choice)) { $choice = "2" }
    return $choice
}

function Get-PresetValues {
    param([string]$PresetName)

    $presets = @{
        'Lightweight' = @{ MemoryGB = 4; ProcessorCount = 2; DiskSizeGB = 80 }
        'Standard' = @{ MemoryGB = 8; ProcessorCount = 4; DiskSizeGB = 127 }
        'Performance' = @{ MemoryGB = 16; ProcessorCount = 8; DiskSizeGB = 256 }
        'ServerClass' = @{ MemoryGB = 32; ProcessorCount = 16; DiskSizeGB = 512 }
    }

    if ($presets.ContainsKey($PresetName)) {
        return $presets[$PresetName]
    }
    return $presets['Standard']
}

function Show-CustomSpecsPrompt {
    Write-Host ""
    Write-Host "  Enter custom VM specifications:" -ForegroundColor Cyan
    Write-Host ""

    $memInput = Read-Host "  Memory (GB) [8]"
    $cpuInput = Read-Host "  CPUs [4]"
    $diskInput = Read-Host "  Disk Size (GB) [127]"

    $mem = if ([string]::IsNullOrEmpty($memInput)) { 8 } else { [int]$memInput }
    $cpu = if ([string]::IsNullOrEmpty($cpuInput)) { 4 } else { [int]$cpuInput }
    $disk = if ([string]::IsNullOrEmpty($diskInput)) { 127 } else { [int]$diskInput }

    return @{ MemoryGB = $mem; ProcessorCount = $cpu; DiskSizeGB = $disk }
}

function Show-VMNamingMenu {
    param(
        [string]$BaseName = "",
        [int]$Count = 1,
        [string]$Pattern = "-{0:D2}"
    )

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                      VM NAMING                            |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Base Name: " -NoNewline -ForegroundColor White
    Write-Host $BaseName -ForegroundColor Yellow
    Write-Host "  Count: " -NoNewline -ForegroundColor White
    Write-Host $Count -ForegroundColor Yellow
    Write-Host "  Pattern: " -NoNewline -ForegroundColor White
    Write-Host $Pattern -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Live Preview:" -ForegroundColor Cyan

    if ($Count -eq 1) {
        Write-Host "    > $BaseName" -ForegroundColor Green
    } else {
        $maxShow = [Math]::Min($Count, 5)
        for ($i = 1; $i -le $maxShow; $i++) {
            $vmName = $BaseName + ($Pattern -f $i)
            Write-Host "    > $vmName" -ForegroundColor Green
        }
        if ($Count -gt 5) {
            Write-Host "    ... and $($Count - 5) more" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "   [N] Change base name" -ForegroundColor Yellow
    Write-Host "   [C] Change count" -ForegroundColor Yellow
    Write-Host "   [P] Change pattern" -ForegroundColor Yellow
    Write-Host "   [A] Accept and continue" -ForegroundColor Green
    Write-Host "   [B] Back" -ForegroundColor DarkYellow
    Write-Host ""

    $choice = Read-Host "  Enter choice"
    return $choice
}

function Show-PreFlightChecks {
    param($Config)

    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Cyan
    Write-Host "  |                   PRE-FLIGHT CHECKS                       |" -ForegroundColor Cyan
    Write-Host "  +===========================================================+" -ForegroundColor Cyan
    Write-Host ""

    $allPassed = $true

    # Check Hyper-V
    $hypervOk = $false
    try {
        if (Get-Module -ListAvailable -Name Hyper-V) {
            Import-Module Hyper-V -ErrorAction SilentlyContinue
            $hypervOk = $true
        }
    } catch { }

    if ($hypervOk) {
        Write-Host "   [+] Hyper-V enabled and available" -ForegroundColor Green
    } else {
        Write-Host "   [-] Hyper-V not available" -ForegroundColor Red
        $allPassed = $false
    }

    # Check template
    if (Test-Path $Config.TemplatePath) {
        $templateFile = Get-Item $Config.TemplatePath
        $sizeGB = [math]::Round($templateFile.Length / 1GB, 1)
        Write-Host "   [+] Template exists: $(Split-Path $Config.TemplatePath -Leaf) ($sizeGB GB)" -ForegroundColor Green
    } else {
        Write-Host "   [-] Template not found: $($Config.TemplatePath)" -ForegroundColor Red
        $allPassed = $false
    }

    # Check virtual switch
    $switchOk = $false
    try {
        $switch = Get-VMSwitch -Name $Config.SwitchName -ErrorAction SilentlyContinue
        if ($null -ne $switch) { $switchOk = $true }
    } catch { }

    if ($switchOk) {
        Write-Host "   [+] Virtual switch available: $($Config.SwitchName)" -ForegroundColor Green
    } else {
        Write-Host "   [-] Virtual switch not found: $($Config.SwitchName)" -ForegroundColor Red
        $allPassed = $false
    }

    # Check disk space
    $vmDrive = Split-Path -Qualifier $Config.VMPath
    if ([string]::IsNullOrEmpty($vmDrive)) { $vmDrive = "C:" }
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$vmDrive'" -ErrorAction SilentlyContinue
    $requiredGB = $Config.DiskSizeGB * $Config.Count + 10
    $freeGB = if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 0) } else { 0 }

    if ($freeGB -ge $requiredGB) {
        Write-Host "   [+] Disk space: ${freeGB} GB free (need ${requiredGB} GB) OK" -ForegroundColor Green
    } else {
        Write-Host "   [-] Disk space: ${freeGB} GB free (need ${requiredGB} GB)" -ForegroundColor Red
        $allPassed = $false
    }

    # Check VM name conflicts
    $vmNames = if ($Config.Count -eq 1) { @($Config.VMName) } else {
        1..$Config.Count | ForEach-Object { $Config.VMName + ($Config.NamePattern -f $_) }
    }

    $conflicts = @()
    foreach ($name in $vmNames) {
        $existingVM = Get-VM -Name $name -ErrorAction SilentlyContinue
        if ($null -ne $existingVM) {
            $conflicts += $name
        }
    }

    if ($conflicts.Count -eq 0) {
        Write-Host "   [+] No VM name conflicts detected" -ForegroundColor Green
    } else {
        Write-Host "   [-] VM name conflict(s): $($conflicts -join ', ')" -ForegroundColor Red
        $allPassed = $false
    }

    # Check Install-DevBox.ps1
    if ($Config.InstallMode -ne "Manual") {
        if (Test-Path $Script:InstallDevBoxPath) {
            Write-Host "   [+] Install-DevBox.ps1 found (will copy to VM)" -ForegroundColor Green
        } else {
            Write-Host "   [!] Install-DevBox.ps1 not found (auto-install unavailable)" -ForegroundColor Yellow
        }
    }

    Write-Host ""

    $passedCount = if ($allPassed) { "All" } else { "Some" }
    if ($allPassed) {
        Write-Host "   $passedCount checks passed!" -ForegroundColor Green
    } else {
        Write-Host "   $passedCount checks failed. Please resolve issues before proceeding." -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Cyan
    Write-Host ""

    if ($allPassed) {
        $choice = Read-Host "  Press Enter to proceed or 'C' to cancel"
        return ($choice.ToUpper() -ne 'C')
    } else {
        Read-Host "  Press Enter to go back"
        return $false
    }
}

function Show-ConfigurationSummary {
    param($Config)

    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Magenta
    Write-Host "  |                 CONFIGURATION SUMMARY                     |" -ForegroundColor Magenta
    Write-Host "  +===========================================================+" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "   Template:" -ForegroundColor Cyan
    Write-Host "     Path: $($Config.TemplatePath)" -ForegroundColor White
    Write-Host ""

    Write-Host "   VM Settings:" -ForegroundColor Cyan
    if ($Config.Count -eq 1) {
        Write-Host "     Name: $($Config.VMName)" -ForegroundColor White
    } else {
        Write-Host "     Base Name: $($Config.VMName)" -ForegroundColor White
        Write-Host "     Count: $($Config.Count) VMs" -ForegroundColor White
        Write-Host "     Pattern: $($Config.NamePattern)" -ForegroundColor White
    }
    Write-Host "     Memory: $($Config.MemoryGB) GB" -ForegroundColor White
    Write-Host "     CPUs: $($Config.ProcessorCount) cores" -ForegroundColor White
    Write-Host "     Disk: $($Config.DiskSizeGB) GB" -ForegroundColor White
    Write-Host ""

    Write-Host "   DevBox Settings:" -ForegroundColor Cyan
    Write-Host "     Install Mode: $($Config.InstallMode)" -ForegroundColor White
    Write-Host "     Profile: $($Config.DevBoxProfile)" -ForegroundColor White
    Write-Host "     Start VM: $(if ($Config.StartVM) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host ""

    Write-Host "  +===========================================================+" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "   [P] " -ForegroundColor Green -NoNewline
    Write-Host "Proceed" -ForegroundColor White
    Write-Host "   [E] " -ForegroundColor Yellow -NoNewline
    Write-Host "Edit configuration" -ForegroundColor White
    Write-Host "   [C] " -ForegroundColor Red -NoNewline
    Write-Host "Cancel" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Enter choice"
    return $choice
}

function Show-ExistingVMs {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  EXISTING HYPER-V VMs                     |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    try {
        $vms = Get-VM | Sort-Object Name
        if ($vms.Count -eq 0) {
            Write-Host "   No VMs found." -ForegroundColor Yellow
        } else {
            Write-Host "   Name                          State        Memory    CPUs" -ForegroundColor DarkGray
            Write-Host "   ----                          -----        ------    ----" -ForegroundColor DarkGray
            foreach ($vm in $vms) {
                $stateColor = switch ($vm.State) {
                    "Running" { "Green" }
                    "Off" { "DarkGray" }
                    default { "Yellow" }
                }
                $memGB = if ($vm.MemoryAssigned) { [math]::Round($vm.MemoryAssigned / 1GB, 1) } else { "-" }
                $name = $vm.Name.PadRight(30).Substring(0, 30)
                $state = $vm.State.ToString().PadRight(12)
                Write-Host "   $name " -NoNewline -ForegroundColor White
                Write-Host "$state " -NoNewline -ForegroundColor $stateColor
                Write-Host "$memGB GB".PadRight(10) -NoNewline -ForegroundColor Cyan
                Write-Host "$($vm.ProcessorCount)" -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "   Error listing VMs: $_" -ForegroundColor Red
    }

    Write-Host ""
    Read-Host "  Press Enter to continue"
}

function Invoke-InteractiveMode {
    $config = @{
        VMName = ""
        TemplatePath = "C:\HyperV\Templates\Win11-DevBox-Template.vhdx"
        VMPath = "C:\HyperV\VMs"
        MemoryGB = 8
        ProcessorCount = 4
        DiskSizeGB = 127
        SwitchName = "Default Switch"
        InstallMode = "Automatic"
        DevBoxProfile = "Full"
        Count = 1
        NamePattern = "-{0:D2}"
        StartVM = $true
    }

    while ($true) {
        Show-Banner
        $mainChoice = Show-MainMenu

        switch ($mainChoice.ToUpper()) {
            'Q' {
                Write-Host ""
                Write-Log "User cancelled VM creation" -Level Warning
                return $null
            }
            '1' {
                # Quick Create - Single VM
                Show-Banner

                # Template selection
                $templateSelected = $false
                while (-not $templateSelected) {
                    $templateChoice = Show-TemplateSelectionMenu
                    switch ($templateChoice.ToUpper()) {
                        'B' { break }
                        '1' {
                            $templatePath = Show-VHDXFilePicker
                            if ($templatePath) {
                                $validation = Test-TemplateFile -Path $templatePath
                                Show-TemplateValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.TemplatePath = $templatePath
                                    $templateSelected = $true
                                }
                            }
                        }
                        '2' {
                            Write-Host ""
                            $manualPath = Read-Host "  Enter full path to template VHDX"
                            if ($manualPath) {
                                $validation = Test-TemplateFile -Path $manualPath
                                Show-TemplateValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.TemplatePath = $manualPath
                                    $templateSelected = $true
                                }
                            }
                        }
                        '3' {
                            $foundTemplates = Find-TemplateFiles
                            $selectedTemplate = Show-TemplateScanResults -Templates $foundTemplates
                            if ($selectedTemplate) {
                                $validation = Test-TemplateFile -Path $selectedTemplate
                                Show-TemplateValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.TemplatePath = $selectedTemplate
                                    $templateSelected = $true
                                }
                            }
                        }
                    }
                    if ($templateChoice.ToUpper() -eq 'B') { break }
                }

                if (-not $templateSelected) { continue }

                # VM Name
                Write-Host ""
                $vmName = Read-Host "  Enter VM name"
                if ([string]::IsNullOrEmpty($vmName)) { continue }
                $config.VMName = $vmName
                $config.Count = 1

                # Profile selection
                $profileChoice = Show-ProfileSelectionMenu
                switch ($profileChoice.ToUpper()) {
                    'B' { continue }
                    '1' { $config.DevBoxProfile = "Full"; $config.InstallMode = "Automatic" }
                    '2' { $config.DevBoxProfile = "AICoder"; $config.InstallMode = "Automatic" }
                    '3' { $config.DevBoxProfile = "WebDev"; $config.InstallMode = "Automatic" }
                    '4' { $config.DevBoxProfile = "Azure"; $config.InstallMode = "Automatic" }
                    '5' { $config.DevBoxProfile = "Minimal"; $config.InstallMode = "Automatic" }
                    'N' { $config.InstallMode = "Manual"; $config.DevBoxProfile = "Full" }
                    default { $config.DevBoxProfile = "Full"; $config.InstallMode = "Automatic" }
                }

                # Ask to start VM
                Write-Host ""
                $startChoice = Read-Host "  Start VM after creation? (Y/n)"
                $config.StartVM = ($startChoice.ToUpper() -ne 'N')

                # Pre-flight and confirmation
                Show-Banner
                if (Show-PreFlightChecks -Config $config) {
                    return $config
                }
            }
            '2' {
                # Batch Create - Multiple VMs
                Show-Banner

                # Template selection (same as quick create)
                $templateSelected = $false
                while (-not $templateSelected) {
                    $templateChoice = Show-TemplateSelectionMenu
                    switch ($templateChoice.ToUpper()) {
                        'B' { break }
                        '1' {
                            $templatePath = Show-VHDXFilePicker
                            if ($templatePath) {
                                $validation = Test-TemplateFile -Path $templatePath
                                Show-TemplateValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.TemplatePath = $templatePath
                                    $templateSelected = $true
                                }
                            }
                        }
                        '2' {
                            Write-Host ""
                            $manualPath = Read-Host "  Enter full path to template VHDX"
                            if ($manualPath) {
                                $validation = Test-TemplateFile -Path $manualPath
                                Show-TemplateValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.TemplatePath = $manualPath
                                    $templateSelected = $true
                                }
                            }
                        }
                        '3' {
                            $foundTemplates = Find-TemplateFiles
                            $selectedTemplate = Show-TemplateScanResults -Templates $foundTemplates
                            if ($selectedTemplate) {
                                $config.TemplatePath = $selectedTemplate
                                $templateSelected = $true
                            }
                        }
                    }
                    if ($templateChoice.ToUpper() -eq 'B') { break }
                }

                if (-not $templateSelected) { continue }

                # VM Naming with preview
                Write-Host ""
                $baseName = Read-Host "  Enter base name for VMs"
                if ([string]::IsNullOrEmpty($baseName)) { continue }
                $config.VMName = $baseName

                Write-Host ""
                $countInput = Read-Host "  How many VMs? [3]"
                $config.Count = if ([string]::IsNullOrEmpty($countInput)) { 3 } else { [int]$countInput }

                # Show naming preview loop
                $namingDone = $false
                while (-not $namingDone) {
                    Show-Banner
                    $namingChoice = Show-VMNamingMenu -BaseName $config.VMName -Count $config.Count -Pattern $config.NamePattern
                    switch ($namingChoice.ToUpper()) {
                        'N' {
                            $newName = Read-Host "  Enter new base name"
                            if (-not [string]::IsNullOrEmpty($newName)) { $config.VMName = $newName }
                        }
                        'C' {
                            $newCount = Read-Host "  Enter new count"
                            if (-not [string]::IsNullOrEmpty($newCount)) { $config.Count = [int]$newCount }
                        }
                        'P' {
                            Write-Host "  Pattern examples: -{0:D2} = -01, -02  |  -VM{0} = -VM1, -VM2" -ForegroundColor DarkGray
                            $newPattern = Read-Host "  Enter new pattern"
                            if (-not [string]::IsNullOrEmpty($newPattern)) { $config.NamePattern = $newPattern }
                        }
                        'A' { $namingDone = $true }
                        'B' { break }
                    }
                    if ($namingChoice.ToUpper() -eq 'B') { break }
                }

                if (-not $namingDone) { continue }

                # Profile and preset selection
                $profileChoice = Show-ProfileSelectionMenu
                switch ($profileChoice.ToUpper()) {
                    'B' { continue }
                    '1' { $config.DevBoxProfile = "Full"; $config.InstallMode = "Automatic" }
                    '2' { $config.DevBoxProfile = "AICoder"; $config.InstallMode = "Automatic" }
                    '3' { $config.DevBoxProfile = "WebDev"; $config.InstallMode = "Automatic" }
                    '4' { $config.DevBoxProfile = "Azure"; $config.InstallMode = "Automatic" }
                    '5' { $config.DevBoxProfile = "Minimal"; $config.InstallMode = "Automatic" }
                    'N' { $config.InstallMode = "Manual" }
                    default { $config.DevBoxProfile = "Full"; $config.InstallMode = "Automatic" }
                }

                # VM Preset
                $presetChoice = Show-VMPresetMenu
                switch ($presetChoice.ToUpper()) {
                    'B' { continue }
                    '1' { $specs = Get-PresetValues -PresetName 'Lightweight' }
                    '2' { $specs = Get-PresetValues -PresetName 'Standard' }
                    '3' { $specs = Get-PresetValues -PresetName 'Performance' }
                    '4' { $specs = Get-PresetValues -PresetName 'ServerClass' }
                    'C' { $specs = Show-CustomSpecsPrompt }
                    default { $specs = Get-PresetValues -PresetName 'Standard' }
                }
                $config.MemoryGB = $specs.MemoryGB
                $config.ProcessorCount = $specs.ProcessorCount
                $config.DiskSizeGB = $specs.DiskSizeGB

                # Start VMs?
                Write-Host ""
                $startChoice = Read-Host "  Start VMs after creation? (Y/n)"
                $config.StartVM = ($startChoice.ToUpper() -ne 'N')

                # Pre-flight and confirmation
                Show-Banner
                if (Show-PreFlightChecks -Config $config) {
                    return $config
                }
            }
            '3' {
                # Custom Configuration - Full control
                Show-Banner

                # Template selection
                $templateSelected = $false
                while (-not $templateSelected) {
                    $templateChoice = Show-TemplateSelectionMenu
                    switch ($templateChoice.ToUpper()) {
                        'B' { break }
                        '1' {
                            $templatePath = Show-VHDXFilePicker
                            if ($templatePath) {
                                $validation = Test-TemplateFile -Path $templatePath
                                Show-TemplateValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.TemplatePath = $templatePath
                                    $templateSelected = $true
                                }
                            }
                        }
                        '2' {
                            Write-Host ""
                            $manualPath = Read-Host "  Enter full path to template VHDX"
                            if ($manualPath) {
                                $validation = Test-TemplateFile -Path $manualPath
                                Show-TemplateValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.TemplatePath = $manualPath
                                    $templateSelected = $true
                                }
                            }
                        }
                        '3' {
                            $foundTemplates = Find-TemplateFiles
                            $selectedTemplate = Show-TemplateScanResults -Templates $foundTemplates
                            if ($selectedTemplate) {
                                $config.TemplatePath = $selectedTemplate
                                $templateSelected = $true
                            }
                        }
                    }
                    if ($templateChoice.ToUpper() -eq 'B') { break }
                }

                if (-not $templateSelected) { continue }

                # VM Name and Count
                Write-Host ""
                $vmName = Read-Host "  Enter VM name (or base name for multiple)"
                if ([string]::IsNullOrEmpty($vmName)) { continue }
                $config.VMName = $vmName

                Write-Host ""
                $countInput = Read-Host "  Number of VMs [1]"
                $config.Count = if ([string]::IsNullOrEmpty($countInput)) { 1 } else { [int]$countInput }

                if ($config.Count -gt 1) {
                    $patternInput = Read-Host "  Naming pattern [-{0:D2}]"
                    if (-not [string]::IsNullOrEmpty($patternInput)) { $config.NamePattern = $patternInput }
                }

                # VM Preset
                $presetChoice = Show-VMPresetMenu
                switch ($presetChoice.ToUpper()) {
                    'B' { continue }
                    '1' { $specs = Get-PresetValues -PresetName 'Lightweight' }
                    '2' { $specs = Get-PresetValues -PresetName 'Standard' }
                    '3' { $specs = Get-PresetValues -PresetName 'Performance' }
                    '4' { $specs = Get-PresetValues -PresetName 'ServerClass' }
                    'C' { $specs = Show-CustomSpecsPrompt }
                    default { $specs = Get-PresetValues -PresetName 'Standard' }
                }
                $config.MemoryGB = $specs.MemoryGB
                $config.ProcessorCount = $specs.ProcessorCount
                $config.DiskSizeGB = $specs.DiskSizeGB

                # Install Mode
                $modeChoice = Show-InstallModeMenu
                switch ($modeChoice.ToUpper()) {
                    'B' { continue }
                    '1' { $config.InstallMode = "Automatic" }
                    '2' { $config.InstallMode = "SemiAutomatic" }
                    '3' { $config.InstallMode = "Manual" }
                    default { $config.InstallMode = "Automatic" }
                }

                # Profile selection (if not Manual)
                if ($config.InstallMode -ne "Manual") {
                    $profileChoice = Show-ProfileSelectionMenu
                    switch ($profileChoice.ToUpper()) {
                        'B' { continue }
                        '1' { $config.DevBoxProfile = "Full" }
                        '2' { $config.DevBoxProfile = "AICoder" }
                        '3' { $config.DevBoxProfile = "WebDev" }
                        '4' { $config.DevBoxProfile = "Azure" }
                        '5' { $config.DevBoxProfile = "Minimal" }
                        'N' { $config.InstallMode = "Manual" }
                        default { $config.DevBoxProfile = "Full" }
                    }
                }

                # Start VM?
                Write-Host ""
                $startChoice = Read-Host "  Start VM(s) after creation? (Y/n)"
                $config.StartVM = ($startChoice.ToUpper() -ne 'N')

                # Summary and confirmation
                Show-Banner
                $summaryChoice = Show-ConfigurationSummary -Config $config
                switch ($summaryChoice.ToUpper()) {
                    'P' {
                        if (Show-PreFlightChecks -Config $config) {
                            return $config
                        }
                    }
                    'E' { continue }
                    'C' { continue }
                }
            }
            '4' {
                Show-ExistingVMs
            }
        }
    }
}

#endregion

#region Validation

function Test-Prerequisites {
    Write-Log "Validating prerequisites..." -Level Header

    # Check Hyper-V
    if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
        throw "Hyper-V PowerShell module not available. Please run New-DevBoxTemplate.ps1 first."
    }
    Import-Module Hyper-V

    # Check template exists
    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath`nPlease run New-DevBoxTemplate.ps1 first."
    }
    Write-Log "Template found: $TemplatePath" -Level Success

    # Check virtual switch
    $switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if ($null -eq $switch) {
        throw "Virtual switch '$SwitchName' not found. Available switches: $((Get-VMSwitch).Name -join ', ')"
    }
    Write-Log "Virtual switch '$SwitchName' available" -Level Success

    # Check Install-DevBox.ps1 for non-Manual modes
    if ($InstallMode -ne "Manual") {
        if (-not (Test-Path $Script:InstallDevBoxPath)) {
            Write-Log "Install-DevBox.ps1 not found at $Script:InstallDevBoxPath" -Level Warning
            Write-Log "DevBox auto-installation will be skipped" -Level Warning
        } else {
            Write-Log "Install-DevBox.ps1 found" -Level Success
        }
    }

    # Check disk space
    $vmDrive = Split-Path -Qualifier $VMPath
    if ([string]::IsNullOrEmpty($vmDrive)) { $vmDrive = "C:" }

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$vmDrive'"
    $requiredGB = $DiskSizeGB * $Count + 10
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)

    if ($freeGB -lt $requiredGB) {
        throw "Insufficient disk space. Required: ${requiredGB}GB, Available: ${freeGB}GB"
    }
    Write-Log "Disk space OK: ${freeGB}GB available" -Level Success

    # Check for existing VMs with same name
    $vmNames = if ($Count -eq 1) { @($VMName) } else {
        1..$Count | ForEach-Object { $VMName + ($NamePattern -f $_) }
    }

    foreach ($name in $vmNames) {
        $existingVM = Get-VM -Name $name -ErrorAction SilentlyContinue
        if ($null -ne $existingVM) {
            throw "VM '$name' already exists. Remove it first or use a different name."
        }
    }

    Write-Log "All prerequisites validated" -Level Success
}

#endregion

#region VHDX Operations

function Copy-TemplateVHDX {
    param(
        [string]$NewVMName,
        [string]$DestPath
    )

    Write-Log "Cloning template VHDX for $NewVMName..." -Level Info

    # Create VM directory
    $vmDir = Join-Path $VMPath $NewVMName
    if (-not (Test-Path $vmDir)) {
        New-Item -Path $vmDir -ItemType Directory -Force | Out-Null
    }

    # Copy VHDX
    $newVHDXPath = Join-Path $vmDir "$NewVMName.vhdx"
    Copy-Item -Path $TemplatePath -Destination $newVHDXPath -Force

    # Remove read-only attribute
    Set-ItemProperty -Path $newVHDXPath -Name IsReadOnly -Value $false

    # Expand if needed
    $templateVHD = Get-VHD -Path $TemplatePath
    $templateSizeGB = [math]::Round($templateVHD.Size / 1GB, 0)

    if ($DiskSizeGB -gt $templateSizeGB) {
        Write-Log "Expanding VHDX from ${templateSizeGB}GB to ${DiskSizeGB}GB..." -Level Info
        Resize-VHD -Path $newVHDXPath -SizeBytes ($DiskSizeGB * 1GB)
    }

    Write-Log "VHDX cloned: $newVHDXPath" -Level Success
    return $newVHDXPath
}

function Set-VMSpecializeSettings {
    param(
        [string]$VHDXPath,
        [string]$ComputerName
    )

    Write-Log "Injecting specialize settings for $ComputerName..." -Level Info

    # Mount VHDX
    Mount-VHD -Path $VHDXPath
    $disk = Get-Disk | Where-Object { $_.Location -eq $VHDXPath }

    # Find Windows partition
    $winPartition = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.Type -eq "Basic" -and $_.Size -gt 20GB }
    $winLetter = $winPartition.DriveLetter

    if ([string]::IsNullOrEmpty($winLetter)) {
        $winPartition | Add-PartitionAccessPath -AssignDriveLetter
        $winLetter = (Get-Partition -DiskNumber $disk.Number | Where-Object { $_.Type -eq "Basic" -and $_.Size -gt 20GB }).DriveLetter
    }

    try {
        # Create unattend.xml for specialize pass
        $unattendContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
            publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>$ComputerName</ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
            publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>Admin</Name>
                        <Group>Administrators</Group>
                        <Password>
                            <Value>VgBpAGIAZQBEAGUAdgAxADIAMwAhAFAAYQBzAHMAdwBvAHIAZAA=</Value>
                            <PlainText>false</PlainText>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Enabled>true</Enabled>
                <Username>Admin</Username>
                <Password>
                    <Value>VgBpAGIAZQBEAGUAdgAxADIAMwAhAFAAYQBzAHMAdwBvAHIAZAA=</Value>
                    <PlainText>false</PlainText>
                </Password>
                <LogonCount>3</LogonCount>
            </AutoLogon>
"@

        # Add FirstLogonCommands based on InstallMode
        if ($InstallMode -ne "Manual") {
            $unattendContent += @"

            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <CommandLine>powershell.exe -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"</CommandLine>
                    <Description>Enable PowerShell scripts</Description>
                </SynchronousCommand>
"@
            if ($InstallMode -eq "Automatic" -and (Test-Path $Script:InstallDevBoxPath)) {
                $unattendContent += @"
                <SynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <CommandLine>powershell.exe -ExecutionPolicy Bypass -File "C:\DevBox\Install-DevBox.ps1" -Silent -Profile $DevBoxProfile</CommandLine>
                    <Description>Install DevBox tools</Description>
                </SynchronousCommand>
"@
            }
            $unattendContent += @"
            </FirstLogonCommands>
"@
        }

        $unattendContent += @"
        </component>
    </settings>
</unattend>
"@

        # Save unattend.xml
        $pantherPath = "${winLetter}:\Windows\Panther"
        if (-not (Test-Path $pantherPath)) {
            New-Item -Path $pantherPath -ItemType Directory -Force | Out-Null
        }
        $unattendContent | Out-File -FilePath "$pantherPath\unattend.xml" -Encoding utf8 -Force

        # Copy Install-DevBox.ps1 if needed
        if ($InstallMode -ne "Manual" -and (Test-Path $Script:InstallDevBoxPath)) {
            Write-Log "Copying DevBox installation scripts..." -Level Info
            $devBoxDir = "${winLetter}:\DevBox"
            if (-not (Test-Path $devBoxDir)) {
                New-Item -Path $devBoxDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $Script:InstallDevBoxPath -Destination "$devBoxDir\Install-DevBox.ps1" -Force

            # Create desktop shortcut for SemiAutomatic mode
            if ($InstallMode -eq "SemiAutomatic") {
                $publicDesktop = "${winLetter}:\Users\Public\Desktop"
                $shortcutContent = @"
@echo off
echo Starting DevBox Installation...
powershell.exe -ExecutionPolicy Bypass -File "C:\DevBox\Install-DevBox.ps1"
pause
"@
                $shortcutContent | Out-File -FilePath "$publicDesktop\Install-DevBox.cmd" -Encoding ascii -Force
                Write-Log "Created desktop shortcut for DevBox installer" -Level Info
            }
        }

        Write-Log "Specialize settings injected" -Level Success

    } finally {
        # Dismount VHDX
        Dismount-VHD -Path $VHDXPath
    }
}

#endregion

#region VM Creation

function New-DevBoxVM {
    param(
        [string]$NewVMName,
        [string]$VHDXPath
    )

    Write-Log "Creating VM: $NewVMName" -Level Header

    # Create Gen2 VM
    $vm = New-VM -Name $NewVMName `
        -Generation 2 `
        -MemoryStartupBytes ($MemoryGB * 1GB) `
        -VHDPath $VHDXPath `
        -SwitchName $SwitchName `
        -Path $VMPath

    # Configure memory
    if ($DynamicMemory) {
        Set-VM -Name $NewVMName `
            -DynamicMemory `
            -MemoryMinimumBytes (2GB) `
            -MemoryMaximumBytes ($MemoryGB * 1GB)
    }

    # Configure processors
    Set-VM -Name $NewVMName `
        -ProcessorCount $ProcessorCount `
        -AutomaticCheckpointsEnabled $false `
        -CheckpointType Standard

    # Enable TPM
    Write-Log "Enabling TPM..." -Level Info
    Set-VMKeyProtector -VMName $NewVMName -NewLocalKeyProtector
    Enable-VMTPM -VMName $NewVMName

    # Configure Secure Boot
    Write-Log "Configuring Secure Boot..." -Level Info
    Set-VMFirmware -VMName $NewVMName -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows

    # Enable integration services
    Write-Log "Enabling integration services..." -Level Info
    $services = @(
        "Guest Service Interface",
        "Heartbeat",
        "Key-Value Pair Exchange",
        "Shutdown",
        "Time Synchronization",
        "VSS"
    )
    foreach ($service in $services) {
        Enable-VMIntegrationService -VMName $NewVMName -Name $service -ErrorAction SilentlyContinue
    }

    Write-Log "VM created: $NewVMName" -Level Success
    return $vm
}

#endregion

#region Main

function Main {
    $startTime = Get-Date

    Show-Banner

    # Check if running in interactive mode (no VMName provided)
    if ([string]::IsNullOrEmpty($VMName)) {
        Write-Log "Starting interactive mode..." -Level Info
        $config = Invoke-InteractiveMode

        if ($null -eq $config) {
            Write-Host ""
            Write-Host "  VM creation cancelled." -ForegroundColor Yellow
            Write-Host ""
            return
        }

        # Apply interactive configuration to script variables
        $Script:VMName = $config.VMName
        $Script:TemplatePath = $config.TemplatePath
        $Script:VMPath = $config.VMPath
        $Script:MemoryGB = $config.MemoryGB
        $Script:ProcessorCount = $config.ProcessorCount
        $Script:DiskSizeGB = $config.DiskSizeGB
        $Script:SwitchName = $config.SwitchName
        $Script:InstallMode = $config.InstallMode
        $Script:DevBoxProfile = $config.DevBoxProfile
        $Script:Count = $config.Count
        $Script:NamePattern = $config.NamePattern
        $Script:StartVM = $config.StartVM

        # Update local variables for use in this function
        $VMName = $config.VMName
        $TemplatePath = $config.TemplatePath
        $VMPath = $config.VMPath
        $MemoryGB = $config.MemoryGB
        $ProcessorCount = $config.ProcessorCount
        $DiskSizeGB = $config.DiskSizeGB
        $SwitchName = $config.SwitchName
        $InstallMode = $config.InstallMode
        $DevBoxProfile = $config.DevBoxProfile
        $Count = $config.Count
        $NamePattern = $config.NamePattern
        $StartVM = $config.StartVM

        Clear-Host
        Show-Banner
    }

    Write-Log "DevBox VM Creator started" -Level Header
    Write-Log "Base Name: $VMName" -Level Info
    Write-Log "Count: $Count" -Level Info
    Write-Log "Profile: $DevBoxProfile" -Level Info
    Write-Log "Install Mode: $InstallMode" -Level Info
    Write-Log "VM Specs: ${MemoryGB}GB RAM, $ProcessorCount CPUs" -Level Info

    try {
        # Validate prerequisites
        Test-Prerequisites

        # Generate VM names
        $vmNames = if ($Count -eq 1) {
            @($VMName)
        } else {
            1..$Count | ForEach-Object { $VMName + ($NamePattern -f $_) }
        }

        # Create VMs
        foreach ($name in $vmNames) {
            Write-Log "Processing VM: $name" -Level Header

            # Clone VHDX
            $vhdxPath = Copy-TemplateVHDX -NewVMName $name -DestPath $VMPath

            # Inject settings
            Set-VMSpecializeSettings -VHDXPath $vhdxPath -ComputerName $name

            # Create VM
            $vm = New-DevBoxVM -NewVMName $name -VHDXPath $vhdxPath

            $Script:CreatedVMs += @{
                Name = $name
                VHDXPath = $vhdxPath
            }

            # Start VM if requested
            if ($StartVM) {
                Write-Log "Starting VM: $name" -Level Info
                Start-VM -Name $name

                # Wait a bit between starts to avoid resource contention
                if ($vmNames.Count -gt 1) {
                    Start-Sleep -Seconds 5
                }
            }
        }

        # Summary
        $duration = (Get-Date) - $startTime
        Write-Log "VM creation completed in $([math]::Round($duration.TotalMinutes, 1)) minutes" -Level Success

        Write-Host ""
        Write-Host "Created VMs:" -ForegroundColor Cyan
        foreach ($vm in $Script:CreatedVMs) {
            Write-Host "  - $($vm.Name)" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Default credentials:" -ForegroundColor Yellow
        Write-Host "  Username: Admin" -ForegroundColor White
        Write-Host "  Password: VibeDev123!" -ForegroundColor White

        if ($InstallMode -eq "Automatic") {
            Write-Host ""
            Write-Host "DevBox tools will be installed automatically on first login." -ForegroundColor Cyan
            Write-Host "Profile: $DevBoxProfile" -ForegroundColor Cyan
        } elseif ($InstallMode -eq "SemiAutomatic") {
            Write-Host ""
            Write-Host "Run 'Install-DevBox.cmd' from the desktop to install DevBox tools." -ForegroundColor Cyan
        }

        if (-not $StartVM) {
            Write-Host ""
            Write-Host "VMs are ready. Start them with:" -ForegroundColor Yellow
            foreach ($vm in $Script:CreatedVMs) {
                Write-Host "  Start-VM -Name '$($vm.Name)'" -ForegroundColor White
            }
        }

    } catch {
        Write-Log "VM creation failed: $_" -Level Error
        Write-Log $_.ScriptStackTrace -Level Error

        # Cleanup on failure
        foreach ($vm in $Script:CreatedVMs) {
            Write-Log "Cleaning up: $($vm.Name)" -Level Warning
            Stop-VM -Name $vm.Name -Force -TurnOff -ErrorAction SilentlyContinue
            Remove-VM -Name $vm.Name -Force -ErrorAction SilentlyContinue
            Remove-Item -Path (Split-Path $vm.VHDXPath) -Recurse -Force -ErrorAction SilentlyContinue
        }

        throw
    }
}

# Run main
Main
