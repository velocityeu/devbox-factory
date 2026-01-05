<#
.SYNOPSIS
    Creates a sysprepped Windows 11 VHDX template for DevBox Factory development VMs.

.DESCRIPTION
    Stage 1 of DevBox Factory VM automation. This script:
    1. Installs prerequisites (Hyper-V, Windows ADK)
    2. Creates a bootable VHDX from Windows 11 ISO
    3. Creates a Gen2 VM with TPM and Secure Boot
    4. Runs Windows installation unattended
    5. Applies Windows Updates (optional)
    6. Runs Sysprep to generalize the image
    7. Exports the optimized VHDX template

    Run without parameters for interactive menu mode.

.PARAMETER ISOPath
    Path to Windows 11 ISO file. If not provided, interactive mode is launched.

.PARAMETER TemplatePath
    Directory to store the template VHDX. Default: {DevBoxRoot}\HyperV\Templates

.PARAMETER TemplateName
    Name for the template. Default: Win11-DevBox-Template

.PARAMETER MemoryGB
    Memory allocation for template VM during creation. Default: 8

.PARAMETER ProcessorCount
    CPU cores for template VM. Default: 4

.PARAMETER DiskSizeGB
    VHDX disk size. Default: 127

.PARAMETER SwitchName
    Hyper-V virtual switch name. Default: Default Switch

.PARAMETER SkipWindowsUpdates
    Skip Windows Update installation for faster template creation

.PARAMETER AdminPassword
    Secure password for local Admin account

.PARAMETER WindowsEditionIndex
    Windows edition index in install.wim. Default: 3 (auto-detects Enterprise)
    Note: Index varies by ISO. Script auto-detects Enterprise edition when available.

.PARAMETER TimeZone
    Windows timezone. Default: Pacific Standard Time

.PARAMETER Preset
    VM specification preset: Lightweight, Standard, Performance, ServerClass, Custom

.PARAMETER Interactive
    Launch interactive menu mode (default if no ISOPath provided)

.EXAMPLE
    .\New-DevBoxTemplate.ps1
    # Launches interactive menu

.EXAMPLE
    .\New-DevBoxTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso"

.EXAMPLE
    .\New-DevBoxTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso" -Preset Performance -SkipWindowsUpdates

.NOTES
    Requires: Windows 10/11 Pro or Server with Hyper-V capability
    DevBox Factory - https://github.com/velocityeu/devbox-factory
    Version: 3.5.1
    Build: 20260105.1200
#>

[CmdletBinding()]
param(
    [string]$ISOPath,

    [string]$TemplatePath,  # Default set below after module import
    [string]$TemplateName = "Win11-DevBox-Template",

    [ValidateRange(4, 64)]
    [int]$MemoryGB = 8,

    [ValidateRange(2, 32)]
    [int]$ProcessorCount = 4,

    [ValidateRange(64, 2048)]
    [int]$DiskSizeGB = 127,

    [string]$SwitchName = "Default Switch",

    [switch]$SkipWindowsUpdates,

    [SecureString]$AdminPassword,

    [ValidateRange(1, 11)]
    [int]$WindowsEditionIndex = 3,

    [string]$TimeZone = "Pacific Standard Time",

    [ValidateSet('Lightweight', 'Standard', 'Performance', 'ServerClass', 'Custom')]
    [string]$Preset,

    [ValidateSet('Full', 'AICoder', 'WebDev', 'Azure', 'Minimal', 'None')]
    [string]$DevBoxProfile = "Full",

    [switch]$SkipDevBoxTools,

    [switch]$Interactive
)

#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Version information
$Script:DevBoxVersion = @{
    Major       = 3
    Minor       = 5
    Patch       = 1
    BuildDate   = "2026-01-05 12:00"
    BuildNumber = "20260105.1200"
}

# Script-level variables
$Script:RequiresReboot = $false
$Script:VMName = "$TemplateName-Build"
$Script:InteractiveMode = $false
$Script:SelectedConfig = @{}
$Script:ADKPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit"
$Script:ScriptRoot = $PSScriptRoot
$Script:ParentRoot = Split-Path $PSScriptRoot -Parent

# Import modules
$loggerModule = Join-Path $Script:ParentRoot "modules\DevBoxLogger.psm1"
$assetModule = Join-Path $Script:ParentRoot "modules\AssetRegistry.psm1"

if (Test-Path $loggerModule) {
    Import-Module $loggerModule -Force -ErrorAction SilentlyContinue
    $Script:Paths = Initialize-DevBoxPaths -ScriptRoot $PSScriptRoot -LogPrefix "template"
    $Script:LogPath = $Script:Paths.LogFile
    $Script:TempFolder = $Script:Paths.TempFolder
} else {
    # Fallback to default paths
    $Script:LogPath = Join-Path $env:USERPROFILE "DevBox-Template.log"
    $Script:TempFolder = Join-Path $Script:ParentRoot "temp"
    if (-not (Test-Path $Script:TempFolder)) {
        New-Item -Path $Script:TempFolder -ItemType Directory -Force | Out-Null
    }
}

if (Test-Path $assetModule) {
    Import-Module $assetModule -Force -ErrorAction SilentlyContinue
    Initialize-AssetRegistry -ScriptRoot $PSScriptRoot | Out-Null
}

# Set default TemplatePath if not provided (project-relative)
if ([string]::IsNullOrEmpty($TemplatePath)) {
    $TemplatePath = Join-Path $Script:ParentRoot "HyperV\Templates"
}
$Script:VHDXPath = Join-Path $TemplatePath "$TemplateName.vhdx"
$Script:TempVHDXPath = Join-Path $Script:TempFolder "$TemplateName-temp.vhdx"

# Regional settings - detected from host system
$Script:RegionalSettings = @{
    TimeZone = (Get-TimeZone).Id
    InputLocale = (Get-Culture).Name
    SystemLocale = (Get-Culture).Name
    UILanguage = (Get-UICulture).Name
    UserLocale = (Get-Culture).Name
    GeoID = (Get-WinHomeLocation).GeoId
}

# Windows edition mappings
$Script:Win11Editions = @{
    1  = @{ Name = "Windows 11 Home"; Key = "YTMG3-N6DKC-DKB77-7M9GH-8HVX7" }
    2  = @{ Name = "Windows 11 Home N"; Key = "4CPRK-NM3K3-X6XXQ-RXX86-WXCHW" }
    3  = @{ Name = "Windows 11 Home Single Language"; Key = "BT79Q-G7N6G-PGBYW-4YWX6-6F4BT" }
    4  = @{ Name = "Windows 11 Education"; Key = "YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY" }
    5  = @{ Name = "Windows 11 Education N"; Key = "84NGF-MHBT6-FXBX8-QWJK7-DRR8H" }
    6  = @{ Name = "Windows 11 Pro"; Key = "VK7JG-NPHTM-C97JM-9MPGT-3V66T" }
    7  = @{ Name = "Windows 11 Pro N"; Key = "2B87N-8KFHP-DKV6R-Y2C8J-PKCKT" }
    8  = @{ Name = "Windows 11 Pro for Workstations"; Key = "DXG7C-N36C4-C4HTG-X4T3X-2YV77" }
    9  = @{ Name = "Windows 11 Pro for Workstations N"; Key = "WYPNQ-8C467-V2W6J-TX4WX-WT2RQ" }
    10 = @{ Name = "Windows 11 Enterprise"; Key = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C" }
    11 = @{ Name = "Windows 11 Enterprise N"; Key = "WGGHN-J84D6-QYCPR-T7PJ7-X766F" }
}

$Script:Server2025Editions = @{
    1  = @{ Name = "Windows Server 2025 Standard"; Key = "VDYBN-27WPP-V4HQT-9VMD4-VMK7H" }
    2  = @{ Name = "Windows Server 2025 Standard (Desktop)"; Key = "VDYBN-27WPP-V4HQT-9VMD4-VMK7H" }
    3  = @{ Name = "Windows Server 2025 Datacenter"; Key = "WX4NM-KYWYW-QJJR4-XV3QB-6VM33" }
    4  = @{ Name = "Windows Server 2025 Datacenter (Desktop)"; Key = "WX4NM-KYWYW-QJJR4-XV3QB-6VM33" }
}

# Get product key by matching edition name (indices vary by ISO)
function Get-ProductKeyByName {
    param(
        [string]$EditionName,
        [bool]$IsServer = $false
    )

    $editionMap = if ($IsServer) { $Script:Server2025Editions } else { $Script:Win11Editions }

    # Try exact match first by iterating through all entries
    foreach ($key in $editionMap.Keys) {
        if ($editionMap[$key].Name -eq $EditionName) {
            return $editionMap[$key].Key
        }
    }

    # Try partial match (e.g., "Enterprise" matches "Windows 11 Enterprise")
    foreach ($key in $editionMap.Keys) {
        $mapName = $editionMap[$key].Name
        if ($EditionName -match "Enterprise" -and $mapName -match "Enterprise$") {
            return $editionMap[$key].Key
        }
        if ($EditionName -match "Pro$" -and $mapName -match "Pro$") {
            return $editionMap[$key].Key
        }
        if ($EditionName -match "Education$" -and $mapName -match "Education$") {
            return $editionMap[$key].Key
        }
        if ($EditionName -match "Datacenter" -and $mapName -match "Datacenter") {
            return $editionMap[$key].Key
        }
        if ($EditionName -match "Standard" -and $mapName -match "Standard") {
            return $editionMap[$key].Key
        }
    }

    # Default fallback keys
    if ($IsServer) {
        return "WX4NM-KYWYW-QJJR4-XV3QB-6VM33"  # Datacenter
    } else {
        return "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"  # Enterprise
    }
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

function Get-VersionString {
    return "v$($Script:DevBoxVersion.Major).$($Script:DevBoxVersion.Minor).$($Script:DevBoxVersion.Patch)"
}

function Show-Banner {
    $version = Get-VersionString
    $build = $Script:DevBoxVersion.BuildNumber

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
    Write-Host "  |  TEMPLATE CREATOR       Hyper-V Windows 11 Template - Stage 1       |" -ForegroundColor White
    Write-Host "  |  by Velocity EU                           $version build $build  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
}

#endregion

#region Interactive Menu Functions

function Show-ISOFilePicker {
    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select Windows 11 ISO File"
    $dialog.Filter = "ISO Files (*.iso)|*.iso|All Files (*.*)|*.*"
    $dialog.FilterIndex = 1
    $dialog.InitialDirectory = "$env:USERPROFILE\Downloads"
    $dialog.Multiselect = $false

    $result = $dialog.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

function Test-ISOFile {
    param([string]$Path)

    $result = @{
        IsValid = $false
        Path = $Path
        SizeGB = 0
        FileName = ""
        Error = $null
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $result.Error = "No path provided"
        return $result
    }

    if (-not (Test-Path $Path -PathType Leaf)) {
        $result.Error = "File not found: $Path"
        return $result
    }

    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    if ($ext -ne ".iso") {
        $result.Error = "File is not an ISO: $Path"
        return $result
    }

    $fileInfo = Get-Item $Path
    $result.FileName = $fileInfo.Name
    $result.SizeGB = [math]::Round($fileInfo.Length / 1GB, 2)

    if ($result.SizeGB -lt 3) {
        $result.Error = "ISO file too small (${result.SizeGB}GB). Windows 11 ISO should be 4-6GB."
        return $result
    }

    $result.IsValid = $true
    return $result
}

function Find-ISOFiles {
    # Include local iso/ folder and common locations
    $scriptDir = if ($Script:ScriptRoot) { Split-Path $Script:ScriptRoot -Parent } else { $PSScriptRoot }
    $localIsoPath = Join-Path $scriptDir "iso"

    $locations = @(
        $localIsoPath,
        ".\iso",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "C:\ISOs",
        "D:\ISOs",
        "E:\ISOs",
        "$env:USERPROFILE\Documents"
    )

    $isoFiles = @()

    foreach ($loc in $locations) {
        if (Test-Path $loc) {
            $files = Get-ChildItem -Path $loc -Filter "*.iso" -ErrorAction SilentlyContinue |
                     Where-Object { $_.Length -gt 3GB } |
                     Select-Object FullName, Name, @{N='SizeGB';E={[math]::Round($_.Length/1GB,2)}}, LastWriteTime
            $isoFiles += $files
        }
    }

    return $isoFiles | Sort-Object LastWriteTime -Descending
}

function Show-MainMenu {
    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                    MAIN MENU                               |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] Quick Start (Guided Wizard)" -ForegroundColor White
    Write-Host "       Step-by-step template creation with smart defaults" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] Custom Configuration" -ForegroundColor White
    Write-Host "       Full control over all settings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] View Existing Templates" -ForegroundColor White
    Write-Host "       View template details and locations" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [Q] Quit" -ForegroundColor White
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter your choice"
    return $choice
}

function Show-ISOSelectionMenu {
    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                    ISO SELECTION                           |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] Browse for ISO file" -ForegroundColor White
    Write-Host "       Opens Windows file picker dialog" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] Enter path manually" -ForegroundColor White
    Write-Host "       Type the full path to the ISO file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] Scan common locations" -ForegroundColor White
    Write-Host "       Search Downloads, Desktop, C:\ISOs, etc." -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [B] Back to main menu" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter your choice"
    return $choice
}

