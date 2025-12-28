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

STATE_FILE="${DOTFILES_HOME}/state/brewfile.json"
BREWFILE="${DOTFILES_HOME}/repo/Brewfile"

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
    [[ -f "$STATE_FILE" ]]
}

get_version() {
    if is_installed; then
        local install_date=$(json_get "$STATE_FILE" "['installed_date']" 2>/dev/null || echo "")
        echo "${install_date:-installed}"
    else
        echo "not installed"
    fi
}

install() {
    ensure_brew_path

    if [[ ! -f "$BREWFILE" ]]; then
        log_error "Brewfile not found at ${BREWFILE}"
        return 1
    fi

    log_info "Installing packages from Brewfile..."
    start_spinner "Running brew bundle"

    if brew bundle --file="$BREWFILE" --no-lock &>/dev/null; then
        stop_spinner
        log_success "Brewfile packages installed"
    else
        stop_spinner
        log_warn "Some packages may have failed to install"
        log_info "Run 'brew bundle --file=$BREWFILE' for details"
        return 1
    fi

    # Save state
    cat > "$STATE_FILE" <<EOF
{
  "module": "brewfile",
  "status": "installed",
  "installed_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "brewfile": "${BREWFILE}"
}
EOF

    return 0
}

uninstall() {
    log_warn "Brewfile uninstall not supported"
    log_info "Packages remain installed but state will be cleared"

    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        log_success "State cleared"
    fi

    return 0
}

reconfigure() {
    log_info "Updating packages from Brewfile..."
    ensure_brew_path

    if [[ ! -f "$BREWFILE" ]]; then
        log_error "Brewfile not found at ${BREWFILE}"
        return 1
    fi

    start_spinner "Running brew bundle"
    if brew bundle --file="$BREWFILE" --no-lock &>/dev/null; then
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
    if ! is_installed; then
        log_warn "Brewfile has not been run"
        return 1
    fi

    ensure_brew_path

    if [[ ! -f "$BREWFILE" ]]; then
        log_warn "Brewfile not found at ${BREWFILE}"
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
