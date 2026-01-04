<#
.SYNOPSIS
    Creates a sysprepped Windows 11 VHDX template for VibeDev development VMs.

.DESCRIPTION
    Stage 1 of VibeDev VM automation. This script:
    1. Installs prerequisites (Hyper-V, Windows ADK)
    2. Creates a bootable VHDX from Windows 11 ISO
    3. Creates a Gen2 VM with TPM and Secure Boot
    4. Runs Windows installation unattended
    5. Applies Windows Updates (optional)
    6. Runs Sysprep to generalize the image
    7. Exports the optimized VHDX template

.PARAMETER ISOPath
    Path to Windows 11 ISO file (required)

.PARAMETER TemplatePath
    Directory to store the template VHDX. Default: C:\HyperV\Templates

.PARAMETER TemplateName
    Name for the template. Default: Win11-VibeDev-Template

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
    Windows edition index in install.wim. Default: 6 (Pro)
    Common indices: 1=Home, 3=Home Single Language, 5=Education, 6=Pro, 8=Pro for Workstations

.PARAMETER TimeZone
    Windows timezone. Default: Pacific Standard Time

.EXAMPLE
    .\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso"

.EXAMPLE
    .\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso" -SkipWindowsUpdates -MemoryGB 16

.NOTES
    Requires: Windows 10/11 Pro or Server with Hyper-V capability
    Author: VibeDev Team
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ISOPath,

    [string]$TemplatePath = "C:\HyperV\Templates",
    [string]$TemplateName = "Win11-VibeDev-Template",

    [ValidateRange(4, 64)]
    [int]$MemoryGB = 8,

    [ValidateRange(2, 32)]
    [int]$ProcessorCount = 4,

    [ValidateRange(40, 2048)]
    [int]$DiskSizeGB = 127,

    [string]$SwitchName = "Default Switch",

    [switch]$SkipWindowsUpdates,

    [SecureString]$AdminPassword,

    [ValidateRange(1, 11)]
    [int]$WindowsEditionIndex = 6,

    [string]$TimeZone = "Pacific Standard Time"
)

#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Script-level variables
$Script:LogPath = Join-Path $env:USERPROFILE "VibeDev-Template.log"
$Script:RequiresReboot = $false
$Script:VMName = "$TemplateName-Build"
$Script:VHDXPath = Join-Path $TemplatePath "$TemplateName.vhdx"
$Script:TempVHDXPath = Join-Path $env:TEMP "$TemplateName-temp.vhdx"
$Script:ADKPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit"
$Script:ScriptRoot = $PSScriptRoot

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
  ║           HYPER-V TEMPLATE CREATOR - Stage 1                  ║
  ╚═══════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
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
    $hypervFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue

    if ($null -eq $hypervFeature) {
        # Try alternative check for Windows Server
        $hypervRole = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue
        if ($null -ne $hypervRole -and $hypervRole.InstallState -ne 'Installed') {
            Write-Log "Installing Hyper-V role (Server)..." -Level Info
            Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart:$false
            $Script:RequiresReboot = $true
        }
    } elseif ($hypervFeature.State -ne 'Enabled') {
        Write-Log "Enabling Hyper-V feature..." -Level Info
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -All
        $Script:RequiresReboot = $true
    } else {
        Write-Log "Hyper-V is already enabled" -Level Success
    }

    # 3. Check/Install Windows ADK
    Write-Log "Checking Windows ADK..." -Level Info
    $dismPath = Join-Path $Script:ADKPath "Deployment Tools\amd64\DISM\dism.exe"
    $bcdbootPath = Join-Path $Script:ADKPath "Deployment Tools\amd64\BCDBoot\bcdboot.exe"

    if (-not (Test-Path $dismPath)) {
        Write-Log "Installing Windows ADK (this may take several minutes)..." -Level Info

        # Check if winget is available
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($null -eq $winget) {
            throw "WinGet is required to install Windows ADK. Please install App Installer from Microsoft Store."
        }

        # Install ADK
        $result = winget install --id Microsoft.WindowsADK --accept-source-agreements --accept-package-agreements --silent 2>&1
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
            Write-Log "WinGet output: $result" -Level Warning
        }

        # Wait for installation
        Start-Sleep -Seconds 5

        # Verify installation
        if (-not (Test-Path $dismPath)) {
            throw "Windows ADK installation failed. DISM not found at: $dismPath"
        }
        Write-Log "Windows ADK installed successfully" -Level Success
    } else {
        Write-Log "Windows ADK is already installed" -Level Success
    }

    # 4. Check/Install Windows PE Add-on
    Write-Log "Checking Windows PE Add-on..." -Level Info
    $winpePath = Join-Path $Script:ADKPath "Windows Preinstallation Environment"

    if (-not (Test-Path $winpePath)) {
        Write-Log "Installing Windows PE Add-on..." -Level Info
        $result = winget install --id Microsoft.ADKPEAddon --accept-source-agreements --accept-package-agreements --silent 2>&1
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
            Write-Log "WinGet output: $result" -Level Warning
        }
        Start-Sleep -Seconds 5
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
        $efiLetter = $efiPartition.DriveLetter

        # Microsoft Reserved Partition (16MB)
        New-Partition -DiskNumber $disk.Number -Size 16MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' | Out-Null

        # Windows Partition (rest of disk)
        $winPartition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
        $winPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" -Confirm:$false | Out-Null
        $winPartition | Add-PartitionAccessPath -AssignDriveLetter
        $winLetter = $winPartition.DriveLetter

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
            $unattendContent = $unattendContent -replace 'TIMEZONE_PLACEHOLDER', $TimeZone

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
    $credential = New-Object System.Management.Automation.PSCredential("Administrator", $securePassword)

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

