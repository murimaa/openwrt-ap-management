#!/bin/bash

# OpenWRT Complete Infrastructure Deployment Script
# Deploy both network and wireless configurations using access point configuration files

set -e  # Exit on error

# Configuration
NETWORK_DEPLOY_SCRIPT="./deploy-networks.sh"
WIRELESS_DEPLOY_SCRIPT="./deploy-wireless.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS] <ap-config.conf> [ap-config2.conf ...]"
    echo ""
    echo "Deploy complete OpenWRT infrastructure (networks + wireless) to access points."
    echo "This script runs both network and wireless deployments in sequence."
    echo ""
    echo "Options:"
    echo "  -n, --networks-only   Deploy only network configurations"
    echo "  -w, --wireless-only   Deploy only wireless configurations"
    echo "  -d, --dry-run         Show what would be deployed without making changes"
    echo "                        (passed to setup scripts - shows UCI commands without executing)"
    echo "  -v, --verbose         Enable verbose output"
    echo "                        (passed to setup scripts - shows all UCI commands being executed)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 aps/ap-main.conf                           # Complete deployment"
    echo "  $0 aps/*.conf                                 # Deploy to all access points"
    echo "  $0 -n aps/ap-main.conf                       # Networks only"
    echo "  $0 -w aps/ap-main.conf                       # Wireless only"
    echo "  $0 -d aps/ap-main.conf                       # Dry run both systems"
    echo "  $0 -v aps/ap-main.conf                       # Verbose output"
    echo ""
    echo "Access point config files should contain:"
    echo "  AP_IP=\"192.168.1.1\""
    echo "  AP_NAME=\"ap-main\""
    echo "  SSH_USER=\"root\"           # Optional, defaults to 'root'"
    echo "  SSH_PORT=\"22\"             # Optional, defaults to '22'"
    echo "  SSH_KEY=\"/path/to/key\"    # Optional SSH key"
    echo "  + network and wireless override variables"
    echo ""
    echo "Deployment Order:"
    echo "  1. Network deployment (VLANs, switches)"
    echo "  2. Wireless deployment (SSIDs, radio settings)"
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

log_stage() {
    echo -e "${PURPLE}[STAGE]${NC} $1"
}

# Check if required deployment scripts exist
check_requirements() {
    if [ ! -f "$NETWORK_DEPLOY_SCRIPT" ]; then
        log_error "Network deployment script not found: $NETWORK_DEPLOY_SCRIPT"
        exit 1
    fi

    if [ ! -f "$WIRELESS_DEPLOY_SCRIPT" ]; then
        log_error "Wireless deployment script not found: $WIRELESS_DEPLOY_SCRIPT"
        exit 1
    fi

    # Make sure scripts are executable
    chmod +x "$NETWORK_DEPLOY_SCRIPT"
    chmod +x "$WIRELESS_DEPLOY_SCRIPT"
}

# Build deployment arguments
build_deploy_args() {
    local args=()

    [ "$DRY_RUN" = "true" ] && args+=("-d")
    [ "$VERBOSE" = "true" ] && args+=("-v")

    echo "${args[@]}"
}

# Deploy networks to access points
deploy_networks() {
    local ap_configs=("$@")
    local deploy_args
    deploy_args=$(build_deploy_args)

    log_stage "Starting Network Deployment Phase"

    if $NETWORK_DEPLOY_SCRIPT $deploy_args "${ap_configs[@]}"; then
        log_success "Network deployment completed successfully"
        return 0
    else
        log_error "Network deployment failed"
        return 1
    fi
}

# Deploy wireless to access points
deploy_wireless() {
    local ap_configs=("$@")
    local deploy_args
    deploy_args=$(build_deploy_args)

    log_stage "Starting Wireless Deployment Phase"

    if $WIRELESS_DEPLOY_SCRIPT $deploy_args "${ap_configs[@]}"; then
        log_success "Wireless deployment completed successfully"
        return 0
    else
        log_error "Wireless deployment failed"
        return 1
    fi
}

