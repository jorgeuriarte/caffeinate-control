# Guía de Instalación de CaffeinateControl

## Instalación Básica

### Desde Releases (Recomendado)
1. Descarga la última versión desde [Releases](https://github.com/jorgeuriarte/caffeinate-control/releases)
2. Descomprime el archivo ZIP
3. Mueve `CaffeinateControl.app` a `/Applications/`
4. Ejecuta la aplicación

### Compilar desde código
```bash
git clone https://github.com/jorgeuriarte/caffeinate-control.git
cd caffeinate-control
./build.sh
open build/CaffeinateControl.app
```

---

## Instalación del Helper pmset (Recomendado)

Para evitar prompts de contraseña cada vez que cambias la opción "Prevenir suspensión al cerrar tapa", puedes instalar un script helper con privilegios elevados.

### ¿Qué hace?
- Una única vez, solicita tu contraseña para instalar el helper
- Después de eso, los cambios de pmset se aplican al instante sin pedir contraseña
- **Es seguro:** El script solo ejecuta un comando específico y valida los argumentos

### Cómo instalar

```bash
cd /Applications/CaffeinateControl.app/Contents/Resources
sudo /path/to/install-pmset-helper.sh
```

O si descargaste el código:

```bash
cd caffeinate-control/claude_tools
sudo ./install-pmset-helper.sh
```

El script te mostrará:
```
✅ Script exists and is owned by root
✅ SUID bit is set (will run as root)
✅ Script is executable
```

### Verificar la instalación

```bash
./verify-pmset-setup.sh
```

Debería mostrar:
```
✅ Helper script found at /usr/local/bin/caffeinatecontrol-pmset
✅ Owner is root
✅ SUID bit is set (will run as root)
✅ Script is executable
```

---

## Instalación Manual (Sin Helper)

Si prefieres no instalar el helper, la app funciona perfectamente. Simplemente:
- Cada vez que actives "Prevenir suspensión al cerrar tapa" verás un prompt de contraseña
- Esto es seguro: la app usa AppleScript para solicitar los privilegios

---

## Configuración Post-Instalación

### Opción 1: Lanzar al iniciar sesión

En **Preferencias del Sistema > General > Elementos de inicio de sesión:**
1. Click en el "+"
2. Busca `CaffeinateControl.app` en `/Applications/`
3. Click en "Añadir"

### Opción 2: Configurar con Dock

Para tener la app siempre a mano:
1. Abre `/Applications/`
2. Arrastra `CaffeinateControl.app` al Dock

---

## Permiso de Seguridad en macOS

Si macOS muestra una advertencia al iniciar:

> "CaffeinateControl" no puede abrirse porque el desarrollador no puede verificarse

**Solución:**
1. Abre **Preferencias del Sistema > Seguridad y Privacidad**
2. Click en "De todas formas abrir"

O desde Terminal:
```bash
xattr -d com.apple.quarantine /Applications/CaffeinateControl.app
```

---

## Solución de Problemas

### Problema: "La pantalla no se apaga después de usar la app"

**Solución:**
```bash
sudo ./reset-pmset-state.sh
```

Este script resetea pmset a su estado normal.

### Problema: "Sigo viendo prompts de contraseña"

**Causas posibles:**
1. El helper no está instalado → Ejecuta `sudo ./install-pmset-helper.sh`
2. El helper tiene permisos incorrectos → Ejecuta `sudo ./install-pmset-helper.sh` de nuevo

**Verifica:**
```bash
./verify-pmset-setup.sh
```

### Problema: "La app no ve la opción de prevenir suspensión al cerrar tapa"

**Causa:** Probablemente macOS restringe pmset en tu sistema.

**Solución:**
- Verifica que tienes una contraseña de administrador
- Intenta ejecutar manualmente: `sudo pmset -a disablesleep 1`
- Si esto no funciona, tu sistema tiene restricciones especiales

---

## Desinstalación

### Remover la app
```bash
rm -rf /Applications/CaffeinateControl.app
```

### Remover el helper pmset (si lo instalaste)
```bash
sudo rm /usr/local/bin/caffeinatecontrol-pmset
```

### Reset del sistema (por si acaso)
```bash
sudo pmset -a disablesleep 0
```

---

## Scripts Disponibles

Todos en la carpeta `claude_tools/`:

| Script | Propósito |
|--------|-----------|
| `install-pmset-helper.sh` | Instalar el helper con privilegios (SUID) |
| `verify-pmset-setup.sh` | Verificar que todo está correctamente configurado |
| `reset-pmset-state.sh` | Reset de emergencia si algo sale mal |

---

## Arquitectura de Seguridad

### Flujo Normal (Sin Helper)
```
CaffeinateControl App
    ↓
AppleScript (solicita contraseña via macOS)
    ↓
pmset -a disablesleep 1/0 (ejecutado como root)
```

### Flujo Optimizado (Con Helper)
```
CaffeinateControl App
    ↓
Script Helper (/usr/local/bin/caffeinatecontrol-pmset)
    ↓ (ejecuta como root via SUID bit)
pmset -a disablesleep 1/0 (sin solicitar contraseña)
```

---

## FAQ

### ¿Es seguro instalar el helper?
Sí. El helper:
- Solo acepta argumentos `0` o `1` (validación estricta)
- Solo ejecuta `/usr/bin/pmset -a disablesleep`
- Es auditable: puedes ver el código en `install-pmset-helper.sh`
- Los logs de ejecución se guardan en el system log

### ¿Puedo instalar el helper después?
Sí, en cualquier momento. Ejecuta simplemente:
```bash
sudo /path/to/install-pmset-helper.sh
```

### ¿Necesito instalar el helper?
No. La app funciona perfectamente sin él. El helper solo es una comodidad para evitar prompts de contraseña.

### ¿Qué pasa si desinstalo el helper?
La app vuelve a usar AppleScript automáticamente. Sin cambios necesarios en la app.

---

## Soporte

Si tienes problemas:
1. Ejecuta `./verify-pmset-setup.sh` para diagnosticar
2. Revisa los logs: `log show --predicate 'process == "CaffeinateControl"'`
3. Abre un issue en GitHub: https://github.com/jorgeuriarte/caffeinate-control/issues
