#!/bin/bash

# OpenWRT Wireless Configuration Deployment Script
# Deploy using access point configuration files that contain both IP and overrides

set -e  # Exit on error

# Configuration
SCRIPTS_DIR="openwrt-scripts"
CONFIG_DIR="wireless-configs"
SETUP_SCRIPT="setup_wireless.sh"
COMMON_OVERRIDES_FILE="$CONFIG_DIR/common-overrides.conf"
DEFAULT_SSH_USER="root"
DEFAULT_SSH_PORT="22"
SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no"
SCP_OPTS="-O $SSH_OPTS"

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
    echo "Deploy wireless configuration to OpenWrt access points using AP config files."
    echo ""
    echo "Options:"
    echo "  -d, --dry-run     Show what would be deployed without making changes"
    echo "                    (passed to setup script - shows UCI commands without executing)"
    echo "  -v, --verbose     Enable verbose output"
    echo "                    (passed to setup script - shows all UCI commands being executed)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 aps/ap-main.conf"
    echo "  $0 aps/ap-main.conf aps/ap-bedroom.conf"
    echo "  $0 aps/*.conf"
    echo "  $0 -d aps/ap-main.conf  # Dry run"
    echo "  $0 -v aps/ap-main.conf  # Verbose execution"
    echo ""
    echo "Access point config files should contain:"
    echo "  AP_IP=\"192.168.1.1\""
    echo "  AP_NAME=\"ap-main\""
    echo "  SSH_USER=\"root\"           # Optional, defaults to 'root'"
    echo "  SSH_PORT=\"22\"             # Optional, defaults to '22'"
    echo "  SSH_KEY=\"/path/to/key\"    # Optional SSH key"
    echo "  + wireless override variables"
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

