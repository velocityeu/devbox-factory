# DevBox Factory

**One command. Identical dev environments. Every time.**

Professional-grade Windows 11 development environment automation. Create reproducible dev boxes with AI tools, full-stack runtimes, and Hyper-V VM templates.

> Built by [Velocity EU](https://velocity.eu) - Eliminating "works on my machine" since day one.

## Features

- **One-Line Bootstrap** - Download and setup from vanilla Windows 11
- **CLI Wrapper** - Human-friendly `.\devbox` commands
- **Pre-configured Profiles** - Full, AI Coder, Web Dev, Azure, or Custom
- **Hyper-V VM Factory** - Create identical dev VMs from golden templates
- **Interactive Menus** - Guided wizards with file pickers
- **Pre-flight Validation** - Checks prerequisites before changes
- **Health Checks** - Verify your environment with `.\devbox test`
- **Idempotent** - Safe to run multiple times

## Quick Start

### Option 1: Bootstrap (Recommended)

Download all DevBox Factory scripts to your PC:

```powershell
# Run as Administrator
irm https://raw.githubusercontent.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra/main/Initialize-DevBox.ps1 | iex
```

This bootstrap script:
- Checks Windows 11 22H2+ and Administrator privileges
- Lets you choose installation directory (default: `C:\DevBox`)
- Downloads all scripts including Hyper-V VM automation
- Offers to run the installer immediately

### Option 2: Direct Install

Run the installer directly without downloading files:

```powershell
# Run as Administrator
irm https://raw.githubusercontent.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra/main/Install-DevBox.ps1 | iex
```

### Option 3: Clone and Run

```powershell
git clone https://github.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra.git
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
.\devbox test          # Run health checks
.\devbox help          # Show help
```

## Interactive Menu

Run `.\devbox install` with no parameters:

```
  +=================================================================+
  |  DEVBOX FACTORY                       v2.0.0  Build: 2026-01-04  |
  |  One command. Identical dev environments. Every time.            |
  +=================================================================+

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
```

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

Create pre-configured Windows 11 development VMs with tools auto-installed.

### Interactive Mode

```powershell
# Stage 1: Create template with interactive wizard
.\devbox template

# Stage 2: Create VMs with interactive wizard
.\devbox vm
```

Features:
- **File picker dialogs** for ISO and template selection
- **VM presets** (Lightweight, Standard, Performance, Server-class)
- **Pre-flight validation** before any changes
- **Live naming preview** for batch VM creation
- **Back/Cancel** on every screen

### Command-Line Mode

```powershell
# Stage 1: Create template from Windows 11 ISO (one-time, ~30-60 min)
.\devbox template -ISOPath "C:\ISOs\Win11_23H2.iso"

# Stage 2: Create dev VMs (fast, ~2-5 min each)
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
.\devbox vm -VMName "AI-Dev" -VibeDevProfile AICoder -StartVM

# Team of 5 VMs
.\devbox vm -VMName "TeamDev" -Count 5 -MemoryGB 16 -StartVM

# High-spec Azure development
.\devbox vm -VMName "Azure-Dev" -VibeDevProfile Azure -MemoryGB 16 -ProcessorCount 8 -StartVM
```

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

## Health Check

Verify your environment:

```powershell
.\devbox test
```

Output:
```
  +=================================================================+
  |  DEVBOX FACTORY - HEALTH CHECK      v2.0.0  Build: 2026-01-04  |
  +=================================================================+

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

  SUMMARY
  Results: 15 passed, 1 warnings, 0 failed (of 16 checks)

  [OK] DevBox environment is healthy!
```

## Project Structure

```
devbox-factory/
├── Initialize-DevBox.ps1      # Bootstrap entry point
├── Install-DevBox.ps1         # Main installer
├── devbox.ps1                 # CLI wrapper
├── config/
│   └── presets.json           # VM presets and profiles
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

## Log File

Installation logs: `%USERPROFILE%\DevBox-Install.log`

## Why DevBox Factory?

> At Velocity EU, we've spent years watching teams burn weeks on environment setup—configuration drift, dependency conflicts, "but it worked on staging" disasters. DevBox Factory is the internal tool we built to eliminate that waste. One reproducible template, unlimited identical environments, zero setup meetings. We're open-sourcing it because consistent dev environments shouldn't be a competitive advantage—they should be table stakes.

## License

MIT License - Feel free to modify and distribute.

## Contributing

Pull requests welcome! Test on a clean Windows 11 VM before submitting.

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [Hyper-V Documentation](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/)

---

**DevBox Factory v2.0.0** | Built by [Velocity EU](https://velocity.eu) | [Report Issues](https://github.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra/issues)
