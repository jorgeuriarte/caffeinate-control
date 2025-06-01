#!/usr/bin/env swift

import Cocoa
import Foundation

print("🔊 Probando sonidos de alarma...")

print("\n1️⃣ Probando 'tirurí-tirurí-tirurí' (alarma 10% y 5%)...")
for i in 0..<3 {
    print("   Beep \(i*2 + 1)")
    NSSound.beep()
    Thread.sleep(forTimeInterval: 0.2)
    print("   Beep \(i*2 + 2)")
    NSSound.beep()
    Thread.sleep(forTimeInterval: 0.3)
}

print("\n2️⃣ Esperando 2 segundos...")
Thread.sleep(forTimeInterval: 2.0)

print("\n3️⃣ Probando 'pips' finales (últimos 10 segundos)...")
for i in 1...5 {
    print("   Pip \(i)")
    NSSound.beep()
    Thread.sleep(forTimeInterval: 1.0)
}

print("\n✅ Test de sonidos completado!")
print("¿Escuchaste los sonidos correctamente?")