# Check if required files exist
check_requirements() {
    if [ ! -d ./"$CONFIG_DIR" ]; then
        log_error "Configuration directory ./$CONFIG_DIR not found!"
        exit 1
    fi

    if [ ! -f "./$SCRIPTS_DIR/$SETUP_SCRIPT" ]; then
        log_error "Setup script ./$SCRIPTS_DIR/$SETUP_SCRIPT not found!"
        exit 1
    fi

    # Check for SSID config files
    SSID_COUNT=$(find ./"$CONFIG_DIR" -name "ssid_*.conf" | wc -l)
    if [ "$SSID_COUNT" -eq 0 ]; then
        log_error "No SSID configuration files found in ./$CONFIG_DIR!"
        exit 1
    fi

    log_verbose "Found $SSID_COUNT SSID configuration files"
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

# Create access point-specific override file content
create_override_content() {
    local config_file="$1"
    local temp_file=$(mktemp)

    cat "$COMMON_OVERRIDES_FILE" >> "$temp_file"
    cat "$config_file" >> "$temp_file"
    echo "$temp_file"
}

# Deploy to single access point
deploy_to_ap() {
    local config_file="$1"
    local dry_run="${2:-false}"

    log_info "Processing access point config: $config_file"

    # Load access point configuration
    if ! load_ap_config "$config_file"; then
        return 1
    fi

    log_info "Deploying to $AP_NAME ($AP_IP:$SSH_PORT)..."

    # Build SSH command options
    local ssh_cmd_opts="$SSH_OPTS -p $SSH_PORT"
    local scp_cmd_opts="$SCP_OPTS -P $SSH_PORT"
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd_opts="$ssh_cmd_opts -i $SSH_KEY"
        scp_cmd_opts="$scp_cmd_opts -i $SSH_KEY"
    fi

    # Test SSH connectivity
    if ! test_ssh "$AP_IP" "$SSH_USER" "$SSH_PORT" "$SSH_KEY"; then
        log_error "Cannot connect to $AP_IP:$SSH_PORT via SSH"
        return 1
    fi

    # Create access point-specific override content
    local override_content_file
    override_content_file=$(create_override_content "$config_file")

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY RUN] Would copy configuration files to $AP_IP"
        log_info "[DRY RUN] Would create access point overrides with $(wc -l < "$override_content_file") lines"
        if [ "$VERBOSE" = "true" ]; then
            log_verbose "[DRY RUN] Override content:"
            cat "$override_content_file" | sed 's/^/    /'
        fi
        log_info "[DRY RUN] Would execute setup script on $AP_IP"
    fi

    # Create temporary directory on access point
    local temp_dir="/tmp/wireless-config-$$"
    if ! ssh $ssh_cmd_opts "$SSH_USER@$AP_IP" "mkdir -p $temp_dir"; then
        log_error "Failed to create temporary directory on $AP_IP"
        rm -f "$override_content_file"
        return 1
    fi

    # Copy configuration files
    log_info "Copying wireless setup script..."
    if ! scp $scp_cmd_opts "$SCRIPTS_DIR/$SETUP_SCRIPT" "$SSH_USER@$AP_IP:$temp_dir/"; then
        log_error "Failed to copy $SCRIPTS_DIR/$SETUP_SCRIPT to $AP_IP"
        rm -f "$override_content_file"
        return 1
    fi

    # Copy configuration files
    log_info "Copying configuration files..."
    if ! scp $scp_cmd_opts -r ./"$CONFIG_DIR" "$SSH_USER@$AP_IP:$temp_dir/"; then
        log_error "Failed to copy configuration files to $AP_IP"
        rm -f "$override_content_file"
        return 1
    fi

    # Copy access point-specific override file
    log_info "Creating access point-specific overrides..."
    if ! scp $scp_cmd_opts "$override_content_file" "$SSH_USER@$AP_IP:$temp_dir/$CONFIG_DIR/router-overrides.conf"; then
        log_error "Failed to copy override file to $AP_IP"
        rm -f "$override_content_file"
        return 1
    fi

    # Clean up local temp file
    rm -f "$override_content_file"

    # Build setup script arguments
    local setup_args=""
    [ "$dry_run" = "true" ] && setup_args="$setup_args -d"
    [ "$VERBOSE" = "true" ] && setup_args="$setup_args -v"

    # Make setup script executable and run it
    log_info "Executing setup script..."
    if ssh $ssh_cmd_opts "$SSH_USER@$AP_IP" "cd $temp_dir && chmod +x $SETUP_SCRIPT && AP_NAME='$AP_NAME' AP_IP='$AP_IP' ROUTER_NAME='$AP_NAME' ROUTER_IP='$AP_IP' ./$SETUP_SCRIPT $setup_args"; then
        log_success "Configuration applied successfully on $AP_NAME ($AP_IP)"

        # Cleanup
        ssh $ssh_cmd_opts "$SSH_USER@$AP_IP" "rm -rf $temp_dir" 2>/dev/null || true
        return 0
    else
        log_error "Setup script failed on $AP_NAME ($AP_IP)"
        log_info "Temporary files left in $temp_dir for debugging"
        return 1
    fi
}

# Main deployment function
deploy_wireless() {
    local ap_configs=("$@")
    local dry_run="$DRY_RUN"

    check_requirements

    local success_count=0
    local error_count=0
    local total_count=${#ap_configs[@]}

    log_info "Starting deployment to $total_count access point(s)..."

    for config_file in "${ap_configs[@]}"; do
        if deploy_to_ap "$config_file" "$dry_run"; then
            ((success_count++))
        else
            ((error_count++))
        fi

        # Add a small delay between deployments (except for dry runs)
        if [ "$dry_run" != "true" ] && [ $((success_count + error_count)) -lt $total_count ]; then
            sleep 2
        fi
    done

    # Summary
    echo ""
    log_info "Deployment Summary:"
    log_success "Successful deployments: $success_count/$total_count"
    if [ "$error_count" -gt 0 ]; then
        log_error "Failed deployments: $error_count/$total_count"
        exit 1
    else
        log_success "All deployments completed successfully!"
    fi
}

# Parse command line arguments
DRY_RUN=false
VERBOSE=false
AP_CONFIGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
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

# Run deployment
log_info "OpenWRT Wireless Configuration Deployment"
if [ "$DRY_RUN" = "true" ]; then
    log_warning "DRY RUN MODE - No actual changes will be made"
fi
if [ "$VERBOSE" = "true" ]; then
    log_info "Verbose mode enabled"
fi

deploy_wireless "${AP_CONFIGS[@]}"
