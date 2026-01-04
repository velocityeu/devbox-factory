# Install-ClaudeCode-VibeDev-Ultra

Ultimate Windows 11 development environment setup for AI-powered "vibe coding" with Claude Code, Cursor, Azure tools, and full-stack development.

> Create Automatically VibeCoding Environment on vanilla Windows 11 22H2+ PC

## Features

- **Interactive Menu** - No need to remember parameters, just pick an option
- **Pre-configured Profiles** - Full, AI Coder, Web Dev, Azure, or Custom
- **Azure Development** - Complete Azure toolchain for cloud developers
- **Hyper-V VM Automation** - Create dev VMs with VibeDev pre-installed
- **Idempotent** - Safe to run multiple times
- **Smart Fallbacks** - WinGet primary, Chocolatey backup

## Quick Start

### One-Line Install (Run as Administrator)

```powershell
irm https://raw.githubusercontent.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra/main/Install-VibeDev.ps1 | iex
```

### Local Install

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Install-VibeDev.ps1
```

## Interactive Menu

Simply run the script with no parameters to see the menu:

```
  ╔═══════════════════════════════════════════════════════════════╗
  ║   ██╗   ██╗██╗██████╗ ███████╗    ██████╗ ███████╗██╗   ██╗   ║
  ║   ██║   ██║██║██╔══██╗██╔════╝    ██╔══██╗██╔════╝██║   ██║   ║
  ║   ██║   ██║██║██████╔╝█████╗      ██║  ██║█████╗  ██║   ██║   ║
  ║   ╚██╗ ██╔╝██║██╔══██╗██╔══╝      ██║  ██║██╔══╝  ╚██╗ ██╔╝   ║
  ║    ╚████╔╝ ██║██████╔╝███████╗    ██████╔╝███████╗ ╚████╔╝    ║
  ║     ╚═══╝  ╚═╝╚═════╝ ╚══════╝    ╚═════╝ ╚══════╝  ╚═══╝     ║
  ╚═══════════════════════════════════════════════════════════════╝

  ┌─────────────────────────────────────────────────────────────┐
  │                    SELECT INSTALLATION                      │
  └─────────────────────────────────────────────────────────────┘

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

### Custom Installation Menu

Option `[5]` lets you pick specific components:

```
   [1] Core Tools - Git, Windows Terminal, VS Code (Always included)
   [2] AI Coding Tools - Claude Code, Cursor, AI extensions
   [3] Node.js Environment - NVM, Node.js, npm, pnpm, yarn, bun
   [4] Python - Python 3.12 with pip
   [5] Docker & Containers - WSL2, Docker Desktop
   [6] Databases - PostgreSQL, MongoDB, Redis
   [7] Azure Development - Azure CLI, Functions, .NET, Terraform

  Example: 2,3,4 (AI tools + Node.js + Python)
```

## Installation Profiles

| Profile | What's Included |
|---------|-----------------|
| **Full** | Everything: AI, Web Dev, Azure, Docker, Databases |
| **AICoder** | Claude Code, Cursor, VS Code + AI extensions, Node.js, Python |
| **WebDev** | Node.js, Python, Docker, PostgreSQL, MongoDB, Redis |
| **Azure** | Azure CLI, Functions, .NET SDK, Terraform, Bicep, Docker, AI tools |
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
- VS Code Extensions: Azure Functions, Resources, Storage, CosmosDB, Docker, C#, Terraform

## Command-Line Parameters

For automation/scripting, use parameters instead of the menu:

### Profile Parameter

```powershell
# Full installation (silent)
.\Install-VibeDev.ps1 -Silent -Profile Full

# AI Coder setup
.\Install-VibeDev.ps1 -Silent -Profile AICoder

# Azure developer setup
.\Install-VibeDev.ps1 -Silent -Profile Azure

# Web developer setup
.\Install-VibeDev.ps1 -Silent -Profile WebDev

# Minimal setup
.\Install-VibeDev.ps1 -Silent -Profile Minimal
```

### Skip Parameters

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

### Examples

```powershell
# Interactive menu (default)
.\Install-VibeDev.ps1

# Full silent installation
.\Install-VibeDev.ps1 -Silent -Profile Full

# AI tools without databases
.\Install-VibeDev.ps1 -Silent -Profile AICoder

# Azure developer with custom log
.\Install-VibeDev.ps1 -Silent -Profile Azure -LogPath "C:\Logs\install.log"

# Custom: skip databases and Docker
.\Install-VibeDev.ps1 -SkipDatabases -SkipDocker

# Web dev without AI tools
.\Install-VibeDev.ps1 -Silent -Profile WebDev
```

