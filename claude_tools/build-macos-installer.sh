#!/bin/bash

# Advanced macOS Installer Package Builder for CaffeinateControl
# Creates a proper .pkg installer with post-install helper setup

set -e

APP_NAME="CaffeinateControl"
BUILD_DIR="build"
VERSION=${1:-"1.0.0"}
TEMP_DIR="/tmp/caffeinatecontrol-pkg-$$"

echo "📦 Building macOS Installer Package..."
echo ""

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
echo "📁 Creating package structure..."
mkdir -p "$TEMP_DIR/root/Applications"
mkdir -p "$TEMP_DIR/scripts"
mkdir -p "$TEMP_DIR/resources"

# Copy app
cp -r "$BUILD_DIR/$APP_NAME.app" "$TEMP_DIR/root/Applications/"

# Create postinstall script (runs after app is copied)
cat > "$TEMP_DIR/scripts/postinstall" << 'EOF'
#!/bin/bash

# Post-installation script for CaffeinateControl
# This runs after the app is copied to Applications

APP_PATH="/Applications/CaffeinateControl.app"
INSTALL_HELPER="$APP_PATH/Contents/Resources/install-pmset-helper.sh"

# Check if helper exists
if [ ! -f "$INSTALL_HELPER" ]; then
    echo "Warning: Could not find helper script"
    exit 0
fi

# Make scripts executable
chmod +x "$INSTALL_HELPER" 2>/dev/null || true
chmod +x "$APP_PATH/Contents/Resources/verify-pmset-setup.sh" 2>/dev/null || true
chmod +x "$APP_PATH/Contents/Resources/reset-pmset-state.sh" 2>/dev/null || true

# Success
exit 0
EOF

chmod +x "$TEMP_DIR/scripts/postinstall"

# Create preinstall script (validation before install)
cat > "$TEMP_DIR/scripts/preinstall" << 'EOF'
#!/bin/bash

# Pre-installation script for CaffeinateControl
# Validates system requirements

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
REQUIRED_VERSION="10.15"

if ! printf '%s\n' "$REQUIRED_VERSION" "$MACOS_VERSION" | sort -V | head -n 1 | grep -q "^$REQUIRED_VERSION"; then
    echo "Error: macOS $REQUIRED_VERSION or later required"
    exit 1
fi

# Check if app is already running
if pgrep -f "CaffeinateControl" > /dev/null 2>&1; then
    echo "Warning: CaffeinateControl is currently running"
    echo "It will be updated in place"
fi

exit 0
EOF

chmod +x "$TEMP_DIR/scripts/preinstall"

# Create Distribution file (package metadata)
cat > "$TEMP_DIR/Distribution" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>$APP_NAME</title>
    <organization>com.local</organization>
    <domains enable_localSystem="true"/>

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
            <line choice="caffeinate.app"/>
        </line>
    </choices-outline>

    <choice id="default"/>
    <choice id="caffeinate.app" title="$APP_NAME" description="Install $APP_NAME to Applications folder">
        <pkg-ref id="com.local.caffeinate.app"/>
    </choice>

    <pkg-ref id="com.local.caffeinate.app" installKBytes="10000" version="$VERSION" auth="root">
        #caffeinate.pkg
    </pkg-ref>
</installer-gui-script>
EOF

# Create the component package (simplified, without plist)
echo "🔧 Building component package..."
pkgbuild \
    --root "$TEMP_DIR/root" \
    --scripts "$TEMP_DIR/scripts" \
    --install-location "/" \
    --identifier "com.local.caffeinate.app" \
    --version "$VERSION" \
    --ownership preserve \
    "$TEMP_DIR/caffeinate.pkg" \
    || {
        echo "❌ Failed to create component package"
        exit 1
    }

# Create the product package (the final installer)
echo "🔧 Creating product installer..."
productbuild \
    --distribution "$TEMP_DIR/Distribution" \
    --resources "$TEMP_DIR/resources" \
    --package-path "$TEMP_DIR" \
    "$BUILD_DIR/$APP_NAME-$VERSION.pkg" \
    || {
        echo "❌ Failed to create installer package"
        exit 1
    }

if [ -f "$BUILD_DIR/$APP_NAME-$VERSION.pkg" ]; then
    echo "✅ Installer created successfully!"
    echo "📦 Location: $BUILD_DIR/$APP_NAME-$VERSION.pkg"
    echo "📊 Size: $(du -h "$BUILD_DIR/$APP_NAME-$VERSION.pkg" | cut -f1)"

    # Create checksum
    CHECKSUM=$(shasum -a 256 "$BUILD_DIR/$APP_NAME-$VERSION.pkg" | cut -d' ' -f1)
    echo "🔐 SHA256: $CHECKSUM"
    echo "$CHECKSUM  $APP_NAME-$VERSION.pkg" > "$BUILD_DIR/$APP_NAME-$VERSION.pkg.sha256"

    echo ""
    echo "🚀 To test the installer:"
    echo "   open $BUILD_DIR/$APP_NAME-$VERSION.pkg"
else
    echo "❌ Failed to create installer"
    exit 1
fi
