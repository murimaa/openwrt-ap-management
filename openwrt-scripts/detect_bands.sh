#!/bin/sh

# Radio band detection script for OpenWrt
# Analyzes board.json to determine radio capabilities and optimal band assignments

BOARD_JSON="/etc/board.json"

# Colors for output (only used when not in quiet mode)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default options
QUIET=false
ACTION=""

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  list                  List all radios and their band capabilities"
    echo "  assign                Show optimal band assignments"
    echo "  detect-radio <band>   Find radio supporting specific band (2g|5g)"
    echo "  detect-band <radio>   Show band capability of specific radio"
    echo ""
    echo "Options:"
    echo "  -q, --quiet          Output only essential information"
    echo "  -b, --board-json     Specify alternative board.json path"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list              # List all radio capabilities"
    echo "  $0 assign            # Show optimal band assignments"
    echo "  $0 detect-radio 2g   # Find radio that supports 2.4GHz"
    echo "  $0 detect-band radio0 # Show what bands radio0 supports"
}

# Logging functions
log_error() {
    if [ "$QUIET" = "false" ]; then
        echo -e "${RED}[ERROR]${NC} $1" >&2
    fi
}

log_info() {
    if [ "$QUIET" = "false" ]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_verbose() {
    if [ "$QUIET" = "false" ]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1" >&2
    fi
}

# Get list of available radios from UCI
get_radios() {
    uci show wireless 2>/dev/null | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1
}

# Get radio path from UCI
get_radio_path() {
    local radio="$1"
    uci get wireless.$radio.path 2>/dev/null
}

# Find which phy corresponds to a given path in board.json
find_phy_for_path() {
    local target_path="$1"

    if [ ! -f "$BOARD_JSON" ]; then
        return 1
    fi

    # Search through phy0, phy1, phy2, phy3 for matching path
    for phy in phy0 phy1 phy2 phy3; do
        if grep -A 5 "\"$phy\"" "$BOARD_JSON" 2>/dev/null | grep -q "$target_path"; then
            echo "$phy"
            return 0
        fi
    done

    return 1
}

# Get band capabilities for a specific phy from board.json
get_phy_bands() {
    local phy="$1"

    if [ ! -f "$BOARD_JSON" ]; then
        return 1
    fi

    # Extract the phy section
    local phy_section=$(awk "/\"$phy\"/,/^[[:space:]]*}[[:space:]]*\$/" "$BOARD_JSON" 2>/dev/null)

    if [ -z "$phy_section" ]; then
        return 1
    fi

    local has_2g=0
    local has_5g=0

    if echo "$phy_section" | grep -q '"2G"'; then
        has_2g=1
    fi
    if echo "$phy_section" | grep -q '"5G"'; then
        has_5g=1
    fi

    # Output capability
    if [ $has_2g -eq 1 ] && [ $has_5g -eq 1 ]; then
        echo "dual"
    elif [ $has_5g -eq 1 ]; then
        echo "5g"
    elif [ $has_2g -eq 1 ]; then
        echo "2g"
    else
        echo "unknown"
    fi

    return 0
}

# Get band capability for a radio
get_radio_capability() {
    local radio="$1"
    local radio_path=$(get_radio_path "$radio")

    if [ -z "$radio_path" ]; then
        # Fallback: check current UCI band setting
        local current_band=$(uci get wireless.$radio.band 2>/dev/null)
        if [ -n "$current_band" ]; then
            case "$current_band" in
                "2g"|"2.4g") echo "2g" ;;
                "5g"|"5.8g") echo "5g" ;;
                *) echo "unknown" ;;
            esac
        else
            echo "unknown"
        fi
        return 1
    fi

    local phy=$(find_phy_for_path "$radio_path")
    if [ -z "$phy" ]; then
        echo "unknown"
        return 1
    fi

    get_phy_bands "$phy"
}

# List all radios and their capabilities
cmd_list() {
    local radios=$(get_radios)

    if [ -z "$radios" ]; then
        log_error "No wireless radios found"
        return 1
    fi

    log_info "Analyzing radio capabilities..."

    for radio in $radios; do
        local capability=$(get_radio_capability "$radio")
        local radio_path=$(get_radio_path "$radio")

        if [ "$QUIET" = "true" ]; then
            echo "$radio:$capability"
        else
            echo "Radio: $radio"
            echo "  Path: ${radio_path:-unknown}"
            echo "  Bands: $capability"
            echo ""
        fi
    done
}

