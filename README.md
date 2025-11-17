# PyCharm Chocolatey Uninstaller

A PowerShell tool to automatically uninstall old versions of PyCharm that were installed via Chocolatey. This solves the common issue where Chocolatey or PyCharm installers fail to remove previous versions during updates, leading to multiple versions accumulating on the system.

## Problem Statement

When PyCharm is installed or updated via Chocolatey, old versions sometimes remain installed on the system. This tool identifies all installed PyCharm versions and uninstalls older ones, keeping only the latest version (or a specified number of recent versions).

## Features

- Detects all PyCharm installations (Community and Professional editions)
- Automatically identifies the latest version
- Uninstalls old versions silently
- **Cleans up leftover installation folders** after uninstall
- Supports keeping multiple recent versions
- Comprehensive logging
- WhatIf mode for safe testing
- Works with both HKLM and HKCU registry locations
- Silent mode for automated deployments

## Files Included

| File | Description |
|------|-------------|
| `Uninstall-OldPyCharm.ps1` | Main script that removes old PyCharm versions |
| `Detect-OldPyCharm.ps1` | Detection script for Intune Remediations (requires Intune Plan 2) |
| `Set-PyCharmMarker.ps1` | Inventory script that sets registry marker for device grouping (optional - for advanced scenarios) |
| `README.md` | This file - comprehensive documentation |
| `EXAMPLES.md` | Detailed examples for various deployment scenarios |
| `LICENSING.md` | License tier requirements and deployment options for minimal licenses |
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

**License Requirements:** Different deployment options require different Intune license tiers. See `LICENSING.md` for detailed breakdown by license level.

**Quick License Check:**
- **Minimal (Intune Plan 1)**: Use PowerShell Scripts with static groups (Option 1)
- **Standard (Intune Plan 2)**: Use Remediations with All Devices assignment (Option 2) - Recommended
- **Premium (Plan 2 + Azure AD P1)**: All options available including dynamic groups

To deploy this script via Microsoft Intune:

### As a Remediation Script (Requires Intune Plan 2 or Windows E3/E5)

1. In Intune, go to **Devices** > **Remediations**
2. Create a new script package
3. **Detection script**: Upload `Detect-OldPyCharm.ps1`
4. **Remediation script**: Upload `Uninstall-OldPyCharm.ps1`
5. Configure to run in **System context**
6. Assign to target device groups

**Note:** If you don't have Remediations (Intune Plan 1), see "As a PowerShell Script" below or refer to `LICENSING.md` for alternative approaches.

### As a PowerShell Script (Works with all Intune licenses)

For organizations with **Intune Plan 1** (basic license) without Remediations:

1. In Intune, go to **Devices** > **Scripts** > **Add** > **Windows 10 and later**
2. Upload `Uninstall-OldPyCharm.ps1`
3. Configure settings:
   - Run this script using the logged on credentials: **No**
   - Enforce script signature check: **No** (unless you sign it)
   - Run script in 64-bit PowerShell: **Yes**
4. Assign to target groups (use static group from Discovered Apps)

**Difference from Remediations:**
- PowerShell Scripts run once per assignment
- No automatic detection/remediation scheduling
- To run periodically, deploy a scheduled task (see `EXAMPLES.md`)
- Still effective for one-time or scheduled cleanup

### Targeting Devices with PyCharm (No Additional Scripts Needed)

You can target only devices with PyCharm installed using Intune's built-in features. **No additional scripts required** - Intune already reads the existing PyCharm registry entries.

