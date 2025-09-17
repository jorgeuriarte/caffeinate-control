# Pmset Lid Sleep Control - Scaffolding Plan

## Feature Overview
Add system sleep prevention when lid is closed using `pmset disablesleep` command, integrated with CaffeinateControl's existing architecture.

## Architecture Design

### Key Requirements
1. **Sudo Privileges**: pmset requires admin privileges
2. **Automatic Cleanup**: Reset on app termination to prevent permanent setting
3. **User Control**: Toggle option in menu
4. **State Persistence**: Remember user preference
5. **Safety**: Always reset on startup

### Implementation Strategy
Since `pmset` requires sudo privileges, we have two approaches:
1. **Helper Script Approach**: Create a helper script that handles pmset commands
2. **Authorization Services**: Use macOS Authorization Services API for privilege escalation

Given the app's current simplicity, we'll use the helper script approach with user authorization.

## Files to Modify

### 1. main.swift modifications
- [ ] Add `preventLidSleep` flag variable
- [ ] Add menu item for "Prevent lid sleep" option
- [ ] Add toggle handler for lid sleep prevention
- [ ] Integrate pmset control with caffeinate activation
- [ ] Add cleanup on termination
- [ ] Add persistence for lid sleep setting

### 2. Helper Script (new file)
- [ ] Create `pmset_helper.sh` for privilege escalation
- [ ] Add enable/disable functions
- [ ] Add status check function

## Implementation Steps

### Step 1: Add Menu Option
Location: After line 123 (user active flag)
```swift
let lidSleepFlag = NSMenuItem(title: "✓ Prevenir suspensión al cerrar tapa", action: #selector(toggleLidSleep), keyEquivalent: "")
lidSleepFlag.target = self
lidSleepFlag.toolTip = "Evita que el Mac se suspenda al cerrar la tapa (requiere contraseña de admin)"
menu.addItem(lidSleepFlag)
```

### Step 2: Add Variable Declaration
Location: After line 19 (declareUserActive)
```swift
private var preventLidSleep: Bool = false     // Control pmset disablesleep
```

### Step 3: Add Toggle Handler
Location: After toggleUserActive function (line 315)
```swift
@objc private func toggleLidSleep() {
    preventLidSleep.toggle()
    updateMenuStates()
    saveSettings()

    // Apply or remove pmset setting
    if preventLidSleep && isActive {
        enableLidSleepPrevention()
    } else {
        disableLidSleepPrevention()
    }
}
```

### Step 4: Add Pmset Control Functions
Location: After alarm functions (around line 440)
```swift
private func enableLidSleepPrevention() {
    // Request admin privileges and set pmset
    let script = "osascript -e 'do shell script \"sudo pmset -a disablesleep 1\" with administrator privileges'"
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", script]

    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("Lid sleep prevention enabled")
        }
    } catch {
        print("Failed to enable lid sleep prevention: \(error)")
    }
}

private func disableLidSleepPrevention() {
    // Request admin privileges and unset pmset
    let script = "osascript -e 'do shell script \"sudo pmset -a disablesleep 0\" with administrator privileges'"
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", script]

    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("Lid sleep prevention disabled")
        }
    } catch {
        print("Failed to disable lid sleep prevention: \(error)")
    }
}
```

### Step 5: Integration with Caffeinate Start/Stop
Modify `startCaffeinateWithDuration` (line 171):
```swift
// After line 196 (startTimer())
if preventLidSleep {
    enableLidSleepPrevention()
}
```

Modify `stopCaffeinate` (line 202):
```swift
// After line 212 (stopFinalCountdown())
if preventLidSleep {
    disableLidSleepPrevention()
}
```

### Step 6: Add Cleanup on App Launch
Modify `applicationDidFinishLaunching` (line 27):
```swift
// After line 28 (loadSettings())
// Always reset pmset on startup to ensure clean state
disableLidSleepPrevention()
```

### Step 7: Update Menu State Handler
Modify `updateMenuStates` (line 323):
Add new case for lid sleep flag

### Step 8: Update Persistence
Modify `loadSettings` and `saveSettings` to include preventLidSleep

## Testing Plan
1. Test enabling/disabling lid sleep prevention
2. Test persistence across app restarts
3. Test automatic cleanup on termination
4. Test integration with caffeinate timers
5. Test admin privilege request flow

## Documentation Updates
- Update README with new feature description
- Add warning about admin privileges requirement
- Document the automatic reset on startup behavior