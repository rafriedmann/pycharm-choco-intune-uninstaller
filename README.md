# PyCharm Chocolatey Uninstaller

A PowerShell tool to automatically uninstall old versions of PyCharm that were installed via Chocolatey. This solves the common issue where Chocolatey or PyCharm installers fail to remove previous versions during updates, leading to multiple versions accumulating on the system.

## Problem Statement

When PyCharm is installed or updated via Chocolatey, old versions sometimes remain installed on the system. This tool identifies all installed PyCharm versions and uninstalls older ones, keeping only the latest version (or a specified number of recent versions).

## Features

- Detects all PyCharm installations (Community and Professional editions)
- Automatically identifies the latest version
- Uninstalls old versions silently
- Supports keeping multiple recent versions
- Comprehensive logging
- WhatIf mode for safe testing
- Works with both HKLM and HKCU registry locations
- Silent mode for automated deployments
- Device inventory marker for dynamic group targeting

## Files Included

| File | Description |
|------|-------------|
| `Uninstall-OldPyCharm.ps1` | Main script that removes old PyCharm versions |
| `Detect-OldPyCharm.ps1` | Detection script for Intune Remediations |
| `Set-PyCharmMarker.ps1` | Inventory script that sets registry marker for device grouping |
| `README.md` | This file - comprehensive documentation |
| `EXAMPLES.md` | Detailed examples for various deployment scenarios |
| `LICENSE` | MIT License |

## Requirements

- Windows operating system
- PowerShell 5.1 or later
- Administrator privileges

## Usage

### Basic Usage

Run as Administrator to uninstall all old PyCharm versions, keeping only the latest:

```powershell
.\Uninstall-OldPyCharm.ps1
```

### Test Mode (WhatIf)

See what would be uninstalled without actually doing it:

```powershell
.\Uninstall-OldPyCharm.ps1 -WhatIf
```

### Keep Multiple Versions

Keep the 2 most recent versions:

```powershell
.\Uninstall-OldPyCharm.ps1 -KeepVersions 2
```

### Target Specific Edition

Only clean up PyCharm Community Edition:

```powershell
.\Uninstall-OldPyCharm.ps1 -Edition Community
```

Only clean up PyCharm Professional Edition:

```powershell
.\Uninstall-OldPyCharm.ps1 -Edition Professional
```

### Custom Log Location

Specify a custom log file location:

```powershell
.\Uninstall-OldPyCharm.ps1 -LogPath "C:\Logs\PyCharmCleanup.log"
```

### Silent Mode

Run without console output (useful for scheduled tasks and automated deployments):

```powershell
.\Uninstall-OldPyCharm.ps1 -Silent
```

Note: Logging to file still occurs in silent mode.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `KeepVersions` | Integer | 1 | Number of most recent versions to keep |
| `Edition` | String | 'All' | Target edition: 'Community', 'Professional', or 'All' |
| `LogPath` | String | `.\PyCharmCleanup.log` | Path to write log file |
| `Silent` | Switch | False | Suppresses console output (logging to file still occurs) |
| `WhatIf` | Switch | False | Preview what would be uninstalled without doing it |

## Intune Deployment

To deploy this script via Microsoft Intune:

### As a Remediation Script

1. In Intune, go to **Devices** > **Remediations**
2. Create a new script package
3. **Detection script**: Check if multiple PyCharm versions exist
4. **Remediation script**: Use `Uninstall-OldPyCharm.ps1`
5. Configure to run in **System context**
6. Assign to target device groups

### As a PowerShell Script

1. In Intune, go to **Devices** > **Scripts** > **Add** > **Windows 10 and later**
2. Upload `Uninstall-OldPyCharm.ps1`
3. Configure settings:
   - Run this script using the logged on credentials: **No**
   - Enforce script signature check: **No** (unless you sign it)
   - Run script in 64-bit PowerShell: **Yes**
4. Assign to target groups

### Creating a Dynamic Group for Devices with PyCharm

To automatically target only devices that have PyCharm installed, you can create a dynamic device group in Intune.

#### Option 1: Using Custom Device Properties (Recommended)

Since Intune doesn't natively expose installed applications in dynamic group rules, use a detection script to set a custom registry value, then create a compliance policy to read it.

1. **Create a Detection Script** (`Set-PyCharmMarker.ps1`):
```powershell
# Check if PyCharm is installed
$pyCharmInstalled = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName -like "PyCharm*" }

if ($pyCharmInstalled) {
    # Set a marker in registry for dynamic group detection
    $registryPath = "HKLM:\SOFTWARE\YourCompany\Inventory"
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    Set-ItemProperty -Path $registryPath -Name "PyCharmInstalled" -Value "True" -Type String
    Write-Host "PyCharm detected and marker set"
    exit 0
} else {
    Write-Host "PyCharm not installed"
    exit 0
}
```

2. **Deploy Detection Script via Intune**:
   - Go to **Devices** > **Scripts** > **Add** > **Windows 10 and later**
   - Upload the detection script
   - Assign to **All Devices**
   - Schedule to run daily or weekly

3. **Create Custom Compliance Policy**:
   - Go to **Devices** > **Compliance policies** > **Create policy**
   - Platform: **Windows 10 and later**
   - Add a custom compliance setting using a detection script:
```powershell
$marker = Get-ItemProperty -Path "HKLM:\SOFTWARE\YourCompany\Inventory" -Name "PyCharmInstalled" -ErrorAction SilentlyContinue
if ($marker.PyCharmInstalled -eq "True") {
    return "Compliant"
}
```
   - This creates a device property you can reference

