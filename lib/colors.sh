#!/usr/bin/env bash
# =============================================================================
# colors.sh - Nord Theme Color Definitions
# =============================================================================
# Nord color palette - muted, professional, easy on the eyes
# https://www.nordtheme.com/

# Set the lib directory location for other lib files to use
if [[ -z "${DOTFILES_LIB_DIR}" ]]; then
    DOTFILES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
    if [[ -z "${DOTFILES_LIB_DIR}" ]]; then
        DOTFILES_LIB_DIR="${HOME}/.dotfiles/repo/lib"
    fi
    export DOTFILES_LIB_DIR
fi

# =============================================================================
# Nord Palette
# =============================================================================
# Polar Night (dark)
NORD0='\033[38;5;236m'   # #2E3440
NORD1='\033[38;5;237m'   # #3B4252
NORD2='\033[38;5;239m'   # #434C5E
NORD3='\033[38;5;243m'   # #4C566A

# Snow Storm (light)
NORD4='\033[38;5;250m'   # #D8DEE9
NORD5='\033[38;5;252m'   # #E5E9F0
NORD6='\033[38;5;255m'   # #ECEFF4

# Frost (blues/teals)
NORD7='\033[38;5;109m'   # #8FBCBB - teal
NORD8='\033[38;5;110m'   # #88C0D0 - cyan
NORD9='\033[38;5;67m'    # #81A1C1 - blue
NORD10='\033[38;5;68m'   # #5E81AC - dark blue

# Aurora (accent colors)
NORD11='\033[38;5;131m'  # #BF616A - red
NORD12='\033[38;5;173m'  # #D08770 - orange
NORD13='\033[38;5;214m'  # #EBCB8B - yellow
NORD14='\033[38;5;108m'  # #A3BE8C - green
NORD15='\033[38;5;139m'  # #B48EAD - purple

# =============================================================================
# Functional Color Assignments (Nord Theme)
# =============================================================================
# Headers and titles
HEADER="${NORD9}"              # Nord blue
TITLE='\033[1m'${NORD6}        # Bold snow storm

# Status colors
SUCCESS="${NORD14}"            # Nord green
INFO="${NORD8}"                # Nord cyan
WARN="${NORD12}"               # Nord orange
ERROR="${NORD11}"              # Nord red

# UI Elements
SPINNER="${NORD7}"             # Nord teal
SECTION="${NORD15}"            # Nord purple
PROGRESS="${NORD8}"            # Nord cyan
DIM="${NORD3}"                 # Dark gray

# Text
TEXT="${NORD4}"                # Light gray
BRIGHT='\033[1m'${NORD6}       # Bold white
MUTED="${NORD3}"               # Muted gray

# Special formatting
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
NC='\033[0m'                   # No Color / Reset

# =============================================================================
# Box Drawing Characters
# =============================================================================
# Single line
BOX_TL='┌'  # Top-left
BOX_TR='┐'  # Top-right
BOX_BL='└'  # Bottom-left
BOX_BR='┘'  # Bottom-right
BOX_H='─'   # Horizontal
BOX_V='│'   # Vertical

# Double line
BOX_D_TL='╔'  # Top-left
BOX_D_TR='╗'  # Top-right
BOX_D_BL='╚'  # Bottom-left
BOX_D_BR='╝'  # Bottom-right
BOX_D_H='═'   # Horizontal
BOX_D_V='║'   # Vertical

# Heavy line
BOX_H_TL='┏'  # Top-left
BOX_H_TR='┓'  # Top-right
BOX_H_BL='┗'  # Bottom-left
BOX_H_BR='┛'  # Bottom-right
BOX_H_H='━'   # Horizontal
BOX_H_V='┃'   # Vertical

# =============================================================================
# Status Symbols
# =============================================================================
SYMBOL_SUCCESS='✓'
SYMBOL_ERROR='✗'
SYMBOL_WARN='⚠'
SYMBOL_INFO='▸'
SYMBOL_SPINNER='⟳'
SYMBOL_ARROW='→'
SYMBOL_BULLET='•'
SYMBOL_CHECK='◆'

# =============================================================================
# Helper Functions
# =============================================================================

# Strip ANSI color codes from string (for length calculation)
strip_ansi() {
    echo -e "$1" | sed -E 's/\x1b\[[0-9;]*m//g'
}

# Get visual length of string (without ANSI codes)
visual_length() {
    local stripped=$(strip_ansi "$1")
    echo "${#stripped}"
}

# Color test function - displays all Nord colors
color_test() {
    echo -e "\n${BOLD}${NORD6}Nord Color Palette Test${NC}\n"

    echo -e "${NORD0}NORD0 - Polar Night 0${NC}"
    echo -e "${NORD1}NORD1 - Polar Night 1${NC}"
    echo -e "${NORD2}NORD2 - Polar Night 2${NC}"
    echo -e "${NORD3}NORD3 - Polar Night 3${NC}"
    echo ""
    echo -e "${NORD4}NORD4 - Snow Storm 0${NC}"
    echo -e "${NORD5}NORD5 - Snow Storm 1${NC}"
    echo -e "${NORD6}NORD6 - Snow Storm 2${NC}"
    echo ""
    echo -e "${NORD7}NORD7 - Frost Teal${NC}"
    echo -e "${NORD8}NORD8 - Frost Cyan${NC}"
    echo -e "${NORD9}NORD9 - Frost Blue${NC}"
    echo -e "${NORD10}NORD10 - Frost Dark Blue${NC}"
    echo ""
    echo -e "${NORD11}NORD11 - Aurora Red${NC}"
    echo -e "${NORD12}NORD12 - Aurora Orange${NC}"
    echo -e "${NORD13}NORD13 - Aurora Yellow${NC}"
    echo -e "${NORD14}NORD14 - Aurora Green${NC}"
    echo -e "${NORD15}NORD15 - Aurora Purple${NC}"
    echo ""

    echo -e "${BOLD}Functional Colors:${NC}"
    echo -e "${SUCCESS}${SYMBOL_SUCCESS}${NC} SUCCESS - Success messages"
    echo -e "${INFO}${SYMBOL_INFO}${NC} INFO - Informational messages"
    echo -e "${WARN}${SYMBOL_WARN}${NC} WARN - Warning messages"
    echo -e "${ERROR}${SYMBOL_ERROR}${NC} ERROR - Error messages"
    echo -e "${SPINNER}${SYMBOL_SPINNER}${NC} SPINNER - Loading indicator"
    echo -e "${SECTION}━━━━${NC} SECTION - Section dividers"
    echo ""
}

# Export all colors and symbols
export NORD0 NORD1 NORD2 NORD3 NORD4 NORD5 NORD6 NORD7 NORD8 NORD9 NORD10
export NORD11 NORD12 NORD13 NORD14 NORD15
export HEADER TITLE SUCCESS INFO WARN ERROR SPINNER SECTION PROGRESS DIM
export TEXT BRIGHT MUTED BOLD ITALIC UNDERLINE NC
export BOX_TL BOX_TR BOX_BL BOX_BR BOX_H BOX_V
export BOX_D_TL BOX_D_TR BOX_D_BL BOX_D_BR BOX_D_H BOX_D_V
export BOX_H_TL BOX_H_TR BOX_H_BL BOX_H_BR BOX_H_H BOX_H_V
export SYMBOL_SUCCESS SYMBOL_ERROR SYMBOL_WARN SYMBOL_INFO SYMBOL_SPINNER
export SYMBOL_ARROW SYMBOL_BULLET SYMBOL_CHECK