# Main deployment function
deploy_complete() {
    local ap_configs=("$@")
    local network_success=false
    local wireless_success=false
    local total_count=${#ap_configs[@]}

    check_requirements

    log_info "OpenWRT Complete Infrastructure Deployment"
    log_info "Deploying to $total_count access point(s): ${ap_configs[*]##*/}"

    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN MODE - No actual changes will be made"
    fi

    echo ""

    # Deploy networks (unless wireless-only mode)
    if [ "$WIRELESS_ONLY" != "true" ]; then
        if deploy_networks "${ap_configs[@]}"; then
            network_success=true
        else
            if [ "$NETWORKS_ONLY" = "true" ]; then
                # If networks-only mode and it failed, exit
                exit 1
            else
                # If complete deployment and networks failed, don't try wireless
                log_error "Skipping wireless deployment due to network deployment failure"
                exit 1
            fi
        fi
        echo ""
    else
        network_success=true  # Not deploying networks, so consider it "successful"
    fi

    # Deploy wireless (unless networks-only mode)
    if [ "$NETWORKS_ONLY" != "true" ] && [ "$network_success" = "true" ]; then
        if deploy_wireless "${ap_configs[@]}"; then
            wireless_success=true
        fi
        echo ""
    else
        wireless_success=true  # Not deploying wireless, so consider it "successful"
    fi

    # Final summary
    log_info "Complete Deployment Summary:"

    if [ "$WIRELESS_ONLY" != "true" ]; then
        if [ "$network_success" = "true" ]; then
            log_success "✓ Network deployment: SUCCESS"
        else
            log_error "✗ Network deployment: FAILED"
        fi
    fi

    if [ "$NETWORKS_ONLY" != "true" ]; then
        if [ "$wireless_success" = "true" ]; then
            log_success "✓ Wireless deployment: SUCCESS"
        else
            log_error "✗ Wireless deployment: FAILED"
        fi
    fi

    if [ "$network_success" = "true" ] && [ "$wireless_success" = "true" ]; then
        log_success "🎉 Complete infrastructure deployment successful!"
        echo ""
        log_info "Your OpenWRT access points are now configured with:"
        [ "$WIRELESS_ONLY" != "true" ] && log_info "  • VLAN network segmentation"
        [ "$NETWORKS_ONLY" != "true" ] && log_info "  • Wireless networks mapped to VLANs"
        [ "$NETWORKS_ONLY" != "true" ] && log_info "  • Optimized radio settings"
        echo ""
        log_info "Next steps:"
        log_info "  • Verify connectivity to each VLAN/SSID"
        log_info "  • Monitor access point performance and adjust as needed"
        log_info "  • Test client connectivity across network segments"

        exit 0
    else
        log_error "⚠️  Infrastructure deployment completed with errors"
        exit 1
    fi
}

# Parse command line arguments
DRY_RUN=false
VERBOSE=false
NETWORKS_ONLY=false
WIRELESS_ONLY=false
AP_CONFIGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--networks-only)
            NETWORKS_ONLY=true
            shift
            ;;
        -w|--wireless-only)
            WIRELESS_ONLY=true
            shift
            ;;
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

# Validate mutually exclusive options
if [ "$NETWORKS_ONLY" = "true" ] && [ "$WIRELESS_ONLY" = "true" ]; then
    log_error "Cannot specify both --networks-only and --wireless-only"
    exit 1
fi

# Check if any router configs were provided
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

# Display deployment mode
if [ "$NETWORKS_ONLY" = "true" ]; then
    log_info "Mode: Networks Only"
elif [ "$WIRELESS_ONLY" = "true" ]; then
    log_info "Mode: Wireless Only"
else
    log_info "Mode: Complete Infrastructure (Networks + Wireless)"
fi

# Run deployment
deploy_complete "${AP_CONFIGS[@]}"