function Show-ISOScanResults {
    param([array]$ISOFiles)

    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  FOUND ISO FILES                           |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    if ($ISOFiles.Count -eq 0) {
        Write-Host "   No ISO files found in common locations." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Press Enter to go back..." -ForegroundColor Gray
        $null = Read-Host
        return $null
    }

    $index = 1
    foreach ($iso in $ISOFiles) {
        Write-Host "   [$index] $($iso.Name)" -ForegroundColor White
        Write-Host "       Size: $($iso.SizeGB) GB | Modified: $($iso.LastWriteTime.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
        Write-Host "       Path: $($iso.FullName)" -ForegroundColor DarkGray
        Write-Host ""
        $index++
    }

    Write-Host "   [B] Back" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Select ISO file"

    if ($choice -eq 'B' -or $choice -eq 'b') {
        return $null
    }

    $selectedIndex = 0
    if ([int]::TryParse($choice, [ref]$selectedIndex)) {
        if ($selectedIndex -ge 1 -and $selectedIndex -le $ISOFiles.Count) {
            return $ISOFiles[$selectedIndex - 1].FullName
        }
    }

    return $null
}

function Show-ISOValidation {
    param([hashtable]$ValidationResult)

    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  ISO VALIDATION                            |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   File: $($ValidationResult.FileName)" -ForegroundColor White
    Write-Host "   Size: $($ValidationResult.SizeGB) GB" -ForegroundColor White
    Write-Host "   Path: $($ValidationResult.Path)" -ForegroundColor Gray
    Write-Host ""

    if ($ValidationResult.IsValid) {
        Write-Host "   [+] File exists" -ForegroundColor Green
        Write-Host "   [+] Valid ISO format" -ForegroundColor Green
        Write-Host "   [+] Size appropriate for Windows 11" -ForegroundColor Green
        Write-Host ""
        Write-Host "   ISO validated successfully!" -ForegroundColor Green
    } else {
        Write-Host "   [X] Validation failed: $($ValidationResult.Error)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Press Enter to continue..." -ForegroundColor Gray
    $null = Read-Host
}

function Get-ISOEditions {
    param([string]$ISOPath)

    $result = @{
        IsServer = $false
        IsWindows11 = $false
        Editions = @()
        WimPath = ""
        Error = $null
    }

    Write-Host "    Checking ISO..." -ForegroundColor DarkGray -NoNewline

    try {
        # Check if ISO is already mounted - use job with timeout to prevent hang
        $checkJob = Start-Job -ScriptBlock {
            param($path)
            Get-DiskImage -ImagePath $path -ErrorAction SilentlyContinue
        } -ArgumentList $ISOPath

        $checkComplete = Wait-Job $checkJob -Timeout 10
        if ($checkComplete) {
            $existingMount = Receive-Job $checkJob
            Remove-Job $checkJob -Force -ErrorAction SilentlyContinue

            if ($existingMount -and $existingMount.Attached) {
                Write-Host " dismounting previous..." -ForegroundColor DarkGray -NoNewline
                Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue | Out-Null
                Start-Sleep -Milliseconds 500
            }
        } else {
            Stop-Job $checkJob -ErrorAction SilentlyContinue
            Remove-Job $checkJob -Force -ErrorAction SilentlyContinue
            Write-Host ""
            Write-Host "    [!] Disk check timed out - continuing anyway..." -ForegroundColor Yellow
        }

        # Mount ISO
        Write-Host " mounting..." -ForegroundColor DarkGray -NoNewline
        $mountJob = Start-Job -ScriptBlock {
            param($path)
            Mount-DiskImage -ImagePath $path -PassThru -ErrorAction Stop
        } -ArgumentList $ISOPath

        $mountComplete = Wait-Job $mountJob -Timeout 30
        if (-not $mountComplete) {
            Stop-Job $mountJob -ErrorAction SilentlyContinue
            Remove-Job $mountJob -Force -ErrorAction SilentlyContinue
            Write-Host ""
            $result.Error = "ISO mount timed out (30s) - file may be corrupted or on slow storage"
            return $result
        }

        $mount = Receive-Job $mountJob
        Remove-Job $mountJob -Force -ErrorAction SilentlyContinue

        if (-not $mount) {
            Write-Host ""
            $result.Error = "Failed to mount ISO"
            return $result
        }

        # Wait for volume to be available (up to 10 seconds)
        Write-Host " waiting for volume..." -ForegroundColor DarkGray -NoNewline
        $driveLetter = $null
        $attempts = 0
        while (-not $driveLetter -and $attempts -lt 20) {
            Start-Sleep -Milliseconds 500
            $volume = $mount | Get-Volume -ErrorAction SilentlyContinue
            if ($volume -and $volume.DriveLetter) {
                $driveLetter = $volume.DriveLetter + ":"
            }
            $attempts++
        }

        if (-not $driveLetter) {
            Write-Host ""
            $result.Error = "Could not get drive letter after mounting ISO"
            Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue | Out-Null
            return $result
        }

        Write-Host " $driveLetter" -ForegroundColor Green

        try {
            # Find install.wim or install.esd
            $wimPath = Join-Path $driveLetter "sources\install.wim"
            $isEsd = $false
            if (-not (Test-Path $wimPath)) {
                $wimPath = Join-Path $driveLetter "sources\install.esd"
                $isEsd = $true
                if (-not (Test-Path $wimPath)) {
                    $result.Error = "Could not find install.wim or install.esd in ISO"
                    return $result
                }
            }
            $result.WimPath = $wimPath

            # Get editions using DISM (with progress for ESD files which are slower)
            if ($isEsd) {
                Write-Host "    Reading install.esd (this may take 30-60 seconds)..." -ForegroundColor DarkGray
            } else {
                Write-Host "    Reading install.wim..." -ForegroundColor DarkGray
            }

            # Run DISM with timeout
            $dismJob = Start-Job -ScriptBlock {
                param($wim)
                & dism /Get-WimInfo /WimFile:"$wim" 2>&1
            } -ArgumentList $wimPath

            # Wait up to 120 seconds for DISM
            $completed = Wait-Job $dismJob -Timeout 120
            if (-not $completed) {
                Stop-Job $dismJob -ErrorAction SilentlyContinue
                Remove-Job $dismJob -Force -ErrorAction SilentlyContinue
                $result.Error = "DISM timed out reading image info (try a different ISO)"
                return $result
            }

            $dismOutput = Receive-Job $dismJob
            Remove-Job $dismJob -Force -ErrorAction SilentlyContinue

            # Parse editions
            $currentIndex = 0
            $currentName = ""
            foreach ($line in $dismOutput) {
                if ($line -match "^Index\s*:\s*(\d+)") {
                    $currentIndex = [int]$matches[1]
                }
                if ($line -match "^Name\s*:\s*(.+)$") {
                    $currentName = $matches[1].Trim()
                    $result.Editions += @{
                        Index = $currentIndex
                        Name = $currentName
                    }

                    # Detect OS type
                    if ($currentName -match "Server") {
                        $result.IsServer = $true
                    } elseif ($currentName -match "Windows 11|Windows 10") {
                        $result.IsWindows11 = $true
                    }
                }
            }

        } finally {
            # Dismount ISO
            Write-Host "    Dismounting ISO..." -ForegroundColor DarkGray
            Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue | Out-Null
        }

    } catch {
        $result.Error = $_.Exception.Message
        # Try to dismount on error
        Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue | Out-Null
    }

    return $result
}

function Show-EditionSelectionMenu {
    param(
        [array]$Editions,
        [bool]$IsServer
    )

    Show-Banner

    $osType = if ($IsServer) { "WINDOWS SERVER" } else { "WINDOWS 11" }

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |              SELECT $osType EDITION                    |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    # Show available editions
    foreach ($edition in $Editions) {
        $recommended = ""
        if ($edition.Name -match "Enterprise$" -or $edition.Name -match "Datacenter.*Desktop") {
            $recommended = " * Recommended"
            Write-Host "   [$($edition.Index)] $($edition.Name)$recommended" -ForegroundColor Green
        } else {
            Write-Host "   [$($edition.Index)] $($edition.Name)" -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "   [B] Back" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    # Auto-detect best default: Enterprise for Win11, Datacenter for Server
    $defaultIndex = $null
    if ($IsServer) {
        # Prefer Datacenter Desktop, then Datacenter, then first available
        $datacenterDesktop = $Editions | Where-Object { $_.Name -match "Datacenter.*Desktop" } | Select-Object -First 1
        $datacenter = $Editions | Where-Object { $_.Name -match "Datacenter" } | Select-Object -First 1
        $defaultIndex = if ($datacenterDesktop) { $datacenterDesktop.Index } elseif ($datacenter) { $datacenter.Index } else { $null }
    } else {
        # Prefer Enterprise (not N), then Pro, then first available
        $enterprise = $Editions | Where-Object { $_.Name -match "Enterprise$" } | Select-Object -First 1
        $pro = $Editions | Where-Object { $_.Name -match "Pro$" } | Select-Object -First 1
        $defaultIndex = if ($enterprise) { $enterprise.Index } elseif ($pro) { $pro.Index } else { $null }
    }

    # Fallback to first edition if nothing matched
    if (-not $defaultIndex -and $Editions.Count -gt 0) {
        $defaultIndex = $Editions[0].Index
    }

    $choice = Read-Host "  Select edition [$defaultIndex]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = $defaultIndex.ToString() }

    if ($choice -eq 'B' -or $choice -eq 'b') {
        return $null
    }

    $selectedIndex = 0
    if ([int]::TryParse($choice, [ref]$selectedIndex)) {
        $selected = $Editions | Where-Object { $_.Index -eq $selectedIndex }
        if ($selected) {
            return $selected
        }
    }

    # Return default if invalid input
    return $Editions | Where-Object { $_.Index -eq $defaultIndex } | Select-Object -First 1
}

function Show-RegionalSettingsMenu {
    param([hashtable]$CurrentSettings)

    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |              REGIONAL SETTINGS                             |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Settings detected from your system:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [1] Time Zone:     $($CurrentSettings.TimeZone)" -ForegroundColor White
    Write-Host "   [2] Input Locale:  $($CurrentSettings.InputLocale)" -ForegroundColor White
    Write-Host "   [3] System Locale: $($CurrentSettings.SystemLocale)" -ForegroundColor White
    Write-Host "   [4] UI Language:   $($CurrentSettings.UILanguage)" -ForegroundColor White
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [A] Accept these settings (Recommended)" -ForegroundColor Green
    Write-Host "   [C] Change to common presets" -ForegroundColor White
    Write-Host "   [B] Back" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "  Enter choice [A]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "A" }

    return $choice.ToUpper()
}

function Show-RegionalPresetsMenu {
    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |              REGIONAL PRESETS                              |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] United States (en-US)" -ForegroundColor White
    Write-Host "       Pacific Standard Time, en-US keyboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] United Kingdom (en-GB)" -ForegroundColor White
    Write-Host "       GMT Standard Time, en-GB keyboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] Germany (de-DE)" -ForegroundColor White
    Write-Host "       W. Europe Standard Time, de-DE keyboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [4] France (fr-FR)" -ForegroundColor White
    Write-Host "       Romance Standard Time, fr-FR keyboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [5] Australia (en-AU)" -ForegroundColor White
    Write-Host "       AUS Eastern Standard Time, en-AU keyboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [6] Japan (ja-JP)" -ForegroundColor White
    Write-Host "       Tokyo Standard Time, ja-JP keyboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [B] Back" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Select preset"

    $presets = @{
        '1' = @{ TimeZone = "Pacific Standard Time"; InputLocale = "en-US"; SystemLocale = "en-US"; UILanguage = "en-US"; UserLocale = "en-US" }
        '2' = @{ TimeZone = "GMT Standard Time"; InputLocale = "en-GB"; SystemLocale = "en-GB"; UILanguage = "en-GB"; UserLocale = "en-GB" }
        '3' = @{ TimeZone = "W. Europe Standard Time"; InputLocale = "de-DE"; SystemLocale = "de-DE"; UILanguage = "de-DE"; UserLocale = "de-DE" }
        '4' = @{ TimeZone = "Romance Standard Time"; InputLocale = "fr-FR"; SystemLocale = "fr-FR"; UILanguage = "fr-FR"; UserLocale = "fr-FR" }
        '5' = @{ TimeZone = "AUS Eastern Standard Time"; InputLocale = "en-AU"; SystemLocale = "en-AU"; UILanguage = "en-AU"; UserLocale = "en-AU" }
        '6' = @{ TimeZone = "Tokyo Standard Time"; InputLocale = "ja-JP"; SystemLocale = "ja-JP"; UILanguage = "ja-JP"; UserLocale = "ja-JP" }
    }

    if ($presets.ContainsKey($choice)) {
        return $presets[$choice]
    }

    return $null
}

function Show-PresetMenu {
    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  VM SPECIFICATIONS                         |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] Lightweight    4GB RAM,  2 CPUs,  80GB disk" -ForegroundColor White
    Write-Host "       Basic development, minimal resources" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] Standard       8GB RAM,  4 CPUs, 127GB disk  * Default" -ForegroundColor White
    Write-Host "       Typical development workload" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] Performance   16GB RAM,  8 CPUs, 256GB disk" -ForegroundColor White
    Write-Host "       Heavy workloads, multiple IDEs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [4] Server-class  32GB RAM, 16 CPUs, 512GB disk" -ForegroundColor White
    Write-Host "       Database servers, enterprise apps" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [C] Custom - enter your own values" -ForegroundColor White
    Write-Host ""
    Write-Host "   [B] Back" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter choice [2]"

    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "2" }

    return $choice
}

