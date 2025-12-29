#!/usr/bin/env bash
# =============================================================================
# gitconfig.sh - Generate Git Configuration
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
MODULE_NAME="Git Config"
MODULE_DESC="Generate .gitconfig from template with user information"
MODULE_DEPS=()
MODULE_ORDER=55
MODULE_CATEGORY="configuration"

# Template and destination
TEMPLATE_FILE="${DOTFILES_HOME}/repo/dot_gitconfig.tmpl.example"
GITCONFIG_FILE="${HOME}/.gitconfig"

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
    [[ -f "$GITCONFIG_FILE" ]]
}

get_version() {
    if is_installed; then
        echo "configured"
    else
        echo "not configured"
    fi
}

install() {
    log_info "Generating .gitconfig from template..."

    # Check if template exists
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_error "Template file not found: $TEMPLATE_FILE"
        return 1
    fi

    # Get user information from user.conf
    local name=$(user_config_get "USER_FULL_NAME")
    local email=$(user_config_get "USER_EMAIL")
    local github_username=$(user_config_get "GITHUB_USERNAME")
    local machine_type=$(user_config_get "MACHINE_TYPE")

    # Validate required fields
    if [[ -z "$name" ]] || [[ -z "$email" ]]; then
        log_error "Missing required user information (name or email)"
        log_info "User config is stored in ${DOTFILES_HOME}/user.conf"
        return 1
    fi

    # Backup existing gitconfig if it exists
    if [[ -f "$GITCONFIG_FILE" ]]; then
        local backup="${GITCONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$GITCONFIG_FILE" "$backup"
        log_info "Backed up existing .gitconfig to $(basename "$backup")"
    fi

    # Process template - replace {{ .variable }} with actual values
    local temp_file=$(mktemp)

    # Read template and substitute variables
    sed \
        -e "s|{{ .name | quote }}|\"${name}\"|g" \
        -e "s|{{ .email | quote }}|\"${email}\"|g" \
        -e "s|{{ .github_username | quote }}|\"${github_username}\"|g" \
        "$TEMPLATE_FILE" > "$temp_file"

    # Handle conditional work-specific config
    if [[ "$machine_type" == "work" ]]; then
        # Keep the work section (remove the template markers)
        sed -i '' \
            -e '/{{ if eq .machine_type "work" }}/d' \
            -e '/{{ end }}/d' \
            "$temp_file"
    else
        # Remove the entire work section
        sed -i '' \
            -e '/{{ if eq .machine_type "work" }}/,/{{ end }}/d' \
            "$temp_file"
    fi

    # Move processed template to final location
    mv "$temp_file" "$GITCONFIG_FILE"

    log_success ".gitconfig generated successfully"
    return 0
}

uninstall() {
    log_warn "Removing .gitconfig is not recommended"

    if confirm "Remove .gitconfig?" "n"; then
        if [[ -f "$GITCONFIG_FILE" ]]; then
            local backup="${GITCONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
            mv "$GITCONFIG_FILE" "$backup"
            log_success ".gitconfig moved to $(basename "$backup")"
        fi
    else
        log_info "Uninstall cancelled"
    fi

    return 0
}

reconfigure() {
    log_info "Regenerating .gitconfig..."
    install
}

verify() {
    if ! is_installed; then
        log_warn ".gitconfig not found"
        return 1
    fi

    # Check that key settings exist
    if git config user.name &>/dev/null && git config user.email &>/dev/null; then
        log_success ".gitconfig is properly configured"
        return 0
    else
        log_warn ".gitconfig exists but missing user.name or user.email"
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
