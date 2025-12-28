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

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
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

    log_info "DEBUG: DOTFILES_HOME=${DOTFILES_HOME}"
    log_info "DEBUG: brewfile=${brewfile}"
    log_info "DEBUG: Checking if Brewfile exists..."

    ensure_brew_path

    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile not found at ${brewfile}"
        return 1
    fi

    log_info "DEBUG: Brewfile found, checking brew command..."
    log_info "DEBUG: which brew: $(which brew)"
    log_info "DEBUG: brew --version: $(brew --version | head -1)"

    log_info "Installing packages from Brewfile..."
    log_info "DEBUG: Running: brew bundle --file=$brewfile --no-lock"

    # Run WITHOUT suppressing output so we can see what's happening
    if brew bundle --file="$brewfile" --no-lock; then
        log_success "Brewfile packages installed"
    else
        log_warn "Some packages may have failed to install"
        log_info "Run 'brew bundle --file=$brewfile' for details"
        return 1
    fi

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

    start_spinner "Running brew bundle"
    if brew bundle --file="$brewfile" --no-lock &>/dev/null; then
        stop_spinner
        log_success "Brewfile packages updated"
        return 0
    else
        stop_spinner
        log_warn "Some packages may have failed"
        return 1
    fi
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
