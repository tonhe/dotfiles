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

# Get list of all dot_ files/dirs (excluding dot_config and examples)
get_dot_files() {
    find "$DOTFILES_SOURCE/" -maxdepth 1 -name "dot_*" ! -name "dot_config" ! -name "*.example" -type f 2>/dev/null
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

# Backup existing file or directory
backup_file() {
    local file="$1"

    if [[ -e "$file" ]]; then
        local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$file" "$backup"
        return 0
    fi
    return 1
}

# Backup entire directory by renaming
backup_directory() {
    local dir="$1"

    if [[ -d "$dir" ]]; then
        local backup="${dir}.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$dir" "$backup"
        log_info "Backed up existing directory: $(basename "$dir") -> $(basename "$backup")"
        return 0
    fi
    return 1
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
    local dot_files=($(get_dot_files))
    local total_dotfiles=${#dot_files[@]}
    local current=0

    for src_file in "${dot_files[@]}"; do
        local dest_name=$(convert_name "$src_file")
        local dest_file="${HOME}/${dest_name}"

        ((current++))
        progress_bar $current $total_dotfiles "Copying: $(basename "$src_file")"

        if needs_update "$src_file" "$dest_file"; then
            backup_file "$dest_file"
            cp "$src_file" "$dest_file"
            ((files_copied++))
        else
            ((files_skipped++))
        fi
    done

    # Copy dot_config directory -> ~/.config/
    if [[ -d "${DOTFILES_SOURCE}/dot_config" ]]; then
        ensure_dir "${HOME}/.config"

        # Copy each subdirectory
        for config_dir in "${DOTFILES_SOURCE}"/dot_config/*; do
            if [[ -d "$config_dir" ]]; then
                local dir_name=$(basename "$config_dir")
                local dest_dir="${HOME}/.config/${dir_name}"

                backup_file "$dest_dir"
                cp -R "$config_dir" "$dest_dir"
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
                    ((files_copied++))
                fi
            fi
        done
    fi

    # Copy home_bin directory -> ~/bin/
    if [[ -d "${DOTFILES_SOURCE}/home_bin" ]]; then
        # Backup existing ~/bin if it exists
        backup_directory "${HOME}/bin"

        # Create fresh bin directory
        mkdir -p "${HOME}/bin"

        # Count total bin files for progress
        local bin_items=($(find "${DOTFILES_SOURCE}/home_bin" -maxdepth 1 -type f -o -type d ! -path "${DOTFILES_SOURCE}/home_bin"))
        local total_bin=${#bin_items[@]}
        local bin_current=0

        # Copy all scripts and make them executable
        for bin_file in "${DOTFILES_SOURCE}"/home_bin/*; do
            ((bin_current++))

            if [[ -f "$bin_file" ]]; then
                local file_name=$(basename "$bin_file")
                local dest_file="${HOME}/bin/${file_name}"

                progress_bar $bin_current $total_bin "Installing: bin/${file_name}"

                cp "$bin_file" "$dest_file"
                chmod +x "$dest_file"
                ((files_copied++))
            elif [[ -d "$bin_file" ]]; then
                local dir_name=$(basename "$bin_file")
                local dest_dir="${HOME}/bin/${dir_name}"

                progress_bar $bin_current $total_bin "Installing: bin/${dir_name}/"

                cp -R "$bin_file" "$dest_dir"

                # Make scripts in subdirectory executable
                find "$dest_dir" -type f -exec chmod +x {} \; 2>/dev/null

                ((files_copied++))
            fi
        done
    fi

    # Note: .gitconfig is generated separately via bootstrap user config

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
