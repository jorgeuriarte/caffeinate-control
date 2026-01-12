#!/bin/bash

# Professional Automated PKG Installer Builder for CaffeinateControl
# Creates a beautiful, user-friendly installer that requires no terminal interaction
# Just double-click and everything is done automatically

set -e

APP_NAME="CaffeinateControl"
BUILD_DIR="build"
VERSION=${1:-"1.0.0"}
TEMP_DIR="/tmp/caffeinate-pro-installer-$$"
HELPER_BINARY="$BUILD_DIR/caffeinatecontrol-pmset"

echo "📦 Building professional automated installer..."
echo ""

# Build the helper binary if source exists and we're on macOS
if [ -f "helper/caffeinatecontrol-pmset.c" ] && [[ "$(uname)" == "Darwin" ]]; then
    echo "🔨 Building pmset helper binary..."
    ./helper/build-helper.sh "$BUILD_DIR"
    echo ""
fi

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# Check if app exists
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ App bundle not found at $BUILD_DIR/$APP_NAME.app"
    echo "   Run: ./build.sh first"
    exit 1
fi

# Create package structure
echo "📁 Creating installer structure..."
mkdir -p "$TEMP_DIR/root/Applications"
mkdir -p "$TEMP_DIR/root/usr/local/bin"
mkdir -p "$TEMP_DIR/scripts"
mkdir -p "$TEMP_DIR/resources"

# Copy app
cp -r "$BUILD_DIR/$APP_NAME.app" "$TEMP_DIR/root/Applications/"

# Copy helper binary if it exists
if [ -f "$HELPER_BINARY" ]; then
    echo "📦 Including pmset helper binary..."
    cp "$HELPER_BINARY" "$TEMP_DIR/root/usr/local/bin/"
else
    echo "⚠️  Helper binary not found at $HELPER_BINARY"
    echo "   The installer will work but won't have password-free pmset control"
fi

# Create preinstall script (validation)
cat > "$TEMP_DIR/scripts/preinstall" << 'PRESCRIPT'
#!/bin/bash
# Validation before installation
MACOS_VERSION=$(sw_vers -productVersion)
REQUIRED_VERSION="10.15"

if ! printf '%s\n' "$REQUIRED_VERSION" "$MACOS_VERSION" | sort -V | head -n 1 | grep -q "^$REQUIRED_VERSION"; then
    echo "Error: macOS $REQUIRED_VERSION or later required (you have $MACOS_VERSION)"
    exit 1
fi

exit 0
PRESCRIPT

chmod +x "$TEMP_DIR/scripts/preinstall"

# Create postinstall script - THIS IS THE MAGIC
# This runs AFTER the app is installed, completely silently, AS ROOT
cat > "$TEMP_DIR/scripts/postinstall" << 'POSTSCRIPT'
#!/bin/bash

# Post-installation script for CaffeinateControl
# This runs as root during PKG installation

HELPER_PATH="/usr/local/bin/caffeinatecontrol-pmset"
LOG_TAG="CaffeinateControl-installer"

log_message() {
    logger -t "$LOG_TAG" "$1"
    echo "$1"
}

# Configure the pmset helper binary with SUID permissions
# The binary was already copied to /usr/local/bin by the installer
if [ -f "$HELPER_PATH" ]; then
    log_message "Configuring pmset helper binary..."

    # Set ownership to root:wheel (required for SUID to work)
    chown root:wheel "$HELPER_PATH"

    # Set permissions: rwsr-xr-x (4755)
    # - Owner (root): read, write, execute + SUID
    # - Group (wheel): read, execute
    # - Others: read, execute
    chmod 4755 "$HELPER_PATH"

    # Verify SUID bit is set
    if [ -u "$HELPER_PATH" ]; then
        log_message "Helper binary configured with SUID - password-free operation enabled"
    else
        log_message "Warning: Could not set SUID bit on helper binary"
    fi
else
    log_message "Note: Helper binary not found - password prompts will be required for lid sleep prevention"
fi

# Reset any existing pmset disablesleep state for safety
# This ensures a clean state after installation
/usr/bin/pmset -a disablesleep 0 2>/dev/null || true

log_message "CaffeinateControl installation completed successfully"

exit 0
POSTSCRIPT

chmod +x "$TEMP_DIR/scripts/postinstall"

# Create a beautiful welcome document (shows when installer opens)
cat > "$TEMP_DIR/resources/Welcome.txt" << 'WELCOME'
CaffeinateControl 2.0
═══════════════════════════════════════════════════════════════

