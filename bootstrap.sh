#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh - Dotfiles 3.0 Main Orchestrator
# =============================================================================
# A modular, maintainable dotfiles bootstrap system with Nord theme
#
# Usage:
#   First time install (remote):
#     curl -fsSL https://raw.githubusercontent.com/tonhe/dotfiles/main/bootstrap.sh | bash
#
#   Local execution:
#     ./bootstrap.sh [OPTIONS]
#
# Options:
#   --help          Show this help message
#   --dry-run       Preview what would be done without making changes
#   --non-interactive   Run without prompts (uses defaults)
#   --show-log      Show the bootstrap log
#   --show-errors   Show only errors from log
#   --clear-log     Archive and clear the log
# =============================================================================

set -e

# =============================================================================
# Bootstrap Configuration
# =============================================================================
DOTFILES_REPO="https://github.com/tonhe/dotfiles.git"
export DOTFILES_HOME="${HOME}/.dotfiles"
DOTFILES_REPO_DIR="${DOTFILES_HOME}/repo"

# Runtime flags
DRY_RUN=false
NON_INTERACTIVE=false
ACTION=""

# =============================================================================
# Argument Parsing
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --dry-run|--preview)
                DRY_RUN=true
                ;;
            --non-interactive|-n)
                NON_INTERACTIVE=true
                ;;
            --show-log)
                ACTION="show-log"
                ;;
            --show-errors)
                ACTION="show-errors"
                ;;
            --clear-log)
                ACTION="clear-log"
                ;;
            *)
                echo "Unknown option: $1"
                echo "Run with --help for usage information"
                exit 1
                ;;
        esac
        shift
    done
}

show_help() {
    cat << 'EOF'
Dotfiles 3.0 Bootstrap

USAGE:
    ./bootstrap.sh [OPTIONS]

OPTIONS:
    --help              Show this help message
    --dry-run           Preview without making changes
    --non-interactive   Run without prompts (CI mode)
    --show-log          Display the bootstrap log
    --show-errors       Display only errors from log
    --clear-log         Archive and clear the log

EXAMPLES:
    # First time setup
    ./bootstrap.sh

    # Preview what would be installed
    ./bootstrap.sh --dry-run

    # Non-interactive installation (CI/automation)
    ./bootstrap.sh --non-interactive

    # View recent errors
    ./bootstrap.sh --show-errors

REMOTE INSTALLATION:
    curl -fsSL https://raw.githubusercontent.com/tonhe/dotfiles/main/bootstrap.sh | bash

EOF
}

# =============================================================================
# Bootstrap Initialization
# =============================================================================

# Check if running from curl | bash
is_remote_install() {
    [[ ! -d "${DOTFILES_REPO_DIR}" ]]
}

# Clone repository if needed
bootstrap_clone_repo() {
    if [[ -d "${DOTFILES_REPO_DIR}/.git" ]]; then
        log_info "Repository already cloned, pulling latest changes..."
        cd "${DOTFILES_REPO_DIR}"
        git pull origin main &>/dev/null || log_warn "Could not pull latest changes"
        cd - >/dev/null
        return 0
    fi

    log_info "Cloning dotfiles repository..."
    start_spinner "Cloning from ${DOTFILES_REPO}"

    if git clone "${DOTFILES_REPO}" "${DOTFILES_REPO_DIR}" &>/dev/null; then
        stop_spinner
        log_success "Repository cloned successfully"
        return 0
    else
        stop_spinner
        log_error "Failed to clone repository from ${DOTFILES_REPO}"
        return 1
    fi
}

# Re-execute from cloned repository (for curl | bash)
bootstrap_reexec() {
    local cloned_script="${DOTFILES_REPO_DIR}/bootstrap.sh"

    if [[ -x "$cloned_script" && "$0" != "$cloned_script" ]]; then
        log_info "Re-executing from cloned repository..."
        exec "$cloned_script" "$@"
    fi
}

# Load all libraries
bootstrap_load_libs() {
    local lib_dir="${DOTFILES_REPO_DIR}/lib"

    if [[ ! -d "$lib_dir" ]]; then
        echo "ERROR: Library directory not found: $lib_dir"
        exit 1
    fi

    source "${lib_dir}/colors.sh"
    source "${lib_dir}/logger.sh"
    source "${lib_dir}/ui.sh"
    source "${lib_dir}/utils.sh"
    source "${lib_dir}/state.sh"
    source "${lib_dir}/modules.sh"
}

