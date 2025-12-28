#!/usr/bin/env bash
# =============================================================================
# xcode-cli.sh - Xcode Command Line Tools Installation
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
MODULE_NAME="Xcode Command Line Tools"
MODULE_DESC="Essential development tools for macOS"
MODULE_DEPS=()
MODULE_ORDER=10
MODULE_CATEGORY="system"

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
    xcode-select -p &>/dev/null
}

get_version() {
    if ! is_installed; then
        echo "not installed"
        return 1
    fi

    pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | grep version | awk '{print $2}'
}

install() {
    log_info "Installing Xcode Command Line Tools..."

    # Try automated installation via softwareupdate
    local clt_label=$(softwareupdate --list 2>/dev/null | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed 's/^ *//' | tr -d '\n')

    if [[ -n "$clt_label" ]]; then
        log_info "Found Command Line Tools package: $clt_label"
        log_info "Installing via softwareupdate (this may take several minutes)..."

        start_spinner "Installing Xcode CLI Tools"

        # Install in the foreground and capture result
        if softwareupdate --install "$clt_label" --agree-to-license &>/dev/null; then
            stop_spinner
            log_success "Xcode Command Line Tools installed"
            return 0
        else
            stop_spinner
            log_warn "softwareupdate installation failed, trying interactive method..."
        fi
    else
        log_warn "Could not find CLI Tools via softwareupdate"
    fi

    # Fallback to interactive installation
    log_info "Launching interactive installer..."
    log_warn "Please complete the installation in the popup window"

    xcode-select --install 2>/dev/null

    # Wait for installation to complete
    log_info "Waiting for installation to complete..."
    local count=0
    local max_wait=600  # 10 minutes

    while ! is_installed; do
        if [[ $count -ge $max_wait ]]; then
            log_error "Installation timeout after 10 minutes"
            return 1
        fi

        sleep 5
        ((count += 5))

        if [[ $((count % 30)) -eq 0 ]]; then
            log_progress "Still waiting... (${count}s elapsed)"
        fi
    done

    log_success "Xcode Command Line Tools installed"
    return 0
}

uninstall() {
    log_error "Xcode Command Line Tools cannot be uninstalled via this script"
    log_info "To manually remove: sudo rm -rf /Library/Developer/CommandLineTools"
    return 1
}

reconfigure() {
    log_info "Checking for Xcode CLI Tools updates..."

    start_spinner "Checking for updates"
    local updates=$(softwareupdate --list 2>/dev/null | grep "Command Line")
    stop_spinner

    if [[ -n "$updates" ]]; then
        log_info "Updates available"
        log_info "$updates"

        if confirm "Install updates?" "y"; then
            local clt_label=$(echo "$updates" | head -n 1 | awk -F"*" '{print $2}' | sed 's/^ *//' | tr -d '\n')
            softwareupdate --install "$clt_label" --agree-to-license
        fi
    else
        log_success "Xcode CLI Tools are up to date"
    fi

    return 0
}

verify() {
    if ! is_installed; then
        log_warn "Xcode CLI Tools are not installed"
        return 1
    fi

    # Try to compile a simple C program
    log_info "Testing compiler..."

    local test_file="/tmp/xcode_test_$$.c"
    local test_bin="/tmp/xcode_test_$$"

    cat > "$test_file" <<'EOF'
#include <stdio.h>
int main() { printf("OK\n"); return 0; }
EOF

    if gcc -o "$test_bin" "$test_file" &>/dev/null && [[ -x "$test_bin" ]]; then
        local output=$("$test_bin")
        rm -f "$test_file" "$test_bin"

        if [[ "$output" == "OK" ]]; then
            log_success "Xcode CLI Tools are working correctly"
            return 0
        fi
    fi

    rm -f "$test_file" "$test_bin"
    log_error "Compiler test failed"
    return 1
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