function Get-PresetValues {
    param([string]$PresetName)

    $presets = @{
        'Lightweight' = @{ MemoryGB = 4; ProcessorCount = 2; DiskSizeGB = 80 }
        'Standard'    = @{ MemoryGB = 8; ProcessorCount = 4; DiskSizeGB = 127 }
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
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                  CUSTOM SPECIFICATIONS                     |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $memInput = Read-Host "  Memory (GB) [8]"
    $memory = if ([string]::IsNullOrWhiteSpace($memInput)) { 8 } else { [int]$memInput }

    $cpuInput = Read-Host "  CPU Cores [4]"
    $cpu = if ([string]::IsNullOrWhiteSpace($cpuInput)) { 4 } else { [int]$cpuInput }

    $diskInput = Read-Host "  Disk Size (GB) [127]"
    $disk = if ([string]::IsNullOrWhiteSpace($diskInput)) { 127 } else { [int]$diskInput }

    return @{
        MemoryGB = [Math]::Max(4, [Math]::Min(64, $memory))
        ProcessorCount = [Math]::Max(2, [Math]::Min(32, $cpu))
        DiskSizeGB = [Math]::Max(40, [Math]::Min(2048, $disk))
    }
}

function Show-ConfigurationSummary {
    param([hashtable]$Config)

    Show-Banner

    Write-Host "  +===========================================================+" -ForegroundColor Green
    Write-Host "  |                  CONFIGURATION SUMMARY                     |" -ForegroundColor Green
    Write-Host "  +===========================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ISO File:" -ForegroundColor Cyan
    Write-Host "    Path: $($Config.ISOPath)" -ForegroundColor White
    Write-Host "    Status: Verified OK" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Windows Edition:" -ForegroundColor Cyan
    $editionDisplay = if ($Config.WindowsEditionName) { $Config.WindowsEditionName } else { "Windows 11 Pro" }
    Write-Host "    Edition: $editionDisplay (Index $($Config.WindowsEditionIndex))" -ForegroundColor White
    if ($Config.IsServer) {
        Write-Host "    Type: Windows Server" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "  Regional Settings:" -ForegroundColor Cyan
    Write-Host "    Time Zone: $($Config.TimeZone)" -ForegroundColor White
    Write-Host "    Locale: $($Config.InputLocale)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Template Settings:" -ForegroundColor Cyan
    Write-Host "    Name: $($Config.TemplateName)" -ForegroundColor White
    Write-Host "    Path: $($Config.TemplatePath)\$($Config.TemplateName).vhdx" -ForegroundColor White
    Write-Host ""
    Write-Host "  VM Specifications:" -ForegroundColor Cyan
    Write-Host "    Memory: $($Config.MemoryGB) GB" -ForegroundColor White
    Write-Host "    CPUs: $($Config.ProcessorCount) cores" -ForegroundColor White
    Write-Host "    Disk: $($Config.DiskSizeGB) GB" -ForegroundColor White
    Write-Host ""
    Write-Host "  DevBox Tools Profile:" -ForegroundColor Cyan
    $profileDesc = switch ($Config.DevBoxProfile) {
        "Full"    { "Full - AI tools, Web Dev, Azure, Docker, Databases" }
        "AICoder" { "AI Coder - Claude Code, Cursor, VS Code, Node.js, Python" }
        "WebDev"  { "Web Developer - Node.js, Python, Docker, Databases" }
        "Azure"   { "Azure Developer - Azure CLI, .NET SDK, Terraform" }
        "Minimal" { "Minimal - Git, Windows Terminal, VS Code only" }
        "None"    { "None - Clean Windows, no tools pre-installed" }
        default   { $Config.DevBoxProfile }
    }
    Write-Host "    Profile: $profileDesc" -ForegroundColor White
    if ($Config.DevBoxProfile -ne "None") {
        Write-Host "    * Tools will be PRE-INSTALLED in template" -ForegroundColor Green
        Write-Host "    * All cloned VMs will be READY TO CODE immediately" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "  Options:" -ForegroundColor Cyan
    Write-Host "    Skip Windows Updates: $(if($Config.SkipWindowsUpdates){'Yes'}else{'No'})" -ForegroundColor White
    Write-Host ""
    Write-Host "  VM Credentials (for all created VMs):" -ForegroundColor Cyan
    Write-Host "    Username: " -ForegroundColor White -NoNewline
    Write-Host "Admin" -ForegroundColor Green
    Write-Host "    Password: " -ForegroundColor White -NoNewline
    Write-Host "VibeDev123!" -ForegroundColor Green
    Write-Host "    Note: NOT 'Administrator' - the local account is 'Admin'" -ForegroundColor DarkGray
    Write-Host ""
    $estTime = if ($Config.DevBoxProfile -eq "None") { "45-60" } else { "60-90" }
    Write-Host "  Estimated Time: $estTime minutes" -ForegroundColor Yellow
    Write-Host "  Required Disk Space: ~150 GB" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  +===========================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "   [P] Proceed with template creation" -ForegroundColor White
    Write-Host "   [E] Edit configuration" -ForegroundColor White
    Write-Host "   [C] Cancel" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter choice"
    return $choice
}

function Show-ExistingTemplates {
    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                 EXISTING TEMPLATES                         |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $templateDir = Join-Path $Script:ParentRoot "HyperV\Templates"
    if (-not (Test-Path $templateDir)) {
        Write-Host "   No templates found. Template directory does not exist." -ForegroundColor Yellow
        Write-Host "   Path: $templateDir" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   Press Enter to go back..." -ForegroundColor Gray
        $null = Read-Host
        return
    }

    $templates = Get-ChildItem -Path $templateDir -Filter "*.vhdx" -ErrorAction SilentlyContinue

    if ($templates.Count -eq 0) {
        Write-Host "   No template VHDX files found." -ForegroundColor Yellow
        Write-Host "   Path: $templateDir" -ForegroundColor Gray
    } else {
        $index = 1
        foreach ($t in $templates) {
            $sizeGB = [math]::Round($t.Length / 1GB, 2)
            Write-Host "   [$index] $($t.Name)" -ForegroundColor White
            Write-Host "       Size: $sizeGB GB | Created: $($t.CreationTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
            Write-Host ""
            $index++
        }
    }

    Write-Host "   [B] Back to main menu" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Press Enter to go back..." -ForegroundColor Gray
    $null = Read-Host
}

function Show-DevBoxProfileMenu {
    Show-Banner

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |              DEVBOX TOOLS PROFILE                          |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Select which dev tools to PRE-INSTALL in the template:" -ForegroundColor White
    Write-Host "  (All cloned VMs will have these tools ready to use)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [1] Full (Recommended)" -ForegroundColor White
    Write-Host "       AI tools, Web Dev, Azure, Docker, Databases" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] AI Coder" -ForegroundColor White
    Write-Host "       Claude Code, Cursor, VS Code + AI extensions, Node.js, Python" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] Web Developer" -ForegroundColor White
    Write-Host "       Node.js, Python, Docker, PostgreSQL, MongoDB, Redis" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [4] Azure Developer" -ForegroundColor White
    Write-Host "       Azure CLI, Functions, .NET SDK, Terraform, Bicep" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [5] Minimal" -ForegroundColor White
    Write-Host "       Git, Windows Terminal, VS Code only" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [6] None - Skip tool installation" -ForegroundColor White
    Write-Host "       Clean Windows only (install tools manually later)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [B] Back" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-Host "  Enter choice [1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    switch ($choice.ToUpper()) {
        'B' { return $null }
        '1' { return "Full" }
        '2' { return "AICoder" }
        '3' { return "WebDev" }
        '4' { return "Azure" }
        '5' { return "Minimal" }
        '6' { return "None" }
        default { return "Full" }
    }
}

