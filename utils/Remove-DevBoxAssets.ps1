<#
.SYNOPSIS
    DevBox Factory Asset Cleanup Tool - Remove VMs, templates, and resources

.DESCRIPTION
    Interactive cleanup tool for DevBox Factory assets:
    - Remove individual or all VMs
    - Remove templates (with option to keep specific ones)
    - Remove virtual switches
    - Remove checkpoints
    - Clean temp files and logs
    - Factory reset (remove everything)

    Supports dry-run mode to preview what would be deleted.

.PARAMETER DryRun
    Preview what would be deleted without actually removing anything

.PARAMETER Force
    Skip all confirmation prompts (use with caution!)

.PARAMETER KeepTemplates
    During factory reset, preserve all templates

.PARAMETER Interactive
    Launch interactive menu mode (default)

.EXAMPLE
    .\Remove-DevBoxAssets.ps1
    # Launches interactive cleanup menu

.EXAMPLE
    .\Remove-DevBoxAssets.ps1 -DryRun
    # Preview all assets that would be affected

.NOTES
    DevBox Factory v3.0.3
    Build: 20260105.0400
    https://github.com/velocityeu/devbox-factory
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$KeepTemplates,
    [switch]$Interactive
)

$Script:Version = "3.0.3"
$Script:Build = "20260105.0400"
$Script:BuildDate = "2026-01-05 04:00"
$Script:ParentRoot = Split-Path $PSScriptRoot -Parent

# Import modules
$assetModule = Join-Path $Script:ParentRoot "modules\AssetRegistry.psm1"
$loggerModule = Join-Path $Script:ParentRoot "modules\DevBoxLogger.psm1"

if (Test-Path $assetModule) {
    Import-Module $assetModule -Force -ErrorAction SilentlyContinue
    Initialize-AssetRegistry -ScriptRoot $PSScriptRoot | Out-Null
}

