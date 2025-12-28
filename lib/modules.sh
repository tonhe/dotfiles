#!/usr/bin/env bash
# =============================================================================
# modules.sh - Module Discovery, Loading, and Dependency Resolution
# =============================================================================
# Compatible with bash 3.2+ (uses indexed arrays, not associative arrays)

# Source dependencies if not already loaded
if [[ -z "${NORD0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/colors.sh"
    source "${SCRIPT_DIR}/logger.sh"
    source "${SCRIPT_DIR}/utils.sh"
    source "${SCRIPT_DIR}/state.sh"
fi

# =============================================================================
# Configuration
# =============================================================================
MODULES_DIR="${DOTFILES_HOME}/repo/scripts"
MODULES_CACHE="${DOTFILES_HOME}/.modules_cache"

# Module registry (using delimited strings instead of associative arrays)
# Format: "module_name|value"
MODULE_REGISTRY=()

# =============================================================================
# Registry Helper Functions
# =============================================================================

# Store module data in registry
# Usage: _registry_set "module_name" "key" "value"
_registry_set() {
    local module="$1"
    local key="$2"
    local value="$3"
    local entry="${module}|${key}|${value}"

    # Remove existing entry if present
    local -a new_registry=()
    for item in "${MODULE_REGISTRY[@]}"; do
        if [[ ! "$item" =~ ^${module}\|${key}\| ]]; then
            new_registry+=("$item")
        fi
    done

    # Add new entry
    new_registry+=("$entry")
    MODULE_REGISTRY=("${new_registry[@]}")
}

# Get module data from registry
# Usage: _registry_get "module_name" "key"
_registry_get() {
    local module="$1"
    local key="$2"

    for item in "${MODULE_REGISTRY[@]}"; do
        if [[ "$item" =~ ^${module}\|${key}\|(.*)$ ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    done

    echo ""
    return 1
}

# Get all modules
_registry_list_modules() {
    local -a modules=()
    for item in "${MODULE_REGISTRY[@]}"; do
        if [[ "$item" =~ ^([^|]+)\|path\| ]]; then
            local module="${BASH_REMATCH[1]}"
            if ! array_contains "$module" "${modules[@]}"; then
                modules+=("$module")
            fi
        fi
    done
    echo "${modules[@]}"
}

# =============================================================================
# Module Discovery
# =============================================================================

# Discover all available modules for current OS
module_discover() {
    local platform_dir=""

    # Determine platform-specific directory
    if is_macos; then
        platform_dir="darwin"
    elif is_linux; then
        platform_dir="linux"
    else
        log_error "Unsupported platform"
        return 1
    fi

    # Clear existing registry
    MODULE_REGISTRY=()

    # Scan all/ directory (cross-platform modules)
    if [[ -d "${MODULES_DIR}/all" ]]; then
        for script in "${MODULES_DIR}/all"/*.sh; do
            [[ -f "$script" ]] || continue
            [[ "$(basename "$script")" == "MODULE_TEMPLATE.sh" ]] && continue
            _module_register "$script"
        done
    fi

    # Scan platform-specific directory
    if [[ -d "${MODULES_DIR}/${platform_dir}" ]]; then
        for script in "${MODULES_DIR}/${platform_dir}"/*.sh; do
            [[ -f "$script" ]] || continue
            _module_register "$script"
        done
    fi

    local count=$(echo "$(_registry_list_modules)" | wc -w)
    log_info "Discovered ${count} module(s)"
}

# Register a module by loading its metadata
_module_register() {
    local script_path="$1"
    local module_name=$(basename "$script_path" .sh)

    # Skip if already registered
    if [[ -n "$(_registry_get "$module_name" "path")" ]]; then
        return 0
    fi

    # Source the script to get metadata
    local metadata=$(bash -c "
        source '$script_path' 2>/dev/null
        echo \"NAME:\${MODULE_NAME}\"
        echo \"DESC:\${MODULE_DESC}\"
        echo \"ORDER:\${MODULE_ORDER:-50}\"
        echo \"CATEGORY:\${MODULE_CATEGORY:-applications}\"
        echo \"DEPS:\${MODULE_DEPS[*]}\"
    " 2>/dev/null)

    if [[ -z "$metadata" ]]; then
        log_warn "Could not load metadata from $script_path"
        return 1
    fi

    # Parse metadata
    local display_name=$(echo "$metadata" | grep "^NAME:" | cut -d: -f2-)
    local description=$(echo "$metadata" | grep "^DESC:" | cut -d: -f2-)
    local order=$(echo "$metadata" | grep "^ORDER:" | cut -d: -f2-)
    local category=$(echo "$metadata" | grep "^CATEGORY:" | cut -d: -f2-)
    local deps=$(echo "$metadata" | grep "^DEPS:" | cut -d: -f2-)

    # Store in registry
    _registry_set "$module_name" "path" "$script_path"
    _registry_set "$module_name" "name" "${display_name:-$module_name}"
    _registry_set "$module_name" "desc" "${description:-No description}"
    _registry_set "$module_name" "order" "${order:-50}"
    _registry_set "$module_name" "category" "${category:-applications}"
    _registry_set "$module_name" "deps" "${deps}"
}

# =============================================================================
# Module Queries
# =============================================================================

module_list_all() {
    _registry_list_modules
}

module_list_by_category() {
    local category="$1"
    local -a modules=()

    for module in $(_registry_list_modules); do
        local mod_category=$(_registry_get "$module" "category")
        if [[ "$mod_category" == "$category" ]]; then
            modules+=("$module")
        fi
    done

    echo "${modules[@]}"
}

module_get_name() {
    _registry_get "$1" "name"
}

module_get_desc() {
    _registry_get "$1" "desc"
}

module_get_path() {
    _registry_get "$1" "path"
}

module_get_order() {
    local order=$(_registry_get "$1" "order")
    echo "${order:-50}"
}

module_get_category() {
    _registry_get "$1" "category"
}

module_get_deps() {
    _registry_get "$1" "deps"
}

# =============================================================================
# Module Execution
# =============================================================================

module_exec() {
    local module="$1"
    local action="$2"
    local script=$(module_get_path "$module")

    if [[ -z "$script" ]]; then
        log_error "Module '$module' not found"
        return 1
    fi

    bash "$script" "$action"
    return $?
}

module_is_installed() {
    local module="$1"
    module_exec "$module" "check" &>/dev/null
}

module_get_version() {
    local module="$1"
    module_exec "$module" "version" 2>/dev/null || echo "unknown"
}

# =============================================================================
# Dependency Resolution
# =============================================================================

module_resolve_deps() {
    local -a requested_modules=("$@")
    local -a resolved=()
    local -a visited=()

    for module in "${requested_modules[@]}"; do
        _module_resolve_recursive "$module" visited resolved || return 1
    done

    echo "${resolved[@]}"
}

_module_resolve_recursive() {
    local module="$1"
    shift
    local visited_var="$1[@]"
    local visited=("${!visited_var}")
    shift
    local resolved_var="$1[@]"
    local resolved=("${!resolved_var}")

    # Check if already resolved
    if array_contains "$module" "${resolved[@]}"; then
        return 0
    fi

    # Check for circular dependency
    if array_contains "$module" "${visited[@]}"; then
        log_error "Circular dependency detected: $module"
        return 1
    fi

    # Mark as visiting
    visited+=("$module")

    # Get dependencies
    local deps_str=$(module_get_deps "$module")
    local -a deps=($deps_str)

    # Recursively resolve dependencies
    for dep in "${deps[@]}"; do
        [[ -z "$dep" ]] && continue

        if [[ -z "$(module_get_path "$dep")" ]]; then
            log_error "Module '$module' depends on '$dep' which was not found"
            return 1
        fi

        _module_resolve_recursive "$dep" visited resolved || return 1
    done

    # Add to resolved list
    resolved+=("$module")

    # Return updated arrays by echoing
    echo "VISITED:${visited[*]}"
    echo "RESOLVED:${resolved[*]}"
}

module_sort_by_order() {
    local -a modules=("$@")
    local -a pairs=()

    for module in "${modules[@]}"; do
        local order=$(module_get_order "$module")
        pairs+=("${order}:${module}")
    done

    printf '%s\n' "${pairs[@]}" | sort -n | cut -d: -f2-
}

# =============================================================================
# Module Installation
# =============================================================================

module_install() {
    local module="$1"
    local display_name=$(module_get_name "$module")

    log_module_start "$module"

    if state_is_installed "$module"; then
        local version=$(state_get_version "$module")
        log_success "${display_name} v${version} (already installed)"
        log_module_end
        return 0
    fi

    if module_is_installed "$module"; then
        local version=$(module_get_version "$module")
        log_info "${display_name} detected on system"
        state_mark_installed "$module" "$version"
        log_success "${display_name} v${version} (detected)"
        log_module_end
        return 0
    fi

    log_info "Installing ${display_name}..."

    if module_exec "$module" "install"; then
        local version=$(module_get_version "$module")
        state_mark_installed "$module" "$version"
        log_success "${display_name} v${version} installed"
        log_module_end
        return 0
    else
        state_mark_failed "$module" "Installation failed"
        log_error "${display_name} installation failed"
        log_module_end
        return 1
    fi
}

module_install_all() {
    local -a modules=("$@")
    local resolved=$(module_resolve_deps "${modules[@]}")

    if [[ -z "$resolved" ]]; then
        log_error "No modules to install"
        return 1
    fi

    local -a sorted=($(module_sort_by_order $resolved))
    log_info "Installation order: ${sorted[*]}"

    local failed=0
    for module in "${sorted[@]}"; do
        if ! module_install "$module"; then
            ((failed++))
            log_warn "Continuing despite failure..."
        fi
    done

    [[ $failed -eq 0 ]]
}

# =============================================================================
# Module Status Display
# =============================================================================

module_display_status() {
    local categories=("system" "packages" "applications" "configuration")
    local width=67

    for category in "${categories[@]}"; do
        local modules=($(module_list_by_category "$category"))

        [[ ${#modules[@]} -eq 0 ]] && continue

        local category_title=$(echo "$category" | sed 's/\b\(.\)/\u\1/')
        local title_len=${#category_title}

        echo -e "${SECTION}┌$(printf '─%.0s' $(seq 1 $width))┐${NC}"
        echo -e "${SECTION}│${NC} ${BRIGHT}${category_title}${NC}$(printf '%*s' $((width - title_len - 2)) '')${SECTION}│${NC}"
        echo -e "${SECTION}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"

        local sorted=($(module_sort_by_order "${modules[@]}"))

        for module in "${sorted[@]}"; do
            local status="pending"
            local version=""
            local date=""

            if state_is_installed "$module"; then
                status="installed"
                version=$(state_get_version "$module")
                date=$(state_get_installed_date "$module" | cut -d'T' -f1)
            elif state_is_failed "$module"; then
                status="failed"
            fi

            display_module_status "$module" "$status" "$version" "$date"
        done

        echo -e "${SECTION}└$(printf '─%.0s' $(seq 1 $width))┘${NC}"
        echo ""
    done
}

# =============================================================================
# Export Functions
# =============================================================================
export -f module_discover _module_register
export -f module_list_all module_list_by_category
export -f module_get_name module_get_desc module_get_path
export -f module_get_order module_get_category module_get_deps
export -f module_exec module_is_installed module_get_version
export -f module_resolve_deps module_sort_by_order
export -f module_install module_install_all
export -f module_display_status
export -f _registry_set _registry_get _registry_list_modules
