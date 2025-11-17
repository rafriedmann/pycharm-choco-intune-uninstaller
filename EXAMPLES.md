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
   - Assign to device groups with PyCharm installations

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
