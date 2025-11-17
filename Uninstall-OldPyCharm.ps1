<#
.SYNOPSIS
    Uninstalls old versions of PyCharm installed via Chocolatey, keeping only the latest version.

.DESCRIPTION
    This script identifies all installed PyCharm versions (Community and Professional editions),
    determines the latest version, and uninstalls all older versions to prevent accumulation
    of outdated installations when Chocolatey or PyCharm installer fails to clean up properly.

.PARAMETER WhatIf
    Shows what would be uninstalled without actually performing the uninstallation.

.PARAMETER KeepVersions
    Number of most recent versions to keep (default: 1)

.PARAMETER Edition
    Specify which edition to clean up: 'Community', 'Professional', or 'All' (default: 'All')

.PARAMETER LogPath
    Path to write log file (default: current directory\PyCharmCleanup.log)

.PARAMETER Silent
    Suppresses console output. Logging to file still occurs.

.EXAMPLE
    .\Uninstall-OldPyCharm.ps1
    Uninstalls all old PyCharm versions, keeping only the latest.

.EXAMPLE
    .\Uninstall-OldPyCharm.ps1 -WhatIf
    Shows what would be uninstalled without actually doing it.

.EXAMPLE
    .\Uninstall-OldPyCharm.ps1 -KeepVersions 2
    Keeps the 2 most recent versions and uninstalls older ones.

.EXAMPLE
    .\Uninstall-OldPyCharm.ps1 -Edition Community
    Only cleans up PyCharm Community Edition installations.

.EXAMPLE
    .\Uninstall-OldPyCharm.ps1 -Silent
    Runs silently without console output (useful for scheduled tasks).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [int]$KeepVersions = 1,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Community', 'Professional', 'All')]
    [string]$Edition = 'All',

    [Parameter(Mandatory=$false)]
    [string]$LogPath = (Join-Path $PSScriptRoot "PyCharmCleanup.log"),

    [Parameter(Mandatory=$false)]
    [switch]$Silent
)

#Requires -RunAsAdministrator

# Initialize logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to console unless Silent mode is enabled
    if (-not $Silent) {
        Write-Host $logMessage
    }

    # Always write to log file
    Add-Content -Path $LogPath -Value $logMessage
}

# Function to parse version from display name
function Get-VersionFromDisplayName {
    param([string]$DisplayName)

    if ($DisplayName -match '(\d{4}\.\d+(?:\.\d+)?)') {
        return [version]$matches[1]
    }
    return $null
}

# Function to get all PyCharm installations from registry
function Get-PyCharmInstallations {
    param([string]$EditionFilter)

    $installations = @()
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        try {
            $items = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.DisplayName -like "PyCharm*" -and
                    $_.UninstallString -ne $null
                }

            foreach ($item in $items) {
                # Determine edition
                $itemEdition = if ($item.DisplayName -like "*Community*") { "Community" }
                              elseif ($item.DisplayName -like "*Professional*") { "Professional" }
                              else { "Unknown" }

                # Skip if edition filter doesn't match
                if ($EditionFilter -ne 'All' -and $itemEdition -ne $EditionFilter) {
                    continue
                }

                $version = Get-VersionFromDisplayName -DisplayName $item.DisplayName

                if ($version) {
                    $installations += [PSCustomObject]@{
                        DisplayName = $item.DisplayName
                        Version = $version
                        UninstallString = $item.UninstallString
                        Edition = $itemEdition
                        InstallLocation = $item.InstallLocation
                        Publisher = $item.Publisher
                    }
                }
            }
        }
        catch {
            Write-Log "Error reading registry path ${path}: $_" "WARNING"
        }
    }

    return $installations
}