¡Bienvenido a CaffeinateControl!

Este instalador configurará CaffeinateControl en tu Mac.

LO QUE SUCEDERÁ:
• La aplicación se instalará en /Applications
• Se configurarán los permisos correctamente
• Se intentará instalar el helper para operación sin contraseña
• ¡Todo automáticamente!

TIEMPO ESTIMADO: 30 segundos

Solo haz clic en "Continuar" y sigue los pasos.

═══════════════════════════════════════════════════════════════
WELCOME

# Create Distribution file with custom graphics
cat > "$TEMP_DIR/Distribution" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>CaffeinateControl</title>
    <organization>io.github.jorgeuriarte</organization>
    <domains enable_localSystem="true"/>

    <welcome file="Welcome.txt"/>

    <installation-check script="pm_install_check()"/>
    <volume-check script="pm_volume_check()"/>

    <script>
        function pm_volume_check() {
            if(!(my.target.mountpoint.charAt(0) == '/')) {
                return false;
            }
            return true;
        }
        function pm_install_check() {
            if(system.version.ProductVersion &lt; "10.15") {
                return false;
            }
            return true;
        }
    </script>

    <choices-outline>
        <line choice="default">
            <line choice="caffeinate.install"/>
        </line>
    </choices-outline>

    <choice id="default"/>
    <choice id="caffeinate.install"
            title="CaffeinateControl"
            description="Instala CaffeinateControl en tu carpeta Applications">
        <pkg-ref id="com.io.github.jorgeuriarte.caffeinate"/>
    </choice>

    <pkg-ref id="com.io.github.jorgeuriarte.caffeinate"
             installKBytes="50000"
             version="$VERSION"
             auth="root">
        #caffeinate.pkg
    </pkg-ref>
</installer-gui-script>
EOF

# Create the component package
echo "🔧 Building component package..."
pkgbuild \
    --root "$TEMP_DIR/root" \
    --scripts "$TEMP_DIR/scripts" \
    --install-location "/" \
    --identifier "com.io.github.jorgeuriarte.caffeinate" \
    --version "$VERSION" \
    --ownership preserve \
    "$TEMP_DIR/caffeinate.pkg" \
    || {
        echo "❌ Failed to create component package"
        exit 1
    }

# Create the final product installer
echo "🔧 Creating professional installer..."
productbuild \
    --distribution "$TEMP_DIR/Distribution" \
    --resources "$TEMP_DIR/resources" \
    --package-path "$TEMP_DIR" \
    "$BUILD_DIR/$APP_NAME-$VERSION-Installer.pkg" \
    || {
        echo "❌ Failed to create installer"
        exit 1
    }

if [ -f "$BUILD_DIR/$APP_NAME-$VERSION-Installer.pkg" ]; then
    echo "✅ Professional installer created successfully!"
    echo ""
    echo "📦 Location: $BUILD_DIR/$APP_NAME-$VERSION-Installer.pkg"
    echo "📊 Size: $(du -h "$BUILD_DIR/$APP_NAME-$VERSION-Installer.pkg" | cut -f1)"

    # Create checksum
    CHECKSUM=$(shasum -a 256 "$BUILD_DIR/$APP_NAME-$VERSION-Installer.pkg" | cut -d' ' -f1)
    echo "🔐 SHA256: $CHECKSUM"
    echo "$CHECKSUM  $APP_NAME-$VERSION-Installer.pkg" > "$BUILD_DIR/$APP_NAME-$VERSION-Installer.pkg.sha256"

    echo ""
    echo "📖 HOW IT WORKS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usuario simplemente:"
    echo "  1. Descarga: CaffeinateControl-$VERSION-Installer.pkg"
    echo "  2. Doble click en el archivo"
    echo "  3. Sigue el instalador (siguiente → siguiente → instalar)"
    echo "  4. Ingresa contraseña si es solicitado"
    echo "  5. ¡Listo! La app está en /Applications"
    echo ""
    echo "No requiere:"
    echo "  ❌ Arrastrar carpetas"
    echo "  ❌ Abrir terminal"
    echo "  ❌ Ejecutar scripts"
    echo "  ❌ Conocimiento técnico"
    echo ""
    echo "🚀 Para probar:"
    echo "   open $BUILD_DIR/$APP_NAME-$VERSION-Installer.pkg"
else
    echo "❌ Failed to create installer"
    exit 1
fi
