# Install-ClaudeCode-VibeDev-Ultra

Ultimate Windows 11 development environment setup for AI-powered "vibe coding" with Claude Code, Cursor, and full-stack tools.

## What Gets Installed

| Category | Tools |
|----------|-------|
| **Package Managers** | WinGet (primary), Chocolatey (fallback) |
| **Core Tools** | Git, Windows Terminal |
| **Runtimes** | Python 3.12+, Node.js LTS (via NVM) |
| **JS Package Managers** | npm, pnpm, yarn, bun |
| **AI Coding Tools** | Claude Code, Cursor IDE, VS Code |
| **VS Code Extensions** | GitHub Copilot, Claude, Continue, Cline, ESLint, Prettier, GitLens |
| **Databases** | PostgreSQL 16, MongoDB, Redis |
| **Containers** | WSL2, Docker Desktop |

## Quick Start

### One-Line Install (Run as Administrator)

```powershell
irm https://raw.githubusercontent.com/velocityeu/Install-ClaudeCode-VibeDev-Ultra/main/Install-VibeDev.ps1 | iex
```

### Local Install

1. Download `Install-VibeDev.ps1`
2. Open PowerShell as Administrator
3. Run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Install-VibeDev.ps1
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `-Silent` | Non-interactive mode (auto-accept all prompts) |
| `-SkipNodeJS` | Skip Node.js and NVM installation |
| `-SkipPython` | Skip Python installation |
| `-SkipDocker` | Skip Docker Desktop and WSL2 setup |
| `-SkipDatabases` | Skip PostgreSQL, MongoDB, and Redis |
| `-SkipAITools` | Skip Claude Code, Cursor, and VS Code |
| `-SkipVSCodeExtensions` | Skip VS Code extension installation |
| `-NoReboot` | Don't prompt for reboot |
| `-LogPath` | Custom log file path |

## Usage Examples

```powershell
# Full installation (interactive)
.\Install-VibeDev.ps1

# Silent mode for automation/CI
.\Install-VibeDev.ps1 -Silent

# Skip databases (minimal setup)
.\Install-VibeDev.ps1 -SkipDatabases

# AI tools only (no Docker/databases)
.\Install-VibeDev.ps1 -SkipDatabases -SkipDocker

# Just runtimes and tools (no AI)
.\Install-VibeDev.ps1 -SkipAITools

# Custom log location
.\Install-VibeDev.ps1 -LogPath "C:\Logs\install.log"
```

## Requirements

- **OS**: Windows 11 22H2 or later (Build 22621+)
- **Privileges**: Administrator
- **Internet**: Required for downloads
- **Disk Space**: ~10GB recommended

## VS Code Extensions Installed

| Extension | Purpose |
|-----------|---------|
| GitHub Copilot | AI code completion |
| GitHub Copilot Chat | AI chat assistant |
| Claude Code | Anthropic's Claude in VS Code |
| Continue | Open-source AI coding assistant |
| Cline | Autonomous coding agent |
| ESLint | JavaScript linting |
| Prettier | Code formatting |
| GitLens | Git supercharged |
| PowerShell | PowerShell language support |
| Python | Python language support |

## Post-Installation

### Verify Installation

Open a **new** PowerShell or terminal window and run:

```powershell
# Check versions
git --version
node --version
python --version
claude --version
docker --version

# Check package managers
pnpm --version
yarn --version
bun --version
```

### Authenticate Claude Code

```powershell
claude
# Follow the browser authentication flow
```

### Start Docker Desktop

Launch Docker Desktop from the Start menu. It may require a restart on first run.

### Configure Git

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Troubleshooting

### "Command not found" after installation

Close and reopen your terminal. The PATH environment needs to refresh.

### WinGet not available

Update Windows or install "App Installer" from the Microsoft Store.

### Docker won't start

1. Ensure WSL2 is enabled: `wsl --status`
2. Reboot if you just enabled WSL2
3. Check virtualization is enabled in BIOS

### Chocolatey installation fails

Run manually:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### VS Code extensions not installing

Install manually via VS Code:
1. Open VS Code
2. Press `Ctrl+Shift+X`
3. Search for and install each extension

## Log File

Installation logs are saved to: `%USERPROFILE%\VibeDev-Install.log`

## License

MIT License - Feel free to modify and distribute.

## Contributing

Pull requests welcome! Please test on a clean Windows 11 VM before submitting.

## Resources

- [Claude Code Documentation](https://code.claude.com/docs/en/setup)
- [WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [Chocolatey Documentation](https://docs.chocolatey.org/)
- [VS Code Marketplace](https://marketplace.visualstudio.com/)
