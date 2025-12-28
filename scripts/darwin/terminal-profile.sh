#!/usr/bin/env bash
# Module for importing Terminal.app profile
MODULE_NAME="Terminal Profile"
MODULE_DESC="Import mySolarizedDark Terminal.app profile"
MODULE_DEPS=()
MODULE_ORDER=42
MODULE_CATEGORY="configuration"

is_installed() {
    defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null | grep -q "mySolarizedDark"
}

get_version() { is_installed && echo "installed" || echo "not installed"; }

install() {
    log_info "Importing Terminal profile..."

    local profile_name="mySolarizedDark"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local profile_path="${script_dir}/assets/mySolarizedDark.terminal"

    # Verify profile file exists
    if [[ ! -f "$profile_path" ]]; then
        log_error "Terminal profile not found at ${profile_path}"
        return 1
    fi
    
    log_info "Importing profile from ${profile_path}..."
    open "$profile_path"
    sleep 2
    
    log_info "Setting as default profile..."
    defaults write com.apple.Terminal "Default Window Settings" -string "$profile_name"
    defaults write com.apple.Terminal "Startup Window Settings" -string "$profile_name"
    
    log_success "Terminal profile configured"
    return 0
}

uninstall() {
    defaults delete com.apple.Terminal "Default Window Settings" 2>/dev/null || true
    defaults delete com.apple.Terminal "Startup Window Settings" 2>/dev/null || true
    return 0
}

reconfigure() { install; }
verify() { is_installed; }

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -z "${NORD0}" ]] && source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)/"{colors,logger,ui,utils,state}.sh
    case "${1:-}" in
        check) is_installed; exit $? ;;
        version) get_version; exit $? ;;
        install|uninstall|reconfigure|verify) $1; exit $? ;;
        info) echo "Name: $MODULE_NAME"; echo "Description: $MODULE_DESC"; echo "Category: $MODULE_CATEGORY"; echo "Order: $MODULE_ORDER"; exit 0 ;;
        *) echo "Usage: $0 {check|version|install|uninstall|reconfigure|verify|info}"; exit 1 ;;
    esac
fi