function Invoke-InteractiveMode {
    $config = @{
        ISOPath = ""
        TemplatePath = (Join-Path $Script:ParentRoot "HyperV\Templates")
        TemplateName = "Win11-DevBox-Template"
        MemoryGB = 8
        ProcessorCount = 4
        DiskSizeGB = 127
        SwitchName = "Default Switch"
        SkipWindowsUpdates = $true
        WindowsEditionIndex = 3
        WindowsEditionName = "Windows 11 Enterprise"
        WindowsProductKey = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"  # Generic KMS key for Enterprise
        IsServer = $false
        TimeZone = $Script:RegionalSettings.TimeZone
        InputLocale = $Script:RegionalSettings.InputLocale
        SystemLocale = $Script:RegionalSettings.SystemLocale
        UILanguage = $Script:RegionalSettings.UILanguage
        UserLocale = $Script:RegionalSettings.UserLocale
        DevBoxProfile = "Full"
    }

    while ($true) {
        $mainChoice = Show-MainMenu

        switch ($mainChoice.ToUpper()) {
            'Q' {
                Write-Host ""
                Write-Log "User cancelled template creation" -Level Warning
                return $null
            }
            '1' {
                # Quick Start - Guided Wizard
                # Step 1: ISO Selection
                $isoSelected = $false
                while (-not $isoSelected) {
                    $isoChoice = Show-ISOSelectionMenu
                    switch ($isoChoice.ToUpper()) {
                        'B' { break }
                        '1' {
                            $isoPath = Show-ISOFilePicker
                            if ($isoPath) {
                                $validation = Test-ISOFile -Path $isoPath
                                Show-ISOValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.ISOPath = $isoPath
                                    $isoSelected = $true
                                }
                            }
                        }
                        '2' {
                            Write-Host ""
                            $manualPath = Read-Host "  Enter full path to ISO file"
                            if ($manualPath) {
                                $validation = Test-ISOFile -Path $manualPath
                                Show-ISOValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.ISOPath = $manualPath
                                    $isoSelected = $true
                                }
                            }
                        }
                        '3' {
                            $foundISOs = Find-ISOFiles
                            $selectedISO = Show-ISOScanResults -ISOFiles $foundISOs
                            if ($selectedISO) {
                                $validation = Test-ISOFile -Path $selectedISO
                                Show-ISOValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.ISOPath = $selectedISO
                                    $isoSelected = $true
                                }
                            }
                        }
                    }
                    if ($isoChoice.ToUpper() -eq 'B') { break }
                }

                if (-not $isoSelected) { continue }

                # Step 2: Detect and Select Windows Edition
                Write-Host ""
                Write-Host "  Detecting available Windows editions..." -ForegroundColor Cyan
                $isoInfo = Get-ISOEditions -ISOPath $config.ISOPath

                if ($isoInfo.Editions.Count -gt 0) {
                    $selectedEdition = Show-EditionSelectionMenu -Editions $isoInfo.Editions -IsServer $isoInfo.IsServer
                    if ($null -eq $selectedEdition) { continue }

                    $config.WindowsEditionIndex = $selectedEdition.Index
                    $config.WindowsEditionName = $selectedEdition.Name
                    $config.IsServer = $isoInfo.IsServer

                    # Get product key based on edition name (handles varying indices across ISOs)
                    $config.WindowsProductKey = Get-ProductKeyByName -EditionName $selectedEdition.Name -IsServer $isoInfo.IsServer

                    # Update template name based on OS type
                    if ($isoInfo.IsServer) {
                        $config.TemplateName = "WinServer-DevBox-Template"
                    }
                } else {
                    Write-Host "  Could not detect editions - using defaults (Enterprise)" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }

                # Step 3: Regional Settings
                $regionalChoice = Show-RegionalSettingsMenu -CurrentSettings @{
                    TimeZone = $config.TimeZone
                    InputLocale = $config.InputLocale
                    SystemLocale = $config.SystemLocale
                    UILanguage = $config.UILanguage
                }

                if ($regionalChoice -eq 'C') {
                    $preset = Show-RegionalPresetsMenu
                    if ($null -ne $preset) {
                        $config.TimeZone = $preset.TimeZone
                        $config.InputLocale = $preset.InputLocale
                        $config.SystemLocale = $preset.SystemLocale
                        $config.UILanguage = $preset.UILanguage
                        $config.UserLocale = $preset.UserLocale
                    }
                } elseif ($regionalChoice -eq 'B') {
                    continue
                }
                # 'A' accepts detected settings (already in config)

                # Step 4: Preset Selection (Quick mode uses Standard)
                $config.MemoryGB = 8
                $config.ProcessorCount = 4
                $config.DiskSizeGB = 127

                # Step 5: DevBox Profile Selection
                $profileChoice = Show-DevBoxProfileMenu
                if ($null -eq $profileChoice) { continue }
                $config.DevBoxProfile = $profileChoice

                # Step 6: Confirmation
                $summaryChoice = Show-ConfigurationSummary -Config $config
                if ($summaryChoice -eq 'P' -or $summaryChoice -eq 'p') {
                    return $config
                } elseif ($summaryChoice -eq 'C' -or $summaryChoice -eq 'c') {
                    continue
                }
                # 'E' or anything else continues to edit
            }
            '2' {
                # Custom Configuration
                # Step 1: ISO Selection
                $isoSelected = $false
                while (-not $isoSelected) {
                    $isoChoice = Show-ISOSelectionMenu
                    switch ($isoChoice.ToUpper()) {
                        'B' { break }
                        '1' {
                            $isoPath = Show-ISOFilePicker
                            if ($isoPath) {
                                $validation = Test-ISOFile -Path $isoPath
                                Show-ISOValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.ISOPath = $isoPath
                                    $isoSelected = $true
                                }
                            }
                        }
                        '2' {
                            Write-Host ""
                            $manualPath = Read-Host "  Enter full path to ISO file"
                            if ($manualPath) {
                                $validation = Test-ISOFile -Path $manualPath
                                Show-ISOValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.ISOPath = $manualPath
                                    $isoSelected = $true
                                }
                            }
                        }
                        '3' {
                            $foundISOs = Find-ISOFiles
                            $selectedISO = Show-ISOScanResults -ISOFiles $foundISOs
                            if ($selectedISO) {
                                $validation = Test-ISOFile -Path $selectedISO
                                Show-ISOValidation -ValidationResult $validation
                                if ($validation.IsValid) {
                                    $config.ISOPath = $selectedISO
                                    $isoSelected = $true
                                }
                            }
                        }
                    }
                    if ($isoChoice.ToUpper() -eq 'B') { break }
                }

                if (-not $isoSelected) { continue }

                # Step 2: Detect and Select Windows Edition
                Write-Host ""
                Write-Host "  Detecting available Windows editions..." -ForegroundColor Cyan
                $isoInfo = Get-ISOEditions -ISOPath $config.ISOPath

                if ($isoInfo.Editions.Count -gt 0) {
                    $selectedEdition = Show-EditionSelectionMenu -Editions $isoInfo.Editions -IsServer $isoInfo.IsServer
                    if ($null -eq $selectedEdition) { continue }

                    $config.WindowsEditionIndex = $selectedEdition.Index
                    $config.WindowsEditionName = $selectedEdition.Name
                    $config.IsServer = $isoInfo.IsServer

                    # Get product key based on edition name (handles varying indices across ISOs)
                    $config.WindowsProductKey = Get-ProductKeyByName -EditionName $selectedEdition.Name -IsServer $isoInfo.IsServer

                    # Update template name based on OS type
                    if ($isoInfo.IsServer) {
                        $config.TemplateName = "WinServer-DevBox-Template"
                    }
                } else {
                    Write-Host "  Could not detect editions - using defaults (Enterprise)" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }

                # Step 3: Regional Settings
                $regionalChoice = Show-RegionalSettingsMenu -CurrentSettings @{
                    TimeZone = $config.TimeZone
                    InputLocale = $config.InputLocale
                    SystemLocale = $config.SystemLocale
                    UILanguage = $config.UILanguage
                }

                if ($regionalChoice -eq 'C') {
                    $preset = Show-RegionalPresetsMenu
                    if ($null -ne $preset) {
                        $config.TimeZone = $preset.TimeZone
                        $config.InputLocale = $preset.InputLocale
                        $config.SystemLocale = $preset.SystemLocale
                        $config.UILanguage = $preset.UILanguage
                        $config.UserLocale = $preset.UserLocale
                    }
                } elseif ($regionalChoice -eq 'B') {
                    continue
                }
                # 'A' accepts detected settings (already in config)

                # Step 4: Preset Selection
                $presetChoice = Show-PresetMenu
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

                # Step 5: DevBox Profile Selection
                $profileChoice = Show-DevBoxProfileMenu
                if ($null -eq $profileChoice) { continue }
                $config.DevBoxProfile = $profileChoice

                # Step 6: Additional Options (default: skip updates for faster creation)
                Write-Host ""
                $skipUpdates = Read-Host "  Skip Windows Updates? (Y/n)"
                $config.SkipWindowsUpdates = -not ($skipUpdates -eq 'n' -or $skipUpdates -eq 'N')

                # Step 7: Confirmation
                $summaryChoice = Show-ConfigurationSummary -Config $config
                if ($summaryChoice -eq 'P' -or $summaryChoice -eq 'p') {
                    return $config
                } elseif ($summaryChoice -eq 'C' -or $summaryChoice -eq 'c') {
                    continue
                }
                # 'E' or anything else continues to edit
            }
            '3' {
                Show-ExistingTemplates
            }
        }
    }
}