# Function to uninstall a PyCharm version
function Uninstall-PyCharm {
    param(
        [PSCustomObject]$Installation
    )

    Write-Log "Uninstalling: $($Installation.DisplayName) (Version: $($Installation.Version))" "INFO"

    $uninstallString = $Installation.UninstallString

    # Parse the uninstall string
    if ($uninstallString -match '^"?(.+?\.exe)"?\s*(.*)$') {
        $exePath = $matches[1]
        $arguments = $matches[2]

        # Add silent uninstall parameters if not present
        if ($arguments -notmatch '/S') {
            $arguments += " /S"
        }

        try {
            Write-Log "Executing: $exePath $arguments" "INFO"

            if ($PSCmdlet.ShouldProcess($Installation.DisplayName, "Uninstall")) {
                $process = Start-Process -FilePath $exePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow

                if ($process.ExitCode -eq 0) {
                    Write-Log "Successfully uninstalled: $($Installation.DisplayName)" "SUCCESS"
                    return $true
                } else {
                    Write-Log "Uninstall returned exit code $($process.ExitCode) for: $($Installation.DisplayName)" "WARNING"
                    return $false
                }
            } else {
                Write-Log "WhatIf: Would uninstall $($Installation.DisplayName)" "INFO"
                return $true
            }
        }
        catch {
            Write-Log "Failed to uninstall $($Installation.DisplayName): $_" "ERROR"
            return $false
        }
    }
    else {
        Write-Log "Could not parse uninstall string: $uninstallString" "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Log "=== PyCharm Cleanup Script Started ===" "INFO"
    Write-Log "Parameters: KeepVersions=$KeepVersions, Edition=$Edition" "INFO"

    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator!" "ERROR"
        throw "Administrator privileges required"
    }

    # Get all PyCharm installations
    Write-Log "Scanning for PyCharm installations..." "INFO"
    $installations = Get-PyCharmInstallations -EditionFilter $Edition

    if ($installations.Count -eq 0) {
        Write-Log "No PyCharm installations found." "INFO"
        exit 0
    }

    Write-Log "Found $($installations.Count) PyCharm installation(s)" "INFO"

    # Group by edition
    $groupedInstalls = $installations | Group-Object -Property Edition

    $totalUninstalled = 0
    $totalKept = 0

    foreach ($group in $groupedInstalls) {
        $editionName = $group.Name
        $editionInstalls = $group.Group | Sort-Object -Property Version -Descending

        Write-Log "Processing PyCharm $editionName Edition: $($editionInstalls.Count) version(s) found" "INFO"

        # Display all versions
        foreach ($install in $editionInstalls) {
            Write-Log "  - $($install.DisplayName) (Version: $($install.Version))" "INFO"
        }

        if ($editionInstalls.Count -le $KeepVersions) {
            Write-Log "Number of installations ($($editionInstalls.Count)) <= KeepVersions ($KeepVersions). Nothing to uninstall for $editionName." "INFO"
            $totalKept += $editionInstalls.Count
            continue
        }

        # Keep the newest version(s)
        $toKeep = $editionInstalls | Select-Object -First $KeepVersions
        $toUninstall = $editionInstalls | Select-Object -Skip $KeepVersions

        Write-Log "Keeping $($toKeep.Count) version(s):" "INFO"
        foreach ($install in $toKeep) {
            Write-Log "  ✓ $($install.DisplayName) (Version: $($install.Version))" "SUCCESS"
        }
        $totalKept += $toKeep.Count

        Write-Log "Uninstalling $($toUninstall.Count) old version(s):" "INFO"
        foreach ($install in $toUninstall) {
            $result = Uninstall-PyCharm -Installation $install
            if ($result) {
                $totalUninstalled++
            }
        }
    }

    Write-Log "=== PyCharm Cleanup Completed ===" "INFO"
    Write-Log "Summary: $totalKept version(s) kept, $totalUninstalled version(s) uninstalled" "INFO"

    exit 0
}
catch {
    Write-Log "Script failed with error: $_" "ERROR"
    Write-Log $_.ScriptStackTrace "ERROR"
    exit 1
}