4. **Alternative: Use Dynamic Group with Device Name Pattern**:

   If your organization uses naming conventions, create a dynamic group:
   - Go to **Azure Active Directory** > **Groups** > **New group**
   - Group type: **Security**
   - Membership type: **Dynamic Device**
   - Click **Add dynamic query**
   - Use rule syntax like:
   ```
   (device.displayName -contains "DEV") or (device.displayName -contains "WORKSTATION")
   ```

#### Option 2: Using Intune Detected Apps Report

1. **Query Intune for Devices with PyCharm**:
   - Go to **Apps** > **Monitor** > **Discovered apps**
   - Search for "PyCharm"
   - Export the list of devices
   - Create a static group with these devices

2. **Create the Device Group**:
   - Go to **Groups** > **New group**
   - Group type: **Security**
   - Membership type: **Assigned** (static)
   - Add devices from the discovered apps list

#### Option 3: Use Hardware Inventory Extensions (Advanced)

For organizations using Configuration Manager co-management or Intune endpoint analytics:

1. **Enable Endpoint Analytics**
2. **Query device inventory** for PyCharm installations
3. **Export and create static group** or use reporting workbooks

#### Recommended Approach

For most organizations, the **simplest approach** is:

1. Deploy the detection script to **All Devices** that sets a registry marker
2. Create a **static group** initially based on Discovered Apps report
3. Use the **Remediation** feature with assignments to this group
4. Let the Remediation detection script handle future device identification automatically

The Intune Remediation feature (Option 1 above) automatically handles device targeting because:
- Detection script runs on all assigned devices
- Only devices where detection fails get remediation
- No need for complex dynamic groups

**Quick Setup:**
1. Create a group called "Devices - PyCharm Users" (static or dynamic based on department/OU)
2. Assign the Remediation package to this group
3. The detection script (`Detect-OldPyCharm.ps1`) will identify which devices actually need cleanup

### Scheduled Task (GPO or Intune)

Create a scheduled task that runs monthly to prevent accumulation:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Uninstall-OldPyCharm.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -At 2am -DaysOfWeek Sunday
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "PyCharm Cleanup" -Action $action -Trigger $trigger -Principal $principal
```

## How It Works

1. **Scans Registry**: Checks both HKLM and HKCU uninstall registry keys for PyCharm installations
2. **Parses Versions**: Extracts version numbers from display names (e.g., "PyCharm Community Edition 2024.2.1")
3. **Groups by Edition**: Separates Community and Professional editions
4. **Sorts by Version**: Orders installations by version number (newest first)
5. **Keeps Latest**: Retains the specified number of most recent versions
6. **Uninstalls Old Versions**: Executes silent uninstall for older versions
7. **Logs Everything**: Creates detailed log file of all operations

## Logging

The script creates a detailed log file (default: `PyCharmCleanup.log`) in the script directory. The log includes:

- Timestamp for each operation
- All detected installations
- Versions kept and uninstalled
- Success/failure status
- Any errors encountered

## Exit Codes

- `0`: Success
- `1`: Error occurred (check log file for details)

## Troubleshooting

### Script requires Administrator privileges

Run PowerShell as Administrator before executing the script.

### Uninstall fails with non-zero exit code

Some PyCharm versions may have corrupted uninstallers. Check the log file for details and consider manually removing these installations.

### No installations found

Ensure PyCharm was installed via the standard installer. Portable versions or custom installations may not be detected.

### WhatIf shows versions but nothing uninstalls

Ensure you're running without the `-WhatIf` parameter when ready to perform actual uninstallation.

## Examples

### Example 1: First Run

```powershell
PS> .\Uninstall-OldPyCharm.ps1

[2025-11-17 10:30:15] [INFO] === PyCharm Cleanup Script Started ===
[2025-11-17 10:30:15] [INFO] Parameters: KeepVersions=1, Edition=All
[2025-11-17 10:30:15] [INFO] Scanning for PyCharm installations...
[2025-11-17 10:30:16] [INFO] Found 3 PyCharm installation(s)
[2025-11-17 10:30:16] [INFO] Processing PyCharm Community Edition: 3 version(s) found
[2025-11-17 10:30:16] [INFO]   - PyCharm Community Edition 2024.2.1 (Version: 2024.2.1)
[2025-11-17 10:30:16] [INFO]   - PyCharm Community Edition 2024.1.0 (Version: 2024.1.0)
[2025-11-17 10:30:16] [INFO]   - PyCharm Community Edition 2023.3.2 (Version: 2023.3.2)
[2025-11-17 10:30:16] [INFO] Keeping 1 version(s):
[2025-11-17 10:30:16] [SUCCESS]   ✓ PyCharm Community Edition 2024.2.1 (Version: 2024.2.1)
[2025-11-17 10:30:16] [INFO] Uninstalling 2 old version(s):
[2025-11-17 10:30:16] [INFO] Uninstalling: PyCharm Community Edition 2024.1.0 (Version: 2024.1.0)
[2025-11-17 10:30:35] [SUCCESS] Successfully uninstalled: PyCharm Community Edition 2024.1.0
[2025-11-17 10:30:35] [INFO] Uninstalling: PyCharm Community Edition 2023.3.2 (Version: 2023.3.2)
[2025-11-17 10:30:52] [SUCCESS] Successfully uninstalled: PyCharm Community Edition 2023.3.2
[2025-11-17 10:30:52] [INFO] === PyCharm Cleanup Completed ===
[2025-11-17 10:30:52] [INFO] Summary: 1 version(s) kept, 2 version(s) uninstalled
```

## License

MIT License - Feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please submit issues or pull requests on the project repository.
