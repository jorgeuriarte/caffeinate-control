# CaffeinateControl

<p align="center">
  <img src="https://img.shields.io/badge/macOS-10.15%2B-blue?style=flat-square&logo=apple" alt="macOS Support" />
  <img src="https://img.shields.io/badge/Swift-5.0%2B-orange?style=flat-square&logo=swift" alt="Swift Version" />
  <img src="https://img.shields.io/github/license/jorgeuriarte/caffeinate-control?style=flat-square" alt="License" />
  <img src="https://img.shields.io/github/v/release/jorgeuriarte/caffeinate-control?style=flat-square" alt="Release" />
</p>

Una aplicación de barra de estado para macOS que proporciona control visual y avanzado del comando `caffeinate`.

## ✨ Características

- **🎯 Control Visual**: Icono en barra de estado con contador en tiempo real
- **⏰ Múltiples Duraciones**: 15min, 30min, 1h, 2h
- **🔧 Flags Configurables**: Control granular de suspensión (pantalla, sistema, disco, etc.)
- **🔔 Alarmas**: Notificaciones sonoras al 10%, 5% y últimos 10 segundos
- **💾 Persistencia**: Recuerda tu configuración entre sesiones
- **🌙 Modo Oscuro**: Se adapta automáticamente al tema del sistema
- **💻 Prevención de Suspensión con Tapa Cerrada**: Evita que el Mac se suspenda al cerrar la tapa (usando `pmset disablesleep`)

## 🚀 Instalación Rápida

### Desde Releases (Recomendado)
1. Descarga la última versión desde [Releases](https://github.com/jorgeuriarte/caffeinate-control/releases)
2. Descomprime y mueve `CaffeinateControl.app` a `/Applications/`
3. Ejecuta la aplicación
4. (Opcional) Instala el helper pmset para evitar prompts de contraseña (ver [INSTALLATION.md](INSTALLATION.md))

### Compilar desde código
```bash
git clone https://github.com/jorgeuriarte/caffeinate-control.git
cd caffeinate-control
./build.sh
open build/CaffeinateControl.app
```

**Ver [INSTALLATION.md](INSTALLATION.md) para instrucciones detalladas y configuración post-instalación.**

## 📖 Uso

### ⚠️ Nota Importante sobre Prevención de Suspensión con Tapa Cerrada
- Esta función utiliza `pmset disablesleep` que requiere privilegios de administrador
- Al activarla por primera vez, verás un diálogo informativo (con opción "No mostrar nunca más")
- Se te pedirá tu contraseña de administrador cuando actives esta opción
- La configuración se **resetea automáticamente** al iniciar la app para evitar dejar el sistema permanentemente sin suspensión
- La configuración también se desactiva automáticamente cuando detienes Caffeinate o cierras la aplicación

#### Optimizar con Helper pmset (Recomendado)
Para **evitar prompts de contraseña** cada vez que cambias esta opción:

```bash
cd /Applications/CaffeinateControl.app/Contents/Resources
sudo ./install-pmset-helper.sh
```

Esto instala un script helper con privilegios elevados que permite cambios instantáneos sin solicitar contraseña. Ver [INSTALLATION.md](INSTALLATION.md) para más detalles.

#### Script de Emergencia
Si por alguna razón la pantalla no se apaga después de usar la app:
```bash
sudo ./reset-pmset-state.sh
```
Este script está incluido en el proyecto y resetea `pmset disablesleep` a su valor por defecto.

Ver [INSTALLATION.md](INSTALLATION.md) para solución de problemas completa.

### Iconos de Estado
- **☕️** (normal): Activo con contador de tiempo
- **☕️** (gris): Inactivo

### Interacción
- **Click**: Abre menú de opciones
- **Tooltip**: Muestra tiempo restante cuando está activo

### Opciones de Caffeinate
- **-d**: Prevenir suspensión de pantalla (ideal para presentaciones)
- **-i**: Prevenir suspensión por inactividad (recomendado)
- **-m**: Prevenir suspensión de disco
- **-s**: Prevenir suspensión del sistema (solo con AC conectado)
- **-u**: Declarar usuario activo (enciende pantalla)
- **Prevenir suspensión al cerrar tapa**: Evita que el Mac se suspenda al cerrar la tapa (requiere contraseña de admin)

## 🔧 Desarrollo

### Requisitos
- macOS 10.15+
- Xcode Command Line Tools
- Swift 5.0+

### Estructura del Proyecto
```
caffeinate-control/
├── main.swift           # Código principal
├── Info.plist          # Configuración de la app
├── build.sh            # Script de compilación
├── README.md           # Documentación
└── .github/
    └── workflows/
        └── build.yml   # CI/CD con GitHub Actions
```

### Scripts Disponibles
- `./build.sh`: Compilar la aplicación
- `./build.sh clean`: Limpiar archivos de compilación

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🙏 Reconocimientos

- Inspirado en el comando nativo `caffeinate` de macOS
- Iconos emoji nativos de macOS