#region Sysprep

function Invoke-Sysprep {
    Write-Log "Running Sysprep to generalize the image..." -Level Header

    # Create credentials
    $securePassword = if ($null -ne $AdminPassword) {
        $AdminPassword
    } else {
        ConvertTo-SecureString "VibeDev123!" -AsPlainText -Force
    }
    $credential = New-Object System.Management.Automation.PSCredential("Administrator", $securePassword)

    # Connect via PowerShell Direct
    $maxAttempts = 20
    $attempt = 0
    $session = $null

    while ($attempt -lt $maxAttempts -and $null -eq $session) {
        try {
            $session = New-PSSession -VMName $Script:VMName -Credential $credential -ErrorAction Stop
        } catch {
            $attempt++
            Start-Sleep -Seconds 10
        }
    }

    if ($null -eq $session) {
        throw "Could not connect to VM for Sysprep"
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

            # Run Sysprep
            $sysprepPath = "$env:SystemRoot\System32\Sysprep\sysprep.exe"
            $args = "/generalize /oobe /shutdown /mode:vm"

            Start-Process -FilePath $sysprepPath -ArgumentList $args -Wait -NoNewWindow
        }

        Write-Log "Sysprep initiated - VM will shut down when complete" -Level Info

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

    Write-Log "VibeDev Template Creator started" -Level Header
    Write-Log "ISO: $ISOPath" -Level Info
    Write-Log "Template: $TemplatePath\$TemplateName.vhdx" -Level Info
    Write-Log "VM Specs: ${MemoryGB}GB RAM, $ProcessorCount CPUs, ${DiskSizeGB}GB Disk" -Level Info

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

        # Step 7: Sysprep
        Invoke-Sysprep

        # Step 8: Export template
        Export-Template

        $duration = (Get-Date) - $startTime
        Write-Log "Template creation completed in $([math]::Round($duration.TotalMinutes, 1)) minutes" -Level Success
        Write-Log "" -Level Info
        Write-Log "Next step: Use New-VibeDevVM.ps1 to create development VMs from this template" -Level Info
        Write-Log "Example: .\New-VibeDevVM.ps1 -VMName 'DevVM-01' -TemplatePath '$Script:VHDXPath'" -Level Info

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
