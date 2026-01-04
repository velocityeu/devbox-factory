# VibeDev Hyper-V VM Automation

Automated Windows 11 development VM creation for Hyper-V hosts.

## Overview

Two-stage process for rapid development VM deployment:

1. **Stage 1** (`New-VibeDevTemplate.ps1`): Create a sysprepped Windows 11 VHDX template
2. **Stage 2** (`New-VibeDevVM.ps1`): Clone template to create ready-to-use dev VMs

## Quick Start

### Stage 1: Create Template (One-Time)

```powershell
# Run as Administrator
.\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso"
```

This takes 30-60 minutes and creates a reusable template.

### Stage 2: Create Development VMs (Fast)

```powershell
# Create a single VM with automatic VibeDev installation
.\New-VibeDevVM.ps1 -VMName "DevVM-01" -InstallMode Automatic -StartVM

# Create 5 team VMs
.\New-VibeDevVM.ps1 -VMName "TeamDev" -Count 5 -VibeDevProfile Full -StartVM
```

VM creation takes 2-5 minutes per VM.

## Prerequisites

### Host Requirements

| Requirement | Minimum |
|-------------|---------|
| OS | Windows 10/11 Pro, Enterprise, or Server 2016+ |
| RAM | 16GB (8GB for VM + host overhead) |
| Disk Space | 150GB free (template + VMs) |
| CPU | VT-x/AMD-V enabled in BIOS |

### Auto-Installed Dependencies

The template script automatically installs:

- **Hyper-V** - VM platform
- **Windows ADK** - DISM, bcdboot for image creation
- **Windows PE Add-on** - Bootable image support

## Stage 1: New-VibeDevTemplate.ps1

Creates a sysprepped Windows 11 VHDX template from ISO.

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-ISOPath` | (Required) | Path to Windows 11 ISO |
| `-TemplatePath` | `C:\HyperV\Templates` | Template storage location |
| `-TemplateName` | `Win11-VibeDev-Template` | Template name |
| `-MemoryGB` | `8` | RAM for template VM |
| `-ProcessorCount` | `4` | CPU cores for template VM |
| `-DiskSizeGB` | `127` | VHDX size |
| `-SwitchName` | `Default Switch` | Virtual switch |
| `-SkipWindowsUpdates` | - | Skip updates (faster) |
| `-AdminPassword` | - | Secure password (default: VibeDev123!) |
| `-WindowsEditionIndex` | `6` | Windows edition (6=Pro) |
| `-TimeZone` | `Pacific Standard Time` | Timezone |

### Windows Edition Indices

| Index | Edition |
|-------|---------|
| 1 | Home |
| 3 | Home Single Language |
| 5 | Education |
| 6 | Pro (default) |
| 8 | Pro for Workstations |

### Examples

```powershell
# Basic template creation
.\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso"

# Fast template (skip updates)
.\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso" `
    -SkipWindowsUpdates -MemoryGB 16

# Custom location and specs
.\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso" `
    -TemplatePath "D:\Templates" `
    -MemoryGB 16 `
    -DiskSizeGB 256

# Custom password
$password = Read-Host -AsSecureString "Enter admin password"
.\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso" `
    -AdminPassword $password
```

### Workflow

1. Install prerequisites (Hyper-V, ADK)
2. Create VHDX with GPT partitions (EFI + MSR + Windows)
3. Apply Windows image with DISM
4. Inject autounattend.xml
5. Create Gen2 VM with TPM, Secure Boot
6. Run Windows installation
7. Apply Windows Updates (optional)
8. Sysprep with /generalize
9. Export optimized template

## Stage 2: New-VibeDevVM.ps1

Creates development VMs from the template.

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-VMName` | (Required) | VM name |
| `-TemplatePath` | `C:\HyperV\Templates\Win11-VibeDev-Template.vhdx` | Template VHDX |
| `-VMPath` | `C:\HyperV\VMs` | VM storage location |
| `-MemoryGB` | `8` | RAM allocation |
| `-ProcessorCount` | `4` | CPU cores |
| `-DiskSizeGB` | `127` | Disk size (>= template) |
| `-DynamicMemory` | - | Enable dynamic memory |
| `-SwitchName` | `Default Switch` | Virtual switch |
| `-InstallMode` | `Automatic` | VibeDev install mode |
| `-VibeDevProfile` | `Full` | VibeDev profile |
| `-Count` | `1` | Number of VMs |
| `-NamePattern` | `-{0:D2}` | Multi-VM naming |
| `-StartVM` | - | Start after creation |

### Installation Modes

