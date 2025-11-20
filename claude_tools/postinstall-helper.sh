#!/bin/bash

# CaffeinateControl Post-Install Helper Setup
# This script is designed to be called after DMG installation
# It automates the helper script installation with user-friendly prompts

set -e

COLOR_OK="\033[32m"      # Green
COLOR_WARN="\033[33m"    # Yellow
COLOR_ERROR="\033[31m"   # Red
COLOR_INFO="\033[34m"    # Blue
COLOR_HEADER="\033[36m"  # Cyan
COLOR_RESET="\033[0m"    # Reset

print_header() {
    echo ""
    echo -e "${COLOR_HEADER}╔═══════════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_HEADER}║        CaffeinateControl - Setup Helper                   ║${COLOR_RESET}"
    echo -e "${COLOR_HEADER}╚═══════════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""
}

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

# Main installation
main() {
    print_header

    echo "This script will help you set up CaffeinateControl for optimal performance."
    echo ""

    # Check if running from correct location
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    RESOURCES_DIR="$SCRIPT_DIR/../Resources"
    INSTALL_HELPER="$RESOURCES_DIR/install-pmset-helper.sh"

    if [ ! -f "$INSTALL_HELPER" ]; then
        # Try alternative path
        INSTALL_HELPER="$SCRIPT_DIR/install-pmset-helper.sh"
        if [ ! -f "$INSTALL_HELPER" ]; then
            print_error "Could not find install-pmset-helper.sh"
            print_info "Make sure you're running this from the CaffeinateControl app bundle"
            exit 1
        fi
    fi

    # Ask user about helper installation
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_info "Password-Free Operation (RECOMMENDED)"
    echo ""
    echo "CaffeinateControl can be set up to manage pmset settings"
    echo "without requesting your password every time."
    echo ""
    echo "This requires a one-time installation of a helper script"
    echo "with administrator privileges."
    echo ""

    read -p "Would you like to set this up now? (y/n) " -n 1 -r
    echo ""
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_helper
    else
        print_info "Skipping helper installation"
        echo ""
        print_info "You can install it later by running:"
        echo "  sudo $INSTALL_HELPER"
        echo ""
        show_next_steps
        return 0
    fi
}

install_helper() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_info "Installing helper script..."
    echo ""

    # Check if already running as sudo
    if [ "$EUID" -ne 0 ]; then
        print_warn "This requires administrator privileges"
        echo "You will be prompted for your password."
        echo ""

        # Run with sudo
        if sudo "$INSTALL_HELPER"; then
            print_ok "Helper installed successfully!"
            echo ""
            print_info "CaffeinateControl is now ready for password-free operation"
        else
            print_error "Helper installation failed or was cancelled"
            echo ""
            print_info "You can try again later by running:"
            echo "  sudo $INSTALL_HELPER"
            return 1
        fi
    else
        # Already root, just run it
        if "$INSTALL_HELPER"; then
            print_ok "Helper installed successfully!"
        else
            print_error "Helper installation failed"
            return 1
        fi
    fi

    echo ""
    show_next_steps
}

show_next_steps() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_info "Next Steps:"
    echo ""
    echo "1. Close this window"
    echo "2. Open CaffeinateControl from Applications"
    echo "3. You're ready to go!"
    echo ""

    # Optional: Launch the app
    read -p "Would you like to launch CaffeinateControl now? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Find and launch the app
        if [ -d "/Applications/CaffeinateControl.app" ]; then
            open /Applications/CaffeinateControl.app
            print_ok "CaffeinateControl launched!"
        else
            print_warn "Could not find CaffeinateControl in Applications"
            echo "Please launch it manually from Applications folder"
        fi
    fi

    echo ""
    print_info "Setup complete!"
    echo ""
}

# Run main function
main
