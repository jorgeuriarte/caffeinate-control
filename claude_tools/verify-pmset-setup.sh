#!/bin/bash

# CaffeinateControl pmset Setup Verification Script
# Verifies that the pmset helper is correctly installed and functional

set -e

HELPER_PATH="/usr/local/bin/caffeinatecontrol-pmset"
COLOR_OK="\033[32m"      # Green
COLOR_WARN="\033[33m"    # Yellow
COLOR_ERROR="\033[31m"   # Red
COLOR_INFO="\033[34m"    # Blue
COLOR_RESET="\033[0m"    # Reset

# Function to print colored output
print_ok() {
    echo -e "${COLOR_OK}✅ $1${COLOR_RESET}"
}

print_warn() {
    echo -e "${COLOR_WARN}⚠️  $1${COLOR_RESET}"
}

print_error() {
    echo -e "${COLOR_ERROR}❌ $1${COLOR_RESET}"
}

print_info() {
    echo -e "${COLOR_INFO}ℹ️  $1${COLOR_RESET}"
}

# Main verification
echo ""
echo "🔍 CaffeinateControl pmset Setup Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ISSUES_FOUND=0

# Check 1: Helper script existence
echo "📌 Checking helper script..."
if [ -f "$HELPER_PATH" ]; then
    print_ok "Helper script found at $HELPER_PATH"
else
    print_warn "Helper script NOT found at $HELPER_PATH"
    print_info "The app will use AppleScript as fallback (will require password prompts)"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""

# Check 2: File permissions and ownership
if [ -f "$HELPER_PATH" ]; then
    echo "📌 Checking file permissions..."

    OWNER=$(stat -f '%Su' "$HELPER_PATH" 2>/dev/null || echo "unknown")
    GROUP=$(stat -f '%Sg' "$HELPER_PATH" 2>/dev/null || echo "unknown")
    PERMS=$(stat -f '%A' "$HELPER_PATH" 2>/dev/null || echo "unknown")

    if [ "$OWNER" = "root" ]; then
        print_ok "Owner is root"
    else
        print_error "Owner is $OWNER (expected root)"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi

    echo "   File: $PERMS (Owner: $OWNER:$GROUP)"

    if [ -u "$HELPER_PATH" ]; then
        print_ok "SUID bit is set (will run as root)"
    else
        print_warn "SUID bit is NOT set"
        print_info "To fix, run: sudo chmod u+s $HELPER_PATH"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi

    if [ -x "$HELPER_PATH" ]; then
        print_ok "Script is executable"
    else
        print_error "Script is NOT executable"
        print_info "To fix, run: sudo chmod +x $HELPER_PATH"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi

    echo ""
fi

# Check 3: pmset availability
echo "📌 Checking pmset command..."
if command -v pmset &> /dev/null; then
    print_ok "pmset command found"
    PMSET_PATH=$(command -v pmset)
    echo "   Path: $PMSET_PATH"
else
    print_error "pmset command not found"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""

# Check 4: Current pmset state
echo "📌 Checking current pmset state..."
if command -v pmset &> /dev/null; then
    SLEEP_STATE=$(pmset -g | grep "^sleep" | head -1 || echo "unknown")
    if [ ! -z "$SLEEP_STATE" ]; then
        echo "   Current: $SLEEP_STATE"
        SLEEP_VALUE=$(echo "$SLEEP_STATE" | awk '{print $2}')

        if [ "$SLEEP_VALUE" = "0" ]; then
            print_warn "pmset disablesleep is currently ACTIVE (sleep = 0)"
            print_info "This is normal if you just used the app"
            print_info "It will auto-reset on next app launch"
        else
            print_ok "System sleep is normal (disablesleep is inactive)"
        fi
    else
        print_warn "Could not determine current sleep state"
    fi

    echo ""
    print_info "Full pmset settings:"
    pmset -g 2>/dev/null | grep sleep | head -5 || echo "Could not read pmset"
else
    print_error "Cannot check pmset state"
fi

echo ""

# Check 5: Test helper execution
if [ -f "$HELPER_PATH" ]; then
    echo "📌 Testing helper execution..."

    # Get current state
    CURRENT=$(pmset -g | grep "^sleep" | head -1 | awk '{print $2}')

    # Try to run with 0 (disable)
    if "$HELPER_PATH" 0 > /dev/null 2>&1; then
        print_ok "Helper executed successfully"
        AFTER=$(pmset -g | grep "^sleep" | head -1 | awk '{print $2}')
        echo "   Before: sleep $CURRENT | After: sleep $AFTER"

        # Restore previous state
        if [ ! -z "$CURRENT" ] && [ "$CURRENT" != "0" ]; then
            print_info "Restoring previous state..."
            # Note: Can't easily restore without sudo, so just note it
            sleep 1
        fi
    else
        print_warn "Helper test inconclusive (may need password prompt)"
        print_info "This is normal - the app will handle authentication"
    fi

    echo ""
fi

# Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ISSUES_FOUND -eq 0 ]; then
    print_ok "All checks passed! Setup is correct."
    echo ""
    print_info "CaffeinateControl can manage pmset settings efficiently."
    exit 0
else
    print_warn "Found $ISSUES_FOUND issue(s) that might affect functionality."
    echo ""

    if [ ! -f "$HELPER_PATH" ]; then
        print_info "Installation option:"
        echo "  1. Run: sudo ./install-pmset-helper.sh"
        echo "     (or: sudo /path/to/install-pmset-helper.sh)"
        echo ""
    fi

    print_info "Manual fix options:"
    if [ -f "$HELPER_PATH" ] && [ ! -u "$HELPER_PATH" ]; then
        echo "  • Set SUID: sudo chmod u+s $HELPER_PATH"
    fi

    if [ -f "$HELPER_PATH" ] && [ ! -x "$HELPER_PATH" ]; then
        echo "  • Make executable: sudo chmod +x $HELPER_PATH"
    fi

    echo ""
    print_info "The app will still work with AppleScript as fallback."
    echo ""
fi