| Mode | Behavior |
|------|----------|
| **Automatic** | Auto-login, run Install-VibeDev.ps1 silently |
| **SemiAutomatic** | Auto-login, desktop shortcut for installer |
| **Manual** | Just Windows, no auto-install |

### VibeDev Profiles

| Profile | What's Installed |
|---------|------------------|
| **Full** | Everything: AI tools, Web Dev, Azure, Docker, DBs |
| **AICoder** | Claude Code, Cursor, VS Code + AI extensions, Node.js, Python |
| **WebDev** | Node.js, Python, Docker, PostgreSQL, MongoDB, Redis |
| **Azure** | Azure CLI, Functions, .NET SDK, Terraform, Bicep |
| **Minimal** | Git, Windows Terminal, VS Code |

### Examples

```powershell
# Single dev VM with full VibeDev
.\New-VibeDevVM.ps1 -VMName "DevVM-01" -StartVM

# AI-focused development
.\New-VibeDevVM.ps1 -VMName "AI-Dev" `
    -InstallMode Automatic `
    -VibeDevProfile AICoder `
    -MemoryGB 16 `
    -StartVM

# Create team VMs
.\New-VibeDevVM.ps1 -VMName "TeamDev" `
    -Count 5 `
    -VibeDevProfile Full `
    -MemoryGB 8 `
    -StartVM

# High-spec Azure development
.\New-VibeDevVM.ps1 -VMName "Azure-Dev" `
    -VibeDevProfile Azure `
    -MemoryGB 16 `
    -ProcessorCount 8 `
    -DiskSizeGB 256 `
    -StartVM

# Clean Windows (no auto-install)
.\New-VibeDevVM.ps1 -VMName "CleanVM" -InstallMode Manual -StartVM
```

## Default Credentials

| Username | Password |
|----------|----------|
| Admin | VibeDev123! |

Change after first login for security.

## File Structure

```
HyperV/
├── New-VibeDevTemplate.ps1   # Stage 1: Template creation
├── New-VibeDevVM.ps1         # Stage 2: VM creation
├── autounattend.xml          # Unattended Windows install
├── SetupComplete.ps1         # Post-install configuration
└── README.md                 # This file
```

## Template Configuration

The template includes:

### Windows Settings
- Developer Mode enabled
- File extensions visible
- Hidden files visible
- Web search disabled in Start
- Telemetry minimized
- PowerShell execution policy: Bypass

### Features Enabled
- WSL (Windows Subsystem for Linux)
- Virtual Machine Platform (WSL2)
- Windows Sandbox (Pro/Enterprise)

### Services Disabled
- DiagTrack (Telemetry)
- dmwappushservice
- MapsBroker
- Geolocation Service

## Troubleshooting

### "Hyper-V not available"

1. Enable in BIOS: VT-x (Intel) or AMD-V (AMD)
2. Run: `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All`
3. Reboot

### Template creation fails

Check log: `%USERPROFILE%\VibeDev-Template.log`

Common issues:
- ISO file corrupted - verify SHA256
- Insufficient disk space
- WinGet not available - install App Installer from Store

### VM won't start

1. Verify template exists: `Test-Path "C:\HyperV\Templates\Win11-VibeDev-Template.vhdx"`
2. Check virtual switch: `Get-VMSwitch`
3. Verify TPM: `Get-VM -Name "VMName" | Get-VMSecurity`

### VibeDev installation fails in VM

1. Check log in VM: `C:\Users\Admin\VibeDev-Install.log`
2. Verify internet connectivity
3. Run manually: `C:\VibeDev\Install-VibeDev.ps1`

### Nested virtualization (Docker in VM)

Enable on host before creating VM:
```powershell
Set-VMProcessor -VMName "VMName" -ExposeVirtualizationExtensions $true
```

## Log Files

| Log | Location |
|-----|----------|
| Template creation | `%USERPROFILE%\VibeDev-Template.log` (host) |
| VM creation | `%USERPROFILE%\VibeDev-VM.log` (host) |
| SetupComplete | `C:\Windows\Temp\SetupComplete.log` (VM) |
| VibeDev install | `%USERPROFILE%\VibeDev-Install.log` (VM) |

## Performance Tips

1. **Use SSD** for template and VM storage
2. **Allocate enough RAM** - 8GB minimum, 16GB recommended
3. **Use dynamic memory** for multiple VMs on limited RAM
4. **Skip Windows Updates** in template for faster creation
5. **Use internal switch** if internet not needed

## Security Notes

- Default password is public - change after first login
- Template is sysprepped - unique SID per VM
- Auto-login is temporary (3-5 logins max)
- TPM keys are unique per VM
