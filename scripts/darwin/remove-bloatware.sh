#!/usr/bin/env bash
# Module for removing unwanted macOS applications
MODULE_NAME="Remove Bloatware"
MODULE_DESC="Remove unwanted pre-installed macOS apps"
MODULE_DEPS=()
MODULE_ORDER=45
MODULE_CATEGORY="configuration"

STATE_FILE="$HOME/.bloatware-removed"

is_installed() { [[ -f "$STATE_FILE" ]]; }
get_version() { is_installed && cat "$STATE_FILE" || echo "not applied"; }

install() {
    local apps=("GarageBand" "iMovie" "Keynote" "Numbers" "Pages" "News" "Stocks" "Home" "Podcasts" "TV" "Music" "Maps" "Chess" "FaceTime")
    local removed=0
    
    log_info "Removing unwanted macOS apps..."
    
    for app in "${apps[@]}"; do
        if [[ -d "/Applications/${app}.app" ]]; then
            log_info "Removing ${app}..."
            if sudo rm -rf "/Applications/${app}.app" 2>/dev/null; then
                log_success "${app} removed"
                ((removed++))
            fi
        fi
    done
    
    date +%Y-%m-%d > "$STATE_FILE"
    log_success "Removed ${removed} applications"
    return 0
}

uninstall() {
    log_info "Apps can be re-downloaded from Mac App Store"
    [[ -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
    return 0
}

reconfigure() { install; }
verify() { is_installed; }

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
    export DOTFILES_HOME="${DOTFILES_HOME:-${HOME}/.dotfiles}"
    case "${1:-}" in
        check) is_installed; exit $? ;;
        version) get_version; exit $? ;;
        install|uninstall|reconfigure|verify) $1; exit $? ;;
        info) echo "Name: $MODULE_NAME"; echo "Description: $MODULE_DESC"; echo "Category: $MODULE_CATEGORY"; echo "Order: $MODULE_ORDER"; exit 0 ;;
        *) echo "Usage: $0 {check|version|install|uninstall|reconfigure|verify|info}"; exit 1 ;;
    esac
fi
