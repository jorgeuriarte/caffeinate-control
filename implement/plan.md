# Implementation Plan - 2025-09-17

## Feature: Lid Sleep Prevention Warning Dialog

### Requirements Analysis
- **Source Type**: Feature enhancement request
- **Core Features**:
  - Warning dialog when toggling lid sleep prevention
  - "Don't show again" persistent option
  - Informative message about admin privileges
  - Helper script for cleanup (pmset reset)

### Implementation Strategy

#### 1. Warning Dialog System
- Create NSAlert with informative text
- Add "Don't show again" checkbox
- Store preference in UserDefaults
- Show dialog BEFORE requesting admin privileges

#### 2. Helper Script for Cleanup
- Create standalone script for pmset reset
- Can be run manually without app
- Useful for emergency cleanup
- Consider adding to /usr/local/bin for easy access

#### 3. Dialog Message
```
"Activar o desactivar el modo sleep al cerrar la tapa requiere permisos de administrador, y se te solicitarán al iniciar el tiempo de actividad"
```

### Implementation Tasks
- [x] Analyze current implementation
- [ ] Add UserDefaults key for "don't show again"
- [ ] Create showLidSleepWarning() function
- [ ] Implement NSAlert with checkbox
- [ ] Modify toggleLidSleep to check preference
- [ ] Create reset_pmset.sh helper script
- [ ] Update documentation

### Files to Modify
1. `main.swift`:
   - Add `lidSleepWarningDismissed` preference
   - Add `showLidSleepWarning()` function
   - Modify `toggleLidSleep()` to show warning
   - Update `loadSettings()` and `saveSettings()`

2. New file: `reset_pmset.sh`:
   - Standalone script to reset pmset
   - Requires sudo privileges
   - Can be distributed with app

### Risk Mitigation
- Test dialog appearance and flow
- Ensure preference persistence works
- Verify helper script functions independently
- Test cancellation scenarios

### Validation Checklist
- [ ] Dialog appears on first toggle
- [ ] "Don't show again" persists across sessions
- [ ] Dialog doesn't appear when dismissed
- [ ] Helper script resets pmset correctly
- [ ] Admin auth flow still works
- [ ] Cancellation handled gracefully