# Install-ClaudeCode-VibeDev-Ultra.ps1
# Windows 11 24H2 "Vibe Dev Ultra" + Claude Code (Claude CLI)
# Adds: Nerd Font, Terminal theme, VS Code settings, project scaffold + vibe.config prompt file

[CmdletBinding()]
param(
  [switch]$Latest,

  [ValidateSet("node","bun","both")]
  [string]$Runtime = "node",

  [switch]$InstallGh,
  [switch]$InstallPython,

  [switch]$ConfigureWindowsTerminal = $true,
  [switch]$InstallVSCodeExtensions  = $true,
  [switch]$ApplyVSCodeSettings      = $true,
  [switch]$InstallNerdFont          = $true,
  [switch]$CreateProjectScaffold    = $true,
  [switch]$RunSmokeTest             = $true,

  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section($title) {
  Write-Host ""
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Host $title -ForegroundColor Cyan
  Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-SetupBanner {
  Write-Section "Best Claude CLI Setup on Windows (Installed by this script)"
  Write-Host "Shell   : PowerShell 7"
  Write-Host "Runtime : Node.js LTS or Bun (selected: $Runtime)"
  Write-Host "Terminal: Windows Terminal"
  Write-Host "Editor  : VS Code"
}

function Assert-Admin {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $isAdmin) { throw "Re-run in an elevated (Administrator) PowerShell session." }
}

function Assert-Winget {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install 'App Installer' from Microsoft Store."
  }
}

function Winget-Install {
  param([Parameter(Mandatory=$true)][string]$Id, [string]$Name = $Id)
  Write-Host "-> Installing: $Name ($Id)"
  $args = @("install","--id",$Id,"--exact","--accept-package-agreements","--accept-source-agreements")
  if ($Quiet) { $args += "--silent" }
  try { & winget @args | Out-Host }
  catch { Write-Warning "winget error for $Id (often already installed). Continuing..." }
}

function Refresh-Path {
  $machine = [Environment]::GetEnvironmentVariable("Path","Machine")
  $user    = [Environment]::GetEnvironmentVariable("Path","User")
  $env:Path = "$machine;$user"
}

function Require-Command {
  param([Parameter(Mandatory=$true)][string]$Cmd)
  if (-not (Get-Command $Cmd -ErrorAction SilentlyContinue)) {
    throw "Expected '$Cmd' not found on PATH."
  }
}

function Run-And-Report {
  param([Parameter(Mandatory=$true)][string]$Label, [Parameter(Mandatory=$true)][scriptblock]$Action)
  Write-Host ""
  Write-Host "## $Label" -ForegroundColor Green
  & $Action
}

function Get-WindowsTerminalSettingsPath {
  $candidates = @(
    Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
  )
  foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
  return $null
}

function Setup-ClaudeGitBashPath {
  Write-Section "Set CLAUDE_CODE_GIT_BASH_PATH (native Windows compatibility)"
  $gitBash = "C:\Program Files\Git\bin\bash.exe"
  if (Test-Path $gitBash) {
    [Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitBash, "User")
    $env:CLAUDE_CODE_GIT_BASH_PATH = $gitBash
    Write-Host "-> CLAUDE_CODE_GIT_BASH_PATH set to: $gitBash"
  } else {
    Write-Warning "Git Bash not found at $gitBash. If Git is elsewhere, set CLAUDE_CODE_GIT_BASH_PATH manually."
  }
}

function Install-NerdFont {
  Write-Section "Install Nerd Font (for icons + nicer terminal UX)"
  # Common winget ID for Cascadia Code Nerd Font:
  # If winget can't find it in your environment, the script continues.
  Winget-Install -Id "Ryanoasis.NerdFont.CascadiaCode" -Name "Cascadia Code Nerd Font"
}

