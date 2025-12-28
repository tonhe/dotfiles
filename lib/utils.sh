#!/usr/bin/env bash
# =============================================================================
# utils.sh - Utility Functions
# =============================================================================

# Source dependencies if not already loaded
if [[ -z "${NORD0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/colors.sh"
fi

# =============================================================================
# OS Detection
# =============================================================================

# Detect operating system
# Sets global variables: OS, OS_VERSION, ARCH, DISTRO (for Linux)
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="darwin"
            OS_VERSION=$(sw_vers -productVersion)
            ARCH=$(uname -m)
            export OS OS_VERSION ARCH
            ;;
        Linux)
            OS="linux"
            OS_VERSION=$(uname -r)
            ARCH=$(uname -m)

            # Detect Linux distribution
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                DISTRO=$ID
            else
                DISTRO="unknown"
            fi
            export OS OS_VERSION ARCH DISTRO
            ;;
        *)
            echo "Unsupported operating system: $(uname -s)"
            return 1
            ;;
    esac
}

# Check if running on macOS
is_macos() {
    [[ "$OS" == "darwin" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$OS" == "linux" ]]
}

# Get human-readable OS name
get_os_name() {
    if is_macos; then
        echo "macOS ${OS_VERSION}"
    elif is_linux; then
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            echo "${NAME} ${VERSION_ID}"
        else
            echo "Linux ${OS_VERSION}"
        fi
    else
        echo "$(uname -s)"
    fi
}

# =============================================================================
# File System Utilities
# =============================================================================

# Safely create directory with logging
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        if [[ $? -eq 0 ]]; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Check if file exists and is readable
file_exists() {
    [[ -f "$1" && -r "$1" ]]
}

# Check if directory exists and is accessible
dir_exists() {
    [[ -d "$1" && -x "$1" ]]
}

# Get file size in bytes
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if is_macos; then
            stat -f%z "$file"
        else
            stat -c%s "$file"
        fi
    else
        echo "0"
    fi
}

# =============================================================================
# Command Checking
# =============================================================================

# Check if command exists in PATH
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if command exists and is executable
executable_exists() {
    [[ -x "$(command -v "$1" 2>/dev/null)" ]]
}

# Get command version (tries common --version flags)
get_command_version() {
    local cmd="$1"
    if command_exists "$cmd"; then
        # Try different version flags
        if $cmd --version &>/dev/null; then
            $cmd --version 2>&1 | head -n1
        elif $cmd -v &>/dev/null; then
            $cmd -v 2>&1 | head -n1
        elif $cmd version &>/dev/null; then
            $cmd version 2>&1 | head -n1
        else
            echo "unknown"
        fi
    else
        echo "not installed"
    fi
}

# =============================================================================
# String Utilities
# =============================================================================

# Trim whitespace from string
trim() {
    local var="$*"
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Check if string contains substring
contains() {
    local string="$1"
    local substring="$2"
    [[ "$string" == *"$substring"* ]]
}

# =============================================================================
# JSON Utilities (using python for portability)
# =============================================================================

# Read JSON value (requires python)
# Usage: json_get file.json ".key.subkey"
json_get() {
    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        echo ""
        return 1
    fi

    if command_exists python3; then
        python3 -c "import json, sys; data=json.load(open('$file')); print(data$key)" 2>/dev/null
    elif command_exists python; then
        python -c "import json, sys; data=json.load(open('$file')); print(data$key)" 2>/dev/null
    else
        echo ""
        return 1
    fi
}

# Set JSON value (requires python)
# Usage: json_set file.json ".key.subkey" "value"
json_set() {
    local file="$1"
    local key="$2"
    local value="$3"

    # Create file if it doesn't exist
    if [[ ! -f "$file" ]]; then
        echo "{}" > "$file"
    fi

    if command_exists python3; then
        python3 -c "
import json
with open('$file', 'r') as f:
    data = json.load(f)
keys = '$key'.strip('.').split('.')
d = data
for k in keys[:-1]:
    d = d.setdefault(k, {})
d[keys[-1]] = '$value'
with open('$file', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null
    elif command_exists python; then
        python -c "
import json
with open('$file', 'r') as f:
    data = json.load(f)
keys = '$key'.strip('.').split('.')
d = data
for k in keys[:-1]:
    d = d.setdefault(k, {})
d[keys[-1]] = '$value'
with open('$file', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null
    else
        return 1
    fi
}

# =============================================================================
# Network Utilities
# =============================================================================

# Check if we have internet connectivity
has_internet() {
    if command_exists ping; then
        ping -c 1 -W 2 8.8.8.8 &>/dev/null
    elif command_exists curl; then
        curl -s --connect-timeout 2 http://www.google.com &>/dev/null
    else
        # Assume we have internet if we can't test
        return 0
    fi
}

# Download file with progress
# Usage: download_file URL DEST
download_file() {
    local url="$1"
    local dest="$2"

    if command_exists curl; then
        curl -fsSL "$url" -o "$dest"
    elif command_exists wget; then
        wget -q -O "$dest" "$url"
    else
        return 1
    fi
}

# =============================================================================
# Process Utilities
# =============================================================================

# Check if process is running
is_process_running() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null
}

# Wait for process to complete with timeout
# Usage: wait_for_process PID TIMEOUT_SECONDS
wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    local elapsed=0

    while is_process_running "$pid"; do
        if [[ $elapsed -ge $timeout ]]; then
            return 1
        fi
        sleep 1
        ((elapsed++))
    done
    return 0
}

# =============================================================================
# Hash/Checksum Utilities
# =============================================================================

# Get file hash (SHA256)
get_file_hash() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo ""
        return 1
    fi

    if command_exists sha256sum; then
        sha256sum "$file" | awk '{print $1}'
    elif command_exists shasum; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo ""
        return 1
    fi
}

# Get string hash (SHA256)
get_string_hash() {
    local string="$1"

    if command_exists sha256sum; then
        echo -n "$string" | sha256sum | awk '{print $1}'
    elif command_exists shasum; then
        echo -n "$string" | shasum -a 256 | awk '{print $1}'
    else
        echo ""
        return 1
    fi
}

# =============================================================================
# Git Utilities
# =============================================================================

# Check if directory is a git repository
is_git_repo() {
    local dir="${1:-.}"
    git -C "$dir" rev-parse --git-dir &>/dev/null
}

# Get current git branch
get_git_branch() {
    local dir="${1:-.}"
    if is_git_repo "$dir"; then
        git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null
    else
        echo ""
    fi
}

# Get git remote URL
get_git_remote() {
    local dir="${1:-.}"
    if is_git_repo "$dir"; then
        git -C "$dir" config --get remote.origin.url 2>/dev/null
    else
        echo ""
    fi
}

# Pull latest changes from git
git_pull_latest() {
    local dir="${1:-.}"
    if is_git_repo "$dir"; then
        git -C "$dir" pull origin "$(get_git_branch "$dir")" 2>&1
    else
        return 1
    fi
}

# =============================================================================
# Sudo Utilities
# =============================================================================

# Request sudo access and keep it alive
request_sudo() {
    # Request sudo upfront
    sudo -v

    # Keep sudo alive in the background
    # Update timestamp every 50 seconds (before the 5-minute timeout)
    (
        while true; do
            sleep 50
            sudo -n true
            kill -0 "$$" 2>/dev/null || exit
        done
    ) &

    SUDO_KEEPALIVE_PID=$!
    export SUDO_KEEPALIVE_PID
}

# Kill sudo keepalive process
kill_sudo_keepalive() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
        unset SUDO_KEEPALIVE_PID
    fi
}

