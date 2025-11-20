#!/bin/bash

# CaffeinateControl pmset Emergency Reset
# Use this if the app leaves pmset in a bad state

set -e

COLOR_OK="\033[32m"      # Green
COLOR_WARN="\033[33m"    # Yellow
COLOR_ERROR="\033[31m"   # Red
COLOR_INFO="\033[34m"    # Blue
COLOR_RESET="\033[0m"    # Reset

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

echo ""
echo "🔧 CaffeinateControl pmset Emergency Reset"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run with sudo"
    echo "   Usage: sudo ./reset-pmset-state.sh"
    echo ""
    exit 1
fi

print_info "This script will reset pmset to its default state."
echo ""

# Show current state
echo "📊 Current system state:"
echo ""
CURRENT_SLEEP=$(pmset -g | grep "^sleep" | head -1 | awk '{print $2}')
echo "   Current sleep setting: $CURRENT_SLEEP"

if [ "$CURRENT_SLEEP" = "0" ]; then
    print_warn "pmset disablesleep is currently ACTIVE"
else
    print_ok "pmset disablesleep is currently INACTIVE"
    echo ""
    print_info "System appears to be in normal state."
    print_info "No reset needed."
    exit 0
fi

echo ""
echo "🔄 Resetting pmset to default..."

# Reset disablesleep to 0 (enable normal sleep)
/usr/bin/pmset -a disablesleep 0
RESULT=$?

if [ $RESULT -eq 0 ]; then
    print_ok "Successfully reset pmset disablesleep to 0"

    # Verify
    sleep 1
    NEW_SLEEP=$(pmset -g | grep "^sleep" | head -1 | awk '{print $2}')
    echo "   New sleep setting: $NEW_SLEEP"

    if [ "$NEW_SLEEP" != "0" ]; then
        print_ok "System sleep is now enabled"
    else
        print_warn "Warning: System still shows sleep = 0"
        print_info "This might be a display delay, try again in a moment"
    fi

    echo ""
    print_ok "Reset complete!"

    # Log the action
    logger -t caffeinatecontrol "pmset emergency reset performed"

else
    print_error "Failed to reset pmset (exit code: $RESULT)"
    echo ""
    print_info "Possible reasons:"
    echo "   • Permission denied"
    echo "   • pmset not available"
    echo "   • System configuration issue"
    exit 1
fi

echo ""
echo "📋 Additional info:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current sleep settings:"
pmset -g | grep sleep | head -5
echo ""

print_info "Your Mac should now sleep normally when you close the lid."
