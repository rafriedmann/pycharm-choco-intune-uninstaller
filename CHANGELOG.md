# Changelog

All notable changes to the PyCharm Chocolatey Uninstaller project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-17

### Initial Release

Complete PyCharm cleanup solution for Microsoft Intune deployments.

### Added

#### Core Scripts
- **Uninstall-OldPyCharm.ps1**: Main remediation script that removes old PyCharm versions
  - Automatic detection of all installed PyCharm editions (Community and Professional)
  - Version parsing and comparison to identify oldest versions
  - Silent uninstallation of old versions
  - Cleanup of leftover installation folders after uninstall
  - Silent mode (`-Silent`) for automated deployments
  - WhatIf mode for safe testing
  - Comprehensive logging
  - Support for keeping multiple recent versions (`-KeepVersions`)
  - Edition-specific targeting (`-Edition`)

- **Detect-OldPyCharm.ps1**: Detection script for Intune Remediations
  - Fast registry-only scanning
  - Early exit optimization (0.1-0.3s on devices without PyCharm)
  - Returns exit codes for Intune remediation workflow

- **Set-PyCharmMarker.ps1**: Optional inventory script for advanced scenarios
  - Sets custom registry markers for device categorization
  - Useful for custom compliance policies
  - Stores metadata about installed editions and versions

#### Documentation
- **README.md**: Comprehensive main documentation
  - Usage examples and parameter reference
  - Multiple deployment options (Remediations, PowerShell Scripts, Scheduled Tasks)
  - Four device targeting strategies with pros/cons
  - License tier requirements (Plan 1 vs Plan 2)
  - Performance optimization notes
  - Troubleshooting guide

- **EXAMPLES.md**: Detailed deployment scenarios
  - Step-by-step Intune Remediation setup
  - PowerShell Script deployment for minimal licensing
  - Discovered Apps targeting with automation scripts
  - Dynamic group setup via compliance policies
  - Assignment filters configuration
  - Scheduled task deployment via GPO/Intune
  - Microsoft Graph PowerShell automation for bulk operations

- **LICENSING.md**: License tier requirements and deployment options
  - Feature availability matrix by license tier
  - Deployment instructions for Intune Plan 1 (basic license)
  - Recommended approaches by organization size
  - Decision tree for choosing deployment method
  - Cost optimization tips

- **PERFORMANCE.md**: Performance characteristics and impact analysis
  - Execution time breakdowns by scenario
  - Resource usage (CPU, memory, disk, network)
  - Impact analysis for 100-10,000+ device deployments
  - Early exit optimization documentation
  - Scaling characteristics
  - Best practices for minimal impact
  - Comparison with alternative solutions
  - Monitoring and troubleshooting performance issues

#### Additional Files
- **.gitignore**: Standard exclusions for PowerShell projects
- **LICENSE**: MIT License for open source distribution

### Features

#### Automatic Detection and Cleanup
- Scans both HKLM and HKCU registry locations
- Identifies all PyCharm installations (Community and Professional)
- Parses version numbers from display names
- Groups installations by edition
- Keeps specified number of most recent versions
- Uninstalls older versions silently

#### Leftover Folder Cleanup
- Automatically removes installation directories after uninstall
- Checks registry InstallLocation path
- Scans common JetBrains installation directories
- Handles folders left behind by uninstaller
- 2-second delay to handle file locks

#### Performance Optimization
- Early exit for devices without PyCharm (0.1-0.3 seconds)
- Registry-only scanning during detection
- No filesystem scans during detection phase
- Zero network traffic
- Minimal CPU and memory usage
- Linear scaling for large environments

#### Intune Integration
- Native support for Intune Remediations (Plan 2)
- PowerShell Scripts deployment option (Plan 1)
- Compatible with Discovered Apps feature
- Support for static and dynamic groups
- Assignment filter support
- Compliance policy integration

#### Deployment Flexibility
- Four targeting options documented
  1. Discovered Apps with static groups
  2. All Devices assignment (recommended)
  3. Dynamic groups by department/naming
  4. Compliance-based dynamic groups
- Works with minimal licensing (Intune Plan 1)
- Supports both System and User context
- Scheduled execution support

#### Logging and Reporting
- Detailed log files with timestamps
- Success/failure tracking
- Version information logging
- Folder cleanup logging
- Silent mode maintains file logging
- Intune remediation reports integration

### Technical Details

#### Requirements
- Windows operating system
- PowerShell 5.1 or later
- Administrator privileges
- Microsoft Intune (Plan 1 or Plan 2)

#### Exit Codes
- `0`: Success or no action needed
- `1`: Error occurred or remediation needed (context-dependent)

#### Performance Metrics
- Detection on devices WITHOUT PyCharm: 0.1-0.3 seconds
- Detection on devices WITH single PyCharm: 0.2-0.5 seconds
- Full cleanup per old version: 20-40 seconds
- 1000-device deployment impact: Negligible for 99.5% of devices

### License Requirements
- **Intune Plan 1**: PowerShell Scripts, Discovered Apps, Static Groups
- **Intune Plan 2**: Remediations, Custom Compliance Policies
- **Azure AD Premium P1**: Dynamic Groups
- **Microsoft 365 E3**: Includes Intune Plan 2 + Azure AD Premium P1

### Migration Notes

This is the initial release. No migration needed.

### Known Limitations

1. **Discovered Apps Export**: CSV export is for reference only and cannot be directly imported into groups. Use PowerShell automation scripts or manual device addition.

2. **Tag Pushing**: Git tag v1.0.0 created locally but may require manual push depending on repository permissions.

3. **Portable Installations**: Script detects only standard installer-based PyCharm installations. Portable versions or custom installations may not be detected.

4. **Corrupted Uninstallers**: Some PyCharm versions with corrupted uninstallers may fail to uninstall. Manual removal may be required.

### Upgrade Path

No upgrades from previous versions - this is the initial release.

Future versions will document upgrade procedures here.

---

## Release Notes

### What's New in v1.0.0

This is the first stable release of the PyCharm Chocolatey Uninstaller for Microsoft Intune. It provides a complete solution for managing PyCharm installations across your organization.

#### Key Highlights

✅ **Automatic Cleanup**: Detects and removes old PyCharm versions automatically
✅ **Performance Optimized**: 0.1-0.3s overhead on devices without PyCharm
✅ **Minimal Licensing**: Works with Intune Plan 1 (basic license)
✅ **Comprehensive Documentation**: Four deployment strategies with step-by-step guides
✅ **Folder Cleanup**: Removes leftover installation directories
✅ **Silent Mode**: Perfect for automated deployments
✅ **Multiple Targeting Options**: From simple "All Devices" to advanced compliance-based groups

#### Recommended Deployment

For most organizations, we recommend:
- **License**: Intune Plan 2 (if available)
- **Method**: Remediations
- **Targeting**: All Devices (Option 2)
- **Schedule**: Weekly checks

This provides automatic detection and remediation with minimal maintenance.

#### Getting Started

1. Review **README.md** for overview and basic usage
2. Check **LICENSING.md** to confirm your license tier
3. Follow **EXAMPLES.md** for your specific deployment scenario
4. Review **PERFORMANCE.md** for impact analysis

#### Support

- Issues: Report on GitHub repository
- License: MIT License - Free to use and modify
- Documentation: Comprehensive guides included

---

[1.0.0]: https://github.com/rafriedmann/pycharm-choco-intune-uninstaller/releases/tag/v1.0.0