# Show optimal band assignments
cmd_assign() {
    local radios=$(get_radios)

    if [ -z "$radios" ]; then
        log_error "No wireless radios found"
        return 1
    fi

    local dual_band_radios=""
    local band_5g_only=""
    local band_2g_only=""

    # Categorize radios by capability
    for radio in $radios; do
        local capability=$(get_radio_capability "$radio")
        case "$capability" in
            "dual")
                dual_band_radios="$dual_band_radios $radio"
                ;;
            "5g")
                band_5g_only="$band_5g_only $radio"
                ;;
            "2g")
                band_2g_only="$band_2g_only $radio"
                ;;
            *)
                log_verbose "Radio $radio has unknown capability, assuming dual-band"
                dual_band_radios="$dual_band_radios $radio"
                ;;
        esac
    done

    # Assignment logic
    local assigned_2g=false
    local assigned_5g=false

    # Assign dedicated radios first
    for radio in $band_2g_only; do
        echo "$radio:2g"
        assigned_2g=true
    done

    for radio in $band_5g_only; do
        echo "$radio:5g"
        assigned_5g=true
    done

    # Assign dual-band radios based on what's needed
    for radio in $dual_band_radios; do
        if [ "$assigned_2g" = "false" ]; then
            echo "$radio:2g"
            assigned_2g=true
        elif [ "$assigned_5g" = "false" ]; then
            echo "$radio:5g"
            assigned_5g=true
        else
            # Both bands covered, prefer 5G
            echo "$radio:5g"
        fi
    done

    # Report coverage status to stderr if not quiet
    if [ "$QUIET" = "false" ]; then
        if [ "$assigned_2g" = "false" ]; then
            log_error "No radio assigned to 2.4GHz band"
        fi
        if [ "$assigned_5g" = "false" ]; then
            log_error "No radio assigned to 5GHz band"
        fi
    fi
}

# Find radio that supports a specific band
cmd_detect_radio() {
    local target_band="$1"

    if [ -z "$target_band" ]; then
        log_error "Band not specified"
        return 1
    fi

    case "$target_band" in
        "2g"|"2.4g") target_band="2g" ;;
        "5g"|"5.8g") target_band="5g" ;;
        *)
            log_error "Invalid band: $target_band (use 2g or 5g)"
            return 1
            ;;
    esac

    local radios=$(get_radios)
    local found_radio=""

    # Look for dedicated radio first, then dual-band
    for radio in $radios; do
        local capability=$(get_radio_capability "$radio")
        if [ "$capability" = "$target_band" ]; then
            found_radio="$radio"
            break
        fi
    done

    # If no dedicated radio found, look for dual-band
    if [ -z "$found_radio" ]; then
        for radio in $radios; do
            local capability=$(get_radio_capability "$radio")
            if [ "$capability" = "dual" ]; then
                found_radio="$radio"
                break
            fi
        done
    fi

    if [ -n "$found_radio" ]; then
        echo "$found_radio"
        return 0
    else
        if [ "$QUIET" = "false" ]; then
            log_error "No radio found supporting $target_band band"
        fi
        return 1
    fi
}

# Show band capability of a specific radio
cmd_detect_band() {
    local radio="$1"

    if [ -z "$radio" ]; then
        log_error "Radio not specified"
        return 1
    fi

    local capability=$(get_radio_capability "$radio")

    if [ "$capability" = "unknown" ]; then
        if [ "$QUIET" = "false" ]; then
            log_error "Could not determine band capability for radio $radio"
        fi
        return 1
    fi

    echo "$capability"
    return 0
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case $1 in
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -b|--board-json)
            BOARD_JSON="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        list|assign|detect-radio|detect-band)
            ACTION="$1"
            shift
            break
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Execute command
case "$ACTION" in
    "list")
        cmd_list
        ;;
    "assign")
        cmd_assign
        ;;
    "detect-radio")
        cmd_detect_radio "$1"
        ;;
    "detect-band")
        cmd_detect_band "$1"
        ;;
    "")
        log_error "No command specified"
        usage
        exit 1
        ;;
    *)
        log_error "Unknown command: $ACTION"
        usage
        exit 1
        ;;
esac