# =============================================================================
# First Run Setup
# =============================================================================

run_first_time_setup() {
    print_banner

    if [[ "$DRY_RUN" == true ]]; then
        draw_box "⚠  DRY RUN MODE - NO CHANGES WILL BE MADE  ⚠" 71 "$WARN"
        echo ""
    fi

    log_section "FIRST TIME SETUP"

    # Discover available modules
    module_discover

    local all_modules=($(module_list_all))
    local module_count=${#all_modules[@]}

    if [[ $module_count -eq 0 ]]; then
        log_error "No modules discovered!"
        return 1
    fi

    echo ""
    module_display_status

    # Confirm unless non-interactive
    if [[ "$NON_INTERACTIVE" == false && "$DRY_RUN" == false ]]; then
        echo -ne "${TEXT}Press ${BOLD}ENTER${NC}${TEXT} to begin installation or ${BOLD}Ctrl+C${NC}${TEXT} to cancel${NC} "
        read -r
    fi

    echo ""

    # Request sudo upfront
    if [[ "$DRY_RUN" == false ]]; then
        log_section "SYSTEM ACCESS"
        log_info "Some operations require administrator privileges"
        log_info "DEBUG: About to call request_sudo..."
        if ! request_sudo; then
            log_error "Failed to obtain administrator privileges"
            return 1
        fi
        log_info "DEBUG: request_sudo returned successfully"
        log_success "Administrator access granted"
    fi

    log_info "DEBUG: Checking user config..."
    # Check if user config is needed
    if ! user_config_is_complete; then
        log_info "DEBUG: User config incomplete, prompting..."
        log_section "USER CONFIGURATION"
        if [[ "$NON_INTERACTIVE" == true ]]; then
            log_warn "Non-interactive mode: using default user configuration"
        else
            if ! user_config_prompt; then
                log_warn "User configuration prompt failed, continuing with existing config..."
            fi
        fi
    else
        log_info "DEBUG: User config already complete"
    fi

    log_info "DEBUG: Sorting modules..."
    # Sort modules by execution order
    local sorted_modules=($(module_sort_by_order "${all_modules[@]}"))
    if [[ -z "${sorted_modules[*]}" ]]; then
        log_error "No modules available to install"
        return 1
    fi

    log_info "DEBUG: Starting module installation..."
    # Install all modules
    log_section "MODULE INSTALLATION"

    local installed=0
    local failed=0

    for module in "${sorted_modules[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            log_info "Would install: $(module_get_name "$module")"
            installed=$((installed + 1))
        else
            if module_install "$module"; then
                installed=$((installed + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done

    # Summary
    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        log_summary "DRY_RUN"
    elif [[ $failed -eq 0 ]]; then
        log_summary "SUCCESS"
    else
        log_summary "SUCCESS_WITH_ERRORS"
    fi

    # Next steps
    show_next_steps
}

# =============================================================================
# Maintenance Mode
# =============================================================================

run_maintenance_mode() {
    print_banner

    log_section "MAINTENANCE MODE"

    # Discover modules
    module_discover

    while true; do
        echo ""
        display_maintenance_menu

        read -r choice

        case "$choice" in
            1)
                handle_refresh_all
                ;;
            2)
                handle_update_packages
                ;;
            3)
                handle_reconfigure_module
                ;;
            4)
                handle_remove_module
                ;;
            5)
                handle_show_status
                ;;
            6)
                handle_show_logs
                ;;
            7)
                log_info "Exiting..."
                break
                ;;
            *)
                log_warn "Invalid choice: $choice"
                ;;
        esac
    done

    echo ""
    log_info "Maintenance mode complete"
}

# Maintenance handlers
handle_refresh_all() {
    log_section "REFRESH ALL"

    log_info "Pulling latest dotfiles..."
    bootstrap_clone_repo

    log_info "Reconfiguring all installed modules..."

    local all_modules=($(state_list_installed))

    for module in "${all_modules[@]}"; do
        log_module_start "$module"
        if module_exec "$module" "reconfigure"; then
            log_success "$(module_get_name "$module") reconfigured"
        else
            log_error "$(module_get_name "$module") reconfiguration failed"
        fi
        log_module_end
    done

    log_success "Refresh complete"
}

handle_update_packages() {
    log_section "UPDATE PACKAGES"

    # This would handle Brewfile updates
    log_info "Package updates not yet implemented"
    log_info "Run: brew upgrade"
}