## Requirements

- **OS**: Windows 11 22H2 or later (Build 22621+)
- **Privileges**: Administrator
- **Internet**: Required for downloads
- **Disk Space**: ~15GB for full installation

## Post-Installation

### Verify Installation

```powershell
# Core tools
git --version
node --version
python --version

# AI tools
claude --version

# Package managers
pnpm --version
yarn --version
bun --version

# Azure tools
az --version
func --version
azd version
terraform --version
```

### Authenticate Services

```powershell
# Claude Code
claude

# Azure CLI
az login

# GitHub CLI (if needed)
gh auth login
```

### Configure Git

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Hyper-V VM Automation

Create pre-configured Windows 11 development VMs with VibeDev tools auto-installed.

### Quick Start

```powershell
# Stage 1: Create template from Windows 11 ISO (one-time, ~30-60 min)
.\HyperV\New-VibeDevTemplate.ps1 -ISOPath "C:\ISOs\Win11_23H2.iso"

# Stage 2: Create dev VMs (fast, ~2-5 min each)
.\HyperV\New-VibeDevVM.ps1 -VMName "DevVM-01" -InstallMode Automatic -StartVM
```

### Installation Modes

| Mode | Behavior |
|------|----------|
| **Automatic** | Auto-login, run Install-VibeDev.ps1 silently on first boot |
| **SemiAutomatic** | Auto-login, desktop shortcut for VibeDev installer |
| **Manual** | Just Windows, no auto-install |

### Examples

```powershell
# AI Coder VM
.\HyperV\New-VibeDevVM.ps1 -VMName "AI-Dev" -VibeDevProfile AICoder -StartVM

# Team of 5 VMs
.\HyperV\New-VibeDevVM.ps1 -VMName "TeamDev" -Count 5 -MemoryGB 16 -StartVM

# High-spec Azure development
.\HyperV\New-VibeDevVM.ps1 -VMName "Azure-Dev" -VibeDevProfile Azure `
    -MemoryGB 16 -ProcessorCount 8 -StartVM
```

### Default VM Credentials

| Username | Password |
|----------|----------|
| Admin | VibeDev123! |

See [HyperV/README.md](HyperV/README.md) for detailed documentation.

## VS Code Extensions by Category

### Base Extensions
| Extension | ID |
|-----------|-----|
| ESLint | `dbaeumer.vscode-eslint` |
| Prettier | `esbenp.prettier-vscode` |
| GitLens | `eamodio.gitlens` |
| PowerShell | `ms-vscode.powershell` |

### AI Extensions
| Extension | ID |
|-----------|-----|
| GitHub Copilot | `GitHub.copilot` |
| GitHub Copilot Chat | `GitHub.copilot-chat` |
| Claude Code | `anthropic.claude-code` |
| Continue | `Continue.continue` |
| Cline | `saoudrizwan.claude-dev` |

### Web Development Extensions
| Extension | ID |
|-----------|-----|
| Python | `ms-python.python` |
| Pylance | `ms-python.vscode-pylance` |
| Tailwind CSS | `bradlc.vscode-tailwindcss` |
| ES7 React Snippets | `dsznajder.es7-react-js-snippets` |
| Prisma | `Prisma.prisma` |

### Azure Extensions
| Extension | ID |
|-----------|-----|
| Azure Functions | `ms-azuretools.vscode-azurefunctions` |
| Azure Resources | `ms-azuretools.vscode-azureresourcegroups` |
| Azure Storage | `ms-azuretools.vscode-azurestorage` |
| Azure CosmosDB | `ms-azuretools.vscode-cosmosdb` |
| Docker | `ms-azuretools.vscode-docker` |
| C# | `ms-dotnettools.csharp` |
| Azure Account | `ms-vscode.azure-account` |
| Terraform | `hashicorp.terraform` |

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
# Clear cached credentials
az account clear
az login
```

### VS Code extensions not installing
Install manually: `Ctrl+Shift+X` in VS Code

## Log File

Installation logs: `%USERPROFILE%\VibeDev-Install.log`

## License

MIT License - Feel free to modify and distribute.

## Contributing

Pull requests welcome! Test on a clean Windows 11 VM before submitting.

## Resources

- [Claude Code Documentation](https://code.claude.com/docs/en/setup)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [Chocolatey Documentation](https://docs.chocolatey.org/)
