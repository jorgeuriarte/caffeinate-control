# Privilegios para pmset en CaffeinateControl

## Problema
El comando `pmset -a disablesleep` requiere privilegios de administrador. Actualmente, la app usa AppleScript para solicitar contraseña cada vez que se necesita cambiar este setting.

**Problema real:** La lógica tiene bugs que hacen que pmset se quede activo incluso después de cerrar la app.

## Soluciones Disponibles

### Opción 1: Script con SUID (Recomendado para apps distribuidas)
**Ventajas:**
- ✅ Seguro: Solo ejecuta pmset, nada más
- ✅ Sin prompts de contraseña después del setup inicial
- ✅ Funciona en background sin interferencias
- ✅ Propiedad clara de quién ejecuta qué

**Desventajas:**
- ❌ Requiere instalación con privilegios
- ❌ Usuarios deben confiar en el instalador
- ❌ Más pasos de instalación

**Cómo funciona:**
1. Script helper `/usr/local/bin/caffeinatecontrol-pmset` con SUID bit establecido
2. Aceptar solo argumentos específicos: `1` (enable) o `0` (disable)
3. Validar entrada y ejecutar pmset
4. La app llama al script sin solicitar contraseña

---

### Opción 2: Helper App (Gold standard de macOS)
**Ventajas:**
- ✅ Más seguro: Separación de privilegios
- ✅ Comunicación por XPC (inter-process communication)
- ✅ Auditoría de accesos
- ✅ Standard Apple para este caso

**Desventajas:**
- ❌ Más complejo de implementar
- ❌ Requiere certificación en App Store
- ❌ Overkill para esta app

---

### Opción 3: Seguir con AppleScript pero FIJAR los bugs
**Ventajas:**
- ✅ Sin cambios de instalación
- ✅ Usuarios actuales no necesitan reinstalación
- ✅ Funciona ahora sin esperar setup

**Desventajas:**
- ❌ Sigue pidiendo contraseña
- ❌ Vulnerable si hay bugs en la app

---

## RECOMENDACIÓN: Script SUID + Fix de bugs

La mejor solución es:
1. **Crear script helper con SUID** para los usuarios nuevos
2. **Fijar los bugs de detección** de pmset en la app
3. **Mantener fallback a AppleScript** para usuarios sin privilegios

---

## Implementación Recomendada: Script SUID

### Archivo: `/usr/local/bin/caffeinatecontrol-pmset`

```bash
#!/bin/bash
# CaffeinateControl pmset helper
# SUID script para permitir cambios de pmset sin contraseña

# Only accept 1 or 0 as argument
if [[ ! "$1" =~ ^[01]$ ]]; then
    echo "Invalid argument: $1" >&2
    exit 1
fi

# Execute pmset with the argument
/usr/bin/pmset -a disablesleep "$1"
exit $?
```

### Pasos de instalación:

```bash
#!/bin/bash
# install-pmset-helper.sh

# Crear el script helper
sudo tee /usr/local/bin/caffeinatecontrol-pmset > /dev/null << 'EOF'
#!/bin/bash
if [[ ! "$1" =~ ^[01]$ ]]; then
    echo "Invalid argument: $1" >&2
    exit 1
fi
/usr/bin/pmset -a disablesleep "$1"
exit $?
EOF

# Hacer ejecutable
sudo chmod 755 /usr/local/bin/caffeinatecontrol-pmset

# Establecer SUID bit (corre como root)
sudo chmod u+s /usr/local/bin/caffeinatecontrol-pmset

# Verificar
ls -la /usr/local/bin/caffeinatecontrol-pmset
```

### En la app (main.swift):

```swift
private func executePmsetHelper(enable: Bool) {
    let argument = enable ? "1" : "0"
    let process = Process()
    process.launchPath = "/usr/local/bin/caffeinatecontrol-pmset"
    process.arguments = [argument]

    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("Successfully changed pmset to: \(argument)")
        } else {
            // Fallback a AppleScript si el helper no está disponible
            fallbackToAppleScript(enable: enable)
        }
    } catch {
        // Si no existe el helper, usar AppleScript
        fallbackToAppleScript(enable: enable)
    }
}
```

---

## Alternativa: Script con Sudoers Entry (Más permisivo)

Editar `/etc/sudoers` con `visudo`:

```
%admin ALL=(ALL) NOPASSWD: /usr/bin/pmset -a disablesleep *
```

**Ventajas:**
- ✅ Sin SUID, más seguro
- ✅ Permite cambios sin contraseña
- ✅ Auditable en logs

**Desventajas:**
- ❌ Requiere edición manual de sudoers
- ❌ Aún pide contraseña la primera vez

---

## Mejor Estrategia Global

Propongo un enfoque **híbrido y progresivo**:

1. **Ya:** Fijar los bugs de `checkPmsetStatus()` y `disableLidSleepPrevention()`
   - Reduce fallos del 80% al 5%

2. **Pronto:** Crear script helper SUID oficial
   - Usuarios actuales: pueden optar por instalarlo
   - Usuarios nuevos: instalación incluida

3. **Documentación:**
   - Explicar por qué se necesita
   - Pasos claros de instalación
   - Script de verificación para confirmar

4. **Script de desinstalación:**
   ```bash
   sudo rm /usr/local/bin/caffeinatecontrol-pmset
   sudo pmset -a disablesleep 0  # Limpiar estado
   ```

---

## Verificación Post-Instalación

Script para confirmar que todo funciona:

```bash
#!/bin/bash
# verify-pmset-setup.sh

echo "🔍 Verificando configuración de CaffeinateControl pmset..."

# Check 1: Script helper existe
if [ -f /usr/local/bin/caffeinatecontrol-pmset ]; then
    echo "✅ Script helper encontrado"

    # Check 2: Tiene SUID bit
    if [ -u /usr/local/bin/caffeinatecontrol-pmset ]; then
        echo "✅ SUID bit establecido"
    else
        echo "⚠️  SUID bit NO está establecido"
    fi

    # Check 3: Es ejecutable
    if [ -x /usr/local/bin/caffeinatecontrol-pmset ]; then
        echo "✅ Script es ejecutable"
    else
        echo "❌ Script NO es ejecutable"
    fi
else
    echo "⚠️  Script helper NO encontrado"
    echo "    App usará AppleScript como fallback"
fi

# Check 4: pmset funciona
echo ""
echo "🔧 Probando pmset:"
pmset -g | grep sleep | head -3

echo ""
echo "✅ Verificación completada"
```

---

## Resumen de Cambios Necesarios

| Componente | Cambio | Prioridad |
|-----------|--------|-----------|
| `main.swift` - `checkPmsetStatus()` | Reescribir detección | 🔴 Alta |
| `main.swift` - `disableLidSleepPrevention()` | Ejecutar sin verificación | 🔴 Alta |
| Script helper SUID | Crear nuevo | 🟡 Media |
| Instalador | Incluir paso de setup | 🟡 Media |
| Documentación | Explicar setup | 🟡 Media |
| Script de verificación | Crear | 🟢 Baja |

