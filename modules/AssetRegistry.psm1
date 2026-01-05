<#
.SYNOPSIS
    DevBox Factory Asset Registry - Tracks created VMs, templates, and resources

.DESCRIPTION
    Centralized registry for tracking DevBox Factory created assets:
    - VM Templates (VHDX files)
    - Virtual Machines
    - Virtual Switches (custom created)
    - Checkpoints
    Enables safe cleanup and factory reset operations.

.NOTES
    DevBox Factory v3.0.3
    Build: 20260105.0400
#>

$Script:RegistryPath = $null
$Script:ParentRoot = Split-Path $PSScriptRoot -Parent

function Initialize-AssetRegistry {
    <#
    .SYNOPSIS
        Initialize asset registry paths
    #>
    param(
        [string]$ScriptRoot = $PSScriptRoot
    )

    $parentRoot = Split-Path $ScriptRoot -Parent
    if ($parentRoot -eq $ScriptRoot) {
        $parentRoot = $ScriptRoot
    }

    $configFolder = Join-Path $parentRoot "config"
    if (-not (Test-Path $configFolder)) {
        New-Item -Path $configFolder -ItemType Directory -Force | Out-Null
    }

    $Script:RegistryPath = Join-Path $configFolder "asset-registry.json"
    $Script:ParentRoot = $parentRoot

    # Create registry file if it doesn't exist
    if (-not (Test-Path $Script:RegistryPath)) {
        $emptyRegistry = @{
            version = "1.0.0"
            created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            templates = @()
            virtualMachines = @()
            virtualSwitches = @()
            checkpoints = @()
        }
        $emptyRegistry | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:RegistryPath -Encoding UTF8
    }

    return @{
        RegistryPath = $Script:RegistryPath
        ParentRoot = $Script:ParentRoot
    }
}

function Get-AssetRegistry {
    <#
    .SYNOPSIS
        Get the current asset registry
    #>
    if (-not $Script:RegistryPath -or -not (Test-Path $Script:RegistryPath)) {
        Initialize-AssetRegistry | Out-Null
    }

    try {
        $registry = Get-Content -Path $Script:RegistryPath -Raw | ConvertFrom-Json
        return $registry
    } catch {
        Write-Warning "Failed to read asset registry: $_"
        return $null
    }
}

function Save-AssetRegistry {
    <#
    .SYNOPSIS
        Save the asset registry to disk
    #>
    param(
        [Parameter(Mandatory)]
        [PSObject]$Registry
    )

    if (-not $Script:RegistryPath) {
        Initialize-AssetRegistry | Out-Null
    }

    $Registry.lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    try {
        $Registry | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:RegistryPath -Encoding UTF8
        return $true
    } catch {
        Write-Warning "Failed to save asset registry: $_"
        return $false
    }
}

function Register-DevBoxTemplate {
    <#
    .SYNOPSIS
        Register a created template in the asset registry
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$VHDXPath,

        [string]$SourceISO,
        [int]$WindowsEditionIndex,
        [string]$Profile = "Full"
    )

    $registry = Get-AssetRegistry
    if (-not $registry) { return $false }

    # Remove existing entry with same name
    $registry.templates = @($registry.templates | Where-Object { $_.name -ne $Name })

    $template = @{
        name = $Name
        vhdxPath = $VHDXPath
        sourceISO = $SourceISO
        windowsEditionIndex = $WindowsEditionIndex
        profile = $Profile
        createdAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        sizeGB = if (Test-Path $VHDXPath) { [math]::Round((Get-Item $VHDXPath).Length / 1GB, 2) } else { 0 }
    }

    $registry.templates += $template
    return Save-AssetRegistry -Registry $registry
}

