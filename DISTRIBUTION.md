# Distribución e Instalación de CaffeinateControl

Esta guía cubre las diferentes formas de distribuir y instalar CaffeinateControl, desde usuarios individuales hasta distribución masiva.

---

## 📦 Opciones de Distribución

### Opción 1: ZIP Simple (Actual)
**Para:** Usuarios técnicos, releases de GitHub
**Archivo:** `CaffeinateControl-VERSION.zip`

```bash
# Crear
./build.sh VERSION
# La app se encuentra en: build/CaffeinateControl.app

# Distribuir
# Usuarios descargan el ZIP y lo descomprimen
# Arrastran CaffeinateControl.app a /Applications
# Ejecutan setup helpers manualmente si lo desean
```

**Ventajas:**
- ✅ Muy simple
- ✅ Sin dependencias
- ✅ Funciona inmediatamente

**Desventajas:**
- ❌ Usuarios no saben sobre el helper pmset
- ❌ Sin verificación del sistema

---

### Opción 2: DMG Drag-and-Drop (Recomendado)
**Para:** Distribución profesional, releases de GitHub
**Archivo:** `CaffeinateControl-VERSION.dmg`

```bash
# Crear
./build-dmg.sh VERSION
# Resultado: build/CaffeinateControl-VERSION.dmg

# Usuarios:
# 1. Descargan el DMG
# 2. Lo abren (se monta automáticamente)
# 3. Ven instrucciones claras
# 4. Arrastran la app a Applications
# 5. Opcionalmente instalan el helper desde el mismo DMG
```

**Ventajas:**
- ✅ Profesional, estándar en macOS
- ✅ Instrucciones claras incluidas
- ✅ Helper scripts accesibles
- ✅ Arrastrar y soltar intuitivo

**Desventajas:**
- ⚠️ Algunos usuarios podrían no instalar el helper

**Estructura DMG:**
```
CaffeinateControl
├── CaffeinateControl.app
├── Applications (symlink)
├── Install Helpers/
│   ├── install-pmset-helper.sh
│   ├── verify-pmset-setup.sh
│   └── reset-pmset-state.sh
├── INSTALL.txt (instrucciones)
└── README.txt (detalles)
```

---

### Opción 3: macOS .pkg Installer (Profesional)
**Para:** Distribución corporativa, sistemas gestionados
**Archivo:** `CaffeinateControl-VERSION.pkg`

```bash
# Crear
./claude_tools/build-macos-installer.sh VERSION
# Resultado: build/CaffeinateControl-VERSION.pkg

# Características:
# - Post-install script automático
# - Validación de sistema
# - Instala en /Applications automáticamente
# - Versioning y upgrade handling
```

**Ventajas:**
- ✅ Muy profesional
- ✅ Integración con Software Updates
- ✅ Validación automática
- ✅ Permisos correctos automáticamente
- ✅ Para MDM (Mobile Device Management)

**Desventajas:**
- ⚠️ Más complejo de crear
- ⚠️ Requiere notarización para distribución

**Nota sobre Notarización:**
Para distribuir vía App Store o como certificado, necesitas notarizar el paquete:

```bash
xcrun notarytool submit CaffeinateControl-VERSION.pkg \
    --apple-id your-email@example.com \
    --password your-app-specific-password \
    --team-id YOUR_TEAM_ID
```

---

## 🔧 Instaladores con Helper Automático

### Opción 4: Post-Install Interactive Setup
**Archivo:** `postinstall-helper.sh`

Este script puede ejecutarse después de cualquier instalación:

```bash
# Usuarios pueden ejecutar manualmente
./postinstall-helper.sh

# Ofrece:
# - Explicación amable sobre el helper pmset
# - Opción de instalarlo ahora
# - Lanzar la app después
# - Instrucciones si deciden no instalar
```

**Uso en DMG:**
```
1. Usuario abre DMG
2. Ejecuta: Install Helpers/postinstall-helper.sh
3. Script guía todo automáticamente
```

---

## 📋 Opciones Recomendadas por Caso de Uso

### Caso 1: Release en GitHub
**Crear ambos:**

```bash
# En el build/release:
./build.sh VERSION          # ZIP
./build-dmg.sh VERSION      # DMG (profesional)

# Resultado:
build/CaffeinateControl-VERSION.zip
build/CaffeinateControl-VERSION.dmg
build/CaffeinateControl-VERSION.dmg.sha256
```

**Usuarios eligen:**
- ZIP si solo quieren el ejecutable
- DMG para mejor experiencia

---

### Caso 2: Distribución Empresarial (MDM)
**Crear:**

```bash
./claude_tools/build-macos-installer.sh VERSION

# Resultado:
build/CaffeinateControl-VERSION.pkg
build/CaffeinateControl-VERSION.pkg.sha256
```