#endregion

#region Prerequisites

function Install-Prerequisites {
    Write-Log "Checking and installing prerequisites..." -Level Header

    # 1. Check Windows version
    $os = Get-CimInstance Win32_OperatingSystem
    if ($os.BuildNumber -lt 19041) {
        throw "Windows 10 version 2004 or later required. Current build: $($os.BuildNumber)"
    }
    Write-Log "Windows version: $($os.Caption) (Build $($os.BuildNumber))" -Level Info

    # 2. Check/Enable Hyper-V
    Write-Log "Checking Hyper-V status..." -Level Info

    # Detect if running on Windows Server vs Windows Client
    $isServer = (Get-CimInstance Win32_OperatingSystem).ProductType -ne 1

    if ($isServer) {
        # Windows Server: Use Get-WindowsFeature (Server Manager cmdlet)
        $hypervRole = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue
        if ($null -eq $hypervRole) {
            throw "Could not query Hyper-V role status. Ensure you have Server Manager installed."
        }
        if ($hypervRole.InstallState -ne 'Installed') {
            Write-Log "Installing Hyper-V role (Server)..." -Level Info
            Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart:$false
            $Script:RequiresReboot = $true
        } else {
            Write-Log "Hyper-V role is already installed" -Level Success
        }
    } else {
        # Windows Client (10/11): Use Get-WindowsOptionalFeature
        $hypervFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue

        if ($null -eq $hypervFeature) {
            throw "Hyper-V feature not available on this Windows edition. Ensure you have Windows 10/11 Pro, Enterprise, or Education."
        }

        if ($hypervFeature.State -ne 'Enabled') {
            Write-Log "Enabling Hyper-V feature..." -Level Info
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -All
            $Script:RequiresReboot = $true
        } else {
            Write-Log "Hyper-V is already enabled" -Level Success
        }
    }

    # 3. Check/Install Windows ADK
    Write-Log "Checking Windows ADK..." -Level Info
    $dismPath = Join-Path $Script:ADKPath "Deployment Tools\amd64\DISM\dism.exe"
    $bcdbootPath = Join-Path $Script:ADKPath "Deployment Tools\amd64\BCDBoot\bcdboot.exe"

    # WinGet success exit codes:
    # 0 = Success
    # -1978335189 (0x8A150019) = Already installed
    # -1978335194 (0x8A150014) = Newer version available
    $wingetSuccessCodes = @(0, -1978335189, -1978335194)

    if (-not (Test-Path $dismPath)) {
        Write-Log "Installing Windows ADK (this may take several minutes)..." -Level Info

        # Check if winget is available
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($null -eq $winget) {
            throw "WinGet is required to install Windows ADK. Please install App Installer from Microsoft Store."
        }

        # Install ADK
        $result = winget install --id Microsoft.WindowsADK --accept-source-agreements --accept-package-agreements --silent 2>&1
        if ($LASTEXITCODE -notin $wingetSuccessCodes) {
            Write-Log "WinGet returned exit code: $LASTEXITCODE" -Level Warning
            Write-Log "WinGet output: $result" -Level Warning
        }

        # Poll for installation completion (ADK can take 2-5 minutes)
        $maxWaitSeconds = 300  # 5 minutes max
        $pollInterval = 5
        $waited = 0
        Write-Log "Waiting for ADK installation to complete..." -Level Info

        while (-not (Test-Path $dismPath) -and $waited -lt $maxWaitSeconds) {
            Start-Sleep -Seconds $pollInterval
            $waited += $pollInterval
            Write-Host "." -NoNewline
        }
        Write-Host ""  # New line after dots

        # Verify installation
        if (-not (Test-Path $dismPath)) {
            throw "Windows ADK installation failed after ${waited}s. DISM not found at: $dismPath"
        }
        Write-Log "Windows ADK installed successfully" -Level Success
    } else {
        Write-Log "Windows ADK is already installed" -Level Success
    }

    # 4. Check/Install Windows PE Add-on
    Write-Log "Checking Windows PE Add-on..." -Level Info
    $winpePath = Join-Path $Script:ADKPath "Windows Preinstallation Environment"

    if (-not (Test-Path $winpePath)) {
        Write-Log "Installing Windows PE Add-on (this may take a few minutes)..." -Level Info

        # Try WinGet first (may not be available for all ADK versions)
        $wingetResult = winget install --id Microsoft.ADKPEAddon --accept-source-agreements --accept-package-agreements --silent 2>&1
        $wingetSuccess = $LASTEXITCODE -in $wingetSuccessCodes

        if (-not $wingetSuccess) {
            Write-Log "WinGet package not available, downloading directly from Microsoft..." -Level Info

            # Download Windows PE Add-on directly from Microsoft
            # Using go.microsoft.com redirect for stability (ADK 10.1.26100.2454 - Dec 2024)
            $peAddonUrl = "https://go.microsoft.com/fwlink/?linkid=2289981"
            $peAddonInstaller = Join-Path $env:TEMP "adkwinpesetup.exe"

            try {
                Write-Log "Downloading Windows PE Add-on installer..." -Level Info
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $peAddonUrl -OutFile $peAddonInstaller -UseBasicParsing

                if (Test-Path $peAddonInstaller) {
                    Write-Log "Running Windows PE Add-on installer (silent, this downloads ~4GB)..." -Level Info
                    # /ceip off prevents telemetry prompts, /quiet for silent install
                    $process = Start-Process -FilePath $peAddonInstaller -ArgumentList "/quiet", "/norestart", "/ceip", "off", "/features", "OptionId.WindowsPreinstallationEnvironment" -PassThru

                    # Wait up to 15 minutes for the installer (it downloads ~4GB)
                    $timeoutMinutes = 15
                    $completed = $process.WaitForExit($timeoutMinutes * 60 * 1000)

                    if (-not $completed) {
                        Write-Log "PE Add-on installer timed out after $timeoutMinutes minutes" -Level Warning
                        Write-Log "The installer may still be running in the background" -Level Warning
                    } elseif ($process.ExitCode -eq 0) {
                        Write-Log "Windows PE Add-on installer completed" -Level Success
                    } elseif ($process.ExitCode -eq 3010) {
                        Write-Log "Windows PE Add-on installed (reboot may be required)" -Level Success
                    } else {
                        Write-Log "PE Add-on installer returned exit code: $($process.ExitCode)" -Level Warning
                    }

                    # Cleanup installer
                    Remove-Item -Path $peAddonInstaller -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Log "Failed to download/install PE Add-on: $_" -Level Warning
            }
        }

        # Poll for installation completion
        $maxWaitSeconds = 180  # 3 minutes max for direct install
        $waited = 0
        Write-Log "Waiting for WinPE Add-on installation to complete..." -Level Info

        while (-not (Test-Path $winpePath) -and $waited -lt $maxWaitSeconds) {
            Start-Sleep -Seconds 5
            $waited += 5
            Write-Host "." -NoNewline
        }
        Write-Host ""

        if (-not (Test-Path $winpePath)) {
            Write-Log "Windows PE Add-on may not have installed correctly" -Level Warning
            Write-Log "You can install manually: https://docs.microsoft.com/windows-hardware/get-started/adk-install" -Level Warning
        } else {
            Write-Log "Windows PE Add-on installed successfully" -Level Success
        }
    } else {
        Write-Log "Windows PE Add-on is already installed" -Level Success
    }

    # 5. Import Hyper-V module
    Write-Log "Importing Hyper-V PowerShell module..." -Level Info
    if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
        throw "Hyper-V PowerShell module not available. Please enable Hyper-V and reboot."
    }
    Import-Module Hyper-V -ErrorAction Stop
    Write-Log "Hyper-V module imported" -Level Success

    # 6. Verify virtual switch exists
    Write-Log "Checking virtual switch '$SwitchName'..." -Level Info
    $switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if ($null -eq $switch) {
        # Try to create Default Switch if it doesn't exist
        if ($SwitchName -eq "Default Switch") {
            Write-Log "Creating Default Switch..." -Level Info
            New-VMSwitch -Name "Default Switch" -SwitchType Internal
        } else {
            throw "Virtual switch '$SwitchName' not found. Please create it or use 'Default Switch'."
        }
    }
    Write-Log "Virtual switch '$SwitchName' is available" -Level Success

    # Check for reboot requirement
    if ($Script:RequiresReboot) {
        Write-Log "A reboot is required to complete prerequisite installation." -Level Warning
        Write-Log "Please reboot and run this script again." -Level Warning
        throw "Reboot required. Please restart your computer and run this script again."
    }

    Write-Log "All prerequisites satisfied" -Level Success
}

function Test-DiskSpace {
    Write-Log "Checking available disk space..." -Level Info

    $templateDrive = Split-Path -Qualifier $TemplatePath
    if ([string]::IsNullOrEmpty($templateDrive)) {
        $templateDrive = "C:"
    }

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$templateDrive'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $requiredGB = $DiskSizeGB + 20  # Extra space for temp files

    if ($freeGB -lt $requiredGB) {
        throw "Insufficient disk space. Required: ${requiredGB}GB, Available: ${freeGB}GB on $templateDrive"
    }

    Write-Log "Disk space OK: ${freeGB}GB available on $templateDrive" -Level Success
}

#endregion

#region VHDX Creation