handle_reconfigure_module() {
    log_section "RECONFIGURE MODULE"

    local all_modules=($(module_list_all))

    echo ""
    echo -e "${TEXT}Available modules:${NC}"
    echo ""

    local i=1
    local -a menu_modules=()
    for module in "${all_modules[@]}"; do
        local name=$(module_get_name "$module")
        local status="not installed"

        if state_is_installed "$module"; then
            status="installed"
        fi

        echo -e "  ${INFO}[${i}]${NC} ${TEXT}${name}${NC} ${DIM}(${status})${NC}"
        menu_modules+=("$module")
        ((i++))
    done

    echo ""
    echo -ne "${DIM}Choice [1-${#menu_modules[@]}]:${NC} "
    read -r choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#menu_modules[@]} ]]; then
        local selected_module="${menu_modules[$((choice - 1))]}"

        log_module_start "$selected_module"
        if module_exec "$selected_module" "reconfigure"; then
            log_success "$(module_get_name "$selected_module") reconfigured"
        else
            log_error "Reconfiguration failed"
        fi
        log_module_end
    else
        log_warn "Invalid choice"
    fi
}

handle_remove_module() {
    log_section "REMOVE MODULE"
    log_info "Module removal not yet implemented"
}

handle_show_status() {
    log_section "INSTALLATION STATUS"
    echo ""
    module_display_status
}

handle_show_logs() {
    log_section "LOGS"

    echo ""
    echo -e "${TEXT}Log options:${NC}"
    echo -e "  ${INFO}[1]${NC} ${TEXT}View full log${NC}"
    echo -e "  ${INFO}[2]${NC} ${TEXT}View errors only${NC}"
    echo -e "  ${INFO}[3]${NC} ${TEXT}Tail log (live)${NC}"
    echo ""
    echo -ne "${DIM}Choice [1-3]:${NC} "
    read -r choice

    case "$choice" in
        1) log_show | less ;;
        2) log_show_errors | less ;;
        3) log_tail ;;
        *) log_warn "Invalid choice" ;;
    esac
}

# =============================================================================
# Next Steps Display
# =============================================================================

show_next_steps() {
    echo ""
    echo -e "${SECTION}┌───────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${SECTION}│${NC} ${BRIGHT}Next Steps${NC}                                                        ${SECTION}│${NC}"
    echo -e "${SECTION}├───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${SECTION}│${NC}                                                                   ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC} ${BRIGHT}1.${NC} Restart your terminal or run:                                ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC}    ${INFO}source ~/.zshrc${NC}                                                ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC}                                                                   ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC} ${BRIGHT}2.${NC} View the log:                                                 ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC}    ${INFO}cat ~/.dotfiles/bootstrap.log${NC}                                 ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC}                                                                   ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC} ${BRIGHT}3.${NC} Run bootstrap again for maintenance mode:                     ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC}    ${INFO}cd ~/.dotfiles/repo && ./bootstrap.sh${NC}                         ${SECTION}│${NC}"
    echo -e "${SECTION}│${NC}                                                                   ${SECTION}│${NC}"
    echo -e "${SECTION}└───────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    # Parse arguments first (before loading libs, for --help)
    parse_args "$@"

    # Handle remote installation
    if is_remote_install; then
        # Minimal setup before cloning
        echo "Dotfiles 3.0 - Remote Installation"
        echo ""

        # Create dotfiles home
        mkdir -p "${DOTFILES_HOME}"

        # Clone repository
        echo "Cloning repository..."
        if ! git clone "${DOTFILES_REPO}" "${DOTFILES_REPO_DIR}"; then
            echo "ERROR: Failed to clone repository"
            exit 1
        fi

        # Re-execute from cloned repo
        exec "${DOTFILES_REPO_DIR}/bootstrap.sh" "$@"
    fi

    # Load all libraries
    bootstrap_load_libs

    # Initialize systems
    log_init
    state_init
    detect_os

    # Handle log-viewing actions
    case "$ACTION" in
        show-log)
            log_show
            exit 0
            ;;
        show-errors)
            log_show_errors
            exit 0
            ;;
        clear-log)
            log_clear
            exit 0
            ;;
    esac

    # Determine mode: first run or maintenance
    if state_is_first_run; then
        run_first_time_setup
    else
        # Update metadata
        state_update_metadata

        # Run maintenance mode
        run_maintenance_mode
    fi

    # Cleanup
    kill_sudo_keepalive 2>/dev/null || true
}

# Run main
main "$@"
