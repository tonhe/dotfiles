#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh - Copy/Sync Dotfiles and Configuration
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
MODULE_NAME="Dotfiles"
MODULE_DESC="Copy dotfiles and configurations to home directory"
MODULE_DEPS=()
MODULE_ORDER=60
MODULE_CATEGORY="configuration"

# Dotfiles source directory
DOTFILES_SOURCE="${DOTFILES_HOME}/repo"
STATE_FILE="${DOTFILES_HOME}/state/dotfiles.json"

# =============================================================================
# Helper Functions
# =============================================================================

# Get list of all dot_ files/dirs (excluding dot_config which is special)
get_dot_files() {
    find "$DOTFILES_SOURCE/" -maxdepth 1 -name "dot_*" ! -name "dot_config" -type f 2>/dev/null
}

# Convert dot_ filename to actual dotfile name
# dot_zshrc -> .zshrc
# dot_tmux.conf -> .tmux.conf
convert_name() {
    local name=$(basename "$1")
    echo "${name#dot_}" | sed 's/^/./'
}

# Check if file needs updating (different content)
needs_update() {
    local src="$1"
    local dest="$2"

    # If dest doesn't exist, needs update
    [[ ! -f "$dest" ]] && return 0

    # Compare checksums
    local src_hash=$(get_file_hash "$src")
    local dest_hash=$(get_file_hash "$dest")

    [[ "$src_hash" != "$dest_hash" ]]
}

# Backup existing file
backup_file() {
    local file="$1"

    if [[ -f "$file" ]] || [[ -d "$file" ]]; then
        local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up existing file to ${backup}"
        cp -a "$file" "$backup"
    fi
}

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
    [[ -f "$STATE_FILE" ]]
}

get_version() {
    if is_installed; then
        local install_date=$(json_get "$STATE_FILE" "['last_sync']" 2>/dev/null || echo "")
        echo "${install_date:-applied}"
    else
        echo "not applied"
    fi
}

install() {
    log_info "Applying dotfiles to home directory..."

    local files_copied=0
    local files_skipped=0

    # Copy dot_ files (dot_zshrc -> ~/.zshrc, etc.)
    log_info "Processing root-level dotfiles..."

    for src_file in $(get_dot_files); do
        local dest_name=$(convert_name "$src_file")
        local dest_file="${HOME}/${dest_name}"

        if needs_update "$src_file" "$dest_file"; then
            backup_file "$dest_file"
            log_info "Copying $(basename "$src_file") -> ${dest_name}"
            cp "$src_file" "$dest_file"
            log_success "$(basename "$src_file") -> ${dest_name}"
            ((files_copied++))
        else
            log_progress "$(basename "$src_file") (unchanged)"
            ((files_skipped++))
        fi
    done

    # Copy dot_config directory -> ~/.config/
    if [[ -d "${DOTFILES_SOURCE}/dot_config" ]]; then
        log_info "Processing .config directory..."

        ensure_dir "${HOME}/.config"

        # Copy each subdirectory
        for config_dir in "${DOTFILES_SOURCE}"/dot_config/*; do
            if [[ -d "$config_dir" ]]; then
                local dir_name=$(basename "$config_dir")
                local dest_dir="${HOME}/.config/${dir_name}"

                log_info "Syncing .config/${dir_name}..."

                # Backup if exists
                backup_file "$dest_dir"

                # Copy directory
                cp -R "$config_dir" "$dest_dir"
                log_success ".config/${dir_name} synced"
                ((files_copied++))
            fi
        done

        # Copy individual files in dot_config/
        for config_file in "${DOTFILES_SOURCE}"/dot_config/*; do
            if [[ -f "$config_file" ]]; then
                local file_name=$(basename "$config_file")
                local dest_file="${HOME}/.config/${file_name}"

                if needs_update "$config_file" "$dest_file"; then
                    backup_file "$dest_file"
                    cp "$config_file" "$dest_file"
                    log_success ".config/${file_name} copied"
                    ((files_copied++))
                fi
            fi
        done
    fi

    # Copy private_bin directory -> ~/bin/
    if [[ -d "${DOTFILES_SOURCE}/private_bin" ]]; then
        log_info "Processing bin directory..."

        ensure_dir "${HOME}/bin"

        # Copy all scripts and make them executable
        for bin_file in "${DOTFILES_SOURCE}"/private_bin/*; do
            if [[ -f "$bin_file" ]]; then
                local file_name=$(basename "$bin_file")
                local dest_file="${HOME}/bin/${file_name}"

                if needs_update "$bin_file" "$dest_file"; then
                    backup_file "$dest_file"
                    cp "$bin_file" "$dest_file"
                    chmod +x "$dest_file"
                    log_success "bin/${file_name} (executable)"
                    ((files_copied++))
                else
                    ((files_skipped++))
                fi
            fi
        done

        # Copy directories in private_bin
        for bin_dir in "${DOTFILES_SOURCE}"/private_bin/*; do
            if [[ -d "$bin_dir" ]]; then
                local dir_name=$(basename "$bin_dir")
                local dest_dir="${HOME}/bin/${dir_name}"

                backup_file "$dest_dir"
                cp -R "$bin_dir" "$dest_dir"

                # Make scripts in subdirectory executable
                find "$dest_dir" -type f -exec chmod +x {} \;

                log_success "bin/${dir_name}/ (directory)"
                ((files_copied++))
            fi
        done
    fi

    # Handle dot_gitconfig.tmpl if it exists (template processing)
    if [[ -f "${DOTFILES_SOURCE}/dot_gitconfig.tmpl.example" ]]; then
        if [[ ! -f "${HOME}/.gitconfig" ]]; then
            log_warn ".gitconfig template found but not auto-applied"
            log_info "User config will be created separately if needed"
        fi
    fi

    # Save state
    cat > "$STATE_FILE" <<EOF
{
  "module": "dotfiles",
  "status": "installed",
  "installed_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "last_sync": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "files_copied": ${files_copied},
  "files_skipped": ${files_skipped}
}
EOF

    log_success "Dotfiles applied: ${files_copied} copied, ${files_skipped} unchanged"

    # Remind user to reload shell
    if [[ $files_copied -gt 0 ]]; then
        log_warn "Shell config updated - reload with: source ~/.zshrc"
    fi

    return 0
}

uninstall() {
    log_warn "Removing dotfiles is not recommended"
    log_info "Dotfiles are in your home directory and should be managed manually"

    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        log_success "State file removed"
    fi

    return 0
}

reconfigure() {
    log_info "Re-syncing dotfiles..."
    install
}

verify() {
    if ! is_installed; then
        log_warn "Dotfiles have not been applied"
        return 1
    fi

    # Check that key files exist
    local missing=0
    local key_files=(".zshrc" ".tmux.conf")

    for file in "${key_files[@]}"; do
        if [[ ! -f "${HOME}/${file}" ]]; then
            log_warn "Missing: ${file}"
            ((missing++))
        fi
    done

    if [[ -d "${HOME}/bin" ]]; then
        log_info "~/bin directory exists"
    else
        log_warn "~/bin directory missing"
        ((missing++))
    fi

    if [[ $missing -eq 0 ]]; then
        log_success "Dotfiles are properly installed"
        return 0
    else
        log_error "${missing} key file(s) missing"
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
