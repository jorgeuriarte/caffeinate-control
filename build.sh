#!/bin/bash

# Script para compilar la aplicación Caffeinate Control

set -e  # Exit on any error

APP_NAME="CaffeinateControl"
BUILD_DIR="build"
VERSION=${1:-"1.0.0"}

# Función para limpiar
clean() {
    echo "🧹 Limpiando archivos de compilación..."
    rm -rf "$BUILD_DIR"
    echo "✅ Limpieza completada"
}

# Función para compilar
build() {
    echo "🔨 Compilando $APP_NAME v$VERSION..."
    
    # Crear directorio de compilación
    mkdir -p "$BUILD_DIR"
    
    # Compilar el código Swift con flags para app GUI
    swiftc -o "$BUILD_DIR/$APP_NAME" main.swift \
        -framework Cocoa \
        -framework AVFoundation \
        -suppress-warnings
    
    if [ $? -eq 0 ]; then
        echo "✅ Compilación exitosa!"
        
        # Crear estructura de la aplicación .app
        APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
        mkdir -p "$APP_BUNDLE/Contents/MacOS"
        mkdir -p "$APP_BUNDLE/Contents/Resources"
        
        # Copiar el ejecutable
        cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
        
        # Copiar Info.plist y actualizar versión
        cp Info.plist "$APP_BUNDLE/Contents/"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_BUNDLE/Contents/Info.plist"

        echo "📦 Aplicación creada en: $APP_BUNDLE (v$VERSION)"
        echo "🚀 Para ejecutar: open $APP_BUNDLE"
        
        # Crear ZIP para distribución si estamos en CI
        if [ "$CI" = "true" ]; then
            echo "📦 Creando archivo ZIP para distribución..."
            cd "$BUILD_DIR"
            zip -r "$APP_NAME-$VERSION.zip" "$APP_NAME.app"
            echo "✅ ZIP creado: $BUILD_DIR/$APP_NAME-$VERSION.zip"
        fi
    else
        echo "❌ Error en la compilación"
        exit 1
    fi
}

# Manejar argumentos
case "$1" in
    clean)
        clean
        ;;
    ""|-*)
        build
        ;;
    *)
        VERSION="$1"
        build
        ;;
esac