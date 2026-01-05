<#
.SYNOPSIS
    Windows Customization Script for DevBox Factory

.DESCRIPTION
    Interactive and command-line tool for applying Windows customizations:
    - Privacy settings (Basic, Enhanced, Maximum levels)
    - Bloatware removal (Conservative, Moderate, Aggressive modes)
    - OOBE bypass (first-run wizard disabling)
    - Microsoft Edge configuration

.PARAMETER Privacy
    Privacy level to apply: Basic, Enhanced, or Maximum

.PARAMETER Debloat
    Debloat mode: Conservative, Moderate, or Aggressive

.PARAMETER ConfigureEdge
    Apply Edge browser configuration

.PARAMETER EdgeHomepage
    Homepage URL for Edge (default: https://google.com)

.PARAMETER EdgeSearchEngine
    Search engine for Edge: Google, DuckDuckGo, or Bing

.PARAMETER All
    Apply all customizations with recommended defaults

.PARAMETER DryRun
    Show what would be changed without making changes

.EXAMPLE
    .\Invoke-WindowsCustomization.ps1
    # Interactive menu

.EXAMPLE
    .\Invoke-WindowsCustomization.ps1 -Privacy Enhanced -Debloat Conservative
    # Apply specific settings

.EXAMPLE
    .\Invoke-WindowsCustomization.ps1 -All
    # Apply all with defaults

.NOTES
    DevBox Factory v3.1.1
    Build: 20260105.0700
    Requires Administrator privileges
#>

[CmdletBinding()]
param(
    [ValidateSet('Basic', 'Enhanced', 'Maximum')]
    [string]$Privacy,

    [ValidateSet('Conservative', 'Moderate', 'Aggressive')]
    [string]$Debloat,

    [switch]$ConfigureEdge,

    [string]$EdgeHomepage = "https://google.com",

    [ValidateSet('Google', 'DuckDuckGo', 'Bing')]
    [string]$EdgeSearchEngine = 'Google',

    [switch]$OOBE,

    [switch]$All,

    [switch]$DryRun
)

$Script:Version = "3.5.1"
$Script:Build = "20260105.1200"
$Script:BuildDate = "2026-01-05 12:00"

#region Check Admin

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  [!] Administrator privileges required" -ForegroundColor Red
    Write-Host "      Please run this script as Administrator" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

#endregion

#region Import Module

$modulePath = Join-Path $PSScriptRoot "modules\WindowsCustomization.psm1"
if (-not (Test-Path $modulePath)) {
    Write-Host "  [X] WindowsCustomization module not found at: $modulePath" -ForegroundColor Red
    exit 1
}

Import-Module $modulePath -Force -ErrorAction Stop

#endregion

#region Banner and Menu Functions

function Show-Banner {
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
    Write-Host "  |  WINDOWS CUSTOMIZATION      Privacy, Debloat, Edge Configuration    |" -ForegroundColor White
    Write-Host "  |  by Velocity EU                           v$Script:Version build $Script:Build  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-MainMenu {
    Show-Banner

    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |               CUSTOMIZATION OPTIONS                           |" -ForegroundColor Cyan
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Privacy Settings" -ForegroundColor White -NoNewline
    Write-Host " - Reduce telemetry, disable tracking" -ForegroundColor Gray
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Debloat Windows" -ForegroundColor White -NoNewline
    Write-Host " - Remove unwanted pre-installed apps" -ForegroundColor Gray
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "OOBE Bypass" -ForegroundColor White -NoNewline
    Write-Host " - Disable first-run wizards" -ForegroundColor Gray
    Write-Host "   [4] " -ForegroundColor Yellow -NoNewline
    Write-Host "Configure Edge" -ForegroundColor White -NoNewline
    Write-Host " - Homepage, search engine, disable ads" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [A] " -ForegroundColor Yellow -NoNewline
    Write-Host "Apply All" -ForegroundColor White -NoNewline
    Write-Host " (Enhanced privacy, Conservative debloat, Edge config)" -ForegroundColor Green
    Write-Host ""
    Write-Host "   [Q] " -ForegroundColor Yellow -NoNewline
    Write-Host "Quit" -ForegroundColor White
    Write-Host ""

    return Read-Host "  Enter choice"
}

function Show-PrivacyMenu {
    Show-Banner

    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                   PRIVACY SETTINGS                            |" -ForegroundColor Cyan
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Basic" -ForegroundColor White -NoNewline
    Write-Host " - Disable advertising ID and activity tracking" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Enhanced" -ForegroundColor White -NoNewline
    Write-Host " (Recommended)" -ForegroundColor Green
    Write-Host "       Basic + telemetry reduction + Cortana disabled" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Maximum" -ForegroundColor White -NoNewline
    Write-Host " - All settings + Copilot + location disabled" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [B] " -ForegroundColor Yellow -NoNewline
    Write-Host "Back" -ForegroundColor White
    Write-Host ""

    return Read-Host "  Enter choice"
}

function Show-DebloatMenu {
    Show-Banner

    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                   DEBLOAT OPTIONS                             |" -ForegroundColor Cyan
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Conservative" -ForegroundColor White -NoNewline
    Write-Host " (Recommended)" -ForegroundColor Green
    Write-Host "       Remove only third-party apps (Candy Crush, TikTok, etc.)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Moderate" -ForegroundColor White
    Write-Host "       + Entertainment, Xbox, and utility apps" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Aggressive" -ForegroundColor White
    Write-Host "       + Bing, Cortana, Copilot, Communication apps" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [P] " -ForegroundColor Yellow -NoNewline
    Write-Host "Preview" -ForegroundColor White -NoNewline
    Write-Host " - Show what would be removed (dry run)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [B] " -ForegroundColor Yellow -NoNewline
    Write-Host "Back" -ForegroundColor White
    Write-Host ""

    return Read-Host "  Enter choice"
}

function Show-EdgeMenu {
    Show-Banner

    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                   EDGE CONFIGURATION                          |" -ForegroundColor Cyan
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Current settings:" -ForegroundColor Gray
    Write-Host "    Homepage: " -NoNewline
    Write-Host $EdgeHomepage -ForegroundColor White
    Write-Host "    Search:   " -NoNewline
    Write-Host $EdgeSearchEngine -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Apply with current settings" -ForegroundColor White
    Write-Host "   [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Change homepage" -ForegroundColor White
    Write-Host "   [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Change search engine" -ForegroundColor White -NoNewline
    Write-Host " (Google/DuckDuckGo/Bing)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [B] " -ForegroundColor Yellow -NoNewline
    Write-Host "Back" -ForegroundColor White
    Write-Host ""

    return Read-Host "  Enter choice"
}

#endregion

#region Command-line Execution

if ($All -or $Privacy -or $Debloat -or $OOBE -or $ConfigureEdge) {
    Show-Banner
    Write-Host "  Running in command-line mode..." -ForegroundColor Cyan
    Write-Host ""

    if ($DryRun) {
        Write-Host "  [DRY RUN] No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }

    $results = @{
        Privacy = $null
        Debloat = $null
        OOBE = $null
        Edge = $null
    }

    if ($All) {
        $Privacy = "Enhanced"
        $Debloat = "Conservative"
        $OOBE = $true
        $ConfigureEdge = $true
    }

    if ($Privacy) {
        Write-Host "  Applying Privacy settings ($Privacy)..." -ForegroundColor White
        $results.Privacy = Set-PrivacySettings -Level $Privacy
    }

    if ($Debloat) {
        Write-Host "  Applying Debloat ($Debloat)..." -ForegroundColor White
        $results.Debloat = Remove-Bloatware -Mode $Debloat -DryRun:$DryRun
    }

    if ($OOBE) {
        Write-Host "  Applying OOBE Bypass..." -ForegroundColor White
        $results.OOBE = Invoke-OOBEBypass -All
    }

    if ($ConfigureEdge) {
        Write-Host "  Configuring Edge..." -ForegroundColor White
        $results.Edge = Set-EdgeConfiguration -Homepage $EdgeHomepage -SearchEngine $EdgeSearchEngine -DisableTracking -DisableAds
    }

    Write-Host ""
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Magenta
    Write-Host "  |                       SUMMARY                                 |" -ForegroundColor Magenta
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Magenta
    Write-Host ""

    foreach ($key in $results.Keys) {
        if ($null -ne $results[$key]) {
            $status = if ($results[$key]) { "[OK]" } else { "[FAIL]" }
            $color = if ($results[$key]) { "Green" } else { "Red" }
            Write-Host "    $key : " -NoNewline
            Write-Host $status -ForegroundColor $color
        }
    }

    Write-Host ""
    exit 0
}

#endregion

#region Interactive Menu Loop

$running = $true

while ($running) {
    $choice = Show-MainMenu

    switch ($choice.ToUpper()) {
        '1' {
            $privacyChoice = Show-PrivacyMenu
            switch ($privacyChoice) {
                '1' { Set-PrivacySettings -Level 'Basic' }
                '2' { Set-PrivacySettings -Level 'Enhanced' }
                '3' { Set-PrivacySettings -Level 'Maximum' }
            }
            if ($privacyChoice -ne 'B') {
                Write-Host ""
                Read-Host "  Press Enter to continue"
            }
        }
        '2' {
            $debloatChoice = Show-DebloatMenu
            switch ($debloatChoice) {
                '1' { Remove-Bloatware -Mode 'Conservative' }
                '2' { Remove-Bloatware -Mode 'Moderate' }
                '3' { Remove-Bloatware -Mode 'Aggressive' }
                'P' {
                    Write-Host ""
                    Write-Host "  Scanning for bloatware..." -ForegroundColor Cyan
                    $found = Get-InstalledBloatware
                    if ($found.Count -gt 0) {
                        Write-Host "  Found $($found.Count) removable apps:" -ForegroundColor White
                        $found | Group-Object CategoryDisplayName | ForEach-Object {
                            Write-Host "    $($_.Name): $($_.Count) apps" -ForegroundColor Gray
                        }
                    } else {
                        Write-Host "  No bloatware found" -ForegroundColor Green
                    }
                }
            }
            if ($debloatChoice -ne 'B') {
                Write-Host ""
                Read-Host "  Press Enter to continue"
            }
        }
        '3' {
            Invoke-OOBEBypass -All
            Write-Host ""
            Read-Host "  Press Enter to continue"
        }
        '4' {
            $edgeChoice = Show-EdgeMenu
            switch ($edgeChoice) {
                '1' {
                    Set-EdgeConfiguration -Homepage $EdgeHomepage -SearchEngine $EdgeSearchEngine -DisableTracking -DisableAds
                }
                '2' {
                    $newHomepage = Read-Host "  Enter homepage URL"
                    if ($newHomepage) {
                        $Script:EdgeHomepage = $newHomepage
                        Set-EdgeConfiguration -Homepage $newHomepage -SearchEngine $EdgeSearchEngine -DisableTracking -DisableAds
                    }
                }
                '3' {
                    Write-Host "    [1] Google  [2] DuckDuckGo  [3] Bing" -ForegroundColor Gray
                    $seChoice = Read-Host "  Enter choice"
                    $newEngine = switch ($seChoice) {
                        '1' { 'Google' }
                        '2' { 'DuckDuckGo' }
                        '3' { 'Bing' }
                        default { $EdgeSearchEngine }
                    }
                    $Script:EdgeSearchEngine = $newEngine
                    Set-EdgeConfiguration -Homepage $EdgeHomepage -SearchEngine $newEngine -DisableTracking -DisableAds
                }
            }
            if ($edgeChoice -ne 'B') {
                Write-Host ""
                Read-Host "  Press Enter to continue"
            }
        }
        'A' {
            Write-Host ""
            Write-Host "  Applying all recommended customizations..." -ForegroundColor Cyan
            Write-Host ""

            Invoke-OOBEBypass -All
            Set-PrivacySettings -Level 'Enhanced'
            Remove-Bloatware -Mode 'Conservative'
            Set-EdgeConfiguration -Homepage $EdgeHomepage -SearchEngine $EdgeSearchEngine -DisableTracking -DisableAds

            Write-Host ""
            Write-Host "  [OK] All customizations applied!" -ForegroundColor Green
            Write-Host ""
            Read-Host "  Press Enter to continue"
        }
        'Q' {
            $running = $false
        }
    }
}

Show-Banner
Write-Host "  Customization complete. Some changes may require a restart." -ForegroundColor White
Write-Host ""

#endregion
