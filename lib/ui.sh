#!/usr/bin/env bash
# =============================================================================
# ui.sh - User Interface Functions (Spinners, Menus, Banners)
# =============================================================================

# Source guard - prevent double-sourcing
[[ -n "${_UI_SH_LOADED}" ]] && return 0
_UI_SH_LOADED=1

# Source dependencies if not already loaded
if [[ -z "${NORD0}" ]]; then
    # Determine lib directory
    if [[ -z "${DOTFILES_LIB_DIR}" ]]; then
        _ui_sh_dir=$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)
        if [[ -n "${_ui_sh_dir}" ]] && cd "${_ui_sh_dir}" 2>/dev/null; then
            DOTFILES_LIB_DIR=$(pwd)
            cd - >/dev/null 2>&1
        else
            DOTFILES_LIB_DIR="${HOME}/.dotfiles/repo/lib"
        fi
    fi
    source "${DOTFILES_LIB_DIR}/colors.sh" 2>/dev/null || source "${HOME}/.dotfiles/repo/lib/colors.sh"
fi

# =============================================================================
# ASCII Art Banner
# =============================================================================

print_banner() {
    clear
    echo -e "${HEADER}"
    cat << "EOF"
    ____        __  ____  __          
   / __ \____  / /_/ __(_) /__  _____ 
  / / / / __ \/ __/ /_/ / / _ \/ ___/ 
 / /_/ / /_/ / /_/ __/ / /  __(__  )  
/_____/\____/\__/_/ /_/_/\___/____/   

EOF
    echo -e "${NC}"

    # System info in muted colors
    echo -e "${DIM}  System:${NC} ${TEXT}$(uname -s) $(uname -r) $(uname -m)${NC}"
    echo -e "${DIM}  User:${NC}   ${TEXT}$(whoami)${NC}"
    echo -e "${DIM}  Date:${NC}   ${TEXT}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# =============================================================================
# Simple Header Drawing
# =============================================================================

# Draw a simple header with line
# Usage: draw_header "Title" "color"
draw_header() {
    local text="$1"
    local color=${2:-$HEADER}
    local line_length=60

    echo ""
    echo -e "${color}[ ${BRIGHT}${text}${NC}${color} ]$(printf '%.0s─' $(seq 1 $line_length))${NC}"
    echo ""
}

# =============================================================================
# Spinner Animation
# =============================================================================

# Global spinner state
SPINNER_PID=""
SPINNER_FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

# Start a spinner in the background
# Usage: start_spinner "Loading message"
start_spinner() {
    local message="$1"

    # Spinner animation loop
    {
        local i=0
        while true; do
            local frame="${SPINNER_FRAMES:i++:1}"
            local timestamp=$(format_boot_time 2>/dev/null || echo "[    -.---]")
            printf "\r${DIM}${timestamp}${NC} ${SPINNER}${frame}${NC} ${DIM}${message}${NC}"
            if [ $i -ge ${#SPINNER_FRAMES} ]; then i=0; fi
            sleep 0.1
        done
    } &

    SPINNER_PID=$!
    # Disable job control messages
    disown 2>/dev/null
}

# Stop the spinner
# Usage: stop_spinner
stop_spinner() {
    if [[ -n "${SPINNER_PID}" ]]; then
        kill "${SPINNER_PID}" 2>/dev/null
        wait "${SPINNER_PID}" 2>/dev/null
        printf "\r\033[K"  # Clear the line
        SPINNER_PID=""
    fi
}

# =============================================================================
# Progress Bar
# =============================================================================

# Draw a progress bar
# Usage: progress_bar 50 100 "Installing packages"
progress_bar() {
    local current=$1
    local total=$2
    local message=${3:-"Processing"}
    local width=40

    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    # Build the progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="━"; done
    for ((i=0; i<empty; i++)); do bar+="─"; done

    # Get timestamp
    local timestamp=$(format_boot_time 2>/dev/null || echo "[    -.---]")

    # Print with percentage
    printf "\r${DIM}${timestamp}${NC} ${PROGRESS}[%s]${NC} ${BRIGHT}%3d%%${NC} ${DIM}%s${NC}" "$bar" "$percentage" "$message"

    # New line if complete
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# =============================================================================
# Menu System
# =============================================================================

# Display a numbered menu and get user choice
# Usage: show_menu "Title" option1 option2 option3 ...
# Returns: Selected option number (1-based)
show_menu() {
    local title="$1"
    shift
    local options=("$@")

    echo -e "${SECTION}${BOX_TL}$(printf '%.0s─' {1..69})${BOX_TR}${NC}"
    echo -e "${SECTION}${BOX_V}${NC} ${BRIGHT}${title}${NC}$(printf '%*s' $((68 - ${#title})) '')${SECTION}${BOX_V}${NC}"
    echo -e "${SECTION}${BOX_BL}$(printf '%.0s─' {1..69})${BOX_TR}${NC}"
    echo ""

    local i=1
    for option in "${options[@]}"; do
        echo -e "  ${INFO}[${i}]${NC} ${TEXT}${option}${NC}"
        ((i++))
    done

    echo ""
    echo -ne "${DIM}Choice [1-${#options[@]}]:${NC} "
}

# Display a yes/no prompt
# Usage: confirm "Are you sure?"
# Returns: 0 for yes, 1 for no
confirm() {
    local message="$1"
    local default=${2:-n}  # Default to 'n' if not specified

    if [[ "$default" == "y" ]]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi

    echo -ne "${WARN}${SYMBOL_WARN}${NC} ${TEXT}${message}${NC} ${DIM}${prompt}${NC} "
    read -r response < /dev/tty

    # Convert to lowercase
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    # Check response
    if [[ "$default" == "y" ]]; then
        [[ "$response" != "n" && "$response" != "no" ]]
    else
        [[ "$response" == "y" || "$response" == "yes" ]]
    fi
}

# =============================================================================
# Status Display
# =============================================================================

# Display module status in a formatted list
# Usage: display_module_status "module-name" "status" "version" "date"
# Status can be: installed, pending, failed, update_available
display_module_status() {
    local module="$1"
    local status="$2"
    local version="${3:-}"
    local date="${4:-}"

    local symbol=""
    local color=""
    local status_text=""

    case "$status" in
        installed)
            symbol="${SYMBOL_SUCCESS}"
            color="${SUCCESS}"
            status_text="Installed"
            ;;
        pending)
            symbol="○"
            color="${DIM}"
            status_text="Pending"
            ;;
        failed)
            symbol="${SYMBOL_ERROR}"
            color="${ERROR}"
            status_text="Failed"
            ;;
        update_available)
            symbol="${SYMBOL_SPINNER}"
            color="${WARN}"
            status_text="Update Available"
            ;;
        *)
            symbol="?"
            color="${DIM}"
            status_text="Unknown"
            ;;
    esac

    # Format the line with proper spacing
    # Truncate version to max 8 chars (including 'v' prefix)
    local version_display=""
    if [[ -n "${version}" ]]; then
        if [[ ${#version} -gt 6 ]]; then
            version_display="v${version:0:4}.."
        else
            version_display="v${version}"
        fi
    fi

    # Truncate date to 5 chars (MM-DD format)
    local date_display=""
    if [[ -n "${date}" ]]; then
        # Extract month and day from YYYY-MM-DD
        date_display="${date:5:5}"
    fi

    # Build info_text with truncated values
    # Max: status(9) + space(1) + version(8) + space(1) + date(5) = 24 chars
    local info_text=""
    if [[ -n "${version_display}" ]]; then
        info_text="${version_display}"
    fi
    if [[ -n "${date_display}" ]]; then
        if [[ -n "${info_text}" ]]; then
            info_text="${info_text} ${date_display}"
        else
            info_text="${date_display}"
        fi
    fi

    # Simple list format without boxes
    local status_info="${status_text}${info_text:+ }${info_text}"
    printf "  ${color}${symbol}${NC} %-24s ${DIM}%-30s${NC}\n" "${module}" "${status_info}"
}

# =============================================================================
# Module List Display
# =============================================================================

# Display a categorized list of modules
# Usage: display_module_list
display_module_list() {
    echo ""
    echo -e "${SECTION}[ ${BRIGHT}System Setup${NC}${SECTION} ]$(printf '%.0s─' {1..60})${NC}"
    echo ""

    # This is a template - actual implementation will load from state files
    display_module_status "xcode-cli" "installed" "15.1" "2024-01-15"
    display_module_status "homebrew" "installed" "4.2.0" "2024-01-15"
    display_module_status "macos-defaults" "pending"

    echo ""
    echo -e "${SECTION}[ ${BRIGHT}Applications & Tools${NC}${SECTION} ]$(printf '%.0s─' {1..60})${NC}"
    echo ""

    display_module_status "brewfile" "update_available" "47 pkgs" "2024-01-20"
    display_module_status "nvchad" "installed" "2.5" "2024-01-15"

    echo ""
}

# =============================================================================
# Maintenance Menu
# =============================================================================

# Display the maintenance mode menu
display_maintenance_menu() {
    draw_header "MAINTENANCE MODE" "${SECTION}"
    echo -e "${TEXT}What would you like to do?${NC}"
    echo ""
    echo -e "  ${INFO}[1]${NC} ${TEXT}Install module${NC}"
    echo -e "  ${INFO}[2]${NC} ${TEXT}Uninstall module${NC}"
    echo -e "  ${INFO}[3]${NC} ${TEXT}Update Homebrew packages${NC}"
    echo -e "  ${INFO}[4]${NC} ${TEXT}Update dotfiles repository${NC}"
    echo -e "  ${INFO}[5]${NC} ${TEXT}Show installation status${NC}"
    echo -e "  ${INFO}[6]${NC} ${TEXT}View logs${NC}"
    echo -e "  ${INFO}[0]${NC} ${TEXT}Exit${NC}"
    echo ""
    echo -ne "${DIM}Choice [0-6]:${NC} "
}

# =============================================================================
# First Run Display
# =============================================================================

# Display first-run installation plan
display_first_run() {
    local module_count=$1
    shift
    local modules=("$@")

    draw_header "FIRST TIME SETUP" "${HEADER}"
    echo -e "${TEXT}This appears to be your first run.${NC}"
    echo -e "${TEXT}The following ${BOLD}${module_count} modules${NC}${TEXT} will be installed:${NC}"
    echo ""

    # Display modules (this will be dynamic based on discovered modules)
    for module in "${modules[@]}"; do
        display_module_status "$module" "pending"
    done

    echo ""
    echo -e "${DIM}Legend: ${SUCCESS}${SYMBOL_SUCCESS}${NC}${DIM} Installed  ○ Pending  ${ERROR}${SYMBOL_ERROR}${NC}${DIM} Failed  ${WARN}${SYMBOL_SPINNER}${NC}${DIM} Update Available${NC}"
    echo ""
    echo -ne "${TEXT}Press ${BOLD}ENTER${NC}${TEXT} to begin installation or ${BOLD}Ctrl+C${NC}${TEXT} to cancel${NC} "
}

# =============================================================================
# Export Functions
# =============================================================================
export -f print_banner draw_header
export -f start_spinner stop_spinner progress_bar
export -f show_menu confirm
export -f display_module_status display_module_list
export -f display_maintenance_menu display_first_run
