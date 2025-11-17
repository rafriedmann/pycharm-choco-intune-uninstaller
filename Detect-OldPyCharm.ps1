<#
.SYNOPSIS
    Detection script for Intune Remediation to check if old PyCharm versions exist.

.DESCRIPTION
    This script detects if there are multiple PyCharm versions installed on the system.
    It's designed to be used as the detection script in Microsoft Intune Remediations,
    paired with Uninstall-OldPyCharm.ps1 as the remediation script.

    Exit Codes:
    - 0: No remediation needed (only one or zero PyCharm versions found)
    - 1: Remediation needed (multiple PyCharm versions detected)

.PARAMETER KeepVersions
    Number of versions that should be kept (default: 1)

.EXAMPLE
    .\Detect-OldPyCharm.ps1
    Checks if there are multiple PyCharm versions installed.
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$KeepVersions = 1
)

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

                $version = Get-VersionFromDisplayName -DisplayName $item.DisplayName

                if ($version) {
                    $installations += [PSCustomObject]@{
                        DisplayName = $item.DisplayName
                        Version = $version
                        Edition = $itemEdition
                    }
                }
            }
        }
        catch {
            # Silently continue on error
        }
    }

    return $installations
}

try {
    # Get all PyCharm installations
    $installations = Get-PyCharmInstallations

    if ($installations.Count -eq 0) {
        Write-Host "No PyCharm installations found. No remediation needed."
        exit 0
    }

    # Group by edition
    $groupedInstalls = $installations | Group-Object -Property Edition
    $needsRemediation = $false

    foreach ($group in $groupedInstalls) {
        $editionName = $group.Name
        $editionInstalls = $group.Group | Sort-Object -Property Version -Descending

        if ($editionInstalls.Count -gt $KeepVersions) {
            $needsRemediation = $true
            $toRemove = $editionInstalls.Count - $KeepVersions
            Write-Host "Found $($editionInstalls.Count) versions of PyCharm $editionName Edition. $toRemove old version(s) should be removed."

            # List versions
            $editionInstalls | ForEach-Object {
                Write-Host "  - $($_.DisplayName) (Version: $($_.Version))"
            }
        }
        else {
            Write-Host "Found $($editionInstalls.Count) version(s) of PyCharm $editionName Edition. No cleanup needed."
        }
    }

    if ($needsRemediation) {
        Write-Host "Remediation required: Old PyCharm versions detected."
        exit 1
    }
    else {
        Write-Host "No remediation needed: System is clean."
        exit 0
    }
}
catch {
    Write-Host "Detection script failed: $_"
    # Exit 0 to prevent remediation on detection errors
    exit 0
}
