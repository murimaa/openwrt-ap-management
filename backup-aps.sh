#!/bin/bash

# OpenWRT UCI Configuration Backup Script
# Create UCI export backups from OpenWrt access points using AP config files

set -e  # Exit on error

# Configuration
DEFAULT_SSH_USER="root"
DEFAULT_SSH_PORT="22"
SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS] <ap-config.conf> [ap-config2.conf ...]"
    echo ""
    echo "Create UCI export backups from OpenWrt access points using AP config files."
    echo ""
    echo "Options:"
    echo "  -v, --verbose     Enable verbose output"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 aps/ap-main.conf"
    echo "  $0 aps/ap-main.conf aps/ap-bedroom.conf"
    echo "  $0 aps/*.conf"
    echo "  $0 -v aps/ap-main.conf  # Verbose output"
    echo ""
    echo "Access point config files should contain:"
    echo "  AP_IP=\"192.168.1.1\""
    echo "  AP_NAME=\"ap-main\""
    echo "  SSH_USER=\"root\"           # Optional, defaults to 'root'"
    echo "  SSH_PORT=\"22\"             # Optional, defaults to '22'"
    echo "  SSH_KEY=\"/path/to/key\"    # Optional SSH key"
    echo ""
    echo "Backup files are created as: {AP_NAME}.{YYYYMMDD_HHMMSS}.uciexport"
    echo ""
    echo "To restore a backup:"
    echo "  scp backup-file.uciexport root@ap:/tmp/"
    echo "  ssh root@ap \"uci import < /tmp/backup-file.uciexport && uci commit\""
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Load access point configuration file
load_ap_config() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        log_error "Access point config file not found: $config_file"
        return 1
    fi

    # Reset variables
    unset AP_IP AP_NAME ROUTER_IP ROUTER_NAME SSH_USER SSH_PORT SSH_KEY

    # Source the config file
    if ! . "$config_file"; then
        log_error "Failed to load access point config: $config_file"
        return 1
    fi

    # Support both new AP_ and legacy ROUTER_ variables for compatibility
    AP_IP="${AP_IP:-$ROUTER_IP}"
    AP_NAME="${AP_NAME:-$ROUTER_NAME}"

    # Validate required variables
    if [ -z "$AP_IP" ]; then
        log_error "AP_IP (or ROUTER_IP) not defined in $config_file"
        return 1
    fi

    # Set defaults
    SSH_USER="${SSH_USER:-$DEFAULT_SSH_USER}"
    SSH_PORT="${SSH_PORT:-$DEFAULT_SSH_PORT}"
    AP_NAME="${AP_NAME:-$AP_IP}"

    log_verbose "Loaded config: $AP_NAME ($AP_IP:$SSH_PORT)"
    return 0
}

# Test SSH connectivity
test_ssh() {
    local ap_ip="$1"
    local ssh_user="$2"
    local ssh_port="$3"
    local ssh_key="$4"

    local ssh_cmd_opts="$SSH_OPTS -p $ssh_port"
    if [ -n "$ssh_key" ]; then
        ssh_cmd_opts="$ssh_cmd_opts -i $ssh_key"
    fi

    if ssh $ssh_cmd_opts "$ssh_user@$ap_ip" "echo 'SSH test successful'" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Create UCI backup
create_backup() {
    local ap_ip="$1"
    local ap_name="$2"
    local ssh_user="$3"
    local ssh_port="$4"
    local ssh_key="$5"

    local ssh_cmd_opts="$SSH_OPTS -p $ssh_port"
    if [ -n "$ssh_key" ]; then
        ssh_cmd_opts="$ssh_cmd_opts -i $ssh_key"
    fi

    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${ap_name}.${timestamp}.uciexport"

    log_info "Creating UCI backup from $ap_name ($ap_ip): $backup_file"

    if ssh $ssh_cmd_opts "$ssh_user@$ap_ip" "uci export" > "$backup_file"; then
        local line_count=$(wc -l < "$backup_file")
        log_success "UCI backup created: $backup_file ($line_count lines)"
        return 0
    else
        log_error "Failed to create UCI backup for $ap_name"
        return 1
    fi
}

# Backup single access point
backup_ap() {
    local config_file="$1"

    log_info "Processing access point config: $config_file"

    # Load access point configuration
    if ! load_ap_config "$config_file"; then
        return 1
    fi

    log_verbose "Backing up $AP_NAME ($AP_IP:$SSH_PORT)..."

    # Build SSH command options
    local ssh_cmd_opts="$SSH_OPTS -p $SSH_PORT"
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd_opts="$ssh_cmd_opts -i $SSH_KEY"
    fi

    # Test SSH connectivity
    if ! test_ssh "$AP_IP" "$SSH_USER" "$SSH_PORT" "$SSH_KEY"; then
        log_error "Cannot connect to $AP_IP:$SSH_PORT via SSH"
        return 1
    fi

    # Create backup
    if create_backup "$AP_IP" "$AP_NAME" "$SSH_USER" "$SSH_PORT" "$SSH_KEY"; then
        return 0
    else
        return 1
    fi
}

# Main backup function
backup_all_aps() {
    local ap_configs=("$@")

    local success_count=0
    local error_count=0
    local total_count=${#ap_configs[@]}

    log_info "Starting backup of $total_count access point(s)..."

    for config_file in "${ap_configs[@]}"; do
        if backup_ap "$config_file"; then
            ((success_count++))
        else
            ((error_count++))
        fi

        # Add a small delay between backups
        if [ $((success_count + error_count)) -lt $total_count ]; then
            sleep 1
        fi
    done

    # Summary
    echo ""
    log_info "Backup Summary:"
    log_success "Successful backups: $success_count/$total_count"
    if [ "$error_count" -gt 0 ]; then
        log_error "Failed backups: $error_count/$total_count"
        exit 1
    else
        log_success "All backups completed successfully!"
        echo ""
        log_info "Backup files created in current directory:"
        for config_file in "${ap_configs[@]}"; do
            if load_ap_config "$config_file" >/dev/null 2>&1; then
                local latest_backup=$(ls -t "${AP_NAME}".*.uciexport 2>/dev/null | head -1)
                if [ -n "$latest_backup" ]; then
                    log_info "  • $latest_backup"
                fi
            fi
        done
    fi
}

# Parse command line arguments
VERBOSE=false
AP_CONFIGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            AP_CONFIGS+=("$1")
            shift
            ;;
    esac
done

# Check if any access point configs were provided
if [ ${#AP_CONFIGS[@]} -eq 0 ]; then
    log_error "No access point configuration files specified!"
    echo ""
    usage
    exit 1
fi

# Validate that all config files exist
for config_file in "${AP_CONFIGS[@]}"; do
    if [ ! -f "$config_file" ]; then
        log_error "Access point config file not found: $config_file"
        exit 1
    fi
done

# Run backup
log_info "OpenWRT UCI Configuration Backup"
if [ "$VERBOSE" = "true" ]; then
    log_info "Verbose mode enabled"
fi

backup_all_aps "${AP_CONFIGS[@]}"
