<#
.SYNOPSIS
    Sets a registry marker when PyCharm is detected on the device.

.DESCRIPTION
    This script checks if PyCharm (any edition) is installed on the device.
    If found, it sets a registry marker that can be used for:
    - Custom compliance policies
    - Inventory reporting
    - Dynamic group membership (via compliance)
    - Device categorization

    This is useful for identifying devices that need the PyCharm cleanup script
    without querying the entire Intune discovered apps database.

.PARAMETER RegistryPath
    Custom registry path for the marker (default: HKLM:\SOFTWARE\Organization\Inventory)

.PARAMETER MarkerName
    Name of the registry value (default: PyCharmInstalled)

.EXAMPLE
    .\Set-PyCharmMarker.ps1
    Checks for PyCharm and sets the default registry marker.

.EXAMPLE
    .\Set-PyCharmMarker.ps1 -RegistryPath "HKLM:\SOFTWARE\Contoso\AppInventory"
    Uses a custom registry path for the marker.

.NOTES
    Deploy this script via Intune to all devices to maintain an inventory
    of which devices have PyCharm installed. Run it periodically (daily/weekly)
    to keep the inventory current.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$RegistryPath = "HKLM:\SOFTWARE\Organization\Inventory",

    [Parameter(Mandatory=$false)]
    [string]$MarkerName = "PyCharmInstalled"
)

try {
    # Search for PyCharm installations in registry
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $pyCharmInstalled = $false
    $editions = @()
    $versions = @()

    foreach ($path in $registryPaths) {
        $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "PyCharm*" }

        foreach ($app in $apps) {
            $pyCharmInstalled = $true

            # Extract edition
            if ($app.DisplayName -like "*Community*") {
                $editions += "Community"
            } elseif ($app.DisplayName -like "*Professional*") {
                $editions += "Professional"
            }

            # Extract version if available
            if ($app.DisplayVersion) {
                $versions += $app.DisplayVersion
            }
        }
    }

    # Create registry path if it doesn't exist
    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
        Write-Host "Created registry path: $RegistryPath"
    }

    if ($pyCharmInstalled) {
        # Set marker to True
        Set-ItemProperty -Path $RegistryPath -Name $MarkerName -Value "True" -Type String

        # Store additional metadata
        if ($editions.Count -gt 0) {
            $uniqueEditions = $editions | Select-Object -Unique
            Set-ItemProperty -Path $RegistryPath -Name "PyCharmEditions" -Value ($uniqueEditions -join ",") -Type String
        }

        if ($versions.Count -gt 0) {
            $uniqueVersions = $versions | Select-Object -Unique
            Set-ItemProperty -Path $RegistryPath -Name "PyCharmVersions" -Value ($uniqueVersions -join ",") -Type String
        }

        Set-ItemProperty -Path $RegistryPath -Name "PyCharmLastDetected" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Type String
        Set-ItemProperty -Path $RegistryPath -Name "PyCharmCount" -Value $versions.Count -Type String

        Write-Host "PyCharm detected - Marker set to True"
        Write-Host "Editions: $($uniqueEditions -join ', ')"
        Write-Host "Versions: $($uniqueVersions -join ', ')"
        exit 0
    } else {
        # Set marker to False or remove it
        Set-ItemProperty -Path $RegistryPath -Name $MarkerName -Value "False" -Type String
        Set-ItemProperty -Path $RegistryPath -Name "PyCharmLastChecked" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Type String

        Write-Host "PyCharm not detected - Marker set to False"
        exit 0
    }
}
catch {
    Write-Host "Error setting PyCharm marker: $_"
    exit 1
}
