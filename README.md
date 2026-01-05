# DevBox Factory

![Version](https://img.shields.io/badge/version-3.0.3-blue) ![Build](https://img.shields.io/badge/build-20260105.0400-darkgray) ![Platform](https://img.shields.io/badge/platform-Windows%2011-0078D4) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)

**One command. Identical dev environments. Every time.**

Professional-grade Windows 11 development environment automation. Create reproducible dev boxes with AI tools, full-stack runtimes, and Hyper-V VM templates.

> Built by [Velocity EU](https://www.velocity-eu.com) - Eliminating "works on my machine" since day one.

## Features

- **One-Line Bootstrap** - Download and setup from vanilla Windows 11 or Server 2025
- **Auto-Update** - Re-run bootstrap to check for updates and upgrade in-place
- **Offline Installation** - Pre-download dependencies for air-gapped environments
- **Download Progress** - Visual progress bars and spinners for all downloads
- **Tools PRE-INSTALLED in Template** - VMs are ready to code in 2-3 minutes
- **CLI Wrapper** - Human-friendly `.\devbox` commands
- **Pre-configured Profiles** - Full, AI Coder, Web Dev, Azure, or Minimal
- **Hyper-V VM Factory** - Create identical dev VMs from golden templates
- **Windows Edition Selection** - Choose Home, Pro, Enterprise, Education, or Server editions
- **Regional Auto-Detection** - Automatically uses host timezone, locale, and language
- **Interactive Menus** - Guided wizards with file pickers
- **Comprehensive Pre-flight Checks** - Validates Hyper-V, ISO, disk space upfront
- **Centralized Logging** - All operations logged to `log/` folder with timestamps
- **Temp File Management** - Cleanup command to manage temporary files
- **Health Checks** - Verify your environment with `.\devbox test`
- **Idempotent** - Safe to run multiple times

## The 3-Stage Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  STAGE 0: BOOTSTRAP                              (.\devbox init)            │
│  ─────────────────────────────────────────────────────────────────────────  │
│  • Checks Windows 11/Server 2025, Hyper-V, ISO, disk space                  │
│  • Downloads all DevBox Factory scripts                                     │
│  • Offers to enable Hyper-V if not enabled                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  STAGE 1: CREATE TEMPLATE (one-time, ~60 min)    (.\devbox template)        │
│  ─────────────────────────────────────────────────────────────────────────  │
│  • Select Windows ISO (Win11 or Server 2025)                                │
│  • Select DevBox profile (Full/AICoder/WebDev/Azure/Minimal)                │
│  • *** TOOLS ARE PRE-INSTALLED IN THE TEMPLATE ***                          │
│  • Sysprep and export template VHDX                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  STAGE 2: CREATE VMs (instant, ~2-3 min each)    (.\devbox vm)              │
│  ─────────────────────────────────────────────────────────────────────────  │
│  • Clone template to new VM                                                 │
│  • VM boots with ALL tools already installed                                │
│  • *** READY TO CODE IMMEDIATELY ***                                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Benefit:** Tools are installed ONCE in the template. Every VM cloned from it is instantly ready to use - no waiting 20-30 minutes for tool installation per VM!

## Quick Start

### Option 1: Bootstrap (Recommended)

Download all DevBox Factory scripts to your PC:

```powershell
# Run as Administrator
irm https://raw.githubusercontent.com/velocityeu/devbox-factory/main/Initialize-DevBox.ps1 | iex
```

This bootstrap script:
- Checks Windows 11 22H2+ or Server 2025 and Administrator privileges
- Validates Hyper-V capability, CPU virtualization, and disk space
- Scans for Windows ISO files in common locations
- Downloads all scripts including Hyper-V VM automation
- Offers to enable Hyper-V if not already enabled
- Guides you to the next step based on system readiness

### Option 2: Direct Install

Run the installer directly without downloading files:

```powershell
# Run as Administrator
irm https://raw.githubusercontent.com/velocityeu/devbox-factory/main/Install-DevBox.ps1 | iex
```

### Option 3: Clone and Run

```powershell
git clone https://github.com/velocityeu/devbox-factory.git
cd devbox-factory
.\devbox install
```

## CLI Commands

DevBox Factory provides a human-friendly CLI wrapper:

```powershell
.\devbox init          # Download and initialize DevBox Factory
.\devbox install       # Install development tools (interactive menu)
.\devbox template      # Create VM template from Windows ISO
.\devbox vm            # Create VM from template
.\devbox deps          # Manage offline dependencies (download/status)
.\devbox test          # Run health checks
.\devbox cleanup       # Clean temp files and old logs
.\devbox help          # Show help
```

### Help Menu

```
  +=====================================================================+
  |  DEVBOX FACTORY                                                     |
  |  One command. Identical dev environments. Every time.               |
  |  by Velocity EU                           v3.0.3 build 20260105.0400|
  +=====================================================================+

  USAGE: .\devbox <command> [arguments]

  COMMANDS:

    init        Download and initialize DevBox Factory
    install     Install development tools (interactive menu)
    template    Create VM template from Windows ISO
    vm          Create development VM from template
    deps        Manage offline dependencies (download/status)
    test        Run health checks and verify installation
    cleanup     Clean temp files and old logs
    help        Show this help message

  CLEANUP OPTIONS:

    .\devbox cleanup -Temp      Remove temporary files
    .\devbox cleanup -Logs      Remove logs older than 30 days
    .\devbox cleanup -All       Clean both temp and old logs

  EXAMPLES:

    .\devbox install
    .\devbox template -ISOPath C:\ISOs\Win11.iso
    .\devbox vm -VMName DevVM-01 -StartVM
    .\devbox cleanup -All

  MORE INFO:
    https://github.com/velocityeu/devbox-factory
```

---

## Interactive Menus

All DevBox Factory scripts feature interactive menus with guided wizards. Simply run any command without parameters to launch the menu.

### Installation Menu (`.\devbox install`)

```
  +=====================================================================+
  |  ____  ______      ______   ____  __  __                            |
  | |  _ \| ____\ \   / /  _ \ / __ \ \ \/ /                            |
  | | | | |  _|  \ \ / /| |_) | |  | | \  /                             |
  | | |_| | |___  \ V / |  _ <| |  | | /  \                             |
  | |____/|_____|  \_/  |_| \_\ \__/ /_/\_\                             |
  |                                                                     |
  |                      F A C T O R Y                                  |
  +=====================================================================+
  |  TOOL INSTALLER          Windows 11 Development Environment         |
  |  by Velocity EU                           v3.0.3 build 20260105.0400|
  +=====================================================================+

  SELECT INSTALLATION PROFILE

   [1] Full Installation (Recommended)
       Everything: AI tools, Web dev, Docker, Databases, Azure

   [2] AI Vibe Coder
       Claude Code, Cursor, VS Code + AI extensions, Node.js, Python

   [3] Full-Stack Web Developer
       Node.js, Python, Docker, PostgreSQL, MongoDB, Redis

   [4] Azure Cloud Developer
       Azure CLI, Functions, .NET SDK, Terraform, Bicep, Docker

   [5] Custom Installation
       Choose exactly what to install

   [6] Minimal (Core Only)
       Git, Windows Terminal, VS Code

   [Q] Quit

  Enter choice [1-6, Q]:
```

### Custom Installation Menu

When you select `[5] Custom Installation`:

```
  CUSTOM INSTALLATION - Select Components

   [1] Core Tools (Required)
       Git, Windows Terminal, VS Code

   [2] AI Coding Tools
       Claude Code, Cursor, VS Code AI extensions

   [3] Node.js Environment
       NVM, Node.js LTS, npm, pnpm, yarn, bun

   [4] Python
       Python 3.12 with pip

   [5] Docker & Containers
       WSL2, Docker Desktop

   [6] Databases
       PostgreSQL, MongoDB, Redis

   [7] Azure Development
       Azure CLI, Functions, .NET SDK, Terraform, Bicep

  Enter components (comma-separated, e.g., 2,3,4):
```

---

### Template Creation Menu (`.\devbox template`)

Stage 1 of VM automation - creates a sysprepped Windows 11 template VHDX.

```
  +=====================================================================+
  |  ____  ______      ______   ____  __  __                            |
  | |  _ \| ____\ \   / /  _ \ / __ \ \ \/ /                            |
  | | | | |  _|  \ \ / /| |_) | |  | | \  /                             |
  | | |_| | |___  \ V / |  _ <| |  | | /  \                             |
  | |____/|_____|  \_/  |_| \_\ \__/ /_/\_\                             |
  |                                                                     |
  |                      F A C T O R Y                                  |
  +=====================================================================+
  |  TEMPLATE CREATOR       Hyper-V Windows 11 Template - Stage 1       |
  |  by Velocity EU                           v3.0.3 build 20260105.0400|
  +=====================================================================+

  MAIN MENU

   [1] Quick Start (Recommended)
       Select ISO, use default settings, create template

   [2] Custom Configuration
       Configure all template settings manually

   [3] View Current Settings
       Review default configuration

   [Q] Quit

  Enter choice [1-3, Q]:
```

#### ISO Selection

```
  SELECT WINDOWS 11 ISO

  Found ISOs in common locations:

   [1] C:\ISOs\Win11_23H2_English_x64.iso (5.2 GB)
   [2] C:\Users\Admin\Downloads\Win11_23H2.iso (5.1 GB)

   [B] Browse for ISO file...
   [Q] Back

  Enter choice:
```

#### VM Preset Selection

```
  SELECT VM PRESET

   [1] Lightweight
       4 GB RAM, 2 CPUs, 80 GB Disk
       Best for: Testing, Light coding, Learning

   [2] Standard (Recommended)
       8 GB RAM, 4 CPUs, 127 GB Disk
       Best for: Web development, General coding, Most users

   [3] Performance
       16 GB RAM, 8 CPUs, 256 GB Disk
       Best for: AI/ML development, Multiple projects, Docker heavy

   [4] Server-Class
       32 GB RAM, 16 CPUs, 512 GB Disk
       Best for: Database hosting, Enterprise development

   [C] Custom specs...
   [B] Back

  Enter choice [1-4, C, B]:
```

---

### VM Creation Menu (`.\devbox vm`)

Stage 2 of VM automation - creates VMs from the template.

```
  +=====================================================================+
  |  ____  ______      ______   ____  __  __                            |
  | |  _ \| ____\ \   / /  _ \ / __ \ \ \/ /                            |
  | | | | |  _|  \ \ / /| |_) | |  | | \  /                             |
  | | |_| | |___  \ V / |  _ <| |  | | /  \                             |
  | |____/|_____|  \_/  |_| \_\ \__/ /_/\_\                             |
  |                                                                     |
  |                      F A C T O R Y                                  |
  +=====================================================================+
  |  VM CREATOR             Create Dev VMs from Template - Stage 2      |
  |  by Velocity EU                           v3.0.3 build 20260105.0400|
  +=====================================================================+

  MAIN MENU

   [1] Quick Create (Recommended)
       Create a single VM with default settings

   [2] Batch Create
       Create multiple VMs with naming pattern

   [3] Advanced Configuration
       Full control over all settings

   [4] List Existing VMs
       View and manage DevBox VMs

   [Q] Quit

  Enter choice [1-4, Q]:
```

#### DevBox Profile Selection

```
  SELECT DEVBOX PROFILE

  Choose which tools to auto-install on first boot:

   [1] Full (Recommended)
       Everything: AI tools, Web Dev, Azure, Docker, Databases

   [2] AI Coder
       Claude Code, Cursor, VS Code + AI extensions, Node.js, Python

   [3] Web Developer
       Node.js, Python, Docker, PostgreSQL, MongoDB, Redis

   [4] Azure Developer
       Azure CLI, Functions, .NET SDK, Terraform, Bicep

   [5] Minimal
       Git, Windows Terminal, VS Code only

   [N] None - skip DevBox installation

   [B] Back

  Enter choice [1-5, N, B]:
```

#### Batch VM Creation Preview

```
  BATCH VM CREATION

  Base Name: TeamDev
  Count: 5
  Pattern: -{0:D2}

  Preview of VM names:
    - TeamDev-01
    - TeamDev-02
    - TeamDev-03
    - TeamDev-04
    - TeamDev-05

  [C] Confirm and create
  [E] Edit settings
  [B] Back

  Enter choice:
```

#### Pre-flight Validation

```
  PRE-FLIGHT VALIDATION

   [+] Template VHDX exists
   [+] Hyper-V module available
   [+] Virtual switch 'Default Switch' found
   [+] Sufficient disk space (523 GB free)
   [+] No VM name conflicts
   [+] Install-DevBox.ps1 found (will copy to VM)

   All checks passed!

  [C] Continue with VM creation
  [B] Back to menu

  Enter choice:
```

---

### Health Check Menu (`.\devbox test`)

```
  +=====================================================================+
  |  ____  ______      ______   ____  __  __                            |
  | |  _ \| ____\ \   / /  _ \ / __ \ \ \/ /                            |
  | | | | |  _|  \ \ / /| |_) | |  | | \  /                             |
  | | |_| | |___  \ V / |  _ <| |  | | /  \                             |
  | |____/|_____|  \_/  |_| \_\ \__/ /_/\_\                             |
  |                                                                     |
  |                      F A C T O R Y                                  |
  +=====================================================================+
  |  HEALTH CHECK            Verify Installation and Environment        |
  |  by Velocity EU                           v3.0.3 build 20260105.0400|
  +=====================================================================+

  CORE TOOLS
  ----------
  Checking Git... [PASS] 2.43.0
  Checking VS Code... [PASS] 1.85.0
  Checking Windows Terminal... [PASS]
  Checking PowerShell 7... [PASS] 7.4.0

  AI CODING TOOLS
  ----------------
  Checking Claude Code... [PASS] 1.0.0
  Checking Cursor IDE... [PASS]
  Checking VS Code AI extensions... [PASS] 3 AI extension(s)

  DEVELOPMENT RUNTIMES
  ---------------------
  Checking Node.js... [PASS] 20.10.0
  Checking npm... [PASS] 10.2.3
  Checking Python... [PASS] 3.12.0
  Checking pip... [PASS] 23.3.1
  Checking .NET SDK... [PASS] 8.0.100
  Checking pnpm... [PASS] 8.12.0

  CONTAINERIZATION
  -----------------
  Checking Docker... [PASS] 24.0.7
  Checking Docker Compose... [PASS] 2.23.3
  Checking WSL... [PASS] 2.0.9.0
  Checking Docker Desktop Service... [PASS] Running

  HYPER-V / VM SUPPORT
  ---------------------
  Checking Hyper-V... [PASS] Enabled
  Checking Hyper-V VM Management... [PASS] Running
  Checking DevBox Templates... [PASS] C:\HyperV\Templates
  Checking DevBox VMs... [PASS] C:\HyperV\VMs

  NETWORK CONNECTIVITY
  ---------------------
  Checking GitHub access... [PASS] Connected
  Checking npm registry... [PASS] Connected

  +=================================================================+
  |                          SUMMARY                                |
  +=================================================================+

  Results: 22 passed, 0 warnings, 0 failed (of 22 checks)

  [OK] DevBox environment is healthy!
```

You can also run specific categories:

```powershell
.\devbox test -Category Core,AI      # Only check core and AI tools
.\devbox test -Category Docker       # Only check containerization
.\devbox test -Category HyperV       # Only check VM support
```

---

## Installation Profiles

| Profile | What's Included |
|---------|-----------------|
| **Full** | Everything: AI, Web Dev, Azure, Docker, Databases |
| **AICoder** | Claude Code, Cursor, VS Code + AI extensions, Node.js, Python |
| **WebDev** | Node.js, Python, Docker, PostgreSQL, MongoDB, Redis |
| **Azure** | Azure CLI, Functions, .NET SDK, Terraform, Bicep, Docker |
| **Minimal** | Git, Windows Terminal, VS Code only |

## What Gets Installed

### Core (Always Installed)
- Git
- Windows Terminal
- VS Code

### AI Coding Tools
- Claude Code (CLI)
- Cursor IDE
- VS Code Extensions: GitHub Copilot, Claude, Continue, Cline

### Web Development
- Node.js LTS (via NVM)
- npm, pnpm, yarn, bun
- Python 3.12
- VS Code Extensions: ESLint, Prettier, Tailwind, React snippets

### Databases
- PostgreSQL 16
- MongoDB
- Redis

### Containers
- WSL2
- Docker Desktop

### Azure Development
- Azure CLI
- Azure Functions Core Tools
- Azure Developer CLI (azd)
- Azure Data Studio
- Azure Storage Explorer
- Bicep CLI
- Terraform
- .NET SDK 8
- Az PowerShell Module

## Hyper-V VM Factory

Create pre-configured Windows 11/Server 2025 development VMs with **tools PRE-INSTALLED in the template**.

### Two-Stage Process

| Stage | Command | What Happens | Time |
|-------|---------|--------------|------|
| **1. Template** | `.\devbox template` | Create VHDX with Windows + DevBox tools installed | 60-90 min (one-time) |
| **2. VM** | `.\devbox vm` | Clone template → VM is **READY TO CODE** | 2-3 min each |

**The key difference:** Tools are installed IN THE TEMPLATE, not after VM creation. This means:
- Template creation takes longer (tools are installed once)
- VM creation is instant (just clone and boot)
- Every team member gets identical, ready-to-use environments

### ISO Files

Place your Windows ISO files in the `iso/` folder:

| OS | Download Link |
|----|---------------|
| **Windows 11 23H2/24H2** | [Microsoft Download](https://www.microsoft.com/software-download/windows11) |
| **Windows Server 2025** | [Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025) |

```
devbox-factory/
└── iso/
    ├── Win11_24H2_English_x64.iso      <- Place your ISO here
    └── README.md                        <- Instructions
```

### Interactive Mode

```powershell
# Stage 1: Create template with interactive wizard
.\devbox template

# Stage 2: Create VMs with interactive wizard
.\devbox vm
```

### Command-Line Mode

```powershell
# Stage 1: Create template from Windows 11 ISO
.\devbox template -ISOPath "C:\ISOs\Win11_23H2.iso"

# Stage 2: Create dev VMs
.\devbox vm -VMName "DevVM-01" -InstallMode Automatic -StartVM
```

### Installation Modes

| Mode | Behavior |
|------|----------|
| **Automatic** | Auto-login, run installer silently on first boot |
| **SemiAutomatic** | Auto-login, desktop shortcut for installer |
| **Manual** | Just Windows, no auto-install |

### VM Examples

```powershell
# AI Coder VM
.\devbox vm -VMName "AI-Dev" -DevBoxProfile AICoder -StartVM

# Team of 5 VMs
.\devbox vm -VMName "TeamDev" -Count 5 -MemoryGB 16 -StartVM

# High-spec Azure development
.\devbox vm -VMName "Azure-Dev" -DevBoxProfile Azure -MemoryGB 16 -ProcessorCount 8 -StartVM
```

### VM Presets

| Preset | RAM | CPUs | Disk | Best For |
|--------|-----|------|------|----------|
| **Lightweight** | 4 GB | 2 | 80 GB | Testing, learning |
| **Standard** | 8 GB | 4 | 127 GB | General development |
| **Performance** | 16 GB | 8 | 256 GB | AI/ML, Docker heavy |
| **Server-Class** | 32 GB | 16 | 512 GB | Enterprise, databases |

### Default VM Credentials

| Username | Password |
|----------|----------|
| Admin | VibeDev123! |

## Command-Line Parameters

For automation/scripting:

```powershell
# Full silent installation
.\Install-DevBox.ps1 -Silent -Profile Full

# AI Coder setup
.\Install-DevBox.ps1 -Silent -Profile AICoder

# Azure developer setup
.\Install-DevBox.ps1 -Silent -Profile Azure

# Custom: skip databases and Docker
.\Install-DevBox.ps1 -SkipDatabases -SkipDocker
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| `-Silent` | Non-interactive mode |
| `-Profile` | Installation profile: Full, AICoder, WebDev, Azure, Minimal |
| `-SkipNodeJS` | Skip Node.js and NVM |
| `-SkipPython` | Skip Python |
| `-SkipDotNet` | Skip .NET SDK |
| `-SkipDocker` | Skip Docker and WSL2 |
| `-SkipDatabases` | Skip PostgreSQL, MongoDB, Redis |
| `-SkipAITools` | Skip Claude Code, Cursor |
| `-SkipAzure` | Skip Azure tools |
| `-SkipVSCodeExtensions` | Skip VS Code extensions |
| `-NoReboot` | Don't prompt for reboot |
| `-LogPath` | Custom log file path |

## Project Structure

```
devbox-factory/
├── Initialize-DevBox.ps1      # Bootstrap entry point
├── Install-DevBox.ps1         # Main installer
├── devbox.ps1                 # CLI wrapper
├── Download-Dependencies.ps1  # Offline dependency manager
├── config/
│   └── presets.json           # VM presets and profiles
├── dependencies/              # Pre-downloaded installers (offline mode)
│   ├── manifest.json          # Dependency definitions
│   └── README.md              # Offline installation guide
├── log/                       # Centralized log files (auto-generated)
│   └── README.md              # Logging documentation
├── temp/                      # Temporary files (VHDX creation, etc.)
│   └── README.md              # Temp folder documentation
├── modules/
│   ├── DevBoxLogger.psm1      # Centralized logging module
│   └── DownloadHelpers.psm1   # Download progress functions
├── iso/                       # Place Windows ISOs here
│   └── README.md              # ISO instructions
├── templates/
│   ├── New-DevBoxTemplate.ps1 # VHDX template creation
│   ├── autounattend.xml       # Unattended Windows install
│   └── SetupComplete.ps1      # Post-install configuration
├── vms/
│   └── New-DevBoxVM.ps1       # VM provisioning
├── utils/
│   └── Test-DevBoxHealth.ps1  # Health verification
└── README.md
```

## Requirements

- **OS**: Windows 11 22H2 or later (Build 22621+)
- **Privileges**: Administrator
- **Internet**: Required for downloads
- **Disk Space**: ~15GB for full installation
- **Hyper-V**: For VM features (Windows Pro/Enterprise/Education)

## Post-Installation

### Verify Installation

```powershell
.\devbox test

# Or manually:
git --version
node --version
python --version
claude --version
```

### Authenticate Services

```powershell
# Claude Code
claude

# Azure CLI
az login

# GitHub CLI
gh auth login
```

### Configure Git

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Troubleshooting

### "Command not found" after installation
Close and reopen your terminal to refresh PATH.

### WinGet not available
Update Windows or install "App Installer" from Microsoft Store.

### Docker won't start
1. Ensure WSL2 is enabled: `wsl --status`
2. Reboot if you just enabled WSL2
3. Check virtualization is enabled in BIOS

### Azure CLI login issues
```powershell
az account clear
az login
```

### VS Code extensions not installing
Install manually: `Ctrl+Shift+X` in VS Code

## Logging and Cleanup

### Log Files

All DevBox Factory operations are logged to the `log/` folder with timestamps:

```
log/
├── devbox-20260105-120000.log     # CLI wrapper operations
├── template-20260105-130000.log   # Template creation logs
├── vm-20260105-140000.log         # VM creation logs
├── install-20260105-150000.log    # Tool installation logs
└── health-20260105-160000.log     # Health check logs
```

Legacy log location (fallback): `%USERPROFILE%\DevBox-Install.log`

### Temporary Files

Template creation uses the `temp/` folder for intermediate files (e.g., VHDX during creation). If a previous operation failed, stale temp files may remain.

### Cleanup Command

```powershell
# Interactive cleanup menu
.\devbox cleanup

# Remove temporary files only
.\devbox cleanup -Temp

# Remove logs older than 30 days
.\devbox cleanup -Logs

# Clean both temp files and old logs
.\devbox cleanup -All
```

**Startup Detection:** DevBox Factory automatically detects leftover temp files and prompts you to clean them when running any command.

## Why DevBox Factory?

> At Velocity EU, we've spent years watching teams burn weeks on environment setup—configuration drift, dependency conflicts, "but it worked on staging" disasters. DevBox Factory is the internal tool we built to eliminate that waste. One reproducible template, unlimited identical environments, zero setup meetings. We're open-sourcing it because consistent dev environments shouldn't be a competitive advantage—they should be table stakes.

## License

MIT License - Feel free to modify and distribute.

## Contributing

Pull requests welcome! Test on a clean Windows 11 VM before submitting.

## Offline Installation

DevBox Factory supports pre-downloading dependencies for environments with limited or no internet access.

### Pre-Download Dependencies

```powershell
# Download all dependencies (~1.5 GB)
.\devbox deps -All

# Download only core tools
.\devbox deps -Category core

# Download for specific profile
.\devbox deps -Profile AICoder

# Check download status
.\devbox deps -Status
```

### Dependency Status Example

```
  DEPENDENCY STATUS
  =================

  Core Tools
  ----------
    [+] Git for Windows (60.1MB) - verified
    [+] Visual Studio Code (90.6MB) - verified
    [~] Windows Terminal - winget-only

  Runtimes & SDKs
  ---------------
    [-] Node.js LTS (~28.6MB) - missing
    [-] Python 3.12 (~23.8MB) - missing

  SUMMARY
  -------
    Verified:    2
    Downloaded:  0
    Missing:     2
    WinGet-only: 1
```

### How It Works

1. **Online Mode**: Downloads dependencies with progress indicators, falls back to WinGet/Chocolatey
2. **Offline Mode**: Uses pre-downloaded installers from `dependencies/` folder
3. **Verification**: SHA256 checksums validate file integrity before installation

### Supported Dependencies

| Dependency | Category | Offline Support |
|------------|----------|-----------------|
| Git | Core | Yes |
| VS Code | Core | Yes |
| Windows Terminal | Core | WinGet only |
| Node.js LTS | Runtime | Yes |
| Python 3.12 | Runtime | Yes |
| .NET SDK 8 | Runtime | Yes |
| Docker Desktop | Containers | Yes |
| Azure CLI | Cloud | Yes |
| Windows ADK | VM Tools | Yes |

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [Hyper-V Documentation](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/)

---

**DevBox Factory v3.0.3** | Built by [Velocity EU](https://www.velocity-eu.com) | [Report Issues](https://github.com/velocityeu/devbox-factory/issues)
