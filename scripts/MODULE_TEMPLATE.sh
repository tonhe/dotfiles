#!/usr/bin/env bash
# =============================================================================
# MODULE_TEMPLATE.sh - Template for creating new modules
# =============================================================================
# Copy this template to create new modules in scripts/all/, scripts/darwin/,
# or scripts/linux/ depending on the target platform.
#
# Module naming convention: lowercase-with-dashes.sh
# Examples: homebrew.sh, xcode-cli.sh, nvchad-setup.sh
#
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
# These variables define module behavior and dependencies

# Human-readable module name (shown in UI)
MODULE_NAME="Example Module"

# Short description (shown in menus and status)
MODULE_DESC="Description of what this module does"

# Dependencies (array of module names that must run first)
# Example: MODULE_DEPS=("homebrew" "xcode-cli")
MODULE_DEPS=()

# Execution order (lower numbers run first, default is 50)
# System modules: 10-19
# Package managers: 20-29
# Applications: 30-49
# Configuration: 50-69
# Finalization: 70-89
MODULE_ORDER=50

# Module category for grouping in UI
# Options: system, packages, applications, configuration
MODULE_CATEGORY="applications"

# =============================================================================
# Module Functions
# =============================================================================

# Check if module is already installed/configured
# Returns: 0 if installed, 1 if not installed
is_installed() {
    # Example checks:
    # - command -v some_command &>/dev/null
    # - [[ -f ~/.config/some/file ]]
    # - [[ -d /Applications/Something.app ]]

    # IMPLEMENT YOUR CHECK HERE
    return 1  # Not installed
}

# Get current installed version
# Returns: version string or "unknown"
get_version() {
    if ! is_installed; then
        echo "not installed"
        return 1
    fi

    # IMPLEMENT VERSION DETECTION HERE
    # Example: some_command --version | head -n1 | awk '{print $2}'

    echo "unknown"
}

# Main installation function
# Returns: 0 on success, 1 on failure
install() {
    log_info "Installing ${MODULE_NAME}..."

    # IMPLEMENT INSTALLATION HERE
    # Example:
    # if ! some_install_command; then
    #     log_error "Installation failed"
    #     return 1
    # fi

    log_success "${MODULE_NAME} installed successfully"
    return 0
}

# Uninstall/remove function
# Returns: 0 on success, 1 on failure
uninstall() {
    log_info "Removing ${MODULE_NAME}..."

    # IMPLEMENT REMOVAL HERE
    # Example:
    # rm -rf ~/.config/something
    # brew uninstall something

    log_success "${MODULE_NAME} removed successfully"
    return 0
}

# Reconfigure/update function
# Returns: 0 on success, 1 on failure
reconfigure() {
    log_info "Reconfiguring ${MODULE_NAME}..."

    # IMPLEMENT RECONFIGURATION HERE
    # This is called when the module is already installed
    # but the user wants to update/refresh it

    log_success "${MODULE_NAME} reconfigured successfully"
    return 0
}

# Verify installation is working correctly
# Returns: 0 if healthy, 1 if problems detected
verify() {
    if ! is_installed; then
        log_warn "${MODULE_NAME} is not installed"
        return 1
    fi

    # IMPLEMENT VERIFICATION CHECKS HERE
    # Example:
    # if ! some_command --test; then
    #     log_error "Verification failed"
    #     return 1
    # fi

    log_success "${MODULE_NAME} is working correctly"
    return 0
}

# =============================================================================
# Module Execution Handler
# =============================================================================
# This section handles command-line invocation
# DO NOT MODIFY unless you know what you're doing

# If script is executed directly (not sourced), run the requested action
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Source libraries if not already loaded
    if [[ -z "${NORD0}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        LIB_DIR="$(cd "${SCRIPT_DIR}/../lib" && pwd)"
        source "${LIB_DIR}/colors.sh"
        source "${LIB_DIR}/logger.sh"
        source "${LIB_DIR}/utils.sh"
        source "${LIB_DIR}/state.sh"
    fi

    # Parse command
    case "${1:-}" in
        check)
            is_installed
            exit $?
            ;;
        version)
            get_version
            exit $?
            ;;
        install)
            install
            exit $?
            ;;
        uninstall)
            uninstall
            exit $?
            ;;
        reconfigure)
            reconfigure
            exit $?
            ;;
        verify)
            verify
            exit $?
            ;;
        info)
            echo "Name: ${MODULE_NAME}"
            echo "Description: ${MODULE_DESC}"
            echo "Category: ${MODULE_CATEGORY}"
            echo "Order: ${MODULE_ORDER}"
            echo "Dependencies: ${MODULE_DEPS[*]}"
            exit 0
            ;;
        *)
            echo "Usage: $0 {check|version|install|uninstall|reconfigure|verify|info}"
            echo ""
            echo "Commands:"
            echo "  check        - Check if module is installed"
            echo "  version      - Get installed version"
            echo "  install      - Install the module"
            echo "  uninstall    - Remove the module"
            echo "  reconfigure  - Reconfigure/update the module"
            echo "  verify       - Verify module is working"
            echo "  info         - Show module information"
            exit 1
            ;;
    esac
fi
