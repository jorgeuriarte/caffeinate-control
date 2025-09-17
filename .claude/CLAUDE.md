# CaffeinateControl - Project Memory

## Project Overview
A macOS status bar application that provides visual and advanced control of the `caffeinate` command.

## Current Session
**Date**: 2025-09-17
**Branch**: main (clean)
**Last Commit**: 6f21021 - 🔧 Improve menu bar space handling

## Session Goals
*Awaiting user input for today's objectives*

## Project Status
- ✅ Core functionality implemented
- ✅ GitHub Actions CI/CD configured
- ✅ Sound alarms implemented
- ✅ Menu bar space handling improved
- ✅ Security checks passed

## Tech Stack
- Language: Swift 5.0+
- Platform: macOS 10.15+
- UI: NSStatusBar, NSMenu
- Build: Custom build.sh script

## Key Files
- `main.swift`: Core application logic
- `Info.plist`: App configuration
- `build.sh`: Build automation
- `.github/workflows/build.yml`: CI/CD pipeline

## Recent Work
Based on recent commits:
1. Improved menu bar space handling
2. Enhanced -u flag description
3. Fixed GitHub Actions permissions
4. Improved alarm sounds
5. Security checks and README cleanup
6. **NEW**: Added lid sleep prevention using `pmset disablesleep`

## Feature: Lid Sleep Prevention (2025-09-17)
- Added option to prevent Mac from sleeping when lid is closed
- Uses `pmset -a disablesleep 1/0` with admin privileges
- Implementation details:
  - NSAppleScript for privilege escalation
  - Automatic cleanup on app startup (silent check)
  - Automatic cleanup on app termination
  - User authentication required (admin password)
  - Graceful handling of user cancellation
  - Status verification after setting changes

## Notes for Future Sessions
- Application uses native macOS APIs for status bar control
- Implements caffeinate flags: -d, -i, -m, -s, -u
- Features countdown timer with visual feedback
- Sound notifications at 10%, 5%, and last 10 seconds
- Lid sleep prevention requires admin privileges via AppleScript