# =============================================================================
# Array Utilities
# =============================================================================

# Check if array contains element
# Usage: array_contains "element" "${array[@]}"
array_contains() {
    local element="$1"
    shift
    local array=("$@")

    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

# Join array elements with delimiter
# Usage: array_join "," "${array[@]}"
array_join() {
    local delimiter="$1"
    shift
    local array=("$@")

    local result=""
    for item in "${array[@]}"; do
        if [[ -z "$result" ]]; then
            result="$item"
        else
            result="${result}${delimiter}${item}"
        fi
    done
    echo "$result"
}

# =============================================================================
# Cleanup Handler
# =============================================================================

# Register cleanup function to run on exit
# Usage: register_cleanup my_cleanup_function
register_cleanup() {
    local cleanup_fn="$1"
    trap "$cleanup_fn" EXIT INT TERM
}

# =============================================================================
# Export Functions
# =============================================================================
export -f detect_os is_macos is_linux get_os_name
export -f ensure_dir file_exists dir_exists get_file_size
export -f command_exists executable_exists get_command_version
export -f trim to_lower to_upper contains
export -f json_get json_set
export -f has_internet download_file
export -f is_process_running wait_for_process
export -f get_file_hash get_string_hash
export -f is_git_repo get_git_branch get_git_remote git_pull_latest
export -f request_sudo kill_sudo_keepalive
export -f array_contains array_join
export -f register_cleanup
