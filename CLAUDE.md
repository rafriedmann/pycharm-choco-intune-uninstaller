# Claude Code Reference Guide

This guide helps Claude Code instances quickly understand and work with the PyCharm Chocolatey Intune Uninstaller project.

## Project Overview

**Purpose**: PowerShell tool to automatically uninstall old PyCharm versions on Windows devices managed by Microsoft Intune.

**Problem Solved**: When PyCharm is installed/updated via Chocolatey, old versions often accumulate on systems. This tool detects all PyCharm installations, keeps the latest version(s), and removes older ones.

**Language**: PowerShell 5.1+  
**Platform**: Windows  
**Deployment**: Microsoft Intune (Remediations or PowerShell Scripts)  
**License**: MIT

## Common Commands

### Testing Scripts Locally

```powershell
# Dry run - see what would be uninstalled without doing it
.\Uninstall-OldPyCharm.ps1 -WhatIf

# Run detection script to check if remediation is needed
.\Detect-OldPyCharm.ps1
# Exit code 0 = no remediation needed
# Exit code 1 = remediation required (multiple versions found)

# Uninstall old versions (requires Administrator)
.\Uninstall-OldPyCharm.ps1

# Keep 2 most recent versions
.\Uninstall-OldPyCharm.ps1 -KeepVersions 2

# Target specific edition
.\Uninstall-OldPyCharm.ps1 -Edition Community
.\Uninstall-OldPyCharm.ps1 -Edition Professional

# Silent mode (for automated deployments)
.\Uninstall-OldPyCharm.ps1 -Silent

# Custom log location
.\Uninstall-OldPyCharm.ps1 -LogPath "C:\Logs\PyCharmCleanup.log"
```

### Git Operations

```bash
# Check status
git status

# View recent commits
git log --oneline -10

# View branches
git branch -a

# Current branch is: claude/pycharm-chocolatey-uninstall-01J4UkAYAycpWqrv6uG63nNc
# This is both the current and main branch
```

### Documentation Commands

```bash
# View main documentation
cat README.md

# View deployment examples
cat EXAMPLES.md

# Check licensing requirements
cat LICENSING.md

# Review performance characteristics
cat PERFORMANCE.md

# See version history
cat CHANGELOG.md
```

### File Analysis

```bash
# List all project files
ls -la

# Find all PowerShell scripts
ls *.ps1

# Check for log files
ls *.log

# View gitignore
cat .gitignore
```

## Project Architecture

### File Structure

```
pycharm-choco-intune-uninstaller/
├── Core Scripts (PowerShell)
│   ├── Uninstall-OldPyCharm.ps1    # Main remediation script (338 lines)
│   ├── Detect-OldPyCharm.ps1       # Detection script for Intune (125 lines)
│   └── Set-PyCharmMarker.ps1       # Optional inventory script (117 lines)
│
├── Documentation (Markdown)
│   ├── README.md                    # Main documentation (333 lines)
│   ├── EXAMPLES.md                  # Deployment scenarios (649 lines)
│   ├── LICENSING.md                 # License tier requirements (292 lines)
│   ├── PERFORMANCE.md               # Performance analysis (259 lines)
│   ├── CHANGELOG.md                 # Version history (216 lines)
│   └── CLAUDE.md                    # This file
│
├── Configuration
│   ├── .gitignore                   # Git exclusions
│   └── LICENSE                      # MIT License
│
└── .git/                            # Git repository
```

### Architecture Overview

This is a **deployment automation tool** for Microsoft Intune, not a traditional software application. There's no build process, no dependencies to install, and no compilation required.

#### Three-Script Architecture

1. **Detect-OldPyCharm.ps1** (Detection)
   - Entry point for Intune Remediations
   - Fast registry-only scanning (0.1-0.3 seconds)
   - Returns exit codes: 0 (compliant) or 1 (needs remediation)
   - Early exit optimization for devices without PyCharm

2. **Uninstall-OldPyCharm.ps1** (Remediation)
   - Main logic for cleanup
   - Scans registry for PyCharm installations
   - Groups by edition (Community/Professional)
   - Sorts by version, keeps latest N versions
   - Silently uninstalls old versions
   - Cleans up leftover installation folders
   - Comprehensive logging

3. **Set-PyCharmMarker.ps1** (Optional Inventory)
   - Advanced scenario only
   - Sets registry markers for compliance policies
   - Not required for basic deployments

#### Key Design Patterns

**Registry-Based Detection**
```powershell
# All scripts scan these registry paths:
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
```