function New-BootableVHDX {
    Write-Log "Creating bootable VHDX from ISO..." -Level Header

    # Create template directory
    if (-not (Test-Path $TemplatePath)) {
        New-Item -Path $TemplatePath -ItemType Directory -Force | Out-Null
        Write-Log "Created template directory: $TemplatePath" -Level Info
    }

    # Clean up any existing temp VHDX from previous failed runs
    if (Test-Path $Script:TempVHDXPath) {
        Write-Log "Removing existing temp VHDX from previous run..." -Level Warning
        try {
            # Try to dismount first in case it's still mounted
            Dismount-VHD -Path $Script:TempVHDXPath -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Remove-Item -Path $Script:TempVHDXPath -Force -ErrorAction Stop
            Write-Log "Previous temp VHDX removed" -Level Info
        } catch {
            Write-Log "Could not remove existing temp VHDX: $_" -Level Error
            throw "Failed to clean up existing temp VHDX at $Script:TempVHDXPath. Please delete it manually and try again."
        }
    }

    # Mount ISO
    Write-Log "Mounting ISO: $ISOPath" -Level Info
    $isoMount = Mount-DiskImage -ImagePath $ISOPath -PassThru
    $isoDrive = ($isoMount | Get-Volume).DriveLetter + ":"

    try {
        # Verify install.wim exists
        $wimPath = Join-Path $isoDrive "sources\install.wim"
        if (-not (Test-Path $wimPath)) {
            # Check for install.esd (compressed)
            $esdPath = Join-Path $isoDrive "sources\install.esd"
            if (Test-Path $esdPath) {
                $wimPath = $esdPath
                Write-Log "Found install.esd (compressed image)" -Level Info
            } else {
                throw "Neither install.wim nor install.esd found in ISO"
            }
        }

        # List available editions
        Write-Log "Available Windows editions:" -Level Info
        $editions = & dism /Get-WimInfo /WimFile:$wimPath 2>&1
        Write-Log ($editions | Out-String) -Level Info

        # Create VHDX
        Write-Log "Creating VHDX: $Script:TempVHDXPath ($DiskSizeGB GB)" -Level Info
        $vhdx = New-VHD -Path $Script:TempVHDXPath -SizeBytes ($DiskSizeGB * 1GB) -Dynamic
        Mount-VHD -Path $Script:TempVHDXPath

        # Get disk and initialize
        $disk = Get-Disk | Where-Object { $_.Location -eq $Script:TempVHDXPath }
        Write-Log "Initializing disk as GPT (UEFI)..." -Level Info
        Initialize-Disk -Number $disk.Number -PartitionStyle GPT

        # Create partitions (EFI System, MSR, Windows)
        Write-Log "Creating partitions..." -Level Info

        # EFI System Partition (260MB)
        $efiPartition = New-Partition -DiskNumber $disk.Number -Size 260MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
        $efiPartition | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "System" -Confirm:$false | Out-Null
        $efiPartition | Add-PartitionAccessPath -AssignDriveLetter
        # Re-fetch partition to get assigned drive letter
        Start-Sleep -Milliseconds 500
        $efiPartition = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' }
        $efiLetter = $efiPartition.DriveLetter

        if ([string]::IsNullOrEmpty($efiLetter)) {
            throw "Failed to assign drive letter to EFI partition"
        }

        # Microsoft Reserved Partition (16MB)
        New-Partition -DiskNumber $disk.Number -Size 16MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' | Out-Null

        # Windows Partition (rest of disk)
        $winPartition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
        $winPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" -Confirm:$false | Out-Null
        $winPartition | Add-PartitionAccessPath -AssignDriveLetter
        # Re-fetch partition to get assigned drive letter
        Start-Sleep -Milliseconds 500
        $winPartition = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.GptType -eq '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' }
        $winLetter = $winPartition.DriveLetter

        if ([string]::IsNullOrEmpty($winLetter)) {
            throw "Failed to assign drive letter to Windows partition"
        }

        Write-Log "Partitions created: EFI=$efiLetter`:, Windows=$winLetter`:" -Level Success

        # Apply Windows image with DISM
        Write-Log "Applying Windows image (Edition Index: $WindowsEditionIndex)..." -Level Info
        Write-Log "This may take 10-20 minutes..." -Level Info

        $dismArgs = "/Apply-Image /ImageFile:`"$wimPath`" /Index:$WindowsEditionIndex /ApplyDir:${winLetter}:\"
        $dismExe = Join-Path $Script:ADKPath "Deployment Tools\amd64\DISM\dism.exe"

        if (Test-Path $dismExe) {
            $process = Start-Process -FilePath $dismExe -ArgumentList $dismArgs -Wait -PassThru -NoNewWindow
        } else {
            $process = Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -Wait -PassThru -NoNewWindow
        }

        if ($process.ExitCode -ne 0) {
            throw "DISM Apply-Image failed with exit code: $($process.ExitCode)"
        }
        Write-Log "Windows image applied successfully" -Level Success

        # Configure boot files
        Write-Log "Configuring boot files..." -Level Info
        $bcdbootArgs = "${winLetter}:\Windows /s ${efiLetter}: /f UEFI"
        $bcdbootExe = Join-Path $Script:ADKPath "Deployment Tools\amd64\BCDBoot\bcdboot.exe"

        if (Test-Path $bcdbootExe) {
            $process = Start-Process -FilePath $bcdbootExe -ArgumentList $bcdbootArgs -Wait -PassThru -NoNewWindow
        } else {
            $process = Start-Process -FilePath "bcdboot.exe" -ArgumentList $bcdbootArgs -Wait -PassThru -NoNewWindow
        }

        if ($process.ExitCode -ne 0) {
            throw "BCDBoot failed with exit code: $($process.ExitCode)"
        }
        Write-Log "Boot files configured" -Level Success

        # Copy autounattend.xml
        $unattendPath = Join-Path $Script:ScriptRoot "autounattend.xml"
        if (Test-Path $unattendPath) {
            Write-Log "Injecting autounattend.xml..." -Level Info

            # Read and customize autounattend.xml
            $unattendContent = Get-Content $unattendPath -Raw

            # Set admin password if provided
            if ($null -ne $AdminPassword) {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
                $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

                # Encode password for unattend
                $encodedPassword = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($plainPassword + "AdministratorPassword"))
                $unattendContent = $unattendContent -replace 'ADMIN_PASSWORD_PLACEHOLDER', $encodedPassword
            } else {
                # Use default password: VibeDev123!
                $defaultPassword = "VibeDev123!" + "AdministratorPassword"
                $encodedPassword = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($defaultPassword))
                $unattendContent = $unattendContent -replace 'ADMIN_PASSWORD_PLACEHOLDER', $encodedPassword
            }

            # Set timezone
            $tzValue = if ($Script:TimeZone) { $Script:TimeZone } else { $TimeZone }
            $unattendContent = $unattendContent -replace 'TIMEZONE_PLACEHOLDER', $tzValue

            # Set regional settings
            $inputLocale = if ($Script:InputLocale) { $Script:InputLocale } else { $Script:RegionalSettings.InputLocale }
            $systemLocale = if ($Script:SystemLocale) { $Script:SystemLocale } else { $Script:RegionalSettings.SystemLocale }
            $uiLanguage = if ($Script:UILanguage) { $Script:UILanguage } else { $Script:RegionalSettings.UILanguage }
            $userLocale = if ($Script:UserLocale) { $Script:UserLocale } else { $Script:RegionalSettings.UserLocale }

            $unattendContent = $unattendContent -replace 'INPUTLOCALE_PLACEHOLDER', $inputLocale
            $unattendContent = $unattendContent -replace 'SYSTEMLOCALE_PLACEHOLDER', $systemLocale
            $unattendContent = $unattendContent -replace 'UILANGUAGE_PLACEHOLDER', $uiLanguage
            $unattendContent = $unattendContent -replace 'USERLOCALE_PLACEHOLDER', $userLocale

            # Set product key based on selected edition
            $productKey = if ($Script:WindowsProductKey) { $Script:WindowsProductKey } else { "VK7JG-NPHTM-C97JM-9MPGT-3V66T" }
            $unattendContent = $unattendContent -replace 'PRODUCTKEY_PLACEHOLDER', $productKey

            Write-Log "Regional settings: $inputLocale, TimeZone: $tzValue" -Level Info

            # Create Panther directory and save unattend
            $pantherPath = "${winLetter}:\Windows\Panther"
            if (-not (Test-Path $pantherPath)) {
                New-Item -Path $pantherPath -ItemType Directory -Force | Out-Null
            }
            $unattendContent | Out-File -FilePath "${winLetter}:\Windows\Panther\unattend.xml" -Encoding utf8 -Force

            # Also copy to Windows\System32\Sysprep for offline servicing
            Copy-Item -Path "${winLetter}:\Windows\Panther\unattend.xml" -Destination "${winLetter}:\Windows\System32\Sysprep\unattend.xml" -Force

            Write-Log "autounattend.xml injected" -Level Success
        } else {
            Write-Log "No autounattend.xml found at $unattendPath - manual OOBE required" -Level Warning
        }

        # Copy SetupComplete.ps1
        $setupCompletePath = Join-Path $Script:ScriptRoot "SetupComplete.ps1"
        if (Test-Path $setupCompletePath) {
            Write-Log "Injecting SetupComplete.ps1..." -Level Info
            $setupDir = "${winLetter}:\Windows\Setup\Scripts"
            if (-not (Test-Path $setupDir)) {
                New-Item -Path $setupDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $setupCompletePath -Destination "$setupDir\SetupComplete.ps1" -Force

            # Create SetupComplete.cmd to call PowerShell script
            $cmdContent = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0SetupComplete.ps1"
"@
            $cmdContent | Out-File -FilePath "$setupDir\SetupComplete.cmd" -Encoding ascii -Force
            Write-Log "SetupComplete scripts injected" -Level Success
        }

        # Dismount VHDX
        Write-Log "Dismounting VHDX..." -Level Info
        Dismount-VHD -Path $Script:TempVHDXPath

    } finally {
        # Always dismount ISO
        Write-Log "Dismounting ISO..." -Level Info
        Dismount-DiskImage -ImagePath $ISOPath
    }

    Write-Log "Bootable VHDX created successfully" -Level Success
}

#endregion

#region VM Creation

function New-TemplateVM {
    Write-Log "Creating template VM..." -Level Header

    # Remove existing VM if present
    $existingVM = Get-VM -Name $Script:VMName -ErrorAction SilentlyContinue
    if ($null -ne $existingVM) {
        Write-Log "Removing existing VM: $Script:VMName" -Level Warning
        Stop-VM -Name $Script:VMName -Force -TurnOff -ErrorAction SilentlyContinue
        Remove-VM -Name $Script:VMName -Force
    }

    # Copy VHDX to final location for VM
    $vmVHDXPath = Join-Path (Split-Path $Script:VHDXPath) "$Script:VMName.vhdx"
    Write-Log "Copying VHDX for VM: $vmVHDXPath" -Level Info
    Copy-Item -Path $Script:TempVHDXPath -Destination $vmVHDXPath -Force

    # Create Gen2 VM
    Write-Log "Creating Generation 2 VM: $Script:VMName" -Level Info
    $vm = New-VM -Name $Script:VMName `
        -Generation 2 `
        -MemoryStartupBytes ($MemoryGB * 1GB) `
        -VHDPath $vmVHDXPath `
        -SwitchName $SwitchName

    # Configure VM settings
    Write-Log "Configuring VM settings..." -Level Info
    Set-VM -Name $Script:VMName `
        -ProcessorCount $ProcessorCount `
        -AutomaticCheckpointsEnabled $false `
        -CheckpointType Disabled

    # Enable TPM (required for Windows 11)
    Write-Log "Enabling TPM (required for Windows 11)..." -Level Info
    Set-VMKeyProtector -VMName $Script:VMName -NewLocalKeyProtector
    Enable-VMTPM -VMName $Script:VMName

    # Configure Secure Boot
    Write-Log "Configuring Secure Boot..." -Level Info
    Set-VMFirmware -VMName $Script:VMName -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows

    # Enable integration services
    Write-Log "Enabling integration services..." -Level Info
    Enable-VMIntegrationService -VMName $Script:VMName -Name "Guest Service Interface"
    Enable-VMIntegrationService -VMName $Script:VMName -Name "Heartbeat"
    Enable-VMIntegrationService -VMName $Script:VMName -Name "Key-Value Pair Exchange"
    Enable-VMIntegrationService -VMName $Script:VMName -Name "Shutdown"
    Enable-VMIntegrationService -VMName $Script:VMName -Name "Time Synchronization"
    Enable-VMIntegrationService -VMName $Script:VMName -Name "VSS"

    Write-Log "Template VM created: $Script:VMName" -Level Success
    return $vm
}

