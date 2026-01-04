# DevBox Factory - Pre-Downloaded Dependencies

This folder contains pre-downloaded installers for offline installation capability.

## Purpose

When DevBox Factory is deployed in environments with:
- Limited or slow internet connectivity
- Air-gapped networks
- Corporate firewalls blocking download sites

Pre-downloading dependencies allows fully offline installation.

## How It Works

1. **Online Mode**: If dependencies are not pre-downloaded, DevBox Factory downloads them with progress indicators and falls back to WinGet/Chocolatey
2. **Offline Mode**: If installers exist here and pass checksum verification, they are used directly - no internet required

## Manifest

The `manifest.json` file defines all available dependencies with:
- Download URLs (official sources)
- Expected file sizes
- SHA256 checksums for verification
- Silent install arguments
- WinGet fallback package IDs

## Pre-Downloading Dependencies

### Option 1: Using the download script (Recommended)

```powershell
# Download all dependencies (~1.5 GB)
.\Download-Dependencies.ps1 -All

# Download only core tools
.\Download-Dependencies.ps1 -Category core

# Download specific dependencies
.\Download-Dependencies.ps1 -Dependencies git,vscode,nodejs-lts

# Check status of dependencies
.\Download-Dependencies.ps1 -Status
```

### Option 2: Manual download

Download files matching the URLs and filenames in `manifest.json` and place them in this folder.

## Dependency List

| Dependency | File | Size | Required |
|------------|------|------|----------|
| Windows ADK | adksetup.exe | ~2 MB (bootstrapper) | For VM templates |
| VC++ Redistributable | vc_redist.x64.exe | ~25 MB | Yes |
| .NET SDK 8 | dotnet-sdk-8.0.x-win-x64.exe | ~200 MB | Profile-dependent |
| Node.js LTS | node-vXX.X.X-x64.msi | ~30 MB | Profile-dependent |
| Python 3.12 | python-3.12.x-amd64.exe | ~25 MB | Profile-dependent |
| Git | Git-X.XX.X-64-bit.exe | ~60 MB | Yes |
| VS Code | VSCodeUserSetup-x64.exe | ~95 MB | Yes |

**Note**: Windows ADK bootstrapper downloads additional components (~1.5 GB) during installation.

## Verification

DevBox Factory verifies downloads using SHA256 checksums before installation:
- **Valid checksum**: Install from local file
- **Invalid/corrupt**: Re-download online or use WinGet
- **Missing file**: Download with progress indicator

## Git Ignore

The installer files (`*.exe`, `*.msi`) are gitignored to keep the repository small.
Only `manifest.json` and this README are tracked in git.

## Updating Dependencies

When new versions are released:
1. Update `manifest.json` with new URLs, sizes, and checksums
2. Run `.\Download-Dependencies.ps1 -All -Force` to re-download
3. Test installation before distributing

## Checksum Generation

To generate SHA256 checksums for new files:

```powershell
Get-FileHash -Path ".\dependencies\filename.exe" -Algorithm SHA256 | Select-Object Hash
```
