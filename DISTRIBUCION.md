# Cómo Distribuir CaffeinateControl

## Opción 1: Distribución Personal (Más Simple)

### Para tu uso personal:
1. **Copia la app**: Simplemente copia `build/CaffeinateControl.app` a `/Applications/`
2. **Auto-iniciar**: Agrégala a "Elementos de Inicio" en Preferencias del Sistema

### Para compartir con amigos/colegas:
1. **Comprimir**: Haz zip de `CaffeinateControl.app`
2. **Compartir**: GitHub releases, email, o almacenamiento en la nube
3. **Instrucciones**: Los usuarios deben copiar a `/Applications/` y dar permisos si es necesario

## Opción 2: Distribución Firme (Recomendada)

### Prerrequisitos:
- Cuenta de desarrollador de Apple ($99/año)
- Certificado de Developer ID

### Pasos:
```bash
# 1. Firmar la aplicación
codesign --force --options runtime --sign "Developer ID Application: Tu Nombre" build/CaffeinateControl.app

# 2. Crear archivo DMG (opcional pero profesional)
hdiutil create -volname "CaffeinateControl" -srcfolder build/CaffeinateControl.app -ov -format UDZO CaffeinateControl.dmg

# 3. Notarizar con Apple (opcional pero recomendado)
xcrun notarytool submit CaffeinateControl.dmg --keychain-profile "AC_PASSWORD" --wait
```

## Opción 3: App Store (Más Complejo)

### Requiere:
- Cuenta de desarrollador de Apple
- Cumplir guidelines del App Store
- Proceso de revisión (1-7 días)

### Pasos:
1. Crear App ID en Apple Developer Portal
2. Configurar capacidades necesarias
3. Usar Xcode para subir a App Store Connect
4. Enviar para revisión

## Opción 4: Homebrew (Para Desarrolladores)

### Crear fórmula Homebrew:
```ruby
class CaffeinateControl < Formula
  desc "Menu bar app to control macOS caffeinate command"
  homepage "https://github.com/tu-usuario/caffeinate-control"
  url "https://github.com/tu-usuario/caffeinate-control/archive/v1.0.tar.gz"
  
  def install
    system "./build.sh"
    applications.install "build/CaffeinateControl.app"
  end
end
```

## Recomendación

**Para empezar**: Usa la **Opción 1** (distribución personal)
- Es gratis e inmediato
- Perfecto para uso personal y compartir con conocidos
- Puedes actualizar a firmado más tarde

**Para distribución seria**: Usa la **Opción 2** (firmado)
- Los usuarios no verán advertencias de seguridad
- Más profesional y confiable
- Requiere cuenta de desarrollador ($99/año)

## Archivos a Incluir en la Distribución

- `CaffeinateControl.app` (la aplicación)
- `README.md` (instrucciones de uso)
- `LICENCIA` (si planeas distribuir públicamente)

## GitHub Release

1. Crear repositorio en GitHub
2. Subir código fuente
3. Crear release con el .app comprimido
4. Los usuarios pueden descargar desde Releases