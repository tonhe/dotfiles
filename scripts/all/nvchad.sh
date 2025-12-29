#!/usr/bin/env bash
# =============================================================================
# nvchad.sh - NvChad (Neovim Configuration Framework)
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
MODULE_NAME="NvChad"
MODULE_DESC="Neovim configuration and plugins"
MODULE_DEPS=("brewfile")
MODULE_ORDER=65
MODULE_CATEGORY="configuration"

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
    [[ -f "$HOME/.config/nvim/init.lua" ]]
}

get_version() {
    if ! is_installed; then
        echo "not installed"
        return 1
    fi

    # Try to get NvChad version from git
    if [[ -d "$HOME/.config/nvim/.git" ]]; then
        cd "$HOME/.config/nvim"
        git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown"
        cd - >/dev/null
    else
        echo "unknown"
    fi
}

install() {
    log_info "Installing NvChad..."

    # Trust that brewfile dependency installed git and neovim
    # No need to check - dependency system ensures brewfile ran first

    # Remove any existing partial nvim config (except our lua/ directory)
    if [[ -d "$HOME/.config/nvim" ]]; then
        log_info "Backing up existing nvim configuration..."

        # Backup custom config
        if [[ -d "$HOME/.config/nvim/lua" ]]; then
            mv "$HOME/.config/nvim/lua" "$HOME/.config/nvim-lua-backup"
        fi

        # Clean up existing nvim directory
        rm -rf "$HOME/.config/nvim"
    fi

    # Clone NvChad starter template
    log_info "Cloning NvChad starter template..."
    start_spinner "Cloning from GitHub"

    if git clone https://github.com/NvChad/starter "$HOME/.config/nvim" --depth 1 &>/dev/null; then
        stop_spinner
        log_success "NvChad repository cloned"
    else
        stop_spinner
        log_error "Failed to clone NvChad repository"
        return 1
    fi

    # Restore custom config
    if [[ -d "$HOME/.config/nvim-lua-backup" ]]; then
        log_info "Restoring custom configuration..."
        mkdir -p "$HOME/.config/nvim/lua"
        cp -r "$HOME/.config/nvim-lua-backup/"* "$HOME/.config/nvim/lua/" 2>/dev/null || true
        rm -rf "$HOME/.config/nvim-lua-backup"
    fi

    log_success "NvChad installed successfully"
    log_info "Run 'nvim' to complete first-time setup and install plugins"
    return 0
}

uninstall() {
    log_warn "Removing NvChad will delete your Neovim configuration"

    if ! confirm "Are you sure you want to remove NvChad?" "n"; then
        log_info "Uninstall cancelled"
        return 0
    fi

    # Backup before removal
    if [[ -d "$HOME/.config/nvim" ]]; then
        local backup_dir="$HOME/.config/nvim-backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up to ${backup_dir}..."
        mv "$HOME/.config/nvim" "$backup_dir"
        log_success "NvChad removed (backup: ${backup_dir})"
    else
        log_info "NvChad not found"
    fi

    return 0
}

reconfigure() {
    log_info "Updating NvChad..."

    if ! is_installed; then
        log_error "NvChad is not installed"
        return 1
    fi

    # Pull latest changes
    cd "$HOME/.config/nvim"

    if [[ -d .git ]]; then
        start_spinner "Pulling latest changes"
        if git pull origin main &>/dev/null; then
            stop_spinner
            log_success "NvChad updated"
        else
            stop_spinner
            log_warn "Could not update NvChad (check git status)"
        fi
    else
        log_warn "NvChad directory is not a git repository"
    fi

    cd - >/dev/null
    return 0
}

verify() {
    if ! is_installed; then
        log_warn "NvChad is not installed"
        return 1
    fi

    # Check if nvim runs without errors
    log_info "Testing Neovim with NvChad..."

    if nvim --headless "+qa" 2>/dev/null; then
        log_success "NvChad is working correctly"
        return 0
    else
        log_error "Neovim failed to start (may need first-time setup)"
        return 1
    fi
}

# =============================================================================
# Module Execution Handler
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "${NORD0}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
        if [[ -z "$SCRIPT_DIR" ]]; then
            echo "ERROR: Could not determine script directory" >&2
            exit 1
        fi
        LIB_DIR="$(cd "${SCRIPT_DIR}/../../lib" 2>/dev/null && pwd)"
        if [[ -z "$LIB_DIR" ]] || [[ ! -d "$LIB_DIR" ]]; then
            LIB_DIR="${HOME}/.dotfiles/repo/lib"
        fi
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
