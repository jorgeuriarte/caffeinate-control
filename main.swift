import Cocoa
import AVFoundation
import os.log

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var caffeinateProcess: Process?
    private var isActive: Bool = false
    private var timer: Timer?
    private var endTime: Date?
    private var selectedDuration: TimeInterval = 3600
    
    // Flags de caffeinate
    private var preventDisplaySleep: Bool = false  // -d
    private var preventIdleSleep: Bool = true      // -i (por defecto)
    private var preventDiskSleep: Bool = false     // -m
    private var preventSystemSleep: Bool = false   // -s
    private var declareUserActive: Bool = false    // -u
    private var preventLidSleep: Bool = false       // User PREFERENCE for lid sleep prevention
    private var lidSleepPreventionActive: Bool = false  // ACTUAL current state of pmset disablesleep
    private var lidSleepWarningDismissed: Bool = false  // Don't show lid sleep warning again
    private var alarmEnabled: Bool = false          // Alarma de finalización
    
    // Variables para el sistema de alarmas
    private var alarm10PercentTriggered: Bool = false
    private var alarm5PercentTriggered: Bool = false
    private var finalCountdownActive: Bool = false
    private var finalCountdownTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        loadSettings()

        // Check actual pmset status on startup
        let pmsetIsActive = checkPmsetStatus()
        lidSleepPreventionActive = pmsetIsActive

        if pmsetIsActive {
            // pmset is active from a previous session - try to reset it
            print("Found pmset disablesleep enabled on startup, will attempt to reset")
            disableLidSleepPreventionSilently()
        }
        // Note: We don't clear preventLidSleep here - it's the user's preference
        // for what should happen when they START caffeinate next time

        setupMenu()
        setupStatusBar()
        updateStatusIcon()
        updateMenuStates()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopCaffeinate()
        // Ensure pmset is reset on termination (only if actually active)
        if lidSleepPreventionActive {
            disableLidSleepPrevention()
        }
        saveSettings()
    }
    
    private func setupStatusBar() {
        // Usar longitud variable pero con límite compacto
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu
        
        // Configurar el comportamiento del statusItem
        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        }
        
        // Verificar visibilidad después de un pequeño delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkVisibility()
        }
    }
    
    private func checkVisibility() {
        // Si el botón no tiene frame válido, probablemente no hay espacio
        if let button = statusItem.button, button.frame.width == 0 {
            showNoSpaceAlert()
        }
    }
    
    private func showNoSpaceAlert() {
        let alert = NSAlert()
        alert.messageText = "CaffeinateControl está ejecutándose"
        alert.informativeText = "La barra de estado está llena. Puedes:\n\n• Cerrar otras apps de la barra\n• Mantener presionado ⌘ y arrastrar iconos fuera\n• La app sigue funcionando aunque no veas el icono"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func setupMenu() {
        menu = NSMenu()
        menu.delegate = self  // For menuWillOpen to sync pmset state

        // Opciones de duración
        let duration15m = NSMenuItem(title: "Activar 15 minutos", action: #selector(start15Minutes), keyEquivalent: "")
        duration15m.target = self
        menu.addItem(duration15m)
        
        let duration30m = NSMenuItem(title: "Activar 30 minutos", action: #selector(start30Minutes), keyEquivalent: "")
        duration30m.target = self
        menu.addItem(duration30m)
        
        let duration1h = NSMenuItem(title: "Activar 1 hora", action: #selector(start1Hour), keyEquivalent: "")
        duration1h.target = self
        menu.addItem(duration1h)
        
        let duration2h = NSMenuItem(title: "Activar 2 horas", action: #selector(start2Hours), keyEquivalent: "")
        duration2h.target = self
        menu.addItem(duration2h)
        
        menu.addItem(NSMenuItem.separator())
        
        // Sección de configuración de flags
        let configTitle = NSMenuItem(title: "Configuración:", action: nil, keyEquivalent: "")
        configTitle.isEnabled = false
        menu.addItem(configTitle)
        
        let displayFlag = NSMenuItem(title: "Prevenir suspensión de pantalla (-d)", action: #selector(toggleDisplaySleep), keyEquivalent: "")
        displayFlag.target = self
        displayFlag.toolTip = "Evita que la pantalla se apague (ideal para presentaciones)"
        menu.addItem(displayFlag)

        let idleFlag = NSMenuItem(title: "Prevenir suspensión por inactividad (-i)", action: #selector(toggleIdleSleep), keyEquivalent: "")
        idleFlag.target = self
        idleFlag.toolTip = "Evita que el sistema se suspenda por inactividad (recomendado)"
        idleFlag.state = .on
        menu.addItem(idleFlag)

        let diskFlag = NSMenuItem(title: "Prevenir suspensión de disco (-m)", action: #selector(toggleDiskSleep), keyEquivalent: "")
        diskFlag.target = self
        diskFlag.toolTip = "Evita que el disco duro se suspenda"
        menu.addItem(diskFlag)

        let systemFlag = NSMenuItem(title: "Prevenir suspensión del sistema (-s)", action: #selector(toggleSystemSleep), keyEquivalent: "")
        systemFlag.target = self
        systemFlag.toolTip = "Evita suspensión del sistema (SOLO con AC conectado - no funciona en batería)"
        menu.addItem(systemFlag)

        let userFlag = NSMenuItem(title: "Declarar usuario activo (-u)", action: #selector(toggleUserActive), keyEquivalent: "")
        userFlag.target = self
        userFlag.toolTip = "Simula actividad del usuario (útil para demos/presentaciones)"
        menu.addItem(userFlag)

        let lidSleepFlag = NSMenuItem(title: "Prevenir suspensión al cerrar tapa", action: #selector(toggleLidSleep), keyEquivalent: "")
        lidSleepFlag.target = self
        lidSleepFlag.toolTip = "Evita que el Mac se suspenda al cerrar la tapa (requiere contraseña de admin)"
        menu.addItem(lidSleepFlag)

        menu.addItem(NSMenuItem.separator())
        
        let alarmFlag = NSMenuItem(title: "Alarma de finalización", action: #selector(toggleAlarm), keyEquivalent: "")
        alarmFlag.target = self
        alarmFlag.toolTip = "Suena al 10%, 5% y últimos 10 segundos del tiempo restante"
        menu.addItem(alarmFlag)
        
        menu.addItem(NSMenuItem.separator())
        
        let stopItem = NSMenuItem(title: "Parar Caffeinate", action: #selector(stopCaffeinate), keyEquivalent: "")
        stopItem.target = self
        menu.addItem(stopItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Salir", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        // Sync the actual pmset state before showing menu
        // This ensures the checkbox reflects reality
        let actualPmsetState = checkPmsetStatus()
        if actualPmsetState != lidSleepPreventionActive {
            print("DEBUG menuWillOpen: Syncing pmset state. Was \(lidSleepPreventionActive), actual is \(actualPmsetState)")
            lidSleepPreventionActive = actualPmsetState
        }
        updateMenuStates()
    }

    // MARK: - Duration Actions

    @objc private func start15Minutes() {
        selectedDuration = 15 * 60
        startCaffeinateWithDuration(selectedDuration)
        saveSettings()
    }
    
    @objc private func start30Minutes() {
        selectedDuration = 30 * 60
        startCaffeinateWithDuration(selectedDuration)
        saveSettings()
    }
    
    @objc private func start1Hour() {
        selectedDuration = 60 * 60
        startCaffeinateWithDuration(selectedDuration)
        saveSettings()
    }
    
    @objc private func start2Hours() {
        selectedDuration = 2 * 60 * 60
        startCaffeinateWithDuration(selectedDuration)
        saveSettings()
    }
    
    private func startCaffeinateWithDuration(_ duration: TimeInterval) {
        // Si ya está activo, primero lo paramos
        if isActive {
            stopCaffeinate()
        }
        
        selectedDuration = duration
        caffeinateProcess = Process()
        caffeinateProcess!.launchPath = "/usr/bin/caffeinate"
        var arguments = ["-t", "\(Int(duration))"]
        
        if preventDisplaySleep { arguments.append("-d") }
        if preventIdleSleep { arguments.append("-i") }
        if preventDiskSleep { arguments.append("-m") }
        if preventSystemSleep { arguments.append("-s") }
        if declareUserActive { arguments.append("-u") }
        
        caffeinateProcess!.arguments = arguments
        
        do {
            try caffeinateProcess!.run()
            isActive = true
            endTime = Date().addingTimeInterval(duration)
            resetAlarmStates()
            updateStatusIcon()
            startTimer()

            // Enable lid sleep prevention if configured
            if preventLidSleep {
                enableLidSleepPrevention()
            }
        } catch {
            print("Error starting caffeinate: \(error)")
        }
    }
    
    @objc private func stopCaffeinate() {
        guard isActive else { return }

        caffeinateProcess?.terminate()
        caffeinateProcess = nil
        isActive = false
        endTime = nil
        resetAlarmStates()
        updateStatusIcon()
        stopTimer()
        stopFinalCountdown()

        // Disable lid sleep prevention when stopping caffeinate
        // Use lidSleepPreventionActive (actual state) not preventLidSleep (preference)
        if lidSleepPreventionActive {
            disableLidSleepPrevention()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusIcon()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateStatusIcon() {
        if isActive {
            if let endTime = endTime {
                let remaining = endTime.timeIntervalSinceNow
                let minutes = Int(remaining) / 60
                let seconds = Int(remaining) % 60
                // Formato más compacto: solo mostrar minutos si es menos de 10
                if minutes < 10 {
                    statusItem.button?.title = "☕\(minutes):\(String(format: "%02d", seconds))"
                } else {
                    statusItem.button?.title = "☕\(minutes)m"
                }
            } else {
                statusItem.button?.title = "☕️"
            }
        } else {
            // Crear versión "desactivada" de la taza de café
            statusItem.button?.title = ""
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.tertiaryLabelColor
            ]
            let attributedTitle = NSAttributedString(string: "☕️", attributes: attributes)
            statusItem.button?.attributedTitle = attributedTitle
        }
        updateTooltip()
    }
    
    private func updateTooltip() {
        if isActive, let endTime = endTime {
            let remaining = endTime.timeIntervalSinceNow
            if remaining > 0 {
                // Verificar alarmas si están habilitadas
                if alarmEnabled {
                    checkAlarms(remaining: remaining, totalDuration: selectedDuration)
                }
                
                let hours = Int(remaining) / 3600
                let minutes = Int(remaining.truncatingRemainder(dividingBy: 3600)) / 60
                let seconds = Int(remaining) % 60
                
                var timeString = ""
                if hours > 0 {
                    timeString = "\(hours)h \(minutes)m \(seconds)s"
                } else {
                    timeString = "\(minutes)m \(seconds)s"
                }
                statusItem.button?.toolTip = "Caffeinate activo - \(timeString) restante"
            } else {
                // Timer expired naturally - clean up everything
                isActive = false
                caffeinateProcess = nil
                self.endTime = nil
                resetAlarmStates()
                updateStatusIcon()
                stopTimer()
                stopFinalCountdown()

                // CRITICAL: Disable lid sleep prevention when timer expires
                if lidSleepPreventionActive {
                    disableLidSleepPrevention()
                }
            }
        } else {
            statusItem.button?.toolTip = "Caffeinate inactivo - Click para activar (1h por defecto)"
        }
    }
    
    @objc private func toggleDisplaySleep() {
        preventDisplaySleep.toggle()
        updateMenuStates()
        saveSettings()
    }
    
    @objc private func toggleIdleSleep() {
        preventIdleSleep.toggle()
        updateMenuStates()
        saveSettings()
    }
    
    @objc private func toggleDiskSleep() {
        preventDiskSleep.toggle()
        updateMenuStates()
        saveSettings()
    }
    
    @objc private func toggleSystemSleep() {
        preventSystemSleep.toggle()
        updateMenuStates()
        saveSettings()
    }
    
    @objc private func toggleUserActive() {
        declareUserActive.toggle()
        updateMenuStates()
        saveSettings()
    }

    @objc private func toggleLidSleep() {
        // Show warning dialog if not dismissed before
        if !lidSleepWarningDismissed && !preventLidSleep {
            // Show warning only when enabling (not when disabling)
            if !showLidSleepWarning() {
                // User cancelled, don't toggle
                return
            }
        }

        preventLidSleep.toggle()
        updateMenuStates()
        saveSettings()

        // Apply or remove pmset setting immediately if caffeinate is active
        if isActive {
            if preventLidSleep {
                enableLidSleepPrevention()
            } else {
                disableLidSleepPrevention()
            }
        }
    }
    
    @objc private func toggleAlarm() {
        alarmEnabled.toggle()
        updateMenuStates()
        saveSettings()
    }
    
    private func updateMenuStates() {
        let menuItems = menu.items

        for (index, item) in menuItems.enumerated() {
            switch index {
            case 6: // Display sleep flag
                item.state = preventDisplaySleep ? .on : .off
            case 7: // Idle sleep flag
                item.state = preventIdleSleep ? .on : .off
            case 8: // Disk sleep flag
                item.state = preventDiskSleep ? .on : .off
            case 9: // System sleep flag
                item.state = preventSystemSleep ? .on : .off
            case 10: // User active flag
                item.state = declareUserActive ? .on : .off
            case 11: // Lid sleep flag - show ACTUAL state, not just preference
                // When caffeinate is active: show real pmset state
                // When inactive: show user preference (what will be activated next time)
                if isActive {
                    item.state = lidSleepPreventionActive ? .on : .off
                    // Add visual indicator if pmset is actually active
                    if lidSleepPreventionActive {
                        item.title = "Prevenir suspensión al cerrar tapa (ACTIVO)"
                    } else if preventLidSleep {
                        item.title = "Prevenir suspensión al cerrar tapa (pendiente)"
                    } else {
                        item.title = "Prevenir suspensión al cerrar tapa"
                    }
                } else {
                    item.state = preventLidSleep ? .on : .off
                    // Show if pmset is still active (shouldn't be, but just in case)
                    if lidSleepPreventionActive {
                        item.title = "Prevenir suspensión al cerrar tapa (⚠️ activo)"
                    } else {
                        item.title = "Prevenir suspensión al cerrar tapa"
                    }
                }
            case 13: // Alarm flag
                item.state = alarmEnabled ? .on : .off
            default:
                break
            }
        }
    }
    
    // MARK: - Persistencia de Configuración
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        preventDisplaySleep = defaults.bool(forKey: "preventDisplaySleep")
        preventIdleSleep = defaults.object(forKey: "preventIdleSleep") as? Bool ?? true // Por defecto true
        preventDiskSleep = defaults.bool(forKey: "preventDiskSleep")
        preventSystemSleep = defaults.bool(forKey: "preventSystemSleep")
        declareUserActive = defaults.bool(forKey: "declareUserActive")
        preventLidSleep = defaults.bool(forKey: "preventLidSleep")
        lidSleepWarningDismissed = defaults.bool(forKey: "lidSleepWarningDismissed")
        alarmEnabled = defaults.bool(forKey: "alarmEnabled")
        selectedDuration = defaults.double(forKey: "selectedDuration")
        if selectedDuration == 0 { selectedDuration = 3600 } // Por defecto 1 hora
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(preventDisplaySleep, forKey: "preventDisplaySleep")
        defaults.set(preventIdleSleep, forKey: "preventIdleSleep")
        defaults.set(preventDiskSleep, forKey: "preventDiskSleep")
        defaults.set(preventSystemSleep, forKey: "preventSystemSleep")
        defaults.set(declareUserActive, forKey: "declareUserActive")
        defaults.set(preventLidSleep, forKey: "preventLidSleep")
        defaults.set(lidSleepWarningDismissed, forKey: "lidSleepWarningDismissed")
        defaults.set(alarmEnabled, forKey: "alarmEnabled")
        defaults.set(selectedDuration, forKey: "selectedDuration")
    }
    
    // MARK: - Sistema de Alarmas
    
    private func resetAlarmStates() {
        alarm10PercentTriggered = false
        alarm5PercentTriggered = false
        finalCountdownActive = false
        stopFinalCountdown()
    }
    
    private func checkAlarms(remaining: TimeInterval, totalDuration: TimeInterval) {
        let percentageRemaining = (remaining / totalDuration) * 100
        
        // Alarma del 10%
        if percentageRemaining <= 10 && !alarm10PercentTriggered {
            alarm10PercentTriggered = true
            playAlarmSound()
        }
        
        // Alarma del 5%
        if percentageRemaining <= 5 && !alarm5PercentTriggered {
            alarm5PercentTriggered = true
            playAlarmSound()
        }
        
        // Últimos 10 segundos
        if remaining <= 10 && !finalCountdownActive {
            finalCountdownActive = true
            startFinalCountdown()
        }
    }
    
    private func playAlarmSound() {
        // Reproducir "tirurí-tirurí-tirurí" con sonido del sistema
        DispatchQueue.global(qos: .background).async {
            if let sound = NSSound(named: "Ping") {
                for _ in 0..<3 {
                    sound.play()
                    Thread.sleep(forTimeInterval: 0.2)
                    sound.play()
                    Thread.sleep(forTimeInterval: 0.3)
                }
            }
        }
    }
    
    private func playPipSound() {
        // Usar sonido más suave para los pips finales
        if let sound = NSSound(named: "Pop") {
            sound.play()
        }
    }
    
    private func startFinalCountdown() {
        finalCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let endTime = self.endTime else { return }
            
            let remaining = endTime.timeIntervalSinceNow
            if remaining <= 10 && remaining > 0 {
                self.playPipSound()
            } else {
                self.stopFinalCountdown()
            }
        }
    }
    
    private func stopFinalCountdown() {
        finalCountdownTimer?.invalidate()
        finalCountdownTimer = nil
    }

    // MARK: - Pmset Control for Lid Sleep Prevention

    private func showLidSleepWarning() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Prevención de suspensión al cerrar tapa"
        alert.informativeText = "Activar o desactivar el modo sleep al cerrar la tapa requiere permisos de administrador, y se te solicitarán al iniciar el tiempo de actividad.\n\nNota: La configuración se resetea automáticamente al reiniciar la aplicación por seguridad."
        alert.alertStyle = .informational

        // Add buttons
        alert.addButton(withTitle: "Continuar")
        alert.addButton(withTitle: "Cancelar")

        // Create "Don't show again" checkbox
        let checkbox = NSButton(checkboxWithTitle: "No mostrar nunca más", target: nil, action: nil)
        checkbox.state = .off
        alert.accessoryView = checkbox

        // Show alert and get response
        let response = alert.runModal()

        // Save checkbox state if user continued
        if response == .alertFirstButtonReturn {
            if checkbox.state == .on {
                lidSleepWarningDismissed = true
                saveSettings()
            }
            return true
        }

        return false
    }

    private func checkPmsetStatus() -> Bool {
        // Check pmset -g to determine if disablesleep is active
        // When disablesleep 1 is set, the "sleep" value becomes 0

        let process = Process()
        process.launchPath = "/usr/bin/pmset"
        process.arguments = ["-g"]

        let pipe = Pipe()
        process.standardOutput = pipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)

                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                    // Use regex to match exactly "sleep" followed by whitespace and a number
                    // This avoids matching "displaysleep", "disksleep", "sleepimage", etc.
                    // Pattern: starts with "sleep" then whitespace(s) then a number
                    if let range = trimmedLine.range(of: "^sleep\\s+", options: .regularExpression) {
                        let afterSleep = trimmedLine[range.upperBound...]
                        let valueStr = afterSleep.trimmingCharacters(in: .whitespaces)
                            .components(separatedBy: .whitespaces).first ?? ""

                        print("DEBUG checkPmsetStatus: Found 'sleep' line, value='\(valueStr)'")

                        if valueStr == "0" {
                            print("DEBUG checkPmsetStatus: sleep=0, disablesleep is ACTIVE")
                            return true
                        } else {
                            print("DEBUG checkPmsetStatus: sleep=\(valueStr), disablesleep is NOT active")
                            return false
                        }
                    }
                }

                print("DEBUG checkPmsetStatus: No 'sleep' line found in pmset output")
            }
        } catch {
            print("Failed to check pmset status: \(error)")
        }

        // If we can't read pmset or find the sleep value, assume disabled (safe default)
        return false
    }

    private func enableLidSleepPrevention() {
        // First check if already enabled (to avoid unnecessary prompts)
        if checkPmsetStatus() {
            print("Lid sleep prevention already enabled")
            os_log("Lid sleep prevention already enabled", log: OSLog.default, type: .info)
            lidSleepPreventionActive = true
            updateMenuStates()
            return
        }

        print("Attempting to enable lid sleep prevention...")
        os_log("Attempting to enable lid sleep prevention", log: OSLog.default, type: .info)

        // First, try using the helper script if it exists
        let helperPath = "/usr/local/bin/caffeinatecontrol-pmset"
        print("Checking if helper exists at: \(helperPath)")

        if FileManager.default.fileExists(atPath: helperPath) {
            print("Helper found, attempting to use it...")
            os_log("Helper found at %{public}@, attempting to use it", log: OSLog.default, type: .debug, helperPath)

            let process = Process()
            process.launchPath = helperPath
            process.arguments = ["1"]

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    print("Lid sleep prevention enabled successfully via helper")
                    os_log("Lid sleep prevention enabled successfully via helper", log: OSLog.default, type: .info)
                    // Verify the change took effect
                    Thread.sleep(forTimeInterval: 0.5)
                    lidSleepPreventionActive = checkPmsetStatus()
                    if lidSleepPreventionActive {
                        print("Verified: pmset disablesleep is now active")
                    } else {
                        print("Warning: pmset command succeeded but verification failed")
                        lidSleepPreventionActive = true  // Trust the exit code
                    }
                    updateMenuStates()
                    return
                } else {
                    print("Helper script failed (status: \(process.terminationStatus)), falling back to AppleScript")
                    os_log("Helper script failed with status %d, falling back to AppleScript", log: OSLog.default, type: .error, process.terminationStatus)
                }
            } catch {
                print("Could not execute helper script, falling back to AppleScript: \(error)")
                os_log("Could not execute helper script: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        } else {
            print("Helper NOT found at \(helperPath), will use AppleScript")
            os_log("Helper NOT found at %{public}@, will use AppleScript", log: OSLog.default, type: .debug, helperPath)
        }

        // Fallback to AppleScript if helper is not available
        let appleScript = """
            do shell script "pmset -a disablesleep 1" with administrator privileges
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            _ = scriptObject.executeAndReturnError(&error)

            if let error = error {
                let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                let errorNumber = error["NSAppleScriptErrorNumber"] as? Int ?? -1

                // Error -128 means user cancelled
                if errorNumber == -128 {
                    print("User cancelled admin authentication for lid sleep prevention")
                    // Reset the toggle since user cancelled
                    preventLidSleep = false
                    lidSleepPreventionActive = false
                    updateMenuStates()
                    saveSettings()
                } else {
                    print("Failed to enable lid sleep prevention: \(errorMessage)")
                    showPmsetError(message: "No se pudo activar la prevención de suspensión al cerrar la tapa",
                                   details: errorMessage)
                    // Reset the toggle on error
                    preventLidSleep = false
                    lidSleepPreventionActive = false
                    updateMenuStates()
                    saveSettings()
                }
            } else {
                print("Lid sleep prevention enabled successfully via AppleScript")
                // Verify the change took effect
                Thread.sleep(forTimeInterval: 0.5)
                lidSleepPreventionActive = checkPmsetStatus()
                if lidSleepPreventionActive {
                    print("Verified: pmset disablesleep is now active")
                } else {
                    print("Warning: AppleScript succeeded but verification failed")
                    lidSleepPreventionActive = true  // Trust the AppleScript result
                }
                updateMenuStates()
            }
        }
    }

    private func disableLidSleepPrevention() {
        // IMPORTANT: Don't verify before disabling!
        // If checkPmsetStatus() fails to detect that it's active, we would skip the disable
        // Always attempt to disable, even if we think it's already disabled
        // The pmset command is idempotent - running "disablesleep 0" when it's already 0 is harmless

        print("Attempting to disable lid sleep prevention...")

        // First, try using the helper script if it exists
        let helperPath = "/usr/local/bin/caffeinatecontrol-pmset"
        if FileManager.default.fileExists(atPath: helperPath) {
            let process = Process()
            process.launchPath = helperPath
            process.arguments = ["0"]

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    print("Lid sleep prevention disabled successfully via helper")
                    lidSleepPreventionActive = false
                    updateMenuStates()
                    return
                } else {
                    print("Helper script failed (status: \(process.terminationStatus)), falling back to AppleScript")
                }
            } catch {
                print("Could not execute helper script, falling back to AppleScript: \(error)")
            }
        }

        // Fallback to AppleScript if helper is not available
        let appleScript = """
            do shell script "pmset -a disablesleep 0" with administrator privileges
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            _ = scriptObject.executeAndReturnError(&error)

            if let error = error {
                let errorNumber = error["NSAppleScriptErrorNumber"] as? Int ?? -1

                // Error -128 means user cancelled, which is ok for disable
                if errorNumber == -128 {
                    print("User cancelled admin authentication for disabling lid sleep prevention")
                    // User cancelled - pmset is still active, keep state as-is
                    // Don't show error for cancellation on disable
                } else {
                    let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                    print("Failed to disable lid sleep prevention: \(errorMessage)")
                    // We don't show error dialog on disable failures to avoid annoying the user
                    // But pmset might still be active
                }
            } else {
                print("Lid sleep prevention disabled successfully via AppleScript")
                lidSleepPreventionActive = false
                updateMenuStates()
            }
        }
    }

    private func disableLidSleepPreventionSilently() {
        // Silent version that doesn't show auth dialog - used on startup cleanup
        // Try helper first, then direct pmset (which requires root)

        // First, try using the helper script if it exists (has setuid bit)
        let helperPath = "/usr/local/bin/caffeinatecontrol-pmset"
        if FileManager.default.fileExists(atPath: helperPath) {
            let process = Process()
            process.launchPath = helperPath
            process.arguments = ["0"]

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    print("Successfully reset pmset disablesleep on startup via helper")
                    lidSleepPreventionActive = false
                    // Don't change preventLidSleep - that's the user preference
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.updateMenuStates()
                    }
                    return
                }
            } catch {
                print("Helper script not available: \(error)")
            }
        }

        // Fallback: try direct pmset (will fail without root, but worth trying)
        let process = Process()
        process.launchPath = "/usr/bin/pmset"
        process.arguments = ["-a", "disablesleep", "0"]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                print("Successfully reset pmset disablesleep on startup")
                lidSleepPreventionActive = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.updateMenuStates()
                }
            } else {
                print("Note: Cannot reset pmset without admin privileges")
                // pmset is still in whatever state it was - check actual status
                lidSleepPreventionActive = checkPmsetStatus()
                if lidSleepPreventionActive {
                    print("Warning: pmset disablesleep is still active from previous session")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.updateMenuStates()
                }
            }
        } catch {
            print("Note: Cannot reset pmset on startup: \(error)")
            // Check actual status
            lidSleepPreventionActive = checkPmsetStatus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.updateMenuStates()
            }
        }
    }

    private func showPmsetError(message: String, details: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = """
            Error: \(details)

            Nota: Esta función requiere privilegios de administrador.
            Si continúa teniendo problemas, puede ejecutar manualmente en Terminal:

            Para activar: sudo pmset -a disablesleep 1
            Para desactivar: sudo pmset -a disablesleep 0
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func quit() {
        stopCaffeinate()
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()