**Version Parsing**
```powershell
# Extracts version from display name like "PyCharm Community Edition 2024.2.1"
function Get-VersionFromDisplayName {
    param([string]$DisplayName)
    if ($DisplayName -match '(\d{4}\.\d+(?:\.\d+)?)') {
        return [version]$matches[1]
    }
    return $null
}
```

**Early Exit Optimization**
```powershell
# Exits immediately if no PyCharm found (minimal overhead)
if ($installations.Count -eq 0) {
    exit 0
}
```

**Edition Grouping**
```powershell
# Groups installations by edition, processes separately
$groupedInstalls = $installations | Group-Object -Property Edition
foreach ($group in $groupedInstalls) {
    # Keep latest N versions per edition
    $toKeep = $editionInstalls | Select-Object -First $KeepVersions
    $toUninstall = $editionInstalls | Select-Object -Skip $KeepVersions
}
```

**Silent Uninstallation**
```powershell
# Parses uninstall string and adds /S flag
if ($uninstallString -match '^"?(.+?\.exe)"?\s*(.*)$') {
    $exePath = $matches[1]
    $arguments = $matches[2]
    if ($arguments -notmatch '/S') {
        $arguments += " /S"
    }
    Start-Process -FilePath $exePath -ArgumentList $arguments -Wait
}
```

**Folder Cleanup**
```powershell
# Removes leftover installation directories
# 1. Checks InstallLocation from registry
# 2. Scans common JetBrains paths
# 3. Removes matching folders
Remove-LeftoverFolders -Installation $installation
```

### Data Flow

```
Intune Remediation Workflow:
┌─────────────────────────────────────────────────────────────┐
│ 1. Intune schedules remediation check                       │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Detect-OldPyCharm.ps1 runs                               │
│    - Scans registry for PyCharm installations               │
│    - Counts versions per edition                            │
│    - Exit 0 if ≤ KeepVersions                               │
│    - Exit 1 if > KeepVersions (triggers remediation)        │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. If exit code = 1, Uninstall-OldPyCharm.ps1 runs         │
│    - Scans registry again                                   │
│    - Groups by edition                                      │
│    - Sorts by version (newest first)                        │
│    - Keeps top N versions                                   │
│    - Uninstalls older versions                              │
│    - Cleans up leftover folders                             │
│    - Logs all operations                                    │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Intune reports remediation status                        │
│    - Success/failure                                        │
│    - Log output                                             │
│    - Timestamp                                              │
└─────────────────────────────────────────────────────────────┘
```

### Deployment Models

The project supports **4 deployment strategies**:

1. **Option 1: Discovered Apps + Static Groups**
   - Uses Intune's built-in app inventory
   - Create static group from discovered devices
   - Manual group maintenance required

2. **Option 2: All Devices** (Recommended)
   - Assign to all devices
   - Detection script handles targeting
   - Zero configuration, self-maintaining

3. **Option 3: Dynamic Groups by Department/Naming**
   - Requires Azure AD Premium P1
   - Based on device naming conventions
   - Automatically includes matching devices

4. **Option 4: Compliance-Based Dynamic Groups**
   - Requires Intune Plan 2 + Azure AD Premium P1
   - Uses compliance policy to detect PyCharm
   - Dynamic group based on compliance status
   - Fully automated, most complex setup

### Performance Characteristics

**Critical Performance Features:**
- **Early Exit**: 0.1-0.3s on devices without PyCharm
- **Registry-Only Detection**: No filesystem scans
- **Zero Network Traffic**: All operations local
- **Linear Scaling**: Handles 10,000+ devices efficiently

**Execution Times:**
- Devices without PyCharm: 0.1-0.3 seconds
- Devices with single PyCharm: 0.2-0.5 seconds
- Full cleanup per version: 20-40 seconds

**Resource Usage:**
- CPU: <1% during detection, moderate during uninstall
- Memory: 20-50 MB script overhead, 100-200 MB peak
- Disk I/O: Minimal during detection, moderate during uninstall
- Network: Zero

## Development Workflow

### This Project Has NO Traditional Build Process

**Important**: This is a deployment tool, not a software application:
- No compilation required
- No dependencies to install
- No build scripts
- No testing framework (manual testing only)
- No CI/CD pipeline

### Making Changes

```bash
# 1. Edit PowerShell scripts directly
vim Uninstall-OldPyCharm.ps1

# 2. Test locally (requires Windows + Administrator)
.\Uninstall-OldPyCharm.ps1 -WhatIf

# 3. Update documentation if behavior changes
vim README.md

# 4. Commit changes
git add .
git commit -m "Description of changes"

# 5. Push to repository
git push origin claude/pycharm-chocolatey-uninstall-01J4UkAYAycpWqrv6uG63nNc
```

### Testing Checklist

Since there are no automated tests, manual testing is required:

**Local Testing:**
- [ ] Run `.\Detect-OldPyCharm.ps1` on test system
- [ ] Run `.\Uninstall-OldPyCharm.ps1 -WhatIf` to preview
- [ ] Run `.\Uninstall-OldPyCharm.ps1` to verify actual cleanup
- [ ] Check log file for errors
- [ ] Verify old versions removed, latest kept
- [ ] Verify leftover folders cleaned up

**Intune Testing:**
- [ ] Upload to Intune Remediations (test environment)
- [ ] Assign to pilot group (5-10 devices)
- [ ] Monitor remediation reports
- [ ] Check device logs
- [ ] Verify no performance issues

### Version Numbering

**Current Version**: 1.0.0 (from CHANGELOG.md)

**Semantic Versioning:**
- MAJOR: Breaking changes to script parameters or behavior
- MINOR: New features (e.g., new parameters, additional cleanup)
- PATCH: Bug fixes, documentation updates

**Release Process:**
1. Update CHANGELOG.md with new version section
2. Update version references in documentation
3. Test thoroughly
4. Commit changes
5. Create git tag: `git tag -a v1.x.x -m "Version 1.x.x"`
6. Push tag: `git push origin v1.x.x`

## Key Concepts and Context

### Microsoft Intune Integration

**Intune Remediations** (requires Intune Plan 2):
- Detection script runs on schedule (daily/weekly)
- If detection returns exit code 1, remediation runs
- Reports success/failure to Intune portal
- Logs available in device reports

**PowerShell Scripts** (works with Intune Plan 1):
- Runs once when assigned
- No automatic detection/remediation
- Can be scheduled via task scheduler
- Alternative for basic licensing

### License Requirements

**Minimum**: Intune Plan 1 + Azure AD Free
- Can deploy via PowerShell Scripts
- Static groups only
- Manual targeting

**Recommended**: Intune Plan 2 + Azure AD Premium P1
- Remediations feature
- Dynamic groups
- Compliance policies
- Full automation

### Windows Registry Structure

PyCharm installers create registry entries at:
```
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\
HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
```

Each entry contains:
- DisplayName: "PyCharm Community Edition 2024.2.1"
- DisplayVersion: Version number
- UninstallString: Path to uninstaller.exe
- InstallLocation: Installation directory
- Publisher: "JetBrains s.r.o."

### Logging Strategy

All scripts use consistent logging:
```powershell
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console (unless Silent mode)
    if (-not $Silent) { Write-Host $logMessage }
    
    # Always log to file
    Add-Content -Path $LogPath -Value $logMessage
}
```

**Log Levels:**
- INFO: General information
- SUCCESS: Successful operations
- WARNING: Non-fatal issues
- ERROR: Fatal errors

**Default Log Location**: `.\PyCharmCleanup.log` (same directory as script)

## Common Tasks

### Add New Parameter

1. Add to param block:
```powershell
[Parameter(Mandatory=$false)]
[string]$NewParameter = "DefaultValue"
```

2. Update documentation in script header
3. Update README.md parameter table
4. Update EXAMPLES.md with usage examples
5. Test all parameter combinations

### Modify Version Detection Logic

Edit `Get-VersionFromDisplayName` function in both scripts:
```powershell
function Get-VersionFromDisplayName {
    param([string]$DisplayName)
    # Modify regex pattern here
    if ($DisplayName -match '(\d{4}\.\d+(?:\.\d+)?)') {
        return [version]$matches[1]
    }
    return $null
}
```

### Add Support for Another JetBrains IDE

1. Update display name matching:
```powershell
Where-Object { 
    $_.DisplayName -like "PyCharm*" -or 
    $_.DisplayName -like "IntelliJ*"
}
```

2. Update edition detection logic
3. Update folder cleanup paths
4. Update documentation
5. Consider renaming project for broader scope

### Update Documentation

**Rule of Thumb**: If you change script behavior, update:
1. Script header comments (Synopsis, Description, Examples)
2. README.md (if affects usage)
3. EXAMPLES.md (if new use cases)
4. LICENSING.md (if changes license requirements)
5. PERFORMANCE.md (if affects performance)
6. CHANGELOG.md (always add changes)

