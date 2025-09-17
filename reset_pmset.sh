#!/bin/bash

# reset_pmset.sh - Script de emergencia para resetear pmset disablesleep
# Este script puede ser usado para restaurar el comportamiento normal de suspensión
# si la aplicación CaffeinateControl no puede hacerlo por alguna razón

echo "==================================="
echo "CaffeinateControl - Reset de pmset"
echo "==================================="
echo ""
echo "Este script resetea la configuración de pmset disablesleep"
echo "para restaurar el comportamiento normal de suspensión al cerrar la tapa."
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Este script requiere privilegios de administrador."
    echo "Por favor, ejecuta: sudo $0"
    exit 1
fi

echo "Comprobando estado actual de pmset..."
current_status=$(pmset -g | grep disablesleep)

if [ -z "$current_status" ]; then
    echo "✓ disablesleep no está configurado (comportamiento normal)"
else
    echo "Estado actual: $current_status"
    echo ""
    echo "Reseteando pmset disablesleep..."
    pmset -a disablesleep 0

    if [ $? -eq 0 ]; then
        echo "✓ pmset reseteado correctamente"
        echo ""
        echo "El Mac ahora se suspenderá normalmente al cerrar la tapa."
    else
        echo "✗ Error al resetear pmset"
        echo "Por favor, intenta ejecutar manualmente:"
        echo "  sudo pmset -a disablesleep 0"
        exit 1
    fi
fi

echo ""
echo "==================================="
echo "Proceso completado"
echo "==================================="