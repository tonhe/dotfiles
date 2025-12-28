#!/usr/bin/env bash
# =============================================================================
# logger.sh - Single-file logging system with boot-style output
# =============================================================================

# Source colors if not already loaded
if [[ -z "${NORD0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/colors.sh"
fi

# =============================================================================
# Configuration
# =============================================================================
DOTFILES_HOME="${HOME}/.dotfiles"
LOG_FILE="${DOTFILES_HOME}/bootstrap.log"
LOG_MAX_SIZE=$((10 * 1024 * 1024))  # 10MB

# Boot timer - DISABLED FOR DEBUGGING
# # Only initialize once - don't reset if already set (when re-sourced by modules)
# if [[ -z "${BOOT_START_MS}" ]]; then
#     BOOT_START_TIME=$(date +%s)
#     if [[ "$OSTYPE" == "darwin"* ]]; then
#         if command -v gdate &>/dev/null; then
#             BOOT_START_MS=$(gdate +%s%3N 2>/dev/null || echo "$((BOOT_START_TIME * 1000))")
#         else
#             BOOT_START_MS=$((BOOT_START_TIME * 1000))
#         fi
#     else
#         BOOT_START_MS=$(date +%s%3N 2>/dev/null || echo "$((BOOT_START_TIME * 1000))")
#     fi
#
#     # Ensure BOOT_START_MS is never empty
#     : ${BOOT_START_MS:=$((BOOT_START_TIME * 1000))}
# fi
#
# # Export so child processes (module scripts) inherit it
# export BOOT_START_MS

# Current module context
CURRENT_MODULE=""

# Statistics
STATS_SUCCESS=0
STATS_FAILED=0
STATS_SKIPPED=0

# =============================================================================
# Initialization
# =============================================================================

# Initialize logging system
log_init() {
    # Ensure dotfiles directory exists
    mkdir -p "${DOTFILES_HOME}"

    # Initialize boot timer - DISABLED FOR DEBUGGING
    # BOOT_START_TIME=$(date +%s)
    # if [[ "$OSTYPE" == "darwin"* ]]; then
    #     # macOS has millisecond precision with gdate if available
    #     if command -v gdate &>/dev/null; then
    #         BOOT_START_MS=$(gdate +%s%3N)
    #     else
    #         BOOT_START_MS=$((BOOT_START_TIME * 1000))
    #     fi
    # else
    #     # Linux date has nanosecond precision
    #     BOOT_START_MS=$(date +%s%3N)
    # fi

    # Rotate log if it's too large
    if [[ -f "${LOG_FILE}" ]]; then
        local log_size=$(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)
        if [[ $log_size -gt $LOG_MAX_SIZE ]]; then
            local archive="${LOG_FILE}.$(date +%Y%m%d-%H%M%S)"
            mv "${LOG_FILE}" "${archive}"
            gzip "${archive}" &
            log_to_file "INFO" "Rotated log file to ${archive}.gz"
        fi
    fi

    # Write run separator
    {
        echo ""
        echo "================================================================================"
        echo "BOOTSTRAP RUN: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================================"
    } >> "${LOG_FILE}"
}

# =============================================================================
# Time Formatting - DISABLED FOR DEBUGGING
# =============================================================================

# # Get elapsed time in seconds with millisecond precision
# get_elapsed_ms() {
#     local current_ms=""
#     local current_sec=""
#     local boot_start="${BOOT_START_MS:-0}"
#
#     if [[ "$OSTYPE" == "darwin"* ]]; then
#         if command -v gdate &>/dev/null 2>&1; then
#             current_ms=$(gdate +%s%3N 2>/dev/null || echo "")
#         fi
#         if [[ -z "$current_ms" ]]; then
#             current_sec=$(date +%s 2>/dev/null || echo "")
#             if [[ -n "$current_sec" ]]; then
#                 current_ms=$((current_sec * 1000))
#             else
#                 current_ms=0
#             fi
#         fi
#     else
#         current_ms=$(date +%s%3N 2>/dev/null || echo "")
#         if [[ -z "$current_ms" ]]; then
#             current_sec=$(date +%s 2>/dev/null || echo "")
#             if [[ -n "$current_sec" ]]; then
#                 current_ms=$((current_sec * 1000))
#             else
#                 current_ms=0
#             fi
#         fi
#     fi
#
#     # Final safety check
#     current_ms=${current_ms:-0}
#
#     echo $((current_ms - boot_start))
# }

# Format milliseconds as boot-style timestamp [    X.XXX]
# DISABLED - return nothing (don't echo anything)
#format_boot_time() {
#    return 0
#}

# =============================================================================
# Core Logging Functions
# =============================================================================

# Write to log file only (no console output)
log_to_file() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    #local elapsed=$(format_boot_time)

    #local log_line="${timestamp} ${elapsed} [${level}]"
    local log_line="${timestamp} [${level}]"
    if [[ -n "${CURRENT_MODULE}" ]]; then
        log_line="${log_line} [${CURRENT_MODULE}]"
    fi
    log_line="${log_line} ${message}"

    echo "${log_line}" >> "${LOG_FILE}"
}

# Log and print INFO level
log_info() {
    local message="$*"
    #local timestamp=$(format_boot_time)
    local timestamp=""

    # Console output
    if [[ -n "${CURRENT_MODULE}" ]]; then
        echo -e "${DIM}${timestamp}${NC} ${INFO}[${CURRENT_MODULE}]${NC} ${TEXT}${message}${NC}"
    else
        echo -e "${DIM}${timestamp}${NC} ${TEXT}${message}${NC}"
    fi

    # File output
    log_to_file "INFO" "${message}"
}

# Log and print SUCCESS level
log_success() {
    local message="$*"
    #local timestamp=$(format_boot_time)
    local timestamp=""
    STATS_SUCCESS=$((STATS_SUCCESS + 1))

    # Console output
    if [[ -n "${CURRENT_MODULE}" ]]; then
        echo -e "${DIM}${timestamp}${NC} ${SUCCESS}[${CURRENT_MODULE}] ${SYMBOL_SUCCESS}${NC} ${TEXT}${message}${NC}"
    else
        echo -e "${DIM}${timestamp}${NC} ${SUCCESS}${SYMBOL_SUCCESS}${NC} ${TEXT}${message}${NC}"
    fi

    # File output
    log_to_file "SUCCESS" "${message}"
}

# Log and print WARNING level
log_warn() {
    local message="$*"
    #local timestamp=$(format_boot_time)
    local timestamp=""
    STATS_SKIPPED=$((STATS_SKIPPED + 1))

    # Console output
    if [[ -n "${CURRENT_MODULE}" ]]; then
        echo -e "${DIM}${timestamp}${NC} ${WARN}[${CURRENT_MODULE}] ${SYMBOL_WARN}${NC} ${TEXT}${message}${NC}"
    else
        echo -e "${DIM}${timestamp}${NC} ${WARN}${SYMBOL_WARN}${NC} ${TEXT}${message}${NC}"
    fi

    # File output
    log_to_file "WARN" "${message}"
}

# Log and print ERROR level with visual box
log_error() {
    local message="$*"
    #local timestamp=$(format_boot_time)
    local timestamp=""
    STATS_FAILED=$((STATS_FAILED + 1))

    # Console output with error box (inline, fixed width 62 chars)
    if [[ -n "${CURRENT_MODULE}" ]]; then
        local text="FAILED: ${CURRENT_MODULE}"
        local text_len=${#text}
        local padding=$((56 - text_len))

        echo -e "${DIM}${timestamp}${NC} ${ERROR}┌$(printf '%.0s─' {1..60})┐${NC}"
        echo -e "${DIM}${timestamp}${NC} ${ERROR}│${NC}  ${text}$(printf "%*s" $padding "")  ${ERROR}│${NC}"
        echo -e "${DIM}${timestamp}${NC} ${ERROR}└$(printf '%.0s─' {1..60})┘${NC}"
    fi
    echo -e "${DIM}${timestamp}${NC} ${ERROR}${SYMBOL_ERROR}${NC} ${TEXT}${message}${NC}"

    # File output
    log_to_file "ERROR" "${BOX_D_TL}$(printf '%.0s═' {1..46})${BOX_D_TR}"
    if [[ -n "${CURRENT_MODULE}" ]]; then
        log_to_file "ERROR" "${BOX_D_V}  FAILED: ${CURRENT_MODULE}$(printf '%*s' $((39 - ${#CURRENT_MODULE})) '')${BOX_D_V}"
    else
        log_to_file "ERROR" "${BOX_D_V}  FATAL ERROR$(printf '%*s' 33 '')${BOX_D_V}"
    fi
    log_to_file "ERROR" "${BOX_D_BL}$(printf '%.0s═' {1..46})${BOX_D_BR}"
    log_to_file "ERROR" "${message}"
}

# Log spinner/progress updates (console only, not logged to file to reduce noise)
log_progress() {
    local message="$*"
    #local timestamp=$(format_boot_time)
    local timestamp=""

    # Console output
    if [[ -n "${CURRENT_MODULE}" ]]; then
        echo -e "${DIM}${timestamp}${NC} ${SPINNER}[${CURRENT_MODULE}] ${SYMBOL_SPINNER}${NC} ${DIM}${message}${NC}"
    else
        echo -e "${DIM}${timestamp}${NC} ${SPINNER}${SYMBOL_SPINNER}${NC} ${DIM}${message}${NC}"
    fi
}

# =============================================================================
# Section Headers
# =============================================================================

# Print a section header
log_section() {
    local title="$1"
    local width=71

    # Calculate padding
    local title_len=${#title}
    local dash_count=$(( (width - title_len - 2) / 2 ))
    local padding=$(printf "%.0s${BOX_H_H}" $(seq 1 $dash_count))

    #local timestamp=$(format_boot_time)
    local timestamp=""

    # Console output
    echo ""
    echo -e "${DIM}${timestamp}${NC} ${SECTION}[ ${BOLD}${title}${NC}${SECTION} ]${NC} ${SECTION}${padding}${NC}"
    echo ""

    # File output
    log_to_file "INFO" ""
    log_to_file "INFO" "[ ${title} ] ${padding}"
    log_to_file "INFO" ""
}

# =============================================================================
# Module Context
# =============================================================================

# Set current module name for log context
log_module_start() {
    CURRENT_MODULE="$1"
    log_to_file "INFO" "=== MODULE START: ${CURRENT_MODULE} ==="
}

# Clear module context
log_module_end() {
    if [[ -n "${CURRENT_MODULE}" ]]; then
        log_to_file "INFO" "=== MODULE END: ${CURRENT_MODULE} ==="
    fi
    CURRENT_MODULE=""
}

# =============================================================================
# Summary and Finalization
# =============================================================================

# Print final summary
log_summary() {
    local status="$1"  # SUCCESS, FAILED, or SUCCESS_WITH_ERRORS

    # Timing disabled for debugging
    # local end_time=$(date +%s)
    # local elapsed=$((end_time - BOOT_START_TIME))
    local minutes=0
    local seconds=0

    #local timestamp=$(format_boot_time)
    local timestamp=""

    log_section "COMPLETE"

    echo -e "${DIM}${timestamp}${NC} ${TEXT}Bootstrap completed${NC}"
    echo -e "${DIM}${timestamp}${NC} ${TEXT}Total time: ${BOLD}${minutes}m ${seconds}s${NC}"
    echo -e "${DIM}${timestamp}${NC} ${TEXT}Results: ${SUCCESS}${STATS_SUCCESS} succeeded${NC}, ${ERROR}${STATS_FAILED} failed${NC}, ${WARN}${STATS_SKIPPED} skipped${NC}"
    echo -e "${DIM}${timestamp}${NC} ${TEXT}Log saved: ${DIM}${LOG_FILE}${NC}"
    echo ""

    # File output
    log_to_file "INFO" "Bootstrap completed"
    log_to_file "INFO" "Total time: ${minutes}m ${seconds}s"
    log_to_file "INFO" "Summary: ${STATS_SUCCESS} succeeded, ${STATS_FAILED} failed, ${STATS_SKIPPED} skipped"
    {
        echo "================================================================================"
        echo "END: $(date '+%Y-%m-%d %H:%M:%S') (${status})"
        echo "================================================================================"
        echo ""
    } >> "${LOG_FILE}"
}

# =============================================================================
# Log Viewing Utilities
# =============================================================================

# Show the entire log
log_show() {
    if [[ -f "${LOG_FILE}" ]]; then
        cat "${LOG_FILE}"
    else
        echo "No log file found at ${LOG_FILE}"
    fi
}

# Show only errors from log
log_show_errors() {
    if [[ -f "${LOG_FILE}" ]]; then
        grep -A 3 "ERROR" "${LOG_FILE}" | grep -v "^--$"
    else
        echo "No log file found at ${LOG_FILE}"
    fi
}

# Clear/archive the log
log_clear() {
    if [[ -f "${LOG_FILE}" ]]; then
        local archive="${LOG_FILE}.archive.$(date +%Y%m%d-%H%M%S)"
        mv "${LOG_FILE}" "${archive}"
        echo "Log archived to ${archive}"
        gzip "${archive}"
        echo "Compressed to ${archive}.gz"
    else
        echo "No log file to clear"
    fi
}

# Tail the log in real-time
log_tail() {
    if [[ -f "${LOG_FILE}" ]]; then
        tail -f "${LOG_FILE}"
    else
        echo "No log file found at ${LOG_FILE}"
    fi
}

# =============================================================================
# Export Functions
# =============================================================================
export -f log_init log_info log_success log_warn log_error log_progress
export -f log_section log_module_start log_module_end log_summary
export -f log_show log_show_errors log_clear log_tail
#export -f log_to_file format_boot_time
export -f log_to_file 
# get_elapsed_ms commented out for debugging
