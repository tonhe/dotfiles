#!/usr/bin/env bash
# =============================================================================
# state.sh - State Management System
# =============================================================================
# Manages module installation state, metadata, and configuration

# Source dependencies if not already loaded
if [[ -z "${NORD0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/colors.sh"
    source "${SCRIPT_DIR}/utils.sh"
fi

# =============================================================================
# Configuration
# =============================================================================
DOTFILES_HOME="${DOTFILES_HOME:-${HOME}/.dotfiles}"
STATE_DIR="${DOTFILES_HOME}/state"
METADATA_FILE="${DOTFILES_HOME}/metadata.json"
USER_CONF="${DOTFILES_HOME}/user.conf"

# =============================================================================
# Initialization
# =============================================================================

# Initialize state management system
state_init() {
    # Create directories
    ensure_dir "$DOTFILES_HOME" || return 1
    ensure_dir "$STATE_DIR" || return 1

    # Initialize metadata file if it doesn't exist
    if [[ ! -f "$METADATA_FILE" ]]; then
        cat > "$METADATA_FILE" <<EOF
{
  "version": "3.0",
  "first_run": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "last_run": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "os": "$(uname -s)",
  "os_version": "$(uname -r)",
  "arch": "$(uname -m)",
  "run_count": 1
}
EOF
    fi

    return 0
}

# Update metadata for a new run
state_update_metadata() {
    if [[ -f "$METADATA_FILE" ]]; then
        # Read current run count
        local run_count=$(json_get "$METADATA_FILE" "['run_count']" 2>/dev/null || echo "0")
        run_count=$((run_count + 1))

        # Update metadata using a temp file for atomicity
        local temp_file="${METADATA_FILE}.tmp"
        cat > "$temp_file" <<EOF
{
  "version": "3.0",
  "first_run": "$(json_get "$METADATA_FILE" "['first_run']" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "last_run": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "os": "$(uname -s)",
  "os_version": "$(uname -r)",
  "arch": "$(uname -m)",
  "run_count": ${run_count}
}
EOF
        mv "$temp_file" "$METADATA_FILE"
    fi
}

# Check if this is the first run
state_is_first_run() {
    if [[ ! -f "$METADATA_FILE" ]]; then
        return 0
    fi

    local run_count=$(json_get "$METADATA_FILE" "['run_count']" 2>/dev/null || echo "0")
    [[ "$run_count" -le 1 ]]
}

# =============================================================================
# Module State Management
# =============================================================================

# Get state file path for a module
state_get_file() {
    local module="$1"
    echo "${STATE_DIR}/${module}.json"
}

# Check if module state exists
state_exists() {
    local module="$1"
    local state_file=$(state_get_file "$module")
    [[ -f "$state_file" ]]
}

# Get module state value
# Usage: state_get MODULE KEY
state_get() {
    local module="$1"
    local key="$2"
    local state_file=$(state_get_file "$module")

    if [[ ! -f "$state_file" ]]; then
        echo ""
        return 1
    fi

    json_get "$state_file" "['$key']"
}

# Set module state (creates or updates)
# Usage: state_set MODULE STATUS [VERSION] [METADATA]
state_set() {
    local module="$1"
    local status="$2"
    local version="${3:-}"
    local metadata="${4:-{}}"
    local state_file=$(state_get_file "$module")

    # Determine dates
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local installed_date="$now"

    # If state exists, preserve installed_date
    if [[ -f "$state_file" ]]; then
        local existing_date=$(json_get "$state_file" "['installed_date']" 2>/dev/null)
        if [[ -n "$existing_date" && "$existing_date" != "None" ]]; then
            installed_date="$existing_date"
        fi
    fi

    # Create state file
    cat > "$state_file" <<EOF
{
  "module": "${module}",
  "status": "${status}",
  "installed_date": "${installed_date}",
  "last_updated": "${now}",
  "version": "${version}",
  "metadata": ${metadata}
}
EOF
}

# Mark module as installed
# Usage: state_mark_installed MODULE [VERSION] [METADATA]
state_mark_installed() {
    local module="$1"
    local version="${2:-unknown}"
    local metadata="${3:-{}}"

    state_set "$module" "installed" "$version" "$metadata"
}

# Mark module as failed
# Usage: state_mark_failed MODULE ERROR_MESSAGE
state_mark_failed() {
    local module="$1"
    local error="${2:-unknown error}"

    local metadata="{\"error\": \"$error\"}"
    state_set "$module" "failed" "" "$metadata"
}

# Mark module as pending
# Usage: state_mark_pending MODULE
state_mark_pending() {
    local module="$1"
    state_set "$module" "pending" "" "{}"
}

# Remove module state
# Usage: state_remove MODULE
state_remove() {
    local module="$1"
    local state_file=$(state_get_file "$module")

    if [[ -f "$state_file" ]]; then
        rm -f "$state_file"
    fi
}

# =============================================================================
# Module Status Queries
# =============================================================================

# Get module status
# Returns: installed, failed, pending, or empty string if not found
state_get_status() {
    local module="$1"
    state_get "$module" "status"
}

# Check if module is installed
state_is_installed() {
    local module="$1"
    local status=$(state_get_status "$module")
    [[ "$status" == "installed" ]]
}

# Check if module failed
state_is_failed() {
    local module="$1"
    local status=$(state_get_status "$module")
    [[ "$status" == "failed" ]]
}

# Get module version
state_get_version() {
    local module="$1"
    state_get "$module" "version"
}

# Get module installed date
state_get_installed_date() {
    local module="$1"
    state_get "$module" "installed_date"
}

# =============================================================================
# List All Modules
# =============================================================================

# Get list of all modules with state
state_list_all() {
    if [[ ! -d "$STATE_DIR" ]]; then
        return 0
    fi

    for state_file in "$STATE_DIR"/*.json; do
        if [[ -f "$state_file" ]]; then
            local module=$(basename "$state_file" .json)
            echo "$module"
        fi
    done
}

# Get list of installed modules
state_list_installed() {
    state_list_all | while read -r module; do
        if state_is_installed "$module"; then
            echo "$module"
        fi
    done
}

# Get list of failed modules
state_list_failed() {
    state_list_all | while read -r module; do
        if state_is_failed "$module"; then
            echo "$module"
        fi
    done
}

# =============================================================================
# User Configuration
# =============================================================================

# Initialize user config file
user_config_init() {
    if [[ ! -f "$USER_CONF" ]]; then
        cat > "$USER_CONF" <<EOF
# Dotfiles User Configuration
# This file stores personal information for dotfile templates

# Personal Information
USER_FULL_NAME=""
USER_EMAIL=""
GITHUB_USERNAME=""
MACHINE_TYPE="personal"  # personal or work

# Git Configuration
GIT_DEFAULT_BRANCH="main"
GIT_EDITOR="nvim"

# Preferences
AUTO_UPDATE="true"
VERBOSE_LOGGING="false"
EOF
    fi
}

# Get user config value
# Usage: user_config_get KEY
user_config_get() {
    local key="$1"

    if [[ ! -f "$USER_CONF" ]]; then
        echo ""
        return 1
    fi

    # Parse simple KEY="value" format
    grep "^${key}=" "$USER_CONF" 2>/dev/null | cut -d'=' -f2- | tr -d '"'
}

# Set user config value
# Usage: user_config_set KEY VALUE
user_config_set() {
    local key="$1"
    local value="$2"

    user_config_init

    # Check if key exists
    if grep -q "^${key}=" "$USER_CONF"; then
        # Update existing
        if is_macos; then
            sed -i '' "s|^${key}=.*|${key}=\"${value}\"|" "$USER_CONF"
        else
            sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$USER_CONF"
        fi
    else
        # Add new
        echo "${key}=\"${value}\"" >> "$USER_CONF"
    fi
}

# Prompt for user configuration (interactive)
user_config_prompt() {
    echo -e "${INFO}${SYMBOL_INFO}${NC} ${TEXT}User configuration needed for templates...${NC}"
    echo ""

    # Get current values if they exist
    local current_name=$(user_config_get "USER_FULL_NAME")
    local current_email=$(user_config_get "USER_EMAIL")
    local current_github=$(user_config_get "GITHUB_USERNAME")
    local current_machine=$(user_config_get "MACHINE_TYPE")

    # Prompt with defaults
    read -p "  Full name [$current_name]: " user_name < /dev/tty
    user_name=${user_name:-$current_name}

    read -p "  Email address [$current_email]: " user_email < /dev/tty
    user_email=${user_email:-$current_email}

    read -p "  GitHub username [$current_github]: " github_user < /dev/tty
    github_user=${github_user:-$current_github}

    read -p "  Machine type (personal/work) [$current_machine]: " machine_type < /dev/tty
    machine_type=${machine_type:-$current_machine}

    # Save values
    user_config_set "USER_FULL_NAME" "$user_name"
    user_config_set "USER_EMAIL" "$user_email"
    user_config_set "GITHUB_USERNAME" "$github_user"
    user_config_set "MACHINE_TYPE" "$machine_type"

    echo ""
}

# Check if user config is complete
user_config_is_complete() {
    local name=$(user_config_get "USER_FULL_NAME")
    local email=$(user_config_get "USER_EMAIL")

    [[ -n "$name" && -n "$email" ]]
}

# =============================================================================
# Brewfile Package Tracking
# =============================================================================

# Get Brewfile packages state file
brewfile_state_file() {
    echo "${STATE_DIR}/brewfile-packages.json"
}

# Initialize Brewfile package tracking
brewfile_init_tracking() {
    local brewfile="$1"
    local state_file=$(brewfile_state_file)

    if [[ ! -f "$brewfile" ]]; then
        return 1
    fi

    # Get Brewfile hash
    local brewfile_hash=$(get_file_hash "$brewfile")

    # Create initial state
    cat > "$state_file" <<EOF
{
  "last_sync": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "brewfile_hash": "${brewfile_hash}",
  "installed": {},
  "removed": [],
  "failed": []
}
EOF
}

# Check if Brewfile has changed
brewfile_has_changed() {
    local brewfile="$1"
    local state_file=$(brewfile_state_file)

    if [[ ! -f "$state_file" ]]; then
        return 0  # Changed (doesn't exist)
    fi

    local current_hash=$(get_file_hash "$brewfile")
    local stored_hash=$(json_get "$state_file" "['brewfile_hash']" 2>/dev/null)

    [[ "$current_hash" != "$stored_hash" ]]
}

# Record installed package
brewfile_record_package() {
    local package="$1"
    local version="${2:-unknown}"
    local state_file=$(brewfile_state_file)

    # This would use proper JSON manipulation in production
    # For now, we'll keep it simple
    log_to_file "INFO" "Brewfile package installed: $package ($version)"
}

# =============================================================================
# Export Functions
# =============================================================================
export -f state_init state_update_metadata state_is_first_run
export -f state_get_file state_exists state_get state_set
export -f state_mark_installed state_mark_failed state_mark_pending state_remove
export -f state_get_status state_is_installed state_is_failed
export -f state_get_version state_get_installed_date
export -f state_list_all state_list_installed state_list_failed
export -f user_config_init user_config_get user_config_set
export -f user_config_prompt user_config_is_complete
export -f brewfile_state_file brewfile_init_tracking brewfile_has_changed brewfile_record_package

# Export paths
export DOTFILES_HOME STATE_DIR METADATA_FILE USER_CONF