function Register-DevBoxVM {
    <#
    .SYNOPSIS
        Register a created VM in the asset registry
    #>
    param(
        [Parameter(Mandatory)]
        [string]$VMName,

        [Parameter(Mandatory)]
        [string]$VHDXPath,

        [string]$TemplateName,
        [int]$MemoryGB,
        [int]$ProcessorCount,
        [string]$InstallMode,
        [string]$Profile
    )

    $registry = Get-AssetRegistry
    if (-not $registry) { return $false }

    # Remove existing entry with same name
    $registry.virtualMachines = @($registry.virtualMachines | Where-Object { $_.vmName -ne $VMName })

    $vm = @{
        vmName = $VMName
        vhdxPath = $VHDXPath
        templateName = $TemplateName
        memoryGB = $MemoryGB
        processorCount = $ProcessorCount
        installMode = $InstallMode
        profile = $Profile
        createdAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $registry.virtualMachines += $vm
    return Save-AssetRegistry -Registry $registry
}

function Register-DevBoxSwitch {
    <#
    .SYNOPSIS
        Register a created virtual switch in the asset registry
    #>
    param(
        [Parameter(Mandatory)]
        [string]$SwitchName,

        [string]$SwitchType = "Internal"
    )

    $registry = Get-AssetRegistry
    if (-not $registry) { return $false }

    # Don't register built-in switches
    if ($SwitchName -eq "Default Switch") { return $true }

    # Remove existing entry with same name
    $registry.virtualSwitches = @($registry.virtualSwitches | Where-Object { $_.switchName -ne $SwitchName })

    $switch = @{
        switchName = $SwitchName
        switchType = $SwitchType
        createdAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $registry.virtualSwitches += $switch
    return Save-AssetRegistry -Registry $registry
}

function Unregister-DevBoxTemplate {
    <#
    .SYNOPSIS
        Remove a template from the registry
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $registry = Get-AssetRegistry
    if (-not $registry) { return $false }

    $registry.templates = @($registry.templates | Where-Object { $_.name -ne $Name })
    return Save-AssetRegistry -Registry $registry
}

function Unregister-DevBoxVM {
    <#
    .SYNOPSIS
        Remove a VM from the registry
    #>
    param(
        [Parameter(Mandatory)]
        [string]$VMName
    )

    $registry = Get-AssetRegistry
    if (-not $registry) { return $false }

    $registry.virtualMachines = @($registry.virtualMachines | Where-Object { $_.vmName -ne $VMName })
    return Save-AssetRegistry -Registry $registry
}

function Get-DevBoxTemplates {
    <#
    .SYNOPSIS
        Get all registered templates
    #>
    param(
        [switch]$IncludeOrphaned
    )

    $registry = Get-AssetRegistry
    if (-not $registry) { return @() }

    $templates = @($registry.templates)

    foreach ($template in $templates) {
        $template | Add-Member -NotePropertyName "exists" -NotePropertyValue (Test-Path $template.vhdxPath) -Force
    }

    if ($IncludeOrphaned) {
        # Also find VHDX files that aren't registered
        $hyperVPath = Join-Path $Script:ParentRoot "HyperV\Templates"
        if (Test-Path $hyperVPath) {
            $vhdxFiles = Get-ChildItem -Path $hyperVPath -Filter "*.vhdx" -ErrorAction SilentlyContinue
            foreach ($vhdx in $vhdxFiles) {
                $isRegistered = $templates | Where-Object { $_.vhdxPath -eq $vhdx.FullName }
                if (-not $isRegistered) {
                    $orphan = [PSCustomObject]@{
                        name = $vhdx.BaseName
                        vhdxPath = $vhdx.FullName
                        sourceISO = "Unknown"
                        createdAt = $vhdx.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                        sizeGB = [math]::Round($vhdx.Length / 1GB, 2)
                        exists = $true
                        orphaned = $true
                    }
                    $templates += $orphan
                }
            }
        }
    }

    return $templates
}

function Get-DevBoxVMs {
    <#
    .SYNOPSIS
        Get all registered VMs
    #>
    param(
        [switch]$IncludeOrphaned
    )

    $registry = Get-AssetRegistry
    if (-not $registry) { return @() }

    $vms = @($registry.virtualMachines)

    foreach ($vm in $vms) {
        $hyperVVM = Get-VM -Name $vm.vmName -ErrorAction SilentlyContinue
        $vm | Add-Member -NotePropertyName "exists" -NotePropertyValue ($null -ne $hyperVVM) -Force
        $vm | Add-Member -NotePropertyName "state" -NotePropertyValue $(if ($hyperVVM) { $hyperVVM.State.ToString() } else { "NotFound" }) -Force
    }

    if ($IncludeOrphaned) {
        # Also find VMs that match DevBox patterns but aren't registered
        $allVMs = Get-VM -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*DevBox*" -or $_.Name -like "*DevVM*" }
        foreach ($hyperVVM in $allVMs) {
            $isRegistered = $vms | Where-Object { $_.vmName -eq $hyperVVM.Name }
            if (-not $isRegistered) {
                $orphan = [PSCustomObject]@{
                    vmName = $hyperVVM.Name
                    vhdxPath = ($hyperVVM.HardDrives | Select-Object -First 1).Path
                    templateName = "Unknown"
                    memoryGB = [math]::Round($hyperVVM.MemoryStartup / 1GB, 0)
                    processorCount = $hyperVVM.ProcessorCount
                    createdAt = "Unknown"
                    exists = $true
                    state = $hyperVVM.State.ToString()
                    orphaned = $true
                }
                $vms += $orphan
            }
        }
    }

    return $vms
}

function Get-DevBoxSwitches {
    <#
    .SYNOPSIS
        Get all registered virtual switches
    #>
    $registry = Get-AssetRegistry
    if (-not $registry) { return @() }

    $switches = @($registry.virtualSwitches)

    foreach ($sw in $switches) {
        $hyperVSwitch = Get-VMSwitch -Name $sw.switchName -ErrorAction SilentlyContinue
        $sw | Add-Member -NotePropertyName "exists" -NotePropertyValue ($null -ne $hyperVSwitch) -Force
    }

    return $switches
}

function Get-DevBoxPaths {
    <#
    .SYNOPSIS
        Get DevBox Factory standard paths (project-relative)
    #>
    param(
        [string]$ScriptRoot = $PSScriptRoot
    )

    $parentRoot = Split-Path $ScriptRoot -Parent
    if ($parentRoot -eq $ScriptRoot -or [string]::IsNullOrEmpty($parentRoot)) {
        $parentRoot = $ScriptRoot
    }

    # Also check if we're in a subdirectory
    $checkPath = Join-Path $parentRoot "devbox.ps1"
    if (-not (Test-Path $checkPath)) {
        # Try going up one more level
        $parentRoot = Split-Path $parentRoot -Parent
    }

    return @{
        Root = $parentRoot
        HyperV = Join-Path $parentRoot "HyperV"
        Templates = Join-Path $parentRoot "HyperV\Templates"
        VMs = Join-Path $parentRoot "HyperV\VMs"
        Config = Join-Path $parentRoot "config"
        Temp = Join-Path $parentRoot "temp"
        Log = Join-Path $parentRoot "log"
    }
}

function Initialize-DevBoxFolders {
    <#
    .SYNOPSIS
        Create standard DevBox folder structure
    #>
    param(
        [string]$ScriptRoot = $PSScriptRoot
    )

    $paths = Get-DevBoxPaths -ScriptRoot $ScriptRoot

    foreach ($key in $paths.Keys) {
        $path = $paths[$key]
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            Write-Verbose "Created: $path"
        }
    }

    return $paths
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-AssetRegistry'
    'Get-AssetRegistry'
    'Save-AssetRegistry'
    'Register-DevBoxTemplate'
    'Register-DevBoxVM'
    'Register-DevBoxSwitch'
    'Unregister-DevBoxTemplate'
    'Unregister-DevBoxVM'
    'Get-DevBoxTemplates'
    'Get-DevBoxVMs'
    'Get-DevBoxSwitches'
    'Get-DevBoxPaths'
    'Initialize-DevBoxFolders'
)
