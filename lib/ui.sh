#!/usr/bin/env bash
# =============================================================================
# ui.sh - User Interface Functions (Spinners, Menus, Banners)
# =============================================================================

# Source guard - prevent double-sourcing
[[ -n "${_UI_SH_LOADED}" ]] && return 0
_UI_SH_LOADED=1

# Source dependencies if not already loaded
[[ -z "${NORD0}" ]] && source "${HOME}/.dotfiles/repo/lib/colors.sh" 2>/dev/null

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
# Simple Box Drawing
# =============================================================================

# Draw a simple box around text
# Usage: draw_box "Title" "width" "color"
draw_box() {
    local text="$1"
    local width=${2:-71}
    local color=${3:-$HEADER}

    local text_len=${#text}
    local padding=$(( (width - text_len - 4) / 2 ))
    local right_padding=$(( width - text_len - 4 - padding ))

    echo -ne "${color}${BOX_D_TL}"
    printf "%.0s${BOX_D_H}" $(seq 1 $((width - 2)))
    echo -e "${BOX_D_TR}${NC}"

    echo -ne "${color}${BOX_D_V}${NC}"
    printf "%*s" $((padding + 1)) ""
    echo -ne "${BRIGHT}${text}${NC}"
    printf "%*s" $((right_padding + 1)) ""
    echo -e "${color}${BOX_D_V}${NC}"

    echo -ne "${color}${BOX_D_BL}"
    printf "%.0s${BOX_D_H}" $(seq 1 $((width - 2)))
    echo -e "${BOX_D_BR}${NC}"
}

# Draw an error/failure box - single line, fixed width
# Usage: draw_failure_box "module-name"
draw_failure_box() {
    local module="$1"
    local width=62
    local text="FAILED: ${module}"
    local text_len=${#text}
    local padding=$((width - text_len - 4))

    echo -ne "${ERROR}${BOX_D_TL}"
    printf "%.0s${BOX_D_H}" $(seq 1 $((width - 2)))
    echo -e "${BOX_D_TR}${NC}"

    echo -ne "${ERROR}${BOX_D_V}${NC}  ${text}"
    printf "%*s" $((padding + 2)) ""
    echo -e "${ERROR}${BOX_D_V}${NC}"

    echo -ne "${ERROR}${BOX_D_BL}"
    printf "%.0s${BOX_D_H}" $(seq 1 $((width - 2)))
    echo -e "${BOX_D_BR}${NC}"
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
            # Get current boot time for each frame
            #local timestamp=$(format_boot_time 2>/dev/null || echo "[    -.---]")
            local timestamp=""
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
    #local timestamp=$(format_boot_time 2>/dev/null || echo "[    -.---]")
    local timestamp=""

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
    read -r response

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
    local info_text=""
    if [[ -n "${version}" ]]; then
        info_text="v${version}"
    fi
    if [[ -n "${date}" ]]; then
        if [[ -n "${info_text}" ]]; then
            info_text="${info_text}  ${date}"
        else
            info_text="${date}"
        fi
    fi

    # Box border: 69 chars total (┌ + 67 × ─ + ┐)
    # Content line must also be 69 chars (│ + 67 content + │)
    # Content layout: "  ○ module-name (32)              status (30)    "
    # 2 + 1 + 1 + 32 + 1 + 30 = 67 chars between the │ symbols

    local status_info="${status_text}${info_text:+ }${info_text}"
    printf "${SECTION}│${NC}  ${color}${symbol}${NC} %-32s %-30s${SECTION}│${NC}\n" "${module}" "${status_info}"
}

# =============================================================================
# Module List Display
# =============================================================================

# Display a categorized list of modules
# Usage: display_module_list
display_module_list() {
    local width=67

    echo -e "${SECTION}┌$(printf '─%.0s' $(seq 1 $width))┐${NC}"
    echo -e "${SECTION}│${NC} ${BRIGHT}System Setup${NC}$(printf '%*s' $((width - 14)) '')${SECTION}│${NC}"
    echo -e "${SECTION}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"

    # This is a template - actual implementation will load from state files
    display_module_status "xcode-cli" "installed" "15.1" "2024-01-15"
    display_module_status "homebrew" "installed" "4.2.0" "2024-01-15"
    display_module_status "macos-defaults" "pending"

    echo -e "${SECTION}└$(printf '─%.0s' $(seq 1 $width))┘${NC}"
    echo ""

    echo -e "${SECTION}┌$(printf '─%.0s' $(seq 1 $width))┐${NC}"
    echo -e "${SECTION}│${NC} ${BRIGHT}Applications & Tools${NC}$(printf '%*s' $((width - 22)) '')${SECTION}│${NC}"
    echo -e "${SECTION}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"

    display_module_status "brewfile" "update_available" "47 pkgs" "2024-01-20"
    display_module_status "nvchad" "installed" "2.5" "2024-01-15"

    echo -e "${SECTION}└$(printf '─%.0s' $(seq 1 $width))┘${NC}"
    echo ""
}

# =============================================================================
# Maintenance Menu
# =============================================================================

# Display the maintenance mode menu
display_maintenance_menu() {
    echo ""
    draw_box "Maintenance Mode" 71 "${SECTION}"
    echo ""
    echo -e "${TEXT}What would you like to do?${NC}"
    echo ""
    echo -e "  ${INFO}[1]${NC} ${TEXT}Refresh all (pull latest + reconfigure all modules)${NC}"
    echo -e "  ${INFO}[2]${NC} ${TEXT}Update Brewfile packages${NC}"
    echo -e "  ${INFO}[3]${NC} ${TEXT}Reconfigure specific module${NC}"
    echo -e "  ${INFO}[4]${NC} ${TEXT}Remove/uninstall module${NC}"
    echo -e "  ${INFO}[5]${NC} ${TEXT}Show installation status${NC}"
    echo -e "  ${INFO}[6]${NC} ${TEXT}View logs${NC}"
    echo -e "  ${INFO}[7]${NC} ${TEXT}Exit${NC}"
    echo ""
    echo -ne "${DIM}Choice [1-7]:${NC} "
}

# =============================================================================
# First Run Display
# =============================================================================

# Display first-run installation plan
display_first_run() {
    local module_count=$1
    shift
    local modules=("$@")

    echo ""
    draw_box "First Time Setup" 71 "${HEADER}"
    echo ""
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
export -f print_banner draw_box
export -f start_spinner stop_spinner progress_bar
export -f show_menu confirm
export -f display_module_status display_module_list
export -f display_maintenance_menu display_first_run
