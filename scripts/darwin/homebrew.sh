#!/usr/bin/env bash
# =============================================================================
# homebrew.sh - Homebrew Package Manager Installation
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
MODULE_NAME="Homebrew"
MODULE_DESC="Package manager for macOS"
MODULE_DEPS=("xcode-cli")
MODULE_ORDER=20
MODULE_CATEGORY="system"

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
    [[ -x "/opt/homebrew/bin/brew" ]] || [[ -x "/usr/local/bin/brew" ]]
}

get_version() {
    if ! is_installed; then
        echo "not installed"
        return 1
    fi

    local brew_path=""
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        brew_path="/opt/homebrew/bin/brew"
    else
        brew_path="/usr/local/bin/brew"
    fi

    $brew_path --version | head -n1 | awk '{print $2}'
}

install() {
    log_info "Installing Homebrew package manager..."

    # Download and run Homebrew installer
    start_spinner "Downloading Homebrew installer"
    local install_script=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
    stop_spinner

    if [[ -z "$install_script" ]]; then
        log_error "Failed to download Homebrew installer"
        return 1
    fi

    # Run installer
    log_info "Running Homebrew installer (this may take several minutes)..."
    if ! /bin/bash -c "$install_script" </dev/null; then
        log_error "Homebrew installation failed"
        return 1
    fi

    # Determine brew path and add to PATH for current session
    local brew_path=""
    if [[ $(uname -m) == "arm64" ]]; then
        brew_path="/opt/homebrew/bin/brew"
    else
        brew_path="/usr/local/bin/brew"
    fi

    if [[ -x "$brew_path" ]]; then
        eval "$($brew_path shellenv)"
        log_success "Homebrew installed successfully"
        return 0
    else
        log_error "Homebrew binary not found after installation"
        return 1
    fi
}

uninstall() {
    log_warn "Uninstalling Homebrew will remove all installed packages"

    if ! confirm "Are you sure you want to uninstall Homebrew?" "n"; then
        log_info "Uninstall cancelled"
        return 0
    fi

    # Download and run uninstall script
    local uninstall_script=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)

    if [[ -z "$uninstall_script" ]]; then
        log_error "Failed to download Homebrew uninstaller"
        return 1
    fi

    /bin/bash -c "$uninstall_script"
    return $?
}

reconfigure() {
    log_info "Updating Homebrew..."

    local brew_path=""
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        brew_path="/opt/homebrew/bin/brew"
    else
        brew_path="/usr/local/bin/brew"
    fi

    start_spinner "Updating Homebrew"
    $brew_path update &>/dev/null
    stop_spinner
    log_success "Homebrew updated"

    return 0
}

verify() {
    if ! is_installed; then
        log_warn "Homebrew is not installed"
        return 1
    fi

    local brew_path=""
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        brew_path="/opt/homebrew/bin/brew"
    else
        brew_path="/usr/local/bin/brew"
    fi

    log_info "Running Homebrew diagnostics..."
    if $brew_path doctor &>/dev/null; then
        log_success "Homebrew is working correctly"
        return 0
    else
        log_warn "Homebrew diagnostics reported issues (run 'brew doctor' for details)"
        return 1
    fi
}

# =============================================================================
# Module Execution Handler
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "${NORD0}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        LIB_DIR="$(cd "${SCRIPT_DIR}/../../lib" && pwd)"
        source "${LIB_DIR}/colors.sh"
        source "${LIB_DIR}/logger.sh"
        source "${LIB_DIR}/ui.sh"
        source "${LIB_DIR}/utils.sh"
        source "${LIB_DIR}/state.sh"
    fi

    case "${1:-}" in
        check) is_installed; exit $? ;;
        version) get_version; exit $? ;;
        install) install; exit $? ;;
        uninstall) uninstall; exit $? ;;
        reconfigure) reconfigure; exit $? ;;
        verify) verify; exit $? ;;
        info)
            echo "Name: ${MODULE_NAME}"
            echo "Description: ${MODULE_DESC}"
            echo "Category: ${MODULE_CATEGORY}"
            echo "Order: ${MODULE_ORDER}"
            echo "Dependencies: ${MODULE_DEPS[*]}"
            exit 0
            ;;
        *) echo "Usage: $0 {check|version|install|uninstall|reconfigure|verify|info}"; exit 1 ;;
    esac
fi