function Start-TemplateVM {
    Write-Log "Starting template VM..." -Level Info
    Start-VM -Name $Script:VMName

    Write-Log "Waiting for Windows installation to complete..." -Level Info
    Write-Log "This may take 15-30 minutes depending on hardware..." -Level Info

    # Wait for VM to boot and settle
    Start-Sleep -Seconds 30

    # Wait for heartbeat to indicate Windows is running
    $timeout = 3600  # 1 hour timeout
    $elapsed = 0
    $heartbeatReady = $false

    while ($elapsed -lt $timeout) {
        $heartbeat = Get-VMIntegrationService -VMName $Script:VMName -Name "Heartbeat"
        if ($heartbeat.PrimaryStatusDescription -eq "OK") {
            Write-Log "Windows is responding (heartbeat OK)" -Level Success
            $heartbeatReady = $true
            break
        }

        # Check VM state
        $vmState = (Get-VM -Name $Script:VMName).State
        if ($vmState -eq "Off") {
            # VM shut down - check if it was for OOBE completion
            Write-Log "VM shut down during installation - this may be expected for OOBE" -Level Info
            Start-Sleep -Seconds 10
            Start-VM -Name $Script:VMName -ErrorAction SilentlyContinue
        }

        Write-Host "." -NoNewline
        Start-Sleep -Seconds 10
        $elapsed += 10
    }

    Write-Host ""

    if (-not $heartbeatReady) {
        Write-Log "Timeout waiting for Windows installation" -Level Warning
        Write-Log "Please check VM manually via Hyper-V Manager" -Level Warning
    }

    # Additional wait for OOBE to complete
    Write-Log "Waiting for OOBE to complete..." -Level Info
    Start-Sleep -Seconds 120  # 2 minutes for OOBE

    Write-Log "Windows installation phase complete" -Level Success
}

#endregion

#region Windows Updates

function Install-WindowsUpdates {
    if ($SkipWindowsUpdates) {
        Write-Log "Skipping Windows Updates (as requested)" -Level Warning
        return
    }

    Write-Log "Installing Windows Updates via PowerShell Direct..." -Level Header
    Write-Log "This may take 30-60 minutes..." -Level Info

    # Create credentials
    $securePassword = if ($null -ne $AdminPassword) {
        $AdminPassword
    } else {
        ConvertTo-SecureString "VibeDev123!" -AsPlainText -Force
    }
    $credential = New-Object System.Management.Automation.PSCredential("Admin", $securePassword)

    # Wait for PowerShell Direct to be available
    $maxAttempts = 30
    $attempt = 0
    $connected = $false

    while ($attempt -lt $maxAttempts -and -not $connected) {
        try {
            $session = New-PSSession -VMName $Script:VMName -Credential $credential -ErrorAction Stop
            $connected = $true
            Write-Log "PowerShell Direct connection established" -Level Success
        } catch {
            $attempt++
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 10
        }
    }

    Write-Host ""

    if (-not $connected) {
        Write-Log "Could not establish PowerShell Direct connection" -Level Warning
        Write-Log "Windows Updates will need to be installed manually" -Level Warning
        return
    }

    try {
        # Install PSWindowsUpdate and run updates
        Invoke-Command -Session $session -ScriptBlock {
            # Install NuGet provider
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue

            # Install PSWindowsUpdate module
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false

            # Import module
            Import-Module PSWindowsUpdate

            # Get and install updates
            Write-Host "Checking for Windows Updates..."
            $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot

            if ($updates.Count -gt 0) {
                Write-Host "Found $($updates.Count) updates. Installing..."
                Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false
                Write-Host "Updates installed. A reboot may be required."
            } else {
                Write-Host "No updates available."
            }
        }

        Write-Log "Windows Updates completed" -Level Success

        # Reboot VM if needed
        Write-Log "Rebooting VM to apply updates..." -Level Info
        Restart-VM -Name $Script:VMName -Force -Wait

        # Wait for VM to be ready again
        Start-Sleep -Seconds 120

    } finally {
        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
    }
}

#endregion

#region DevBox Tools Installation