function Configure-WindowsTerminalUltra {
  Write-Section "Configure Windows Terminal (PowerShell 7 default + Vibe Dark theme + font)"
  $settingsPath = Get-WindowsTerminalSettingsPath
  if (-not $settingsPath) {
    Write-Warning "Windows Terminal settings.json not found yet. Launch Windows Terminal once, then re-run."
    return
  }

  $backupPath = $settingsPath + ".bak-" + (Get-Date -Format "yyyyMMdd-HHmmss")
  Copy-Item $settingsPath $backupPath -Force
  Write-Host "-> Backed up settings.json to: $backupPath"

  $raw = Get-Content $settingsPath -Raw -Encoding UTF8
  if (-not $raw.Trim()) { throw "Windows Terminal settings.json is empty/unreadable: $settingsPath" }
  $json = $raw | ConvertFrom-Json

  if (-not $json.profiles) { $json | Add-Member -NotePropertyName profiles -NotePropertyValue (@{}) }
  if (-not $json.profiles.list) { $json.profiles | Add-Member -NotePropertyName list -NotePropertyValue (@()) }

  # Find or create PowerShell 7 profile
  $pwshProfile = $null
  foreach ($p in $json.profiles.list) {
    if ($p.commandline -and ($p.commandline -match "pwsh(\.exe)?")) { $pwshProfile = $p; break }
  }

  if (-not $pwshProfile) {
    $newGuid = [Guid]::NewGuid().ToString("B")
    $pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
    if (-not $pwshExe) { $pwshExe = "C:\Program Files\PowerShell\7\pwsh.exe" }

    $pwshProfile = [PSCustomObject]@{
      guid        = $newGuid
      name        = "PowerShell 7"
      commandline = "`"$pwshExe`""
      startingDirectory = "%USERPROFILE%"
    }
    $json.profiles.list += $pwshProfile
    Write-Host "-> Added PowerShell 7 profile: $newGuid"
  } else {
    Write-Host "-> Found pwsh profile: $($pwshProfile.name)"
  }

  if ($pwshProfile.guid) {
    $json.defaultProfile = $pwshProfile.guid
    Write-Host "-> Set defaultProfile to pwsh guid: $($pwshProfile.guid)"
  }

  # Add a minimal “Vibe Dark” scheme (Terminal will ignore fields it doesn't use)
  if (-not $json.schemes) { $json | Add-Member -NotePropertyName schemes -NotePropertyValue (@()) }

  $schemeName = "Vibe Dark"
  $existing = $json.schemes | Where-Object { $_.name -eq $schemeName }
  if (-not $existing) {
    $vibeScheme = [PSCustomObject]@{
      name = $schemeName
      background = "#0b0f14"
      foreground = "#d6d6d6"
      black      = "#0b0f14"
      red        = "#ff5c57"
      green      = "#5af78e"
      yellow     = "#f3f99d"
      blue       = "#57c7ff"
      purple     = "#ff6ac1"
      cyan       = "#9aedfe"
      white      = "#f1f1f0"
      brightBlack  = "#686868"
      brightRed    = "#ff5c57"
      brightGreen  = "#5af78e"
      brightYellow = "#f3f99d"
      brightBlue   = "#57c7ff"
      brightPurple = "#ff6ac1"
      brightCyan   = "#9aedfe"
      brightWhite  = "#ffffff"
    }
    $json.schemes += $vibeScheme
    Write-Host "-> Added color scheme: $schemeName"
  } else {
    Write-Host "-> Color scheme already exists: $schemeName"
  }

  # Apply scheme + font to pwsh profile
  if (-not $pwshProfile.font) { $pwshProfile | Add-Member -NotePropertyName font -NotePropertyValue (@{}) }

  # Prefer Nerd Font face if installed; Terminal will fall back if missing.
  $pwshProfile.font.face = "CaskaydiaMono Nerd Font"
  $pwshProfile.colorScheme = $schemeName
  $pwshProfile.useAcrylic = $true
  $pwshProfile.acrylicOpacity = 0.9

  # Write back
  $out = $json | ConvertTo-Json -Depth 100
  Set-Content -Path $settingsPath -Value $out -Encoding UTF8
  Write-Host "-> Updated: $settingsPath"
}

function Install-VSCodeExtensions {
  Write-Section "Install VS Code Extensions (pro vibe pack)"
  Require-Command -Cmd "code"

  $extensions = @(
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "eamodio.gitlens",
    "EditorConfig.EditorConfig",
    "ms-vscode.powershell",
    "ms-azuretools.vscode-docker",
    "streetsidesoftware.code-spell-checker",
    "usernamehw.errorlens"
  )

  foreach ($ext in $extensions) {
    Write-Host "-> Installing VS Code extension: $ext"
    try { & code --install-extension $ext --force | Out-Host }
    catch { Write-Warning "Failed installing $ext (often PATH not refreshed). Continuing..." }
  }
}

function Apply-VSCodeSettings {
  Write-Section "Apply VS Code settings (format-on-save + Prettier + ESLint fixes)"
  $settingsDir = Join-Path $env:APPDATA "Code\User"
  $settingsPath = Join-Path $settingsDir "settings.json"
  New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null

  if (Test-Path $settingsPath) {
    $backup = $settingsPath + ".bak-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    Copy-Item $settingsPath $backup -Force
    Write-Host "-> Backed up VS Code settings to: $backup"
  }

  # Merge minimal “pro” defaults (kept conservative)
  $settings = @{}
  if (Test-Path $settingsPath) {
    try { $settings = (Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json) }
    catch { $settings = @{} }
  }

  # Convert PSCustomObject to hashtable for easy merging
  function To-Hashtable($obj) {
    if ($null -eq $obj) { return @{} }
    if ($obj -is [hashtable]) { return $obj }
    $ht = @{}
    $obj.PSObject.Properties | ForEach-Object { $ht[$_.Name] = $_.Value }
    return $ht
  }
  $settings = To-Hashtable $settings

  $desired = @{
    "editor.formatOnSave" = $true
    "editor.defaultFormatter" = "esbenp.prettier-vscode"
    "editor.codeActionsOnSave" = @{
      "source.fixAll.eslint" = "explicit"
    }
    "eslint.validate" = @("javascript","javascriptreact","typescript","typescriptreact")
    "files.trimTrailingWhitespace" = $true
    "files.insertFinalNewline" = $true
    "files.autoSave" = "off"
    "terminal.integrated.defaultProfile.windows" = "PowerShell"
    "git.autofetch" = $true
    "git.confirmSync" = $false
    "workbench.editor.enablePreview" = $false
  }

  foreach ($k in $desired.Keys) { $settings[$k] = $desired[$k] }

  $out = $settings | ConvertTo-Json -Depth 50
  Set-Content -Path $settingsPath -Value $out -Encoding UTF8
  Write-Host "-> Wrote: $settingsPath"
}

function Create-ProjectScaffold {
  Write-Section "Create project scaffold + starter vibe config"
  $root = Join-Path $env:USERPROFILE "Projects"
  $folders = @(
    $root,
    (Join-Path $root "_scratch"),
    (Join-Path $root "_templates"),
    (Join-Path $root "_notes")
  )
  foreach ($f in $folders) { New-Item -ItemType Directory -Path $f -Force | Out-Null }

  $vibeConfig = Join-Path $root "vibe.config.md"
  if (-not (Test-Path $vibeConfig)) {
@"
# vibe.config.md (starter)

You are Claude Code in a professional development environment on Windows 11.
Act like a senior engineer pair-programmer.

## Operating principles
- Prefer small, reviewable diffs.
- Ask before destructive actions (delete/overwrite).
- Add tests when changing behavior.
- Explain tradeoffs briefly; keep momentum.

## Project conventions
- Use Prettier formatting.
- Use ESLint rules; fix lint on save.
- Prefer TypeScript if the repo uses it.

## When editing code
- Search first, then change.
- Keep changes minimal; avoid refactors unless requested.
- Update docs/readme if behavior changes.

## Useful commands
- npm run test / bun test
- npm run lint / bun run lint
- npm run build / bun run build

## Current task
(Write the goal here before you start.)
"@ | Set-Content -Path $vibeConfig -Encoding UTF8
    Write-Host "-> Created: $vibeConfig"
  } else {
    Write-Host "-> Exists: $vibeConfig"
  }

  Write-Host "-> Projects root: $root"
}

function Run-SmokeTest {
  Write-Section "Smoke Test (tooling + temp repo + Claude health check)"

  Require-Command -Cmd "git"
  Require-Command -Cmd "claude"

  Run-And-Report -Label "Git version" -Action { git --version }
  Run-And-Report -Label "Claude version" -Action { claude --version }
  Run-And-Report -Label "Claude health check (claude doctor)" -Action { claude doctor }

  if ($Runtime -eq "node" -or $Runtime -eq "both") {
    if (Get-Command node -ErrorAction SilentlyContinue) {
      Run-And-Report -Label "Node + npm versions" -Action { node --version; npm --version }
    } else { Write-Warning "Node not on PATH yet. Reopen terminal and re-run smoke test." }
  }

  if ($Runtime -eq "bun" -or $Runtime -eq "both") {
    if (Get-Command bun -ErrorAction SilentlyContinue) {
      Run-And-Report -Label "Bun version" -Action { bun --version }
    } else { Write-Warning "Bun not on PATH yet. Reopen terminal and re-run smoke test." }
  }

  $repoRoot = Join-Path $env:TEMP ("claude-smoketest-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
  New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null

  Push-Location $repoRoot
  try {
    git init | Out-Host
    "console.log('vibe smoke test ok');" | Set-Content -Path (Join-Path $repoRoot "index.js") -Encoding UTF8
    git add . | Out-Host
    git commit -m "Initial smoke test" | Out-Host

    Write-Host ""
    Write-Host "Smoke-test repo created at:" -ForegroundColor Yellow
    Write-Host "  $repoRoot" -ForegroundColor Yellow
    Write-Host "Manual interactive check:" -ForegroundColor Yellow
    Write-Host "  cd `"$repoRoot`""
    Write-Host "  claude"
  } finally {
    Pop-Location
  }
}

# ------------------- MAIN -------------------
Write-SetupBanner
Write-Section "Claude Code (Claude CLI) + Vibe Dev Ultra Setup (Windows 11 24H2)"

Assert-Admin
Assert-Winget

$logDir = Join-Path $env:TEMP "claude-code-install"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logPath = Join-Path $logDir ("install-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
Start-Transcript -Path $logPath -Force | Out-Null

try {
  Write-Section "1) Install core tools (Terminal + Shell + Editor + Git + rg)"

  Winget-Install -Id "Microsoft.WindowsTerminal"      -Name "Windows Terminal"
  Winget-Install -Id "Microsoft.PowerShell"          -Name "PowerShell 7"
  Winget-Install -Id "Microsoft.VisualStudioCode"    -Name "Visual Studio Code"
  Winget-Install -Id "Git.Git"                       -Name "Git for Windows"
  Winget-Install -Id "BurntSushi.ripgrep.MSVC"       -Name "ripgrep"

  if ($Runtime -eq "node" -or $Runtime -eq "both") { Winget-Install -Id "OpenJS.NodeJS.LTS" -Name "Node.js LTS" }
  if ($Runtime -eq "bun"  -or $Runtime -eq "both") { Winget-Install -Id "Oven-sh.Bun"       -Name "Bun" }

  if ($InstallGh)     { Winget-Install -Id "GitHub.cli"         -Name "GitHub CLI" }
  if ($InstallPython) { Winget-Install -Id "Python.Python.3.12" -Name "Python 3" }

  if ($InstallNerdFont) { Install-NerdFont }

  Refresh-Path

  Write-Section "2) Install Claude Code (Claude CLI)"

  if ($Latest) {
    Write-Host "-> Installing Claude Code (latest channel)..."
    & ([scriptblock]::Create((irm https://claude.ai/install.ps1))) latest
  } else {
    Write-Host "-> Installing Claude Code (stable channel)..."
    irm https://claude.ai/install.ps1 | iex
  }

  Refresh-Path

  Write-Section "3) Verify base commands"

  Require-Command -Cmd "git"
  Require-Command -Cmd "code"
  Require-Command -Cmd "claude"

  Run-And-Report -Label "PowerShell 7 (pwsh) version" -Action { if (Get-Command pwsh -ErrorAction SilentlyContinue) { pwsh --version } }
  Run-And-Report -Label "Git version"                -Action { git --version }
  Run-And-Report -Label "VS Code version"            -Action { code --version | Select-Object -First 1 }
  Run-And-Report -Label "ripgrep version"            -Action { rg --version | Select-Object -First 1 }
  Run-And-Report -Label "Claude version"             -Action { claude --version }

  Setup-ClaudeGitBashPath

  if ($ConfigureWindowsTerminal) { Configure-WindowsTerminalUltra }
  if ($InstallVSCodeExtensions)  { Install-VSCodeExtensions }
  if ($ApplyVSCodeSettings)      { Apply-VSCodeSettings }
  if ($CreateProjectScaffold)    { Create-ProjectScaffold }
  if ($RunSmokeTest)             { Run-SmokeTest }

  Write-Section "Done"
  Write-Host "Log saved to: $logPath" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "After this, close & reopen Windows Terminal, then run:" -ForegroundColor Yellow
  Write-Host "  claude" -ForegroundColor Yellow

} catch {
  Write-Host ""
  Write-Host "INSTALL FAILED: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "Log saved to: $logPath" -ForegroundColor Yellow
  throw
} finally {
  Stop-Transcript | Out-Null
}