**Registry Keys Used by PyCharm (and scanned by Intune):**
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`
- `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*`

#### Option 1: Use Discovered Apps (For Targeted Deployment)

Intune automatically inventories installed applications from registry keys.

**Steps:**
1. Go to **Apps** > **Monitor** > **Discovered apps**
2. Search for "PyCharm"
3. Click on the PyCharm app entry
4. View **Device install status** tab to see which devices have it
5. Note the device names (Export creates CSV but can't be imported directly)
6. Create a static group:
   - **Groups** > **New group**
   - Name: `Devices - PyCharm Installed`
   - Type: **Security**, Membership: **Assigned**
   - **Members** > **Add members** > Search and add devices one by one
7. Assign remediation to this group

**Note:** The export is for reference only. You must manually add devices to the group, or use PowerShell/Graph API for automation (see `EXAMPLES.md`).

**Pros:** Targets only devices with PyCharm, uses existing registry keys
**Cons:** Manual group creation, requires periodic updates

**Recommendation:** For most scenarios, use **Option 2 (All Devices)** instead - it's simpler and self-maintaining.

#### Option 2: Assign to All Devices (Simplest)

The **easiest approach** - let the detection script handle targeting:

1. Assign remediation to **All Devices** or **All Developers**
2. The `Detect-OldPyCharm.ps1` script automatically detects PyCharm
3. Only devices with multiple PyCharm versions get remediated

**How it works:**
- Device without PyCharm → Detection exits 0 (no action)
- Device with one PyCharm → Detection exits 0 (no action)
- Device with multiple PyCharm versions → Detection exits 1 → Remediation runs

**Pros:** Zero configuration, self-maintaining, automatically handles new installations
**Cons:** Detection runs on all assigned devices (minimal overhead)

#### Option 3: Dynamic Group by Department/Naming

If using device naming conventions or department attributes:

1. Create dynamic group in **Azure AD** > **Groups**
2. Use query like:
   ```
   (device.displayName -startsWith "DEV-")
   ```
   or
   ```
   (device.departmentName -eq "Engineering")
   ```
3. Assign remediation to this group

#### Option 4: Dynamic Group via Compliance Policy (Advanced)

For truly dynamic groups, create a custom compliance policy that reads existing PyCharm registry keys, then create a dynamic device group based on compliance status.

See `EXAMPLES.md` for detailed step-by-step instructions on:
- Creating a custom compliance policy to detect PyCharm
- Setting up dynamic groups based on compliance results
- Using assignment filters as an alternative

**Benefits:** Fully automatic, updates as PyCharm is installed/removed
**Limitation:** More complex setup, requires compliance policy knowledge

**Recommended:** Use Option 2 (All Devices) for simplicity, or Option 1 (Discovered Apps) for targeted deployment. Use Option 4 for enterprise scenarios requiring auto-updating groups.

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
7. **Cleans Up Folders**: Removes leftover installation directories after uninstall
   - Checks registry InstallLocation path
   - Scans common JetBrains installation directories
   - Removes matching folders even if uninstaller left them behind
8. **Logs Everything**: Creates detailed log file of all operations

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

### Leftover folders after uninstall

The script automatically detects and removes leftover installation folders after running the uninstaller. This includes:
- The InstallLocation path from registry
- Common JetBrains installation directories (C:\Program Files\JetBrains\PyCharm*)
- Version-specific folders that may have been left behind

If manual cleanup is needed, check these locations:
- `C:\Program Files\JetBrains\`
- `C:\Program Files (x86)\JetBrains\`

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
[2025-11-17 10:30:37] [INFO] Removing leftover folder: C:\Program Files\JetBrains\PyCharm Community Edition 2024.1.0
[2025-11-17 10:30:37] [SUCCESS] Successfully removed folder: C:\Program Files\JetBrains\PyCharm Community Edition 2024.1.0
[2025-11-17 10:30:37] [INFO] Uninstalling: PyCharm Community Edition 2023.3.2 (Version: 2023.3.2)
[2025-11-17 10:30:52] [SUCCESS] Successfully uninstalled: PyCharm Community Edition 2023.3.2
[2025-11-17 10:30:54] [INFO] Removing leftover folder: C:\Program Files\JetBrains\PyCharm Community Edition 2023.3.2
[2025-11-17 10:30:54] [SUCCESS] Successfully removed folder: C:\Program Files\JetBrains\PyCharm Community Edition 2023.3.2
[2025-11-17 10:30:54] [INFO] === PyCharm Cleanup Completed ===
[2025-11-17 10:30:54] [INFO] Summary: 1 version(s) kept, 2 version(s) uninstalled
```

## License

MIT License - Feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please submit issues or pull requests on the project repository.