function Install-DevBoxTools {
    param(
        [string]$Profile = "Full"
    )

    if ($Profile -eq "None" -or $SkipDevBoxTools) {
        Write-Log "Skipping DevBox tools installation (profile: $Profile)" -Level Warning
        return
    }

    Write-Log "Installing DevBox tools in template (profile: $Profile)..." -Level Header
    Write-Log "This may take 20-40 minutes depending on the profile..." -Level Info

    # Create credentials
    $securePassword = if ($null -ne $AdminPassword) {
        $AdminPassword
    } else {
        ConvertTo-SecureString "VibeDev123!" -AsPlainText -Force
    }
    $credential = New-Object System.Management.Automation.PSCredential("Admin", $securePassword)

    # Wait for PowerShell Direct to be available
    $maxAttempts = 30
    $attempt = 0
    $session = $null

    Write-Log "Connecting to VM via PowerShell Direct..." -Level Info
    while ($attempt -lt $maxAttempts -and $null -eq $session) {
        try {
            $session = New-PSSession -VMName $Script:VMName -Credential $credential -ErrorAction Stop
            Write-Log "PowerShell Direct connection established" -Level Success
        } catch {
            $attempt++
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 10
        }
    }

    Write-Host ""

    if ($null -eq $session) {
        Write-Log "Could not establish PowerShell Direct connection" -Level Warning
        Write-Log "DevBox tools will need to be installed manually after VM creation" -Level Warning
        return
    }

    try {
        # Copy Install-DevBox.ps1 to VM
        Write-Log "Copying Install-DevBox.ps1 to template VM..." -Level Info
        $installScriptPath = Join-Path (Split-Path $Script:ScriptRoot -Parent) "Install-DevBox.ps1"

        if (-not (Test-Path $installScriptPath)) {
            Write-Log "Install-DevBox.ps1 not found at: $installScriptPath" -Level Error
            return
        }

        # Create destination directory in VM
        Invoke-Command -Session $session -ScriptBlock {
            if (-not (Test-Path "C:\DevBox")) {
                New-Item -Path "C:\DevBox" -ItemType Directory -Force | Out-Null
            }
        }

        # Copy the script content (can't use Copy-Item directly to VM)
        $scriptContent = Get-Content $installScriptPath -Raw
        Invoke-Command -Session $session -ScriptBlock {
            param($content)
            $content | Out-File -FilePath "C:\DevBox\Install-DevBox.ps1" -Encoding UTF8 -Force
        } -ArgumentList $scriptContent

        Write-Log "Install-DevBox.ps1 copied to VM" -Level Success

        # Run the installer with the selected profile
        Write-Log "Running DevBox installer with profile: $Profile..." -Level Info
        Write-Log "This is the key step - tools will be pre-installed in the template!" -Level Info

        $installResult = Invoke-Command -Session $session -ScriptBlock {
            param($profileName)

            try {
                # Ensure execution policy allows scripts to run
                Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

                Set-Location "C:\DevBox"

                # Run installer in silent mode with the specified profile
                $installArgs = @{
                    Silent = $true
                    Profile = $profileName
                    NoReboot = $true
                }

                # Source the script and run
                & "C:\DevBox\Install-DevBox.ps1" -Silent -Profile $profileName -NoReboot

                return @{ Success = $true; Message = "Installation completed" }
            } catch {
                return @{ Success = $false; Message = $_.Exception.Message }
            }
        } -ArgumentList $Profile

        if ($installResult.Success) {
            Write-Log "DevBox tools installed successfully in template!" -Level Success
        } else {
            Write-Log "DevBox tools installation had issues: $($installResult.Message)" -Level Warning
        }

        # Clean up temporary files but keep the tools
        Write-Log "Cleaning up temporary installation files..." -Level Info
        Invoke-Command -Session $session -ScriptBlock {
            # Clean temp files
            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

            # Clear WinGet cache
            Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_*\LocalState\*" -Recurse -Force -ErrorAction SilentlyContinue

            # Clear Chocolatey cache if it exists
            if (Test-Path "C:\ProgramData\chocolatey\cache") {
                Remove-Item -Path "C:\ProgramData\chocolatey\cache\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Write-Log "Template now has DevBox tools pre-installed!" -Level Success

    } finally {
        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
    }
}

#endregion

#region Sysprep

function Invoke-Sysprep {
    Write-Log "Running Sysprep to generalize the image..." -Level Header

    # Create credentials
    $securePassword = if ($null -ne $AdminPassword) {
        $AdminPassword
    } else {
        ConvertTo-SecureString "VibeDev123!" -AsPlainText -Force
    }
    $credential = New-Object System.Management.Automation.PSCredential("Admin", $securePassword)

    # Connect via PowerShell Direct
    $maxAttempts = 30
    $attempt = 0
    $session = $null
    $lastError = $null

    Write-Log "Connecting to VM via PowerShell Direct (user: Admin)..." -Level Info
    while ($attempt -lt $maxAttempts -and $null -eq $session) {
        try {
            $session = New-PSSession -VMName $Script:VMName -Credential $credential -ErrorAction Stop
            Write-Log "PowerShell Direct connection established" -Level Success
        } catch {
            $lastError = $_.Exception.Message
            $attempt++
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 10
        }
    }
    Write-Host ""

    if ($null -eq $session) {
        Write-Log "Connection attempts: $attempt, Last error: $lastError" -Level Error
        Write-Log "Tip: VM user is 'Admin' with password 'VibeDev123!' - verify OOBE completed" -Level Warning
        throw "Could not connect to VM for Sysprep after $maxAttempts attempts"
    }

    try {
        # Run Sysprep
        Write-Log "Executing Sysprep with /generalize /oobe /shutdown /mode:vm..." -Level Info

        Invoke-Command -Session $session -ScriptBlock {
            # Clean up temp files
            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

            # Remove machine-specific files
            Remove-Item -Path "C:\Windows\Panther\*" -Recurse -Force -ErrorAction SilentlyContinue

            # Run Sysprep - DO NOT use -Wait as sysprep will shutdown the VM
            # which terminates the PS session and causes an error
            $sysprepPath = "$env:SystemRoot\System32\Sysprep\sysprep.exe"
            $sysprepArgs = "/generalize /oobe /shutdown /mode:vm"

            Start-Process -FilePath $sysprepPath -ArgumentList $sysprepArgs -NoNewWindow
            # Give sysprep a moment to start before session closes
            Start-Sleep -Seconds 5
        }

        Write-Log "Sysprep initiated - VM will shut down when complete" -Level Info

    } catch {
        # Expected: session terminates when VM shuts down during sysprep
        if ($_.Exception.Message -match "socket target process has ended|transport failure|connection was closed") {
            Write-Log "Sysprep initiated - VM is shutting down" -Level Info
        } else {
            throw
        }
    } finally {
        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
    }

    # Wait for VM to shut down
    Write-Log "Waiting for VM to shut down..." -Level Info
    $timeout = 600  # 10 minutes
    $elapsed = 0

    while ($elapsed -lt $timeout) {
        $vmState = (Get-VM -Name $Script:VMName).State
        if ($vmState -eq "Off") {
            Write-Log "VM has shut down (Sysprep complete)" -Level Success
            break
        }
        Start-Sleep -Seconds 10
        $elapsed += 10
    }

    if ((Get-VM -Name $Script:VMName).State -ne "Off") {
        Write-Log "VM did not shut down in expected time" -Level Warning
        Stop-VM -Name $Script:VMName -Force -TurnOff
    }
}

#endregion

#region Export Template

function Export-Template {
    Write-Log "Exporting optimized template..." -Level Header

    # Get the VM's VHDX path
    $vmVHDXPath = (Get-VMHardDiskDrive -VMName $Script:VMName).Path

    # Optimize VHDX
    Write-Log "Optimizing VHDX (compacting)..." -Level Info
    Optimize-VHD -Path $vmVHDXPath -Mode Full

    # Copy to final location
    Write-Log "Copying to final template location: $Script:VHDXPath" -Level Info
    Copy-Item -Path $vmVHDXPath -Destination $Script:VHDXPath -Force

    # Set read-only
    Write-Log "Setting template as read-only..." -Level Info
    Set-ItemProperty -Path $Script:VHDXPath -Name IsReadOnly -Value $true

    # Clean up build VM
    Write-Log "Cleaning up build VM..." -Level Info
    Remove-VM -Name $Script:VMName -Force
    Remove-Item -Path $vmVHDXPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $Script:TempVHDXPath -Force -ErrorAction SilentlyContinue

    # Get template size
    $templateSize = [math]::Round((Get-Item $Script:VHDXPath).Length / 1GB, 2)

    Write-Log "Template exported successfully" -Level Success
    Write-Log "Template path: $Script:VHDXPath" -Level Info
    Write-Log "Template size: ${templateSize}GB" -Level Info
}

#endregion

#region Main

function Main {
    $startTime = Get-Date

    Show-Banner

    # Check if running in interactive mode (no ISOPath provided)
    if ([string]::IsNullOrEmpty($ISOPath)) {
        Write-Log "Starting interactive mode..." -Level Info
        $config = Invoke-InteractiveMode

        if ($null -eq $config) {
            Write-Host ""
            Write-Host "  Template creation cancelled." -ForegroundColor Yellow
            Write-Host ""
            return
        }

        # Validate config is a hashtable with required properties
        if ($config -isnot [hashtable]) {
            Write-Host ""
            Write-Host "  [ERROR] Invalid configuration returned (expected hashtable, got $($config.GetType().Name))." -ForegroundColor Red
            Write-Host ""
            return
        }

        if (-not $config.ContainsKey('ISOPath') -or [string]::IsNullOrEmpty($config['ISOPath'])) {
            Write-Host ""
            Write-Host "  [ERROR] No ISO path specified in configuration." -ForegroundColor Red
            Write-Host ""
            return
        }

        # Apply interactive configuration to script variables
        $Script:ISOPath = $config.ISOPath
        $Script:TemplatePath = $config.TemplatePath
        $Script:TemplateName = $config.TemplateName
        $Script:MemoryGB = $config.MemoryGB
        $Script:ProcessorCount = $config.ProcessorCount
        $Script:DiskSizeGB = $config.DiskSizeGB
        $Script:SwitchName = $config.SwitchName
        $Script:SkipWindowsUpdates = $config.SkipWindowsUpdates
        $Script:WindowsEditionIndex = $config.WindowsEditionIndex
        $Script:WindowsEditionName = $config.WindowsEditionName
        $Script:WindowsProductKey = $config.WindowsProductKey
        $Script:IsServer = $config.IsServer
        $Script:TimeZone = $config.TimeZone
        $Script:InputLocale = $config.InputLocale
        $Script:SystemLocale = $config.SystemLocale
        $Script:UILanguage = $config.UILanguage
        $Script:UserLocale = $config.UserLocale
        $Script:DevBoxProfile = $config.DevBoxProfile

        # Update local variables for use in this function
        $ISOPath = $config.ISOPath
        $TemplatePath = $config.TemplatePath
        $TemplateName = $config.TemplateName
        $MemoryGB = $config.MemoryGB
        $ProcessorCount = $config.ProcessorCount
        $DiskSizeGB = $config.DiskSizeGB
        $DevBoxProfile = $config.DevBoxProfile
        $WindowsEditionIndex = $config.WindowsEditionIndex

        Clear-Host
        Show-Banner
    }

    Write-Log "DevBox Template Creator started" -Level Header
    Write-Log "ISO: $ISOPath" -Level Info
    $editionDisplay = if ($Script:WindowsEditionName) { $Script:WindowsEditionName } else { "Windows 11 Pro" }
    Write-Log "Edition: $editionDisplay (Index $WindowsEditionIndex)" -Level Info
    Write-Log "Template: $TemplatePath\$TemplateName.vhdx" -Level Info
    Write-Log "VM Specs: ${MemoryGB}GB RAM, $ProcessorCount CPUs, ${DiskSizeGB}GB Disk" -Level Info
    $tzDisplay = if ($Script:TimeZone) { $Script:TimeZone } else { $TimeZone }
    $localeDisplay = if ($Script:InputLocale) { $Script:InputLocale } else { $Script:RegionalSettings.InputLocale }
    Write-Log "Regional: $tzDisplay, $localeDisplay" -Level Info
    $profileDisplay = if ($Script:DevBoxProfile) { $Script:DevBoxProfile } elseif ($DevBoxProfile) { $DevBoxProfile } else { "Full" }
    Write-Log "DevBox Profile: $profileDisplay (tools will be PRE-INSTALLED)" -Level Info

    try {
        # Step 1: Install prerequisites
        Install-Prerequisites

        # Step 2: Check disk space
        Test-DiskSpace

        # Step 3: Create bootable VHDX
        New-BootableVHDX

        # Step 4: Create and configure VM
        New-TemplateVM

        # Step 5: Start VM and wait for Windows install
        Start-TemplateVM

        # Step 6: Install Windows Updates
        Install-WindowsUpdates

        # Step 7: Install DevBox Tools IN THE TEMPLATE
        # This is the key step that makes VMs "ready to code" instantly!
        $profileToInstall = if ($Script:DevBoxProfile) { $Script:DevBoxProfile } else { $DevBoxProfile }
        if ([string]::IsNullOrEmpty($profileToInstall)) { $profileToInstall = "Full" }
        Install-DevBoxTools -Profile $profileToInstall

        # Step 8: Sysprep
        Invoke-Sysprep

        # Step 9: Export template
        Export-Template

        # Step 10: Register template in asset registry
        if (Get-Command Register-DevBoxTemplate -ErrorAction SilentlyContinue) {
            $registeredName = if ($Script:TemplateName) { $Script:TemplateName } else { $TemplateName }
            Register-DevBoxTemplate -Name $registeredName `
                -VHDXPath $Script:VHDXPath `
                -SourceISO $ISOPath `
                -WindowsEditionIndex $WindowsEditionIndex `
                -Profile $profileToInstall | Out-Null
            Write-Log "Template registered in asset registry" -Level Info
        }

        $duration = (Get-Date) - $startTime
        Write-Log "Template creation completed in $([math]::Round($duration.TotalMinutes, 1)) minutes" -Level Success
        Write-Log "" -Level Info
        Write-Log "TEMPLATE READY with DevBox tools PRE-INSTALLED!" -Level Success
        Write-Log "" -Level Info
        Write-Host "  VM Credentials for all VMs created from this template:" -ForegroundColor Yellow
        Write-Host "    Username: " -ForegroundColor White -NoNewline
        Write-Host "Admin" -ForegroundColor Green
        Write-Host "    Password: " -ForegroundColor White -NoNewline
        Write-Host "VibeDev123!" -ForegroundColor Green
        Write-Host "    Note: NOT 'Administrator' - the local account is 'Admin'" -ForegroundColor DarkGray
        Write-Host ""
        Write-Log "Next step: Create VMs from this template - they will be READY TO CODE instantly!" -Level Info
        Write-Log "Command: .\devbox vm -VMName 'DevVM-01'" -Level Info
        Write-Log "Or run: .\vms\New-DevBoxVM.ps1 -VMName 'DevVM-01' -TemplatePath '$Script:VHDXPath'" -Level Info

    } catch {
        Write-Log "Template creation failed: $_" -Level Error
        Write-Log $_.ScriptStackTrace -Level Error

        # Cleanup on failure
        Write-Log "Cleaning up..." -Level Warning
        Stop-VM -Name $Script:VMName -Force -TurnOff -ErrorAction SilentlyContinue
        Remove-VM -Name $Script:VMName -Force -ErrorAction SilentlyContinue
        Dismount-VHD -Path $Script:TempVHDXPath -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue

        throw
    }
}

# Run main
Main
