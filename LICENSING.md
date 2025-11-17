# Intune License Requirements for PyCharm Cleanup

This document outlines which device targeting and deployment options are available based on your Intune and Azure AD license tier.

## Feature Availability by License

### Microsoft Intune Plan 1 (Basic/Minimal)

**Available:**
- ✅ **Discovered Apps** (Option 1) - View installed applications
- ✅ **PowerShell Scripts** - Deploy scripts to devices
- ✅ **Assignment Filters** - Filter deployments
- ✅ **Static Device Groups** - Manually managed groups

**NOT Available:**
- ❌ **Remediations** (Proactive Remediations) - Requires Plan 2 or Windows E3/E5
- ❌ **Custom Compliance Policies** (Option 4) - Requires Plan 2

### Microsoft Intune Plan 2 (Advanced)

**Includes everything from Plan 1, plus:**
- ✅ **Remediations** (Proactive Remediations)
- ✅ **Custom Compliance Policies**
- ✅ **Endpoint Analytics**

### Azure AD Licenses

**Azure AD Free (Included with Microsoft 365)**
- ✅ Static groups only
- ❌ Dynamic groups require Azure AD Premium P1

**Azure AD Premium P1**
- ✅ Dynamic device groups (Option 3)
- ✅ Group-based assignment

**Azure AD Premium P2**
- ✅ All P1 features
- ✅ Advanced identity protection

## Recommended Approaches by License Tier

### Minimal License (Intune Plan 1 + Azure AD Free)

**Best Option: Use PowerShell Scripts with Discovered Apps**

Since you don't have Remediations, use the alternative deployment method:

**Step 1: Create Static Group from Discovered Apps**

1. Go to **Apps** > **Monitor** > **Discovered apps**
2. Search for "PyCharm"
3. View devices with PyCharm installed
4. Export list (for reference - cannot be directly imported)
5. Create static group: **Groups** > **New group**
   - Name: `Devices - PyCharm Installed`
   - Type: Security
   - Membership: Assigned (static)
   - Manually add devices by searching for them
   - Or use PowerShell automation (see EXAMPLES.md)

**Step 2: Deploy as PowerShell Script**

1. Go to **Devices** > **Scripts** > **Add** > **Windows 10 and later**
2. Upload `Uninstall-OldPyCharm.ps1`
3. Configure:
   - Run using logged-on credentials: **No**
   - Run in 64-bit PowerShell: **Yes**
4. Assign to: `Devices - PyCharm Installed` group
5. Schedule: Run once, or configure as needed

**Step 3: Periodic Maintenance**

- Re-export from Discovered Apps monthly
- Update the static group with new devices
- Or switch to "All Devices" if you prefer (runs on all, but only uninstalls on devices with multiple PyCharm versions)

**Alternative: Assign to All Devices**

Deploy the PowerShell script to **All Devices**:
- Script checks for PyCharm installations
- Only uninstalls if multiple versions found
- Self-contained logic in the script
- No remediation features needed

**Pros:**
- Works with basic licensing
- Uses built-in features only
- Still leverages Discovered Apps

**Cons:**
- Requires manual group updates
- No automatic detection/remediation
- One-time execution (unless you create scheduled task)

### Standard License (Intune Plan 2 + Azure AD Free)

**Best Option: Use Remediations with Static Groups**

1. **Create Remediation Package**
   - Detection: `Detect-OldPyCharm.ps1`
   - Remediation: `Uninstall-OldPyCharm.ps1`

2. **Target with Discovered Apps**
   - Use static group from Discovered Apps (Option 1)
   - Or assign to All Devices (Option 2)

3. **Schedule**
   - Daily or weekly checks
   - Automatic remediation

**Pros:**
- Automatic detection and remediation
- Scheduled execution
- Better than PowerShell scripts approach

**Cons:**
- Still requires static groups (no dynamic groups)

### Premium License (Intune Plan 2 + Azure AD Premium P1)

**Best Option: Full Dynamic Groups**

Use any of the options:
- **Option 1**: Discovered Apps with static group
- **Option 2**: Assign to All Devices (recommended)
- **Option 3**: Dynamic groups by department/naming
- **Option 4**: Dynamic groups via compliance policy

**Recommended: Option 2** (All Devices)
- Simplest to set up
- Self-maintaining
- No group management needed

## Detailed Deployment Instructions

### For Minimal License (No Remediations)

#### Method 1: PowerShell Script with Static Group

**Create Detection/Uninstall Combined Script**

Since you don't have Remediations, combine detection and action in one script:

```powershell
# PyCharm-Cleanup-Combined.ps1
# Run this via Intune PowerShell Scripts

# Check if multiple PyCharm versions exist
$installations = @()
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $registryPaths) {
    $items = Get-ItemProperty $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "PyCharm*" }
    $installations += $items
}

if ($installations.Count -le 1) {
    Write-Output "Only one or no PyCharm installation found. No action needed."
    exit 0
}

# Multiple versions found - call the cleanup script
Write-Output "Multiple PyCharm versions detected. Running cleanup..."
& "$PSScriptRoot\Uninstall-OldPyCharm.ps1" -Silent
exit $LASTEXITCODE
```

Deploy this script instead of using Remediations.

#### Method 2: Use Scheduled Task

Deploy the cleanup script with a scheduled task:

1. Use Intune PowerShell Scripts to create scheduled task
2. Task runs `Uninstall-OldPyCharm.ps1` monthly
3. Set to run as SYSTEM

See `EXAMPLES.md` for scheduled task examples.

### For Standard License (With Remediations, No Dynamic Groups)

Use the standard Remediation approach (Option 1 or 2 from README.md), but:
- Use **static groups** from Discovered Apps
- Update groups periodically
- Or use **All Devices** for automatic coverage

### For Premium License (Full Features)

Use any option from README.md - all features available.

## Feature Comparison Table

| Feature | Intune Plan 1 | Intune Plan 2 | Requires Azure AD P1 |
|---------|---------------|---------------|---------------------|
| PowerShell Scripts | ✅ | ✅ | - |
| Discovered Apps | ✅ | ✅ | - |
| Static Groups | ✅ | ✅ | - |
| Assignment Filters | ✅ | ✅ | - |
| Remediations | ❌ | ✅ | - |
| Custom Compliance | ❌ | ✅ | - |
| Dynamic Groups | - | - | ✅ |

## Cost Optimization Tips

### If You Have Minimal Licensing:

1. **Use Assignment Filters** instead of multiple groups
   - Create filter based on OS version, device properties
   - Single group, multiple filters

2. **Leverage Discovered Apps**
   - Free inventory of all installed apps
   - Export and create groups as needed

3. **Use PowerShell Scripts**
   - More manual but included in base license
   - Can achieve same results with more effort

4. **Deploy Scheduled Tasks**
   - One-time script deployment creates ongoing automation
   - No recurring execution costs

5. **Combine with Group Policy** (if hybrid)
   - Use GPO for on-prem domain-joined devices
   - Reserve Intune for cloud-only devices

## Recommendations by Organization Size

### Small Organization (< 100 devices)
- **License**: Intune Plan 1 sufficient
- **Approach**: PowerShell Scripts with static group
- **Update**: Manually update group quarterly

### Medium Organization (100-1000 devices)
- **License**: Consider Intune Plan 2 for Remediations
- **Approach**: Remediations with "All Devices" assignment
- **Maintenance**: Automatic, no manual updates

### Large Enterprise (> 1000 devices)
- **License**: Intune Plan 2 + Azure AD Premium P1
- **Approach**: Option 4 (Compliance-based dynamic groups)
- **Benefit**: Fully automated, integrates with compliance reporting

## Quick Decision Tree

```
Do you have Microsoft Intune Plan 2 or Windows E3/E5?
├─ YES → Use Remediations (Option 2 - All Devices)
│         Simplest, fully automated
│
└─ NO → Do you have Azure AD Premium P1?
    ├─ YES → Use PowerShell Scripts + Dynamic Groups (Option 3)
    │         Some automation, dynamic targeting
    │
    └─ NO → Use PowerShell Scripts + Static Groups (Option 1)
              Manual but functional with basic licensing
```

## Upgrading Licensing

If you find limitations with basic licensing:

1. **Intune Plan 2** adds:
   - Remediations (worth it for automation)
   - Custom compliance policies
   - ~$6/user/month additional

2. **Azure AD Premium P1** adds:
   - Dynamic groups (worth it for large orgs)
   - Conditional access
   - ~$6/user/month

3. **Microsoft 365 E3** includes:
   - Intune Plan 2
   - Azure AD Premium P1
   - Office apps, Windows 10/11 Enterprise
   - Most cost-effective for full suite

## Getting Help

If unsure about your current licensing:
1. Check **Microsoft 365 admin center** > **Billing** > **Licenses**
2. Look for:
   - "Microsoft Intune Plan 1" or "Plan 2"
   - "Azure Active Directory Premium P1" or "P2"
   - Or bundled licenses (E3, E5, etc.)
3. Contact Microsoft licensing support for clarification