### Debug Issues

```powershell
# Enable verbose logging
$VerbosePreference = "Continue"
.\Uninstall-OldPyCharm.ps1 -Verbose

# Check what's in registry
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName -like "*PyCharm*" } |
    Select-Object DisplayName, DisplayVersion, UninstallString, InstallLocation

# Test detection separately
.\Detect-OldPyCharm.ps1
Write-Host "Exit code: $LASTEXITCODE"

# Run with WhatIf to see what would happen
.\Uninstall-OldPyCharm.ps1 -WhatIf

# Check log file
Get-Content .\PyCharmCleanup.log -Tail 50
```

## Important Considerations

### Security

- **Requires Administrator**: All scripts require elevation
- **Validates Permissions**: Checks admin rights before proceeding
- **Silent Uninstall**: Uses /S flag to avoid user prompts
- **No Credential Storage**: No passwords or secrets in scripts
- **Local Only**: No network communication, no telemetry

### Error Handling

- **Try/Catch Blocks**: All major operations wrapped
- **Graceful Degradation**: Continues on non-fatal errors
- **Detailed Logging**: All errors logged to file
- **Exit Codes**: Consistent 0 (success) / 1 (error)

### Compatibility

- **PowerShell Version**: Requires 5.1+ (standard on Windows 10/11)
- **Windows Version**: Works on Windows 10, Windows 11, Server 2016+
- **Intune Version**: Any version (uses standard features)
- **PyCharm Versions**: Detects all versions with standard installer

### Known Limitations

1. **Portable Installations**: Only detects registry-based installations
2. **Corrupted Uninstallers**: May fail if uninstaller is broken
3. **File Locks**: May fail if PyCharm is running
4. **Discovered Apps Export**: CSV cannot be directly imported (manual or PowerShell required)

## Quick Reference

### File Purposes

| File | Purpose | When to Edit |
|------|---------|--------------|
| Uninstall-OldPyCharm.ps1 | Main cleanup logic | Changing cleanup behavior |
| Detect-OldPyCharm.ps1 | Detection for Intune | Changing detection logic |
| Set-PyCharmMarker.ps1 | Optional inventory | Advanced scenarios only |
| README.md | Main documentation | Usage or features change |
| EXAMPLES.md | Deployment guides | New deployment scenarios |
| LICENSING.md | License requirements | Intune licensing changes |
| PERFORMANCE.md | Performance docs | Performance characteristics change |
| CHANGELOG.md | Version history | Every release |
| CLAUDE.md | This file | Architecture or workflow changes |

### Exit Codes

| Script | Exit 0 | Exit 1 |
|--------|--------|--------|
| Detect-OldPyCharm.ps1 | No remediation needed | Remediation required |
| Uninstall-OldPyCharm.ps1 | Success | Error occurred |
| Set-PyCharmMarker.ps1 | Success | Error occurred |

### Key Functions

**Uninstall-OldPyCharm.ps1:**
- `Write-Log`: Logging to console and file
- `Get-VersionFromDisplayName`: Parse version from display name
- `Get-PyCharmInstallations`: Scan registry for PyCharm
- `Remove-LeftoverFolders`: Clean up installation directories
- `Uninstall-PyCharm`: Execute silent uninstall

**Detect-OldPyCharm.ps1:**
- `Get-VersionFromDisplayName`: Same as above
- `Get-PyCharmInstallations`: Simplified version

**Set-PyCharmMarker.ps1:**
- No functions, linear script flow

### Documentation Cross-References

- **New Users**: Start with README.md
- **Deployment**: See EXAMPLES.md for step-by-step guides
- **License Questions**: Check LICENSING.md for tier requirements
- **Performance Concerns**: Review PERFORMANCE.md for impact analysis
- **Version History**: See CHANGELOG.md for what's changed
- **Development**: This file (CLAUDE.md) for architecture

## Repository Information

**Current Branch**: `claude/pycharm-chocolatey-uninstall-01J4UkAYAycpWqrv6uG63nNc` (also main branch)

**Recent Activity:**
- v1.0.0 released with comprehensive documentation
- Performance optimization documentation added
- Licensing guide for minimal Intune licenses
- Compliance-based dynamic group documentation
- Automatic folder cleanup feature

**No CI/CD**: Manual deployment to Intune required

**No Issue Tracker**: Track issues in repository if available

---

**Last Updated**: 2025-11-18  
**Project Version**: 1.0.0  
**For Questions**: Review documentation files or repository
