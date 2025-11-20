#!/bin/bash

# CaffeinateControl DMG Builder with Post-Install Helper Setup
# Creates a professional DMG installer with automatic helper installation

set -e

APP_NAME="CaffeinateControl"
BUILD_DIR="build"
VERSION=${1:-"1.0.0"}
DMG_TEMP_DIR="/tmp/caffeinatecontrol-dmg-$$"
DMG_SIZE=100  # Size in MB

echo "📦 Building DMG installer for $APP_NAME v$VERSION..."
echo ""

# Clean up function
cleanup() {
    if [ -d "$DMG_TEMP_DIR" ]; then
        rm -rf "$DMG_TEMP_DIR"
    fi
}

# Set trap to clean up on exit
trap cleanup EXIT

# Check if app bundle exists
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ App bundle not found at $BUILD_DIR/$APP_NAME.app"
    echo "   Run: ./build.sh"
    exit 1
fi

# Create temporary DMG directory structure
echo "📁 Creating DMG structure..."
mkdir -p "$DMG_TEMP_DIR"

# Copy app bundle
cp -r "$BUILD_DIR/$APP_NAME.app" "$DMG_TEMP_DIR/"

# Copy helper installation scripts
mkdir -p "$DMG_TEMP_DIR/Install Helpers"
cp claude_tools/install-pmset-helper.sh "$DMG_TEMP_DIR/Install Helpers/"
cp claude_tools/verify-pmset-setup.sh "$DMG_TEMP_DIR/Install Helpers/"
cp claude_tools/reset-pmset-state.sh "$DMG_TEMP_DIR/Install Helpers/"

# Create a symlink to Applications folder
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Create README for the DMG
cat > "$DMG_TEMP_DIR/README.txt" << 'EOF'
CaffeinateControl Installer
════════════════════════════════════════════════════════════════

INSTALLATION STEPS:

1. Drag "CaffeinateControl.app" to the "Applications" folder

2. (OPTIONAL BUT RECOMMENDED) Install the pmset helper for
   password-free operation:

   a) Open Terminal
   b) Run: cd Applications/CaffeinateControl.app/Contents/Resources
   c) Run: sudo ./install-pmset-helper.sh
   d) Enter your password when prompted

   This is a one-time setup. After that, no more password prompts!

3. Launch CaffeinateControl from Applications folder

════════════════════════════════════════════════════════════════

WHAT'S NEW:

✅ Fixed bugs that prevented proper pmset cleanup
✅ Optional helper script for passwordless operation
✅ Better detection of pmset state
✅ Emergency reset tools included

SUPPORT:

- Full documentation: Inside the app bundle
- Quick start: Run the app and check the menu
- Troubleshooting: See INSTALLATION.md in the app resources

════════════════════════════════════════════════════════════════
EOF

# Create drag-and-drop visual instructions
cat > "$DMG_TEMP_DIR/INSTALL.txt" << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                   CAFFEINATE CONTROL                          ║
║                    Quick Install Guide                        ║
╚═══════════════════════════════════════════════════════════════╝

STEP 1: Copy the Application
─────────────────────────────────────────────────────────────────
  → Drag CaffeinateControl.app to the Applications folder

STEP 2: (Optional) Install Helper for Password-Free Operation
─────────────────────────────────────────────────────────────────
  → Open Terminal
  → Copy & paste this command:

    cd Applications/CaffeinateControl.app/Contents/Resources
    sudo ./install-pmset-helper.sh

  → Enter your password when prompted
  → Done! No more password prompts for pmset changes

STEP 3: Launch
─────────────────────────────────────────────────────────────────
  → Go to Applications folder
  → Double-click CaffeinateControl.app
  → Click on the coffee icon in the menu bar

═══════════════════════════════════════════════════════════════

Questions? See INSTALLATION.md in the application resources.

═══════════════════════════════════════════════════════════════
EOF

# Calculate size and create DMG
echo "🔧 Creating DMG image..."
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

# Remove existing DMG if present
if [ -f "$DMG_PATH" ]; then
    rm "$DMG_PATH"
fi

# Create DMG using hdiutil
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

if [ $? -eq 0 ]; then
    echo "✅ DMG created successfully!"
    echo "📦 Location: $DMG_PATH"
    echo "📊 Size: $(du -h "$DMG_PATH" | cut -f1)"

    # Create a checksum
    CHECKSUM=$(shasum -a 256 "$DMG_PATH" | cut -d' ' -f1)
    echo "🔐 SHA256: $CHECKSUM"

    # Save checksum to file
    echo "$CHECKSUM  $APP_NAME-$VERSION.dmg" > "$BUILD_DIR/$APP_NAME-$VERSION.dmg.sha256"

    echo ""
    echo "📋 DMG Contents:"
    echo "  ├─ CaffeinateControl.app"
    echo "  ├─ Applications (symlink for drag-and-drop)"
    echo "  ├─ Install Helpers/"
    echo "  │  ├─ install-pmset-helper.sh"
    echo "  │  ├─ verify-pmset-setup.sh"
    echo "  │  └─ reset-pmset-state.sh"
    echo "  ├─ INSTALL.txt (Quick start guide)"
    echo "  └─ README.txt (Detailed instructions)"

    echo ""
    echo "🚀 To test the DMG:"
    echo "   open $DMG_PATH"
else
    echo "❌ Failed to create DMG"
    exit 1
fi