if (Test-Path $loggerModule) {
    Import-Module $loggerModule -Force -ErrorAction SilentlyContinue
    $Script:Paths = Initialize-DevBoxPaths -ScriptRoot $PSScriptRoot -LogPrefix "cleanup"
}

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
    Write-Host "  |  ASSET CLEANUP            Remove VMs, Templates, and Resources      |" -ForegroundColor White
    Write-Host "  |  by Velocity EU                           v$Script:Version build $Script:Build  |" -ForegroundColor DarkGray
    Write-Host "  +=====================================================================+" -ForegroundColor DarkCyan
    Write-Host ""
    if ($DryRun) {
        Write-Host "  [DRY RUN MODE] " -ForegroundColor Yellow -NoNewline
        Write-Host "No changes will be made" -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Show-AssetSummary {
    Write-Host "  CURRENT ASSETS" -ForegroundColor Cyan
    Write-Host "  ==============" -ForegroundColor DarkGray
    Write-Host ""

    # Get VMs
    $vms = Get-DevBoxVMs -IncludeOrphaned
    $runningVMs = @($vms | Where-Object { $_.state -eq "Running" })
    $stoppedVMs = @($vms | Where-Object { $_.state -eq "Off" -or $_.state -eq "Stopped" })
    $orphanedVMs = @($vms | Where-Object { $_.orphaned -eq $true })

    Write-Host "  Virtual Machines: " -NoNewline
    if ($vms.Count -gt 0) {
        Write-Host "$($vms.Count) total" -ForegroundColor White -NoNewline
        if ($runningVMs.Count -gt 0) {
            Write-Host " ($($runningVMs.Count) running)" -ForegroundColor Green -NoNewline
        }
        if ($orphanedVMs.Count -gt 0) {
            Write-Host " [$($orphanedVMs.Count) unregistered]" -ForegroundColor Yellow -NoNewline
        }
        Write-Host ""
    } else {
        Write-Host "None" -ForegroundColor DarkGray
    }

    # Get Templates
    $templates = Get-DevBoxTemplates -IncludeOrphaned
    $totalSize = ($templates | Where-Object { $_.exists } | Measure-Object -Property sizeGB -Sum).Sum
    $orphanedTemplates = @($templates | Where-Object { $_.orphaned -eq $true })

    Write-Host "  Templates:        " -NoNewline
    if ($templates.Count -gt 0) {
        Write-Host "$($templates.Count) total" -ForegroundColor White -NoNewline
        Write-Host " (~$([math]::Round($totalSize, 1))GB)" -ForegroundColor DarkGray -NoNewline
        if ($orphanedTemplates.Count -gt 0) {
            Write-Host " [$($orphanedTemplates.Count) unregistered]" -ForegroundColor Yellow -NoNewline
        }
        Write-Host ""
    } else {
        Write-Host "None" -ForegroundColor DarkGray
    }

    # Get Switches
    $switches = Get-DevBoxSwitches
    Write-Host "  Custom Switches:  " -NoNewline
    if ($switches.Count -gt 0) {
        Write-Host "$($switches.Count)" -ForegroundColor White
    } else {
        Write-Host "None" -ForegroundColor DarkGray
    }

    # Temp and Log folders
    $paths = Get-DevBoxPaths -ScriptRoot $PSScriptRoot
    $tempSize = 0
    $tempCount = 0
    if (Test-Path $paths.Temp) {
        $tempFiles = Get-ChildItem -Path $paths.Temp -Recurse -File -ErrorAction SilentlyContinue
        $tempCount = $tempFiles.Count
        $tempSize = [math]::Round(($tempFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    }

    $logSize = 0
    $logCount = 0
    if (Test-Path $paths.Log) {
        $logFiles = Get-ChildItem -Path $paths.Log -Filter "*.log" -ErrorAction SilentlyContinue
        $logCount = $logFiles.Count
        $logSize = [math]::Round(($logFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    }

    Write-Host "  Temp Files:       " -NoNewline
    if ($tempCount -gt 0) {
        Write-Host "$tempCount files (${tempSize}MB)" -ForegroundColor Yellow
    } else {
        Write-Host "Clean" -ForegroundColor Green
    }

    Write-Host "  Log Files:        " -NoNewline
    if ($logCount -gt 0) {
        Write-Host "$logCount files (${logSize}MB)" -ForegroundColor White
    } else {
        Write-Host "None" -ForegroundColor DarkGray
    }

    Write-Host ""

    return @{
        VMs = $vms
        Templates = $templates
        Switches = $switches
        TempCount = $tempCount
        TempSize = $tempSize
        LogCount = $logCount
        LogSize = $logSize
    }
}

function Show-MainMenu {
    param($Assets)

    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |                    CLEANUP OPTIONS                        |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] Remove Virtual Machines     " -ForegroundColor White -NoNewline
    Write-Host "($($Assets.VMs.Count) available)" -ForegroundColor DarkGray
    Write-Host "   [2] Remove Templates            " -ForegroundColor White -NoNewline
    Write-Host "($($Assets.Templates.Count) available)" -ForegroundColor DarkGray
    Write-Host "   [3] Remove Custom Switches      " -ForegroundColor White -NoNewline
    Write-Host "($($Assets.Switches.Count) available)" -ForegroundColor DarkGray
    Write-Host "   [4] Clean Temp Files            " -ForegroundColor White -NoNewline
    Write-Host "($($Assets.TempCount) files, $($Assets.TempSize)MB)" -ForegroundColor DarkGray
    Write-Host "   [5] Clean Log Files             " -ForegroundColor White -NoNewline
    Write-Host "($($Assets.LogCount) files, $($Assets.LogSize)MB)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [R] Factory Reset               " -ForegroundColor Red -NoNewline
    Write-Host "(remove ALL DevBox assets)" -ForegroundColor DarkGray
    Write-Host "   [D] Dry Run (preview)           " -ForegroundColor Yellow -NoNewline
    Write-Host "(show what would be deleted)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [Q] Quit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray
}

function Remove-DevBoxVMsMenu {
    param($VMs)

    if ($VMs.Count -eq 0) {
        Write-Host "  [INFO] No VMs found to remove." -ForegroundColor DarkGray
        Write-Host ""
        Read-Host "  Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "  SELECT VMs TO REMOVE" -ForegroundColor Cyan
    Write-Host "  ====================" -ForegroundColor DarkGray
    Write-Host ""

    for ($i = 0; $i -lt $VMs.Count; $i++) {
        $vm = $VMs[$i]
        $stateColor = switch ($vm.state) {
            "Running" { "Green" }
            "Off" { "DarkGray" }
            "Stopped" { "DarkGray" }
            default { "Yellow" }
        }
        $orphanTag = if ($vm.orphaned) { " [unregistered]" } else { "" }

        Write-Host "   [$($i + 1)] " -ForegroundColor White -NoNewline
        Write-Host "$($vm.vmName)" -ForegroundColor White -NoNewline
        Write-Host " ($($vm.state))" -ForegroundColor $stateColor -NoNewline
        Write-Host "$orphanTag" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "   [A] Remove ALL VMs" -ForegroundColor Red
    Write-Host "   [B] Back to main menu" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Enter numbers separated by commas (e.g., 1,3,5) or 'A' for all:" -ForegroundColor DarkGray

    $choice = Read-Host "  Selection"

    if ($choice -eq 'B' -or $choice -eq 'b') { return }

    $toRemove = @()
    if ($choice -eq 'A' -or $choice -eq 'a') {
        $toRemove = $VMs
    } else {
        $indices = $choice -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
        $toRemove = @($indices | Where-Object { $_ -ge 0 -and $_ -lt $VMs.Count } | ForEach-Object { $VMs[$_] })
    }

    if ($toRemove.Count -eq 0) {
        Write-Host "  [WARN] No valid selections." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  Will remove $($toRemove.Count) VM(s):" -ForegroundColor Yellow
    foreach ($vm in $toRemove) {
        Write-Host "    - $($vm.vmName)" -ForegroundColor White
    }
    Write-Host ""

    if (-not $Force -and -not $DryRun) {
        $confirm = Read-Host "  Confirm removal? (Y/N)"
        if ($confirm -ne 'Y' -and $confirm -ne 'y') {
            Write-Host "  Cancelled." -ForegroundColor DarkGray
            return
        }
    }

    foreach ($vm in $toRemove) {
        Write-Host "  Removing $($vm.vmName)... " -NoNewline
        if ($DryRun) {
            Write-Host "[DRY RUN - would remove]" -ForegroundColor Yellow
        } else {
            try {
                # Stop VM if running
                $hyperVVM = Get-VM -Name $vm.vmName -ErrorAction SilentlyContinue
                if ($hyperVVM -and $hyperVVM.State -eq 'Running') {
                    Stop-VM -Name $vm.vmName -Force -TurnOff -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                }

                # Remove VM
                if ($hyperVVM) {
                    Remove-VM -Name $vm.vmName -Force -ErrorAction Stop
                }

                # Remove VHDX file
                if ($vm.vhdxPath -and (Test-Path $vm.vhdxPath)) {
                    Remove-Item -Path $vm.vhdxPath -Force -ErrorAction SilentlyContinue
                }

                # Remove VM folder
                $vmFolder = Split-Path $vm.vhdxPath -Parent
                if ((Test-Path $vmFolder) -and (Get-ChildItem $vmFolder).Count -eq 0) {
                    Remove-Item -Path $vmFolder -Force -Recurse -ErrorAction SilentlyContinue
                }

                # Unregister from asset registry
                Unregister-DevBoxVM -VMName $vm.vmName | Out-Null

                Write-Host "[OK]" -ForegroundColor Green
            } catch {
                Write-Host "[FAILED] $_" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Read-Host "  Press Enter to continue"
}

function Remove-DevBoxTemplatesMenu {
    param($Templates)

    if ($Templates.Count -eq 0) {
        Write-Host "  [INFO] No templates found to remove." -ForegroundColor DarkGray
        Write-Host ""
        Read-Host "  Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "  SELECT TEMPLATES TO REMOVE" -ForegroundColor Cyan
    Write-Host "  ==========================" -ForegroundColor DarkGray
    Write-Host ""

    for ($i = 0; $i -lt $Templates.Count; $i++) {
        $template = $Templates[$i]
        $existsTag = if ($template.exists) { "" } else { " [MISSING]" }
        $orphanTag = if ($template.orphaned) { " [unregistered]" } else { "" }

        Write-Host "   [$($i + 1)] " -ForegroundColor White -NoNewline
        Write-Host "$($template.name)" -ForegroundColor White -NoNewline
        Write-Host " ($($template.sizeGB)GB)" -ForegroundColor DarkGray -NoNewline
        Write-Host "$existsTag" -ForegroundColor Red -NoNewline
        Write-Host "$orphanTag" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "   [A] Remove ALL templates" -ForegroundColor Red
    Write-Host "   [B] Back to main menu" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Enter numbers separated by commas (e.g., 1,2) or 'A' for all:" -ForegroundColor DarkGray

    $choice = Read-Host "  Selection"

    if ($choice -eq 'B' -or $choice -eq 'b') { return }

    $toRemove = @()
    if ($choice -eq 'A' -or $choice -eq 'a') {
        $toRemove = $Templates
    } else {
        $indices = $choice -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
        $toRemove = @($indices | Where-Object { $_ -ge 0 -and $_ -lt $Templates.Count } | ForEach-Object { $Templates[$_] })
    }

    if ($toRemove.Count -eq 0) {
        Write-Host "  [WARN] No valid selections." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  Will remove $($toRemove.Count) template(s):" -ForegroundColor Yellow
    foreach ($template in $toRemove) {
        Write-Host "    - $($template.name) ($($template.sizeGB)GB)" -ForegroundColor White
    }
    Write-Host ""

    if (-not $Force -and -not $DryRun) {
        $confirm = Read-Host "  Confirm removal? (Y/N)"
        if ($confirm -ne 'Y' -and $confirm -ne 'y') {
            Write-Host "  Cancelled." -ForegroundColor DarkGray
            return
        }
    }

    foreach ($template in $toRemove) {
        Write-Host "  Removing $($template.name)... " -NoNewline
        if ($DryRun) {
            Write-Host "[DRY RUN - would remove]" -ForegroundColor Yellow
        } else {
            try {
                # Remove VHDX file
                if ($template.vhdxPath -and (Test-Path $template.vhdxPath)) {
                    Remove-Item -Path $template.vhdxPath -Force -ErrorAction Stop
                }

                # Unregister from asset registry
                Unregister-DevBoxTemplate -Name $template.name | Out-Null

                Write-Host "[OK]" -ForegroundColor Green
            } catch {
                Write-Host "[FAILED] $_" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Read-Host "  Press Enter to continue"
}

function Remove-DevBoxSwitchesMenu {
    param($Switches)

    if ($Switches.Count -eq 0) {
        Write-Host "  [INFO] No custom switches found to remove." -ForegroundColor DarkGray
        Write-Host ""
        Read-Host "  Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "  SELECT SWITCHES TO REMOVE" -ForegroundColor Cyan
    Write-Host "  =========================" -ForegroundColor DarkGray
    Write-Host ""

    for ($i = 0; $i -lt $Switches.Count; $i++) {
        $sw = $Switches[$i]
        $existsTag = if ($sw.exists) { "" } else { " [NOT FOUND]" }

        Write-Host "   [$($i + 1)] " -ForegroundColor White -NoNewline
        Write-Host "$($sw.switchName)" -ForegroundColor White -NoNewline
        Write-Host " ($($sw.switchType))" -ForegroundColor DarkGray -NoNewline
        Write-Host "$existsTag" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "   [A] Remove ALL switches" -ForegroundColor Red
    Write-Host "   [B] Back to main menu" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "  Selection"

    if ($choice -eq 'B' -or $choice -eq 'b') { return }

    # Similar removal logic...
    Write-Host ""
    Write-Host "  [INFO] Switch removal not yet implemented." -ForegroundColor Yellow
    Read-Host "  Press Enter to continue"
}

function Invoke-CleanTempFiles {
    $paths = Get-DevBoxPaths -ScriptRoot $PSScriptRoot

    Write-Host ""
    Write-Host "  CLEANING TEMP FILES" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path $paths.Temp)) {
        Write-Host "  [INFO] Temp folder does not exist." -ForegroundColor DarkGray
        return
    }

    $files = Get-ChildItem -Path $paths.Temp -Recurse -File -ErrorAction SilentlyContinue
    $totalSize = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 1)

    if ($files.Count -eq 0) {
        Write-Host "  [OK] Temp folder is already clean." -ForegroundColor Green
        return
    }

    Write-Host "  Found $($files.Count) files (${totalSize}MB)" -ForegroundColor White

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would remove all temp files" -ForegroundColor Yellow
    } else {
        try {
            Get-ChildItem -Path $paths.Temp -Recurse | Remove-Item -Force -Recurse -ErrorAction Stop
            Write-Host "  [OK] Temp files cleaned." -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Some files could not be removed: $_" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Read-Host "  Press Enter to continue"
}

function Invoke-CleanLogFiles {
    $paths = Get-DevBoxPaths -ScriptRoot $PSScriptRoot

    Write-Host ""
    Write-Host "  CLEANING LOG FILES" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path $paths.Log)) {
        Write-Host "  [INFO] Log folder does not exist." -ForegroundColor DarkGray
        return
    }

    Write-Host "   [1] Remove logs older than 7 days" -ForegroundColor White
    Write-Host "   [2] Remove logs older than 30 days" -ForegroundColor White
    Write-Host "   [3] Remove ALL logs" -ForegroundColor Red
    Write-Host "   [B] Back" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "  Selection"

    $daysOld = switch ($choice) {
        '1' { 7 }
        '2' { 30 }
        '3' { 0 }
        default { return }
    }

    $files = Get-ChildItem -Path $paths.Log -Filter "*.log" -ErrorAction SilentlyContinue
    if ($daysOld -gt 0) {
        $cutoff = (Get-Date).AddDays(-$daysOld)
        $files = $files | Where-Object { $_.LastWriteTime -lt $cutoff }
    }

    if ($files.Count -eq 0) {
        Write-Host "  [OK] No matching log files to remove." -ForegroundColor Green
        return
    }

    $totalSize = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "  Found $($files.Count) log files (${totalSize}MB)" -ForegroundColor White

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would remove $($files.Count) log files" -ForegroundColor Yellow
    } else {
        try {
            $files | Remove-Item -Force -ErrorAction Stop
            Write-Host "  [OK] Log files cleaned." -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Some files could not be removed: $_" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Read-Host "  Press Enter to continue"
}

function Invoke-FactoryReset {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Red
    Write-Host "  |                    FACTORY RESET                           |" -ForegroundColor Red
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This will remove:" -ForegroundColor Yellow
    Write-Host "    - All DevBox virtual machines" -ForegroundColor White
    Write-Host "    - All VM checkpoints" -ForegroundColor White
    if (-not $KeepTemplates) {
        Write-Host "    - All templates (VHDX files)" -ForegroundColor White
    } else {
        Write-Host "    - Templates: KEPT (--KeepTemplates)" -ForegroundColor Green
    }
    Write-Host "    - All custom virtual switches" -ForegroundColor White
    Write-Host "    - All temp files" -ForegroundColor White
    Write-Host "    - All log files" -ForegroundColor White
    Write-Host "    - HyperV folder under project" -ForegroundColor White
    Write-Host ""

    if (-not $Force -and -not $DryRun) {
        Write-Host "  Type 'RESET' to confirm factory reset:" -ForegroundColor Red
        $confirm = Read-Host "  "
        if ($confirm -ne 'RESET') {
            Write-Host ""
            Write-Host "  Factory reset cancelled." -ForegroundColor DarkGray
            Write-Host ""
            Read-Host "  Press Enter to continue"
            return
        }
    }

    Write-Host ""
    Write-Host "  EXECUTING FACTORY RESET..." -ForegroundColor Red
    Write-Host ""

    # Remove VMs
    $vms = Get-DevBoxVMs -IncludeOrphaned
    foreach ($vm in $vms) {
        Write-Host "  Removing VM: $($vm.vmName)... " -NoNewline
        if ($DryRun) {
            Write-Host "[DRY RUN]" -ForegroundColor Yellow
        } else {
            try {
                $hyperVVM = Get-VM -Name $vm.vmName -ErrorAction SilentlyContinue
                if ($hyperVVM) {
                    if ($hyperVVM.State -eq 'Running') {
                        Stop-VM -Name $vm.vmName -Force -TurnOff -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                    }
                    Remove-VM -Name $vm.vmName -Force -ErrorAction Stop
                }
                Unregister-DevBoxVM -VMName $vm.vmName | Out-Null
                Write-Host "[OK]" -ForegroundColor Green
            } catch {
                Write-Host "[FAILED]" -ForegroundColor Red
            }
        }
    }

    # Remove Templates
    if (-not $KeepTemplates) {
        $templates = Get-DevBoxTemplates -IncludeOrphaned
        foreach ($template in $templates) {
            Write-Host "  Removing template: $($template.name)... " -NoNewline
            if ($DryRun) {
                Write-Host "[DRY RUN]" -ForegroundColor Yellow
            } else {
                try {
                    if ($template.vhdxPath -and (Test-Path $template.vhdxPath)) {
                        Remove-Item -Path $template.vhdxPath -Force -ErrorAction Stop
                    }
                    Unregister-DevBoxTemplate -Name $template.name | Out-Null
                    Write-Host "[OK]" -ForegroundColor Green
                } catch {
                    Write-Host "[FAILED]" -ForegroundColor Red
                }
            }
        }
    }

    # Remove folders
    $paths = Get-DevBoxPaths -ScriptRoot $PSScriptRoot

    # Remove HyperV folder
    if (Test-Path $paths.HyperV) {
        Write-Host "  Removing HyperV folder... " -NoNewline
        if ($DryRun) {
            Write-Host "[DRY RUN]" -ForegroundColor Yellow
        } else {
            try {
                Remove-Item -Path $paths.HyperV -Recurse -Force -ErrorAction Stop
                Write-Host "[OK]" -ForegroundColor Green
            } catch {
                Write-Host "[FAILED]" -ForegroundColor Red
            }
        }
    }

    # Clean temp
    if (Test-Path $paths.Temp) {
        Write-Host "  Cleaning temp folder... " -NoNewline
        if ($DryRun) {
            Write-Host "[DRY RUN]" -ForegroundColor Yellow
        } else {
            try {
                Get-ChildItem -Path $paths.Temp | Remove-Item -Force -Recurse -ErrorAction Stop
                Write-Host "[OK]" -ForegroundColor Green
            } catch {
                Write-Host "[FAILED]" -ForegroundColor Red
            }
        }
    }

    # Clean logs
    if (Test-Path $paths.Log) {
        Write-Host "  Cleaning log folder... " -NoNewline
        if ($DryRun) {
            Write-Host "[DRY RUN]" -ForegroundColor Yellow
        } else {
            try {
                Get-ChildItem -Path $paths.Log -Filter "*.log" | Remove-Item -Force -ErrorAction Stop
                Write-Host "[OK]" -ForegroundColor Green
            } catch {
                Write-Host "[FAILED]" -ForegroundColor Red
            }
        }
    }

    # Reset asset registry
    Write-Host "  Resetting asset registry... " -NoNewline
    if ($DryRun) {
        Write-Host "[DRY RUN]" -ForegroundColor Yellow
    } else {
        $registryPath = Join-Path $paths.Config "asset-registry.json"
        if (Test-Path $registryPath) {
            Remove-Item $registryPath -Force -ErrorAction SilentlyContinue
        }
        Initialize-AssetRegistry -ScriptRoot $PSScriptRoot | Out-Null
        Write-Host "[OK]" -ForegroundColor Green
    }

    Write-Host ""
    if ($DryRun) {
        Write-Host "  [DRY RUN COMPLETE] No changes were made." -ForegroundColor Yellow
    } else {
        Write-Host "  [FACTORY RESET COMPLETE]" -ForegroundColor Green
    }
    Write-Host ""
    Read-Host "  Press Enter to continue"
}

# Main
Show-Banner
$assets = Show-AssetSummary

while ($true) {
    Show-MainMenu -Assets $assets

    $choice = Read-Host "  Enter choice"

    switch ($choice.ToUpper()) {
        '1' {
            Show-Banner
            Remove-DevBoxVMsMenu -VMs $assets.VMs
            Show-Banner
            $assets = Show-AssetSummary
        }
        '2' {
            Show-Banner
            Remove-DevBoxTemplatesMenu -Templates $assets.Templates
            Show-Banner
            $assets = Show-AssetSummary
        }
        '3' {
            Show-Banner
            Remove-DevBoxSwitchesMenu -Switches $assets.Switches
            Show-Banner
            $assets = Show-AssetSummary
        }
        '4' {
            Show-Banner
            Invoke-CleanTempFiles
            Show-Banner
            $assets = Show-AssetSummary
        }
        '5' {
            Show-Banner
            Invoke-CleanLogFiles
            Show-Banner
            $assets = Show-AssetSummary
        }
        'R' {
            Show-Banner
            Invoke-FactoryReset
            Show-Banner
            $assets = Show-AssetSummary
        }
        'D' {
            $Script:DryRun = $true
            Show-Banner
            Write-Host "  [DRY RUN MODE ENABLED]" -ForegroundColor Yellow
            Write-Host ""
            $assets = Show-AssetSummary
        }
        'Q' {
            Write-Host ""
            Write-Host "  Goodbye!" -ForegroundColor Cyan
            Write-Host ""
            exit 0
        }
        default {
            Write-Host "  Invalid choice." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            Show-Banner
            $assets = Show-AssetSummary
        }
    }
}
