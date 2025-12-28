#!/usr/bin/env bash
# Module for setting SUID bit on mtr
MODULE_NAME="SUID MTR"
MODULE_DESC="Set SUID bit on mtr-packet"
MODULE_DEPS=("homebrew")
MODULE_ORDER=38
MODULE_CATEGORY="configuration"

is_installed() {
    local mtr_path=$(command -v mtr-packet 2>/dev/null)
    [[ -n "$mtr_path" ]] && [[ -u "$mtr_path" ]]
}

get_version() { is_installed && echo "configured" || echo "not configured"; }

install() {
    log_info "Configuring mtr permissions..."
    
    local mtr_path=""
    if [[ $(uname -m) == "arm64" ]]; then
        mtr_path="/opt/homebrew/sbin/mtr-packet"
    else
        mtr_path="/usr/local/sbin/mtr-packet"
    fi
    
    if [[ ! -f "$mtr_path" ]]; then
        log_error "mtr-packet not found at $mtr_path (install mtr via Homebrew first)"
        return 1
    fi
    
    log_info "Setting setuid bit on mtr-packet..."
    sudo chown root:wheel "$mtr_path"
    sudo chmod u+s "$mtr_path"
    
    log_success "mtr configured to run without sudo"
    return 0
}

uninstall() {
    local mtr_path=$(command -v mtr-packet 2>/dev/null)
    [[ -n "$mtr_path" ]] && sudo chmod u-s "$mtr_path"
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
        info) echo "Name: $MODULE_NAME"; echo "Description: $MODULE_DESC"; echo "Category: $MODULE_CATEGORY"; echo "Order: $MODULE_ORDER"; echo "Dependencies: ${MODULE_DEPS[*]}"; exit 0 ;;
        *) echo "Usage: $0 {check|version|install|uninstall|reconfigure|verify|info}"; exit 1 ;;
    esac
fi
