#!/usr/bin/env swift

import Cocoa
import Foundation

print("🔊 Probando sonidos alternativos...")

print("\n1️⃣ Probando con sonido 'Ping' del sistema...")
if let sound = NSSound(named: "Ping") {
    for i in 0..<3 {
        print("   Ping \(i*2 + 1)")
        sound.play()
        Thread.sleep(forTimeInterval: 0.3)
        print("   Ping \(i*2 + 2)")
        sound.play()
        Thread.sleep(forTimeInterval: 0.4)
    }
} else {
    print("   ❌ Sonido 'Ping' no disponible")
}

print("\n2️⃣ Esperando 2 segundos...")
Thread.sleep(forTimeInterval: 2.0)

print("\n3️⃣ Probando con sonido 'Pop'...")
if let sound = NSSound(named: "Pop") {
    for i in 1...5 {
        print("   Pop \(i)")
        sound.play()
        Thread.sleep(forTimeInterval: 1.0)
    }
} else {
    print("   ❌ Sonido 'Pop' no disponible")
}

print("\n4️⃣ Probando sonidos disponibles en el sistema...")
let systemSounds = ["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]

for soundName in systemSounds {
    if let sound = NSSound(named: soundName) {
        print("   ✅ \(soundName) disponible")
    }
}

print("\n✅ Test completado!")
print("¿Escuchaste algún sonido esta vez?")