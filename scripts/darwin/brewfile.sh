#!/usr/bin/env bash
# =============================================================================
# brewfile.sh - Brewfile Package Installation
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
MODULE_NAME="Brewfile"
MODULE_DESC="Install packages from Brewfile"
MODULE_DEPS=("homebrew")
MODULE_ORDER=25
MODULE_CATEGORY="system"

# =============================================================================
# Helper Functions
# =============================================================================

# Ensure brew is in PATH
ensure_brew_path() {
    local brew_path=""
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        brew_path="/opt/homebrew/bin/brew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        brew_path="/usr/local/bin/brew"
    else
        return 1
    fi

    eval "$($brew_path shellenv)"
    return 0
}

# Mark critical packages as installed in state
mark_critical_packages() {
    local -a critical_packages=("git" "neovim" "node" "npm" "tmux" "zsh")
    for pkg in "${critical_packages[@]}"; do
        if command -v "$pkg" &>/dev/null; then
            # Only mark if not already in state
            if ! state_is_installed "$pkg"; then
                local version=$("$pkg" --version 2>/dev/null | head -1 || echo "installed")
                state_mark_installed "$pkg" "$version"
            fi
        fi
    done
}

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
    # Always mark critical packages when checking if brewfile is installed
    mark_critical_packages

    # Brewfile can never be "detected" on the system - it must always install
    # This ensures install() runs during first-time setup
    # The state file check (in module_install) will skip it on subsequent runs
    return 1
}

get_version() {
    local state_file="${DOTFILES_HOME}/state/brewfile.json"
    if [[ -f "$state_file" ]]; then
        local install_date=$(json_get "$state_file" "['installed_date']" 2>/dev/null || echo "")
        echo "${install_date:-installed}"
    else
        echo "not installed"
    fi
}

install() {
    local brewfile="${DOTFILES_HOME}/repo/Brewfile"
    local state_file="${DOTFILES_HOME}/state/brewfile.json"

    ensure_brew_path

    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile not found at ${brewfile}"
        return 1
    fi

    log_info "Installing packages from Brewfile..."

    # Run brew bundle with output visible
    if brew bundle --file="$brewfile"; then
        log_success "Brewfile packages installed"
    else
        local exit_code=$?
        log_warn "Some packages failed to install (exit code: $exit_code)"
        log_info "Continuing with successfully installed packages..."
        # Don't fail - partial installation is acceptable
    fi

    # Mark individual packages that other modules depend on
    mark_critical_packages

    # Save state
    cat > "$state_file" <<EOF
{
  "module": "brewfile",
  "status": "installed",
  "installed_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "brewfile": "${brewfile}"
}
EOF

    return 0
}

uninstall() {
    local state_file="${DOTFILES_HOME}/state/brewfile.json"

    log_warn "Brewfile uninstall not supported"
    log_info "Packages remain installed but state will be cleared"

    if [[ -f "$state_file" ]]; then
        rm -f "$state_file"
        log_success "State cleared"
    fi

    return 0
}

reconfigure() {
    local brewfile="${DOTFILES_HOME}/repo/Brewfile"

    log_info "Updating packages from Brewfile..."
    ensure_brew_path

    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile not found at ${brewfile}"
        return 1
    fi

    log_info "Updating packages from Brewfile..."
    if brew bundle --file="$brewfile"; then
        log_success "Brewfile packages updated"
    else
        log_warn "Some packages failed to update"
        log_info "Continuing with successfully updated packages..."
    fi
    return 0
}

verify() {
    local brewfile="${DOTFILES_HOME}/repo/Brewfile"

    if ! is_installed; then
        log_warn "Brewfile has not been run"
        return 1
    fi

    ensure_brew_path

    if [[ ! -f "$brewfile" ]]; then
        log_warn "Brewfile not found at ${brewfile}"
        return 1
    fi

    log_success "Brewfile module is configured"
    return 0
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

    # Set DOTFILES_HOME if not set
    export DOTFILES_HOME="${DOTFILES_HOME:-${HOME}/.dotfiles}"

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
