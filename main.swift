import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
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
    private var alarmEnabled: Bool = false          // Alarma de finalización
    
    // Variables para el sistema de alarmas
    private var alarm10PercentTriggered: Bool = false
    private var alarm5PercentTriggered: Bool = false
    private var finalCountdownActive: Bool = false
    private var finalCountdownTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        loadSettings()
        setupMenu()
        setupStatusBar()
        updateStatusIcon()
        updateMenuStates()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopCaffeinate()
        saveSettings()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
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
        
        let displayFlag = NSMenuItem(title: "\u{2713} Prevenir suspensión de pantalla (-d)", action: #selector(toggleDisplaySleep), keyEquivalent: "")
        displayFlag.target = self
        displayFlag.toolTip = "Evita que la pantalla se apague (ideal para presentaciones)"
        menu.addItem(displayFlag)
        
        let idleFlag = NSMenuItem(title: "\u{2713} Prevenir suspensión por inactividad (-i)", action: #selector(toggleIdleSleep), keyEquivalent: "")
        idleFlag.target = self
        idleFlag.toolTip = "Evita que el sistema se suspenda por inactividad (recomendado)"
        idleFlag.state = .on
        menu.addItem(idleFlag)
        
        let diskFlag = NSMenuItem(title: "\u{2713} Prevenir suspensión de disco (-m)", action: #selector(toggleDiskSleep), keyEquivalent: "")
        diskFlag.target = self
        diskFlag.toolTip = "Evita que el disco duro se suspenda"
        menu.addItem(diskFlag)
        
        let systemFlag = NSMenuItem(title: "\u{2713} Prevenir suspensión del sistema (-s)", action: #selector(toggleSystemSleep), keyEquivalent: "")
        systemFlag.target = self
        systemFlag.toolTip = "Evita suspensión del sistema (SOLO con AC conectado - no funciona en batería)"
        menu.addItem(systemFlag)
        
        let userFlag = NSMenuItem(title: "\u{2713} Declarar usuario activo (-u)", action: #selector(toggleUserActive), keyEquivalent: "")
        userFlag.target = self
        userFlag.toolTip = "Simula actividad del usuario (útil para demos/presentaciones)"
        menu.addItem(userFlag)
        
        menu.addItem(NSMenuItem.separator())
        
        let alarmFlag = NSMenuItem(title: "\u{2713} Alarma de finalización", action: #selector(toggleAlarm), keyEquivalent: "")
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
    
    // Ahora el menú se abre siempre con cualquier click
    
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
                statusItem.button?.title = "☕️ \(minutes):\(String(format: "%02d", seconds))"
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
                isActive = false
                caffeinateProcess = nil
                self.endTime = nil
                resetAlarmStates()
                updateStatusIcon()
                stopTimer()
                stopFinalCountdown()
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
            case 12: // Alarm flag
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
    
    @objc private func quit() {
        stopCaffeinate()
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()