# Examples and Use Cases

## Intune Remediation Setup

### Step-by-Step Guide

1. **Navigate to Intune Remediations**
   - Sign in to [Microsoft Intune admin center](https://intune.microsoft.com)
   - Go to **Devices** > **Remediations**
   - Click **+ Create script package**

2. **Configure Basics**
   - Name: `PyCharm Version Cleanup`
   - Description: `Removes old PyCharm versions installed via Chocolatey`
   - Publisher: Your organization name

3. **Upload Scripts**
   - **Detection script**: Upload `Detect-OldPyCharm.ps1`
   - **Remediation script**: Upload `Uninstall-OldPyCharm.ps1`
   - Run this script using the logged-on credentials: **No**
   - Enforce script signature check: **No**
   - Run script in 64-bit PowerShell: **Yes**

4. **Configure Settings**
   - Run schedule: **Daily** or **Once** (depending on needs)

5. **Scope Tags** (if applicable)
   - Add appropriate scope tags for your organization

6. **Assignments**
   - See "Device Targeting Options" below for how to target devices

### Device Targeting Options

You have three options for targeting devices. All options use the **existing registry keys** created by PyCharm - no additional scripts needed.

#### Option A: Assign to All Devices (Recommended)

**The simplest approach:**

1. In the Assignments step above, select **All Devices** (or **All Developers**)
2. The `Detect-OldPyCharm.ps1` script automatically finds PyCharm installations
3. Only devices with multiple versions get remediated

**Example flow:**
```
Remediation runs on device
  ↓
Device has no PyCharm
  → Detection script exits 0 (compliant, no action)

Device has one PyCharm version
  → Detection script exits 0 (compliant, no action)

Device has multiple PyCharm versions
  → Detection script exits 1 (needs remediation)
  → Uninstall-OldPyCharm.ps1 runs automatically
```

**Benefits:**
- Zero configuration
- Self-maintaining
- No group management needed
- Automatically handles new PyCharm installations

#### Option B: Use Discovered Apps to Create Static Group

**For targeted deployment to only PyCharm devices:**

1. **Query for Devices with PyCharm**:
   - Sign in to [Microsoft Intune admin center](https://intune.microsoft.com)
   - Go to **Apps** > **Monitor** > **Discovered apps**
   - Type "PyCharm" in the search box
   - Click on "PyCharm Community Edition" or "PyCharm Professional"
   - Click the **Device install status** tab
   - You'll see all devices with PyCharm installed

2. **Export Device List** (for reference):
   - Click **Export** to download CSV
   - Contains device names and user information
   - **Note:** This CSV cannot be directly imported into a group

3. **Create Static Device Group (Manual Method)**:
   - Go to **Groups** > **New group**
   - Group type: **Security**
   - Group name: `Devices - PyCharm Installed`
   - Membership type: **Assigned** (static)
   - Click **Members** > **Add members**
   - **Manually search and add each device** from your CSV reference
   - Click **Create**

4. **Alternative: Automate with PowerShell** (Recommended for many devices):

   See the "PowerShell Automation" section below for scripting group membership.

5. **Assign Remediation**:
   - Return to your remediation package
   - Click **Assignments**
   - Assign to: `Devices - PyCharm Installed` group
   - Schedule: **Weekly** or **Daily**

**Benefits:**
- Only targets devices that actually have PyCharm
- Can track which devices are affected
- Good for initial cleanup deployment

**Drawbacks:**
- Manual device addition (unless using PowerShell automation)
- Requires periodic updates to keep group current

**Maintenance:**
- Periodically re-export from Discovered Apps to identify new devices
- Manually add new devices to the group
- Or switch to Option A (All Devices) for automatic coverage

### PowerShell Automation for Static Groups

If you have many devices, automate group membership using Microsoft Graph PowerShell:

```powershell
# Install Microsoft Graph module (one-time)
Install-Module Microsoft.Graph -Scope CurrentUser

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.ReadWrite.All", "DeviceManagementManagedDevices.Read.All"

# Get the group ID
$groupName = "Devices - PyCharm Installed"
$group = Get-MgGroup -Filter "displayName eq '$groupName'"

# Import your CSV from Discovered Apps export
$devicesWithPyCharm = Import-Csv -Path "C:\Temp\PyCharmDevices.csv"

# Get all Intune managed devices
$allDevices = Get-MgDeviceManagementManagedDevice -All

# Add devices to group
foreach ($csvDevice in $devicesWithPyCharm) {
    $deviceName = $csvDevice.'Device name'  # Adjust column name as needed

    # Find the Azure AD device object
    $device = $allDevices | Where-Object { $_.DeviceName -eq $deviceName }

    if ($device) {
        try {
            New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $device.AzureADDeviceId
            Write-Host "Added $deviceName to group"
        } catch {
            Write-Host "Failed to add $deviceName : $_"
        }
    }
}

Write-Host "Group membership update complete"
```

**Note:** Adjust the CSV column name based on your actual export format.

**When to Use This Approach:**
- Initial deployment to specific devices
- Testing on a subset of devices
- When you need exact control over which devices are targeted

**When to Use Option A Instead:**
- Most production deployments
- Ongoing maintenance (set and forget)
- Large device populations

#### Option C: Dynamic Group by Department/Naming

**For organizations with device naming conventions:**

1. **Create Dynamic Group**:
   - Go to **Azure Active Directory** > **Groups** > **New group**
   - Group type: **Security**
   - Group name: `Devices - Developers`
   - Membership type: **Dynamic Device**
   - Click **Add dynamic query**

2. **Add Query Rule** - Examples:

   By device name prefix:
   ```
   (device.displayName -startsWith "DEV-")
   ```

   By device name pattern:
   ```
   (device.displayName -contains "WORKSTATION")
   ```

   By department (if populated):
   ```
   (device.departmentName -eq "Engineering")
   ```

   Multiple criteria:
   ```
   (device.displayName -startsWith "DEV-") or (device.departmentName -eq "Engineering")
   ```

3. **Save and Assign**:
   - Save the dynamic group
   - Assign remediation to this group

**Benefits:**
- Automatically includes new developer machines
- No manual group updates
- Works well if you have consistent naming/department attributes

#### Option D: Dynamic Group Using Compliance Policy (Advanced)

**For truly dynamic groups based on actual PyCharm installation:**

This approach uses Intune's compliance policies to read the **existing PyCharm registry keys**, then creates a dynamic group based on compliance status. No additional scripts needed!

**Step 1: Create Custom Compliance Policy**

1. **Navigate to Compliance Policies**:
   - Go to **Devices** > **Compliance policies** > **Create policy**
   - Platform: **Windows 10 and later**
   - Name: `Detect PyCharm Installation`

2. **Add Custom Compliance Setting**:
   - Click **Settings** > **Custom Compliance**
   - Click **Add** to create a new detection script
   - Name: `PyCharm Detection`

3. **Create Detection Script**:
   ```powershell
   # Check existing PyCharm registry keys
   $pycharmFound = $false

   $registryPaths = @(
       "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
       "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
   )

   foreach ($path in $registryPaths) {
       $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue |
           Where-Object { $_.DisplayName -like "PyCharm*" }

       if ($apps) {
           $pycharmFound = $true
           break
       }
   }

   if ($pycharmFound) {
       return @{ PyCharmInstalled = $true }
   } else {
       return @{ PyCharmInstalled = $false }
   }
   ```

4. **Configure Compliance Rule**:
   - Data type: **Boolean**
   - Setting name: `PyCharmInstalled`
   - Operator: **Equals**
   - Value: **True**

5. **Assign the Policy**:
   - Assign to **All Devices** (to scan all devices)
   - This policy just detects, it doesn't enforce anything

**Step 2: Create Dynamic Device Group Based on Compliance**

1. **Create Dynamic Group**:
   - Go to **Azure Active Directory** > **Groups** > **New group**
   - Group type: **Security**
   - Group name: `Devices - PyCharm Installed (Dynamic)`
   - Membership type: **Dynamic Device**

2. **Add Dynamic Query**:
   ```
   (device.deviceComplianceStatus -eq "Compliant") -and (device.displayName -ne "")
   ```

   Note: This requires the compliance policy to mark devices as compliant. Alternatively, if using Intune's device properties, you might need to use Microsoft Graph API to filter based on compliance policy results.

3. **Alternative: Use Filters for Assignment**
   - Instead of a dynamic group, use Assignment Filters
   - Go to **Tenant administration** > **Filters** > **Create**
   - Platform: **Windows 10 and later**
   - Filter name: `Has PyCharm Installed`
   - Rule: Based on device compliance policy results

**Step 3: Assign Remediation to the Group/Filter**

1. Go to your PyCharm cleanup remediation
2. Assign to the dynamic group or use the assignment filter
3. All devices with PyCharm will automatically be included

**Benefits:**
- ✓ Truly dynamic - automatically updates as PyCharm is installed/removed
- ✓ Uses existing PyCharm registry keys (no additional markers)
- ✓ Leverages Intune's built-in compliance engine
- ✓ No manual group maintenance

**Limitations:**
- More complex setup than other options
- Compliance policy evaluation runs on Intune's schedule (typically 8 hours)
- Requires understanding of compliance policies and dynamic groups

**When to Use:**
- Large organizations needing precise, auto-updating device groups
- Compliance reporting requirements
- Integration with other compliance-based workflows

## Command-Line Examples

### Example 1: Dry Run (Test Mode)

```powershell
# See what would happen without making changes
.\Uninstall-OldPyCharm.ps1 -WhatIf
```

**Output:**
```
[2025-11-17 10:00:00] [INFO] === PyCharm Cleanup Script Started ===
[2025-11-17 10:00:00] [INFO] Parameters: KeepVersions=1, Edition=All
[2025-11-17 10:00:00] [INFO] Scanning for PyCharm installations...
[2025-11-17 10:00:01] [INFO] Found 3 PyCharm installation(s)
[2025-11-17 10:00:01] [INFO] Processing PyCharm Community Edition: 3 version(s) found
[2025-11-17 10:00:01] [INFO]   - PyCharm Community Edition 2024.2.1 (Version: 2024.2.1)
[2025-11-17 10:00:01] [INFO]   - PyCharm Community Edition 2024.1.0 (Version: 2024.1.0)
[2025-11-17 10:00:01] [INFO]   - PyCharm Community Edition 2023.3.2 (Version: 2023.3.2)
[2025-11-17 10:00:01] [INFO] Keeping 1 version(s):
[2025-11-17 10:00:01] [SUCCESS]   ✓ PyCharm Community Edition 2024.2.1 (Version: 2024.2.1)
[2025-11-17 10:00:01] [INFO] Uninstalling 2 old version(s):
What if: Performing the operation "Uninstall" on target "PyCharm Community Edition 2024.1.0".
What if: Performing the operation "Uninstall" on target "PyCharm Community Edition 2023.3.2".
```

### Example 2: Keep Last 2 Versions

```powershell
# Keep the 2 most recent versions, remove others
.\Uninstall-OldPyCharm.ps1 -KeepVersions 2
```

### Example 3: Clean Only Community Edition

```powershell
# Only clean up Community Edition installations
.\Uninstall-OldPyCharm.ps1 -Edition Community
```

### Example 4: Clean Only Professional Edition

```powershell
# Only clean up Professional Edition installations
.\Uninstall-OldPyCharm.ps1 -Edition Professional
```

### Example 5: Custom Log Location

```powershell
# Write logs to a specific location
.\Uninstall-OldPyCharm.ps1 -LogPath "C:\Logs\IT\PyCharmCleanup.log"
```

### Example 6: Silent Mode

```powershell
# Run silently without console output (useful for scheduled tasks)
.\Uninstall-OldPyCharm.ps1 -Silent
```

**Benefits:**
- No console output cluttering scheduled task logs
- Faster execution (no console I/O overhead)
- Still creates detailed log file
- Perfect for automated/unattended scenarios

### Example 7: Combine Parameters

```powershell
# Keep 2 versions, only Community, custom log path, silent mode
.\Uninstall-OldPyCharm.ps1 -KeepVersions 2 -Edition Community -LogPath "C:\Logs\PyCharm.log" -Silent
```

## Scheduled Task Examples

### Monthly Cleanup (Recommended)

```powershell
# Create a scheduled task that runs monthly
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File C:\Scripts\Uninstall-OldPyCharm.ps1 -Silent"

$trigger = New-ScheduledTaskTrigger -Monthly -At 2AM -DaysOfMonth 1

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -RunLevel Highest -LogonType ServiceAccount

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "PyCharm Cleanup - Monthly" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Settings $settings -Description "Removes old PyCharm versions monthly"
```

### Weekly Cleanup

```powershell
# Create a scheduled task that runs weekly on Sunday
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File C:\Scripts\Uninstall-OldPyCharm.ps1 -Silent"

$trigger = New-ScheduledTaskTrigger -Weekly -At 3AM -DaysOfWeek Sunday

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -RunLevel Highest -LogonType ServiceAccount

Register-ScheduledTask -TaskName "PyCharm Cleanup - Weekly" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Removes old PyCharm versions weekly"
```

### One-Time Cleanup (For Initial Deployment)

```powershell
# Run once after a specific date/time
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -File C:\Scripts\Uninstall-OldPyCharm.ps1 -Silent"

$trigger = New-ScheduledTaskTrigger -Once -At "2025-11-20 2:00AM"

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "PyCharm Cleanup - One Time" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Initial cleanup of old PyCharm versions"
```

## GPO Deployment Example

### Create GPO for Scheduled Task

1. **Open Group Policy Management Console**
2. **Create or edit a GPO** linked to your target OU
3. Navigate to: **Computer Configuration** > **Preferences** > **Control Panel Settings** > **Scheduled Tasks**
4. Right-click > **New** > **Scheduled Task (At least Windows 7)**
5. Configure as follows:
   - **General Tab:**
     - Name: `PyCharm Version Cleanup`
     - User account: `SYSTEM`
     - Run whether user is logged on or not: **Checked**
     - Run with highest privileges: **Checked**
   - **Triggers Tab:**
     - New trigger: Daily or Weekly
     - Start time: 2:00 AM
   - **Actions Tab:**
     - Action: Start a program
     - Program: `PowerShell.exe`
     - Arguments: `-ExecutionPolicy Bypass -NoProfile -File "\\domain\netlogon\Scripts\Uninstall-OldPyCharm.ps1"`
   - **Conditions Tab:**
     - Uncheck: "Start only if computer is on AC power"
   - **Settings Tab:**
     - Allow task to be run on demand: **Checked**

## Detection Script Testing

### Test Detection Script

```powershell
# Run detection script to see if remediation is needed
.\Detect-OldPyCharm.ps1

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Host "No remediation needed"
} elseif ($LASTEXITCODE -eq 1) {
    Write-Host "Remediation required - old versions detected"
}
```

### Detection with Custom Keep Count

```powershell
# Detect if more than 2 versions exist
.\Detect-OldPyCharm.ps1 -KeepVersions 2
```

## Batch File for Administrators

Create `cleanup-pycharm.bat` for easy execution:

```batch
@echo off
echo PyCharm Version Cleanup Tool
echo ============================
echo.
echo This will remove old PyCharm versions, keeping only the latest.
echo.
pause

PowerShell.exe -ExecutionPolicy Bypass -File "%~dp0Uninstall-OldPyCharm.ps1"

echo.
echo Cleanup completed. Check PyCharmCleanup.log for details.
echo.
pause
```

## SCCM/ConfigMgr Deployment

### Create Package

1. **Create Package**
   - Source folder: Location of scripts
   - Package name: `PyCharm Cleanup Tool`

2. **Create Program**
   - Name: `Run Cleanup`
   - Command line: `PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "Uninstall-OldPyCharm.ps1"`
   - Run: Hidden
   - Program can run: Whether or not a user is logged on
   - Run mode: Run with administrative rights

3. **Distribute and Deploy**
   - Distribute content to distribution points
   - Deploy to device collection
   - Schedule: Recurring monthly

## Real-World Scenarios

### Scenario 1: Multiple Chocolatey Updates Left Behind

**Problem:** Team uses Chocolatey to update PyCharm, but old versions accumulate.

**Solution:**
```powershell
# Deploy via Intune as a remediation
# Detection: Runs daily
# Remediation: Removes old versions automatically
```

### Scenario 2: Disk Space Issues

**Problem:** Development machines running low on disk space due to multiple PyCharm installations (each ~1GB).

**Solution:**
```powershell
# One-time cleanup to free space
.\Uninstall-OldPyCharm.ps1

# Set up monthly scheduled task to prevent recurrence
```

### Scenario 3: Mixed Editions

**Problem:** Some developers have both Community and Professional editions with multiple versions.

**Solution:**
```powershell
# Clean up all editions, keeping latest of each
.\Uninstall-OldPyCharm.ps1 -Edition All -KeepVersions 1
```

### Scenario 4: Testing New Versions

**Problem:** Developers want to keep current and previous version for rollback capability.

**Solution:**
```powershell
# Keep 2 most recent versions
.\Uninstall-OldPyCharm.ps1 -KeepVersions 2
```

## Monitoring and Reporting

### Check Log File

```powershell
# View recent log entries
Get-Content .\PyCharmCleanup.log -Tail 50

# Search for errors
Get-Content .\PyCharmCleanup.log | Select-String "ERROR"

# Count successful uninstalls
(Get-Content .\PyCharmCleanup.log | Select-String "Successfully uninstalled").Count
```

### Generate Report from Intune

1. Navigate to **Devices** > **Remediations**
2. Select your PyCharm cleanup remediation
3. View **Device status** tab to see:
   - Devices that needed remediation
   - Successful remediations
   - Failed remediations

### Create Custom Report

```powershell
# Export log data to CSV for analysis
$logContent = Get-Content .\PyCharmCleanup.log
$uninstalls = $logContent | Select-String "Successfully uninstalled: (.+)" -AllMatches

$report = $uninstalls | ForEach-Object {
    [PSCustomObject]@{
        Timestamp = ($_ -split '\[')[1] -split '\]')[0]
        Application = ($_ -match "uninstalled: (.+)") ? $matches[1] : ""
    }
}

$report | Export-Csv -Path "PyCharmUninstallReport.csv" -NoTypeInformation
```

## Troubleshooting Examples

### Problem: Script Not Running in Intune

**Check:**
```powershell
# Verify script runs locally first
.\Uninstall-OldPyCharm.ps1 -WhatIf

# Check execution policy
Get-ExecutionPolicy -List

# Test with system account (requires PsExec)
PsExec.exe -s -i PowerShell.exe -ExecutionPolicy Bypass -File ".\Uninstall-OldPyCharm.ps1"
```

### Problem: Some Versions Not Detected

**Debug:**
```powershell
# Check registry manually
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName -like "*PyCharm*" } |
    Select-Object DisplayName, DisplayVersion, UninstallString
```

### Problem: Uninstall Fails

**Manual Uninstall:**
```powershell
# Get uninstall string from log
# Run manually with silent flag
& "C:\Program Files\JetBrains\PyCharm Community Edition 2023.3.2\bin\Uninstall.exe" /S
```
