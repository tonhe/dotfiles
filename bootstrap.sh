#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh - Dotfiles 2.0 Bootstrap Script
# =============================================================================
# Description: Sets up a fresh macOS or Linux machine from scratch
# OS Support: macOS (Darwin) and Linux
# Run with:
#   curl -fsSL https://raw.githubusercontent.com/YOURUSERNAME/dotfiles/main/bootstrap.sh | bash
# Or clone the repo and run: ./bootstrap.sh
#
# Options:
#   --dry-run    Preview what would be installed without making changes
#   --preview    Same as --dry-run
#   --help       Show this help message
# =============================================================================

set -e

DOTFILES_REPO="https://github.com/tonhe/dotfiles.git"
START_TIME=$(date +%s)
DRY_RUN=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --dry-run|--preview)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Dotfiles 2.0 Bootstrap Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run, --preview    Preview what would be installed without making changes"
            echo "  --help, -h              Show this help message"
            echo ""
            exit 0
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# =============================================================================
# Colors & Formatting
# =============================================================================
# Standard colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bold colors
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;97m'

# Background colors
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'

# Special formatting
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
NC='\033[0m' # No Color / Reset

# Unicode box drawing characters
BOX_TL='╔'  # Top-left
BOX_TR='╗'  # Top-right
BOX_BL='╚'  # Bottom-left
BOX_BR='╝'  # Bottom-right
BOX_H='═'   # Horizontal
BOX_V='║'   # Vertical
BOX_VR='╠'  # Vertical-right (left edge)
BOX_VL='╣'  # Vertical-left (right edge)
BOX_HU='╩'  # Horizontal-up (bottom edge)
BOX_HD='╦'  # Horizontal-down (top edge)

# Progress tracking
TOTAL_STEPS=0
CURRENT_STEP=0

# Summary tracking
declare -a INSTALLED_ITEMS=()
declare -a SKIPPED_ITEMS=()
declare -a FAILED_ITEMS=()

# =============================================================================
# Box Drawing Helpers
# =============================================================================

