<#
.SYNOPSIS
    Creates development VMs from the VibeDev Windows 11 template.

.DESCRIPTION
    Stage 2 of VibeDev VM automation. This script:
    1. Clones the sysprepped Windows 11 template VHDX
    2. Injects computer name and configuration
    3. Optionally copies VibeDev installation scripts
    4. Creates a Gen2 VM with TPM and Secure Boot
    5. Starts the VM with chosen installation mode

.PARAMETER VMName
    Name for the new VM (required)

.PARAMETER TemplatePath
    Path to the template VHDX file. Default: C:\HyperV\Templates\Win11-VibeDev-Template.vhdx

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
    VibeDev installation mode:
    - Automatic: Auto-login and run Install-VibeDev.ps1 silently
    - SemiAutomatic: Auto-login with desktop shortcut for installer
    - Manual: Just create VM, no auto-install

.PARAMETER VibeDevProfile
    VibeDev installation profile: Full, AICoder, WebDev, Azure, Minimal

.PARAMETER Count
    Number of VMs to create. Default: 1

.PARAMETER NamePattern
    Naming pattern for multiple VMs. Default: "-{0:D2}" (e.g., DevVM-01, DevVM-02)

.PARAMETER StartVM
    Start the VM after creation

.PARAMETER AdminPassword
    Secure password for local Admin account

.EXAMPLE
    .\New-VibeDevVM.ps1 -VMName "DevVM-01" -StartVM

.EXAMPLE
    .\New-VibeDevVM.ps1 -VMName "AI-Dev" -InstallMode Automatic -VibeDevProfile AICoder -StartVM

.EXAMPLE
    .\New-VibeDevVM.ps1 -VMName "TeamDev" -Count 5 -MemoryGB 16 -StartVM

.NOTES
    Requires: VibeDev template created by New-VibeDevTemplate.ps1
    Author: VibeDev Team
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [string]$TemplatePath = "C:\HyperV\Templates\Win11-VibeDev-Template.vhdx",
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
    [string]$VibeDevProfile = "Full",

    [ValidateRange(1, 100)]
    [int]$Count = 1,

    [string]$NamePattern = "-{0:D2}",

    [switch]$StartVM,

    [SecureString]$AdminPassword
)

#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script-level variables
$Script:LogPath = Join-Path $env:USERPROFILE "VibeDev-VM.log"
$Script:ScriptRoot = $PSScriptRoot
$Script:ParentRoot = Split-Path $PSScriptRoot -Parent
$Script:InstallVibeDevPath = Join-Path $Script:ParentRoot "Install-VibeDev.ps1"
$Script:CreatedVMs = @()

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
    $banner = @"

  ╔═══════════════════════════════════════════════════════════════╗
  ║   ██╗   ██╗██╗██████╗ ███████╗    ██████╗ ███████╗██╗   ██╗   ║
  ║   ██║   ██║██║██╔══██╗██╔════╝    ██╔══██╗██╔════╝██║   ██║   ║
  ║   ██║   ██║██║██████╔╝█████╗      ██║  ██║█████╗  ██║   ██║   ║
  ║   ╚██╗ ██╔╝██║██╔══██╗██╔══╝      ██║  ██║██╔══╝  ╚██╗ ██╔╝   ║
  ║    ╚████╔╝ ██║██████╔╝███████╗    ██████╔╝███████╗ ╚████╔╝    ║
  ║     ╚═══╝  ╚═╝╚═════╝ ╚══════╝    ╚═════╝ ╚══════╝  ╚═══╝     ║
  ╠═══════════════════════════════════════════════════════════════╣
  ║           HYPER-V VM CREATOR - Stage 2                        ║
  ╚═══════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}

#endregion

#region Validation

function Test-Prerequisites {
    Write-Log "Validating prerequisites..." -Level Header

    # Check Hyper-V
    if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
        throw "Hyper-V PowerShell module not available. Please run New-VibeDevTemplate.ps1 first."
    }
    Import-Module Hyper-V

    # Check template exists
    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath`nPlease run New-VibeDevTemplate.ps1 first."
    }
    Write-Log "Template found: $TemplatePath" -Level Success

    # Check virtual switch
    $switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if ($null -eq $switch) {
        throw "Virtual switch '$SwitchName' not found. Available switches: $((Get-VMSwitch).Name -join ', ')"
    }
    Write-Log "Virtual switch '$SwitchName' available" -Level Success

    # Check Install-VibeDev.ps1 for non-Manual modes
    if ($InstallMode -ne "Manual") {
        if (-not (Test-Path $Script:InstallVibeDevPath)) {
            Write-Log "Install-VibeDev.ps1 not found at $Script:InstallVibeDevPath" -Level Warning
            Write-Log "VibeDev auto-installation will be skipped" -Level Warning
        } else {
            Write-Log "Install-VibeDev.ps1 found" -Level Success
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
            if ($InstallMode -eq "Automatic" -and (Test-Path $Script:InstallVibeDevPath)) {
                $unattendContent += @"
                <SynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <CommandLine>powershell.exe -ExecutionPolicy Bypass -File "C:\VibeDev\Install-VibeDev.ps1" -Silent -Profile $VibeDevProfile</CommandLine>
                    <Description>Install VibeDev tools</Description>
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

        # Copy Install-VibeDev.ps1 if needed
        if ($InstallMode -ne "Manual" -and (Test-Path $Script:InstallVibeDevPath)) {
            Write-Log "Copying VibeDev installation scripts..." -Level Info
            $vibeDevDir = "${winLetter}:\VibeDev"
            if (-not (Test-Path $vibeDevDir)) {
                New-Item -Path $vibeDevDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $Script:InstallVibeDevPath -Destination "$vibeDevDir\Install-VibeDev.ps1" -Force

            # Create desktop shortcut for SemiAutomatic mode
            if ($InstallMode -eq "SemiAutomatic") {
                $publicDesktop = "${winLetter}:\Users\Public\Desktop"
                $shortcutContent = @"
@echo off
echo Starting VibeDev Installation...
powershell.exe -ExecutionPolicy Bypass -File "C:\VibeDev\Install-VibeDev.ps1"
pause
"@
                $shortcutContent | Out-File -FilePath "$publicDesktop\Install-VibeDev.cmd" -Encoding ascii -Force
                Write-Log "Created desktop shortcut for VibeDev installer" -Level Info
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

function New-VibeDevVM {
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

    Write-Log "VibeDev VM Creator started" -Level Header
    Write-Log "Base Name: $VMName" -Level Info
    Write-Log "Count: $Count" -Level Info
    Write-Log "Profile: $VibeDevProfile" -Level Info
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
            $vm = New-VibeDevVM -NewVMName $name -VHDXPath $vhdxPath

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
            Write-Host "VibeDev tools will be installed automatically on first login." -ForegroundColor Cyan
            Write-Host "Profile: $VibeDevProfile" -ForegroundColor Cyan
        } elseif ($InstallMode -eq "SemiAutomatic") {
            Write-Host ""
            Write-Host "Run 'Install-VibeDev.cmd' from the desktop to install VibeDev tools." -ForegroundColor Cyan
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