**Distribuir vía:**
- Jamf Pro
- Apple Business Manager
- Custom MDM systems

---

### Caso 3: App Store
**Requiere:**
- Cuenta de desarrollador Apple
- Certificados de código
- Notarización
- Almacén de claves firmado

(No cubierto en esta guía, requiere procedimientos especiales)

---

## 🛠️ Flujo de Compilación Completo

### Para Release Manual

```bash
#!/bin/bash
VERSION="1.2.0"

# 1. Compilar app
./build.sh "$VERSION"

# 2. Crear distribuciones
./build-dmg.sh "$VERSION"
./claude_tools/build-macos-installer.sh "$VERSION"

# 3. Crear checksums (ya hecho por los scripts)
cd build/
ls -lh CaffeinateControl-$VERSION.*

# 4. Crear notas de release
cat > RELEASE_NOTES.md << EOF
# CaffeinateControl v$VERSION

## Changes
- Fixed pmset disablesleep bugs
- Added helper script for password-free operation

## Download
- DMG: CaffeinateControl-$VERSION.dmg
- PKG: CaffeinateControl-$VERSION.pkg
- ZIP: CaffeinateControl-$VERSION.zip

## Checksums
$(cat *.sha256)
EOF
```

---

## 📥 Instalación para Diferentes Usuarios

### Usuario General

```bash
# Opción 1: Descargar ZIP
unzip CaffeinateControl-VERSION.zip
mv CaffeinateControl.app /Applications/

# Opción 2: Descargar DMG
# Doble click → Arrastra app a Applications
# (Más intuitivo)
```

### Usuario Técnico / Línea de Comandos

```bash
# Instalación rápida
./build.sh
open build/CaffeinateControl.app

# O con helper pre-instalado
sudo ./claude_tools/install-pmset-helper.sh
```

### Administrador de Sistemas

```bash
# Instalación vía script
cd /Applications
pkgutil --pkg-info com.local.caffeinate.app  # Verificar instalación

# O vía Apple Remote Desktop / Terminal
installer -pkg CaffeinateControl-VERSION.pkg -target /
```

---

## 🔐 Seguridad y Verificación

### Verificar Integridad de Descarga

```bash
# Usuario descarga archivo + .sha256
shasum -a 256 -c CaffeinateControl-VERSION.dmg.sha256

# Debe mostrar:
# CaffeinateControl-VERSION.dmg: OK
```

### Verificar Instalación del Helper

```bash
./claude_tools/verify-pmset-setup.sh

# Debe mostrar:
# ✅ Helper script found
# ✅ SUID bit is set
# ✅ Script is executable
```

---

## 🚀 Integración en CI/CD

### GitHub Actions

```yaml
- name: Build distributions
  run: |
    ./build.sh ${{ github.ref_name }}
    ./build-dmg.sh ${{ github.ref_name }}
    ./claude_tools/build-macos-installer.sh ${{ github.ref_name }}

- name: Create Release
  uses: softprops/action-gh-release@v2
  with:
    files: |
      build/*.dmg
      build/*.dmg.sha256
      build/*.pkg
      build/*.pkg.sha256
```

---

## 📊 Comparación de Opciones

| Aspecto | ZIP | DMG | PKG |
|---------|-----|-----|-----|
| **Profesionalismo** | Básico | Alto | Muy alto |
| **Facilidad de uso** | Media | Muy alta | Muy alta |
| **Compatibilidad** | 100% | 100% | 95% |
| **Tamaño archivo** | Pequeño | Mediano | Pequeño |
| **Helper automático** | No | Manual | Sí |
| **Verificación sistema** | No | No | Sí |
| **App Store compatible** | No | No | Con cambios |
| **Empresas/MDM** | No | No | Sí |

---

## 🎯 Recomendación Final

### Para la mayoría de usuarios:
**Usar DMG** (`./build-dmg.sh`)
- Profesional
- Intuitivo
- Incluye instrucciones claras
- Helper accesible si lo desean

### Comandos de distribución (recomendado):

```bash
# En CI/CD o antes de release
VERSION="1.2.0"

# 1. Build
./build.sh "$VERSION"

# 2. Distribuir
./build-dmg.sh "$VERSION"              # Usuarios finales
./claude_tools/build-macos-installer.sh "$VERSION"  # Empresas/MDM

# 3. Verificar
ls -lh build/CaffeinateControl-$VERSION*
cat build/*.sha256

# 4. Distribuir ambos en release de GitHub
# Usuarios eligen qué descargar según necesidad
```

---

## Notas Finales

- **ZIP:** Para máxima simplicidad
- **DMG:** Para distribución estándar (RECOMENDADO)
- **PKG:** Para empresas y sistemas gestionados
- **Helper:** Automático en PKG, manual en ZIP/DMG pero guiado

Los tres formatos están disponibles y los scripts se encargan de incluir todas las herramientas necesarias.