# Single-line centered box
# Usage: print_box "message" "border_color" ["width"]
# Note: Message should be plain text, colors will be added by the function
print_box() {
    local message=$1
    local border_color=${2:-$CYAN}
    local width=${3:-71}

    # Get actual message length (plain text)
    local message_length=${#message}

    # Calculate padding
    local total_padding=$((width - message_length - 2))  # -2 for the borders
    local left_padding=$((total_padding / 2))
    local right_padding=$((total_padding - left_padding))

    # Top border
    echo -ne "${border_color}┌"
    printf '─%.0s' $(seq 1 $((width - 2)))
    echo -e "┐${NC}"

    # Content line with padding
    echo -ne "${border_color}│${NC}"
    printf '%*s' "$left_padding" ""
    echo -ne "${BOLD_WHITE}${message}${NC}"
    printf '%*s' "$right_padding" ""
    echo -e "${border_color}│${NC}"

    # Bottom border
    echo -ne "${border_color}└"
    printf '─%.0s' $(seq 1 $((width - 2)))
    echo -e "┘${NC}"
}

# Multi-line info box with key-value pairs
# Usage: print_info_box "Key1:Value1" "Key2:Value2" ...
print_info_box() {
    local width=71
    local border_color="${DIM}${CYAN}"

    # Top border
    echo -ne "${border_color}┌"
    printf '─%.0s' $(seq 1 $((width - 2)))
    echo -e "┐${NC}"

    # Print each line
    for line in "$@"; do
        printf "${border_color}│${NC} %-$((width - 4))s ${border_color}│${NC}\n" "$line"
    done

    # Bottom border
    echo -ne "${border_color}└"
    printf '─%.0s' $(seq 1 $((width - 2)))
    echo -e "┘${NC}"
}

# Helper to draw a box border with title in the middle
# Usage: print_box_header "Title" "$COLOR"
print_box_header() {
    local title=$1
    local border_color=$2
    local width=71
    local title_length=${#title}

    # Calculate padding around title
    local border_chars=$((width - 2 - title_length - 2))
    local left_chars=$((border_chars / 2))
    local right_chars=$((border_chars - left_chars))

    echo -ne "${border_color}${BOX_TL}"
    printf "${BOX_H}%.0s" $(seq 1 $left_chars)
    echo -ne " ${title} "
    printf "${BOX_H}%.0s" $(seq 1 $right_chars)
    echo -e "${BOX_TR}${NC}"
}

# Helper to draw a full-width box border
# Usage: print_box_border "top" "$COLOR" or print_box_border "bottom" "$COLOR"
print_box_border() {
    local border_type=$1
    local border_color=$2
    local width=71

    if [[ "$border_type" == "top" ]]; then
        echo -ne "${border_color}${BOX_TL}"
        printf "${BOX_H}%.0s" $(seq 1 $((width - 2)))
        echo -e "${BOX_TR}${NC}"
    else
        echo -ne "${border_color}${BOX_BL}"
        printf "${BOX_H}%.0s" $(seq 1 $((width - 2)))
        echo -e "${BOX_BR}${NC}"
    fi
}

# Helper to print a box line with content (left-aligned)
# Usage: print_box_line "content with ${COLORS}" "$BORDER_COLOR"
print_box_line() {
    local content=$1
    local border_color=$2
    local width=71

    # Strip ANSI codes to calculate actual visual length
    local visual_content=$(echo -e "$content" | sed -E 's/\x1b\[[0-9;]*m//g')
    local content_length=${#visual_content}
    local padding=$((width - 4 - content_length))

    echo -ne "${border_color}${BOX_V}${NC} ${content}"
    printf '%*s' "$((padding + 1))" ""
    echo -e "${border_color}${BOX_V}${NC}"
}

# =============================================================================
# ASCII Art Banner
# =============================================================================
print_banner() {
    clear
    echo -e "${BOLD_CYAN}"
    cat << "EOF"
    ____        __  ____  __
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  )
/_____/\____/\__/_/ /_/_/\___/____/

    ___            __      __                   ___   ____
   / _ )___  ___  / /____ / /________ ____     |__ \ / __ \
  / _  / _ \/ _ \/ __(_-</ __/ __/ _ `/ _ \    __/ // / / /
 /____/\___/\___/\__/___/\__/_/  \_,_/ .__/   / __// /_/ /
                                    /_/      /___(_)____/
EOF
    echo -e "${NC}"

    # Dry run mode indicator
    if [[ "$DRY_RUN" == true ]]; then
        print_box "⚠  DRY RUN MODE - NO CHANGES WILL BE MADE  ⚠" "$BOLD_YELLOW" 71
        echo ""
    fi

    # System info
    if [[ "$DRY_RUN" == true ]]; then
        print_info_box \
            "System: $(uname -s) $(uname -m)" \
            "User: $(whoami)" \
            "Date: $(date '+%Y-%m-%d %H:%M:%S')" \
            "Mode: Preview (--dry-run)"
    else
        print_info_box \
            "System: $(uname -s) $(uname -m)" \
            "User: $(whoami)" \
            "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    echo ""
}

# =============================================================================
# Logging Functions
# =============================================================================
print_step() {
    ((++CURRENT_STEP))
    echo ""
    print_box_border "top" "$BOLD_MAGENTA"
    print_box_line "${BOLD_WHITE}STEP ${CURRENT_STEP}/${TOTAL_STEPS}:${NC} ${BOLD_CYAN}$1${NC}" "$BOLD_MAGENTA"
    print_box_border "bottom" "$BOLD_MAGENTA"
    echo ""
}

info() {
    echo -e "  ${BOLD_CYAN}▸${NC} $1"
}

success() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${BOLD_BLUE}◆${NC} ${DIM}Would install:${NC} $1"
    else
        echo -e "  ${BOLD_GREEN}✓${NC} $1"
    fi
    INSTALLED_ITEMS+=("$1")
}

# For items that are already present/installed (doesn't count toward statistics)
already_installed() {
    echo -e "  ${BOLD_GREEN}✓${NC} $1 ${DIM}(already installed)${NC}"
}

# For items skipped in dry-run (doesn't count toward statistics)
skipped() {
    echo -e "  ${DIM}${CYAN}○${NC} ${DIM}$1${NC}"
}

warn() {
    echo -e "  ${BOLD_YELLOW}⚠${NC} $1"
    SKIPPED_ITEMS+=("$1")
}

error() {
    echo -e "  ${BOLD_RED}✗${NC} $1"
    FAILED_ITEMS+=("$1")
    exit 1
}

# =============================================================================
# Progress Bar
# =============================================================================
# Usage: progress_bar 50 100 "Installing packages"
progress_bar() {
    local current=$1
    local total=$2
    local message=$3
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    # Build the progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    # Print with percentage
    printf "\r  ${BOLD_BLUE}[${GREEN}%s${BLUE}]${NC} ${BOLD_WHITE}%3d%%${NC} ${DIM}%s${NC}" "$bar" "$percentage" "$message"

    # New line if complete
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# =============================================================================
# Spinner Animation
# =============================================================================
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    echo -n "  "
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "${BOLD_CYAN}%c${NC} ${DIM}%s${NC}" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "    \r"  # Clear the line
}

# =============================================================================
# Animated Dots
# =============================================================================
show_loading() {
    local message=$1
    local max_dots=3
    local counter=0

    while true; do
        dots=""
        for ((i=0; i<counter; i++)); do dots+="."; done
        printf "\r  ${BOLD_CYAN}▸${NC} ${message}${dots}   "
        counter=$(((counter + 1) % (max_dots + 1)))
        sleep 0.5
    done
}

kill_loading() {
    if [ ! -z "$LOADING_PID" ]; then
        kill $LOADING_PID 2>/dev/null
        wait $LOADING_PID 2>/dev/null
        printf "\r"
        LOADING_PID=""
    fi
    return 0  # Always return success to avoid set -e issues
}

# =============================================================================
# OS Detection
# =============================================================================
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            OS_ICON="macOS"
            info "Detected ${BOLD_GREEN}macOS${NC} (Darwin)"
            ;;
        Linux)
            OS="linux"
            OS_ICON="Linux"
            info "Detected ${BOLD_GREEN}Linux${NC}"

            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO=$ID
                info "Distribution: ${BOLD_CYAN}$NAME${NC}"
            else
                DISTRO="unknown"
                warn "Could not detect Linux distribution"
            fi
            ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            ;;
    esac
}

# =============================================================================
# macOS: Xcode Command Line Tools
# =============================================================================
install_xcode_cli() {
    info "Checking for Xcode Command Line Tools..."

    if xcode-select -p &>/dev/null; then
        already_installed "Xcode Command Line Tools"
    else
        if [[ "$DRY_RUN" == true ]]; then
            success "Xcode Command Line Tools"
        else
            info "Installing Xcode Command Line Tools..."

            # Start background process
            xcode-select --install &
            local install_pid=$!

            # Show spinner while waiting
            spinner $install_pid "Installing Xcode CLI Tools"

            # Wait for installation to complete
            until xcode-select -p &>/dev/null; do
                sleep 5
            done
            success "Xcode Command Line Tools installed"
        fi
    fi
}

# =============================================================================
# macOS: Homebrew
# =============================================================================
install_homebrew() {
    info "Checking for Homebrew..."

    # Check if Homebrew is actually installed (check filesystem, not just PATH)
    local brew_path=""
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon location
        brew_path="/opt/homebrew/bin/brew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        # Intel Mac location
        brew_path="/usr/local/bin/brew"
    fi

    if [[ -n "$brew_path" ]]; then
        already_installed "Homebrew"

        # Make sure it's in PATH for this session
        if ! command -v brew &>/dev/null; then
            eval "$($brew_path shellenv)"
        fi

        # Don't update during bootstrap - can be slow and isn't critical
        # Brewfile installation will work fine with existing brew version
    else
        if [[ "$DRY_RUN" == true ]]; then
            success "Homebrew package manager"
        else
            info "Installing Homebrew..."

            # Install in background so we can show progress
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &
            local brew_pid=$!

            spinner $brew_pid "Installing Homebrew"
            wait $brew_pid

            # Add Homebrew to PATH for this session and future sessions
            if [[ $(uname -m) == "arm64" ]]; then
                brew_path="/opt/homebrew/bin/brew"
            else
                brew_path="/usr/local/bin/brew"
            fi

            # Add to shell profile if not already there
            if ! grep -q "brew shellenv" "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$($brew_path shellenv)"' >> "$HOME/.zprofile"
            fi
            eval "$($brew_path shellenv)"

            success "Homebrew installed"
        fi
    fi
}

# =============================================================================
# Linux: Package Manager Check
# =============================================================================
check_linux_package_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"
        PKG_UPDATE="sudo apt-get update"
        PKG_INSTALL="sudo apt-get install -y"
        success "Found package manager: ${BOLD_CYAN}apt${NC}"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="sudo dnf check-update"
        PKG_INSTALL="sudo dnf install -y"
        success "Found package manager: ${BOLD_CYAN}dnf${NC}"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="sudo yum check-update"
        PKG_INSTALL="sudo yum install -y"
        success "Found package manager: ${BOLD_CYAN}yum${NC}"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        PKG_UPDATE="sudo pacman -Sy"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        success "Found package manager: ${BOLD_CYAN}pacman${NC}"
    else
        error "No supported package manager found (apt, dnf, yum, or pacman)"
    fi
}

# =============================================================================
# Chezmoi Installation
# =============================================================================
install_chezmoi() {
    info "Checking for chezmoi..."

    if command -v chezmoi &>/dev/null; then
        already_installed "chezmoi"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        success "chezmoi (dotfiles manager)"
        return
    fi

    info "Installing chezmoi..."

    if [[ "$OS" == "macos" ]]; then
        # Install via Homebrew on macOS
        brew install chezmoi &>/dev/null
    elif [[ "$OS" == "linux" ]]; then
        # Install via package manager or install script on Linux
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            # For Debian/Ubuntu, use the install script (more up-to-date)
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" &>/dev/null

            # Add to PATH if not already there
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                export PATH="$HOME/.local/bin:$PATH"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            fi
        else
            # Try package manager first, fall back to install script
            $PKG_INSTALL chezmoi &>/dev/null || sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" &>/dev/null
        fi
    fi

    success "chezmoi installed"
}

# =============================================================================
# Initialize Dotfiles with Chezmoi
# =============================================================================
init_dotfiles() {
    # Check if chezmoi is already initialized with a valid git repo
    if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
        warn "Chezmoi already initialized, updating..."

        if [[ "$DRY_RUN" == false ]]; then
            show_loading "Updating dotfiles" &
            LOADING_PID=$!
            chezmoi update &>/dev/null
            kill_loading
            success "Dotfiles updated"
        fi
    else
        # If directory exists but isn't a git repo, remove it first
        if [[ -d "$HOME/.local/share/chezmoi" ]] && [[ "$DRY_RUN" == false ]]; then
            info "Removing empty chezmoi directory..."
            rm -rf "$HOME/.local/share/chezmoi"
        fi

        info "Initializing dotfiles from ${BOLD_CYAN}${DOTFILES_REPO}${NC}"

        if [[ "$DRY_RUN" == true ]]; then
            success "Clone and apply dotfiles from repository"
        else
            # First, just initialize (clone the repo)
            info "Cloning dotfiles repository..."
            if ! chezmoi init "$DOTFILES_REPO"; then
                error "Failed to clone dotfiles repository from ${DOTFILES_REPO}"
            fi
            success "Dotfiles repository cloned"

            # Then apply the dotfiles
            info "Applying dotfiles to home directory..."
            echo ""

            # Run chezmoi apply with verbose output so user can see what's happening
            if ! chezmoi apply --verbose; then
                echo ""
                warn "Some dotfiles could not be applied. You may need to run 'chezmoi apply' manually."
            else
                echo ""
                success "Dotfiles applied successfully"
            fi
        fi
    fi
}

# =============================================================================
# macOS: Install Brewfile packages
# =============================================================================
install_brew_packages() {
    local brewfile

    # In dry-run mode, look for Brewfile in current directory
    if [[ "$DRY_RUN" == true ]]; then
        if [[ -f "$(dirname "$0")/Brewfile" ]]; then
            brewfile="$(dirname "$0")/Brewfile"
        elif [[ -f "$HOME/.local/share/chezmoi/Brewfile" ]]; then
            brewfile="$HOME/.local/share/chezmoi/Brewfile"
        else
            info "Looking for Brewfile in current directory or chezmoi source..."
            warn "No Brewfile found"
            return
        fi
    else
        # After initialization, use chezmoi source directory
        brewfile="$HOME/.local/share/chezmoi/Brewfile"

        if [[ ! -f "$brewfile" ]]; then
            warn "No Brewfile found at $brewfile"
            return
        fi
    fi

    # Count total packages for progress bar
    local total=$(grep -c "^brew\|^cask\|^mas" "$brewfile" || echo "0")

    if [[ "$DRY_RUN" == true ]]; then
        info "Would install ${total} packages from Brewfile:"
        # Show a sample of what would be installed
        grep "^brew\|^cask\|^mas" "$brewfile" | head -10 | while IFS= read -r line; do
            echo -e "  ${DIM}${CYAN}▸${NC} ${DIM}$line${NC}"
        done
        if [ "$total" -gt 10 ]; then
            echo -e "  ${DIM}${CYAN}▸${NC} ${DIM}... and $((total - 10)) more${NC}"
        fi
        success "Brewfile packages (${total} packages)"
        return
    fi

    info "Installing packages from Brewfile..."

    local current=0

    # Install with progress
    brew bundle --file="$brewfile" 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ "Installing" ]] || [[ "$line" =~ "Using" ]]; then
            ((current++))
            progress_bar $current $total "Installing Homebrew packages"
        fi
    done

    # Ensure progress reaches 100%
    progress_bar $total $total "Installing Homebrew packages"
    success "Brewfile packages installed (${total} packages)"
}

# =============================================================================
# Linux: Install packages from package list
# =============================================================================
install_linux_packages() {
    local package_file="$HOME/.local/share/chezmoi/Aptfile"

    if [[ ! -f "$package_file" ]]; then
        # In dry-run, show what would happen even without the file
        if [[ "$DRY_RUN" == true ]]; then
            info "Would look for Aptfile at: $package_file"
        fi
        warn "No Aptfile found at $package_file"
        info "You may need to install packages manually"
        return
    fi

    # Count packages
    local total=$(grep -v "^#\|^$" "$package_file" | wc -l)

    if [[ "$DRY_RUN" == true ]]; then
        info "Would install ${total} packages from Aptfile:"
        # Show a sample of what would be installed
        grep -v "^#\|^$" "$package_file" | head -10 | while IFS= read -r package; do
            [[ -z "$package" ]] && continue
            echo -e "  ${DIM}${CYAN}▸${NC} ${DIM}$package${NC}"
        done
        if [ "$total" -gt 10 ]; then
            echo -e "  ${DIM}${CYAN}▸${NC} ${DIM}... and $((total - 10)) more${NC}"
        fi
        success "Aptfile packages (${total} packages)"
        return
    fi

    info "Installing packages from Aptfile..."

    local current=0
    local failed=0

    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue

        ((current++))
        progress_bar $current $total "Installing: $package"

        if ! $PKG_INSTALL "$package" &>/dev/null; then
            ((failed++))
        fi
    done < "$package_file"

    if [ $failed -eq 0 ]; then
        success "All packages installed (${total} packages)"
    else
        warn "${failed} packages failed to install, check logs"
    fi
}

# =============================================================================
# Summary Report
# =============================================================================
print_summary() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))

    echo ""
    echo ""

    # Completion box
    if [[ "$DRY_RUN" == true ]]; then
        print_box_border "top" "$BOLD_BLUE"
        print_box_line " ${BOLD_WHITE}DRY RUN PREVIEW COMPLETE!${NC}  ${OS_ICON}" "$BOLD_BLUE"
        print_box_border "bottom" "$BOLD_BLUE"
    else
        print_box_border "top" "$BOLD_GREEN"
        print_box_line " ${BOLD_WHITE}INSTALLATION COMPLETE!${NC}  ${OS_ICON}" "$BOLD_GREEN"
        print_box_border "bottom" "$BOLD_GREEN"
    fi
    echo ""

    # Time elapsed
    echo -e "${BOLD_CYAN}  Time Elapsed:${NC} ${minutes}m ${seconds}s"
    echo ""

    # Next steps box
    print_box_header "Next Steps" "$BOLD_CYAN"
    print_box_line "" "$BOLD_CYAN"

    if [[ "$DRY_RUN" == true ]]; then
        print_box_line " ${BOLD_WHITE}1.${NC} Run without --dry-run to perform actual installation:" "$BOLD_CYAN"
        print_box_line "    ${CYAN}./bootstrap.sh${NC}" "$BOLD_CYAN"
        print_box_line "" "$BOLD_CYAN"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        local step_num="2"
    else
        local step_num="1"
    fi
    print_box_line " ${BOLD_WHITE}${step_num}.${NC} Restart your terminal or run:" "$BOLD_CYAN"

    if [[ "$OS" == "macos" ]]; then
        print_box_line "    ${CYAN}source ~/.zshrc${NC}" "$BOLD_CYAN"
    else
        print_box_line "    ${CYAN}source ~/.bashrc${NC} or ${CYAN}source ~/.zshrc${NC}" "$BOLD_CYAN"
    fi

    print_box_line "" "$BOLD_CYAN"

    if [[ "$DRY_RUN" == true ]]; then
        step_num="3"
    else
        step_num="2"
    fi
    print_box_line " ${BOLD_WHITE}${step_num}.${NC} Review pending changes:" "$BOLD_CYAN"
    print_box_line "    ${CYAN}chezmoi diff${NC}" "$BOLD_CYAN"
    print_box_line "" "$BOLD_CYAN"

    if [[ "$DRY_RUN" == true ]]; then
        step_num="4"
    else
        step_num="3"
    fi
    print_box_line " ${BOLD_WHITE}${step_num}.${NC} Apply any remaining changes:" "$BOLD_CYAN"
    print_box_line "    ${CYAN}chezmoi apply${NC}" "$BOLD_CYAN"
    print_box_line "" "$BOLD_CYAN"
    print_box_border "bottom" "$BOLD_CYAN"
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        if [[ "$OS" == "macos" ]]; then
            warn "You may need to ${BOLD_YELLOW}restart your Mac${NC} for all changes to take effect"
        else
            warn "You may need to ${BOLD_YELLOW}log out and back in${NC} for all changes to take effect"
        fi
    fi

    echo ""
    echo -e "${DIM}${CYAN}Thank you for using Dotfiles 2.0!${NC}"
    echo ""
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_banner

    # Detect OS and set total steps
    detect_os

    if [[ "$OS" == "macos" ]]; then
        TOTAL_STEPS=7
    else
        TOTAL_STEPS=6
    fi

    # Separator
    echo ""
    echo -e "${DIM}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Step 1: OS Detection
    print_step "Operating System Detection"
    # Already done in detect_os() above

    # Step 2: Sudo access
    print_step "Requesting Administrative Access"
    if [[ "$DRY_RUN" == true ]]; then
        skipped "Sudo access check (skipped in dry-run)"
    else
        info "Requesting sudo access..."
        sudo -v
        success "Sudo access granted"

        # Keep sudo alive
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi

    # Platform-specific steps
    if [[ "$OS" == "macos" ]]; then
        # macOS-specific setup
        print_step "Installing Xcode Command Line Tools"
        install_xcode_cli

        print_step "Installing Homebrew Package Manager"
        install_homebrew

        print_step "Installing Chezmoi"
        install_chezmoi

        print_step "Initializing Dotfiles"
        init_dotfiles

        print_step "Installing Brewfile Packages"
        install_brew_packages

    elif [[ "$OS" == "linux" ]]; then
        # Linux-specific setup
        print_step "Detecting Package Manager"
        check_linux_package_manager

        if [[ "$DRY_RUN" == false ]]; then
            info "Updating package database..."
            show_loading "Running package manager update" &
            LOADING_PID=$!
            $PKG_UPDATE &>/dev/null || true
            kill_loading
            success "Package database updated"
        else
            skipped "Package database update (skipped in dry-run)"
        fi

        print_step "Installing Chezmoi"
        install_chezmoi

        print_step "Initializing Dotfiles"
        init_dotfiles

        print_step "Installing Linux Packages"
        install_linux_packages
    fi

    # Summary
    print_summary
}

# Cleanup on exit
trap 'kill_loading' EXIT

# Run main function
main "$@"
