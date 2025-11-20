#!/bin/bash

# CaffeinateControl pmset Helper Installation Script
# This installs a privileged helper to manage pmset without requiring password prompts

set -e

HELPER_PATH="/usr/local/bin/caffeinatecontrol-pmset"
HELPER_OWNER="root"
HELPER_GROUP="wheel"

echo "🔧 Installing CaffeinateControl pmset helper..."
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run with sudo"
    echo "   Usage: sudo ./install-pmset-helper.sh"
    exit 1
fi

# Create /usr/local/bin if it doesn't exist
if [ ! -d /usr/local/bin ]; then
    echo "📁 Creating /usr/local/bin directory..."
    mkdir -p /usr/local/bin
fi

# Create the helper script
echo "📝 Creating helper script at $HELPER_PATH..."
cat > "$HELPER_PATH" << 'EOF'
#!/bin/bash

# CaffeinateControl pmset helper
# This script manages pmset disablesleep setting with elevated privileges
# It's designed to be called from the CaffeinateControl application

# Strict argument validation
if [[ ! "$1" =~ ^[01]$ ]]; then
    echo "Error: Invalid argument '$1'. Expected 0 or 1." >&2
    exit 1
fi

# Additional safety: check if pmset exists
if [ ! -f /usr/bin/pmset ]; then
    echo "Error: pmset not found at /usr/bin/pmset" >&2
    exit 1
fi

# Execute pmset with the provided argument (0 = disable, 1 = enable)
/usr/bin/pmset -a disablesleep "$1"
RESULT=$?

# Log the action
if [ $RESULT -eq 0 ]; then
    logger -t caffeinatecontrol-pmset "pmset disablesleep set to $1"
fi

exit $RESULT
EOF

# Set proper permissions
echo "🔐 Setting permissions..."

# Make owner root:wheel
chown "$HELPER_OWNER:$HELPER_GROUP" "$HELPER_PATH"

# Make executable (755)
chmod 755 "$HELPER_PATH"

# Set SUID bit (u+s means run as owner, which is root)
chmod u+s "$HELPER_PATH"

echo "✅ Permissions set:"
ls -la "$HELPER_PATH"
echo ""

# Verify the installation
echo "🔍 Verifying installation..."
echo ""

# Check 1: File exists and is owned by root
if [ -f "$HELPER_PATH" ] && [ "$(stat -f '%Su' "$HELPER_PATH")" = "root" ]; then
    echo "✅ Script exists and is owned by root"
else
    echo "❌ Script ownership issue"
    exit 1
fi

# Check 2: SUID bit is set
if [ -u "$HELPER_PATH" ]; then
    echo "✅ SUID bit is set (will run as root)"
else
    echo "❌ SUID bit not set. Trying to set it again..."
    chmod u+s "$HELPER_PATH"
    if [ -u "$HELPER_PATH" ]; then
        echo "✅ SUID bit now set"
    else
        echo "⚠️  Warning: Could not set SUID bit. Script may still work if filesystem supports it."
    fi
fi

# Check 3: Executable
if [ -x "$HELPER_PATH" ]; then
    echo "✅ Script is executable"
else
    echo "❌ Script is not executable"
    exit 1
fi

echo ""
echo "🧪 Testing the helper..."

# Test 1: Try disabling (0)
if "$HELPER_PATH" 0 > /dev/null 2>&1; then
    echo "✅ Successfully executed: pmset disablesleep 0"
    CURRENT_STATE=$(pmset -g | grep "^sleep" | awk '{print $2}' | head -1)
    echo "   Current sleep setting: $CURRENT_STATE"
else
    echo "⚠️  Could not test execution (may require password prompt)"
fi

echo ""
echo "📋 Installation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Helper installed at: $HELPER_PATH"
echo "Owner: $(stat -f '%Su:%Sg' "$HELPER_PATH")"
echo "Permissions: $(stat -f '%A' "$HELPER_PATH")"
echo "SUID: $([ -u "$HELPER_PATH" ] && echo 'Yes ✅' || echo 'No ⚠️')"
echo ""
echo "The CaffeinateControl app can now manage pmset settings"
echo "without requiring password prompts for each change."
echo ""
echo "✨ Installation complete!"
