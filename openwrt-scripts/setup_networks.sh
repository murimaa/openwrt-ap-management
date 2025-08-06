#!/bin/sh

CONFIG_DIR="./network-configs"
ROUTER_OVERRIDES_FILE="$CONFIG_DIR/router-overrides.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default options
DRY_RUN=false
VERBOSE=false

# Get router identification for logging
ROUTER_PREFIX=""
if [ -n "$ROUTER_NAME" ]; then
    ROUTER_PREFIX="[$ROUTER_NAME] "
elif [ -n "$ROUTER_IP" ]; then
    ROUTER_PREFIX="[$ROUTER_IP] "
fi

# Parse command line arguments
while [ $# -gt 0 ]; do
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
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -d, --dry-run     Show commands without executing them"
      echo "  -v, --verbose     Show commands being executed"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Logging functions
log_verbose() {
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${ROUTER_PREFIX}${CYAN}[VERBOSE]${NC} $1"
    fi
}

log_info() {
    echo -e "${ROUTER_PREFIX}${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${ROUTER_PREFIX}${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${ROUTER_PREFIX}${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${ROUTER_PREFIX}${RED}[ERROR]${NC} $1"
}

# UCI wrapper function
run_uci() {
  if [ "$DRY_RUN" = "true" ]; then
    echo -e "${ROUTER_PREFIX}${YELLOW}[DRY-RUN]${NC} uci $*"
  elif [ "$VERBOSE" = "true" ]; then
    echo -e "${ROUTER_PREFIX}${CYAN}[VERBOSE]${NC} uci $*"
  fi

  if [ "$DRY_RUN" = "false" ]; then
    uci "$@"
  fi
}

# UCI wrapper function for commands that return output
run_uci_capture() {
  if [ "$DRY_RUN" = "true" ]; then
    echo -e "${ROUTER_PREFIX}${YELLOW}[DRY-RUN]${NC} uci $*" >&2
  elif [ "$VERBOSE" = "true" ]; then
    echo -e "${ROUTER_PREFIX}${CYAN}[VERBOSE]${NC} uci $*" >&2
  fi

  if [ "$DRY_RUN" = "false" ]; then
    uci "$@"
  else
    # Return a dummy value in dry-run mode
    echo "cfg_dummy_$$"
  fi
}

# Other command wrapper function
run_cmd() {
  if [ "$DRY_RUN" = "true" ]; then
    echo -e "${ROUTER_PREFIX}${YELLOW}[DRY-RUN]${NC} $*"
  elif [ "$VERBOSE" = "true" ]; then
    echo -e "${ROUTER_PREFIX}${CYAN}[VERBOSE]${NC} $*"
  fi

  if [ "$DRY_RUN" = "false" ]; then
    "$@"
  fi
}

# Load router-specific overrides if they exist
if [ -f "$ROUTER_OVERRIDES_FILE" ]; then
  log_info "Loading router-specific overrides: $ROUTER_OVERRIDES_FILE"
  . "$ROUTER_OVERRIDES_FILE"
fi

# Function to apply VLAN overrides
apply_vlan_overrides() {
  local vlan_id="$1"

  # Apply VLAN-specific overrides using variable indirection
  eval "override_disabled=\$VLAN_OVERRIDE_${vlan_id}_disabled"
  eval "override_untagged=\$VLAN_OVERRIDE_${vlan_id}_untagged"
  eval "override_proto=\$VLAN_OVERRIDE_${vlan_id}_proto"
  eval "override_ipaddr=\$VLAN_OVERRIDE_${vlan_id}_ipaddr"
  eval "override_netmask=\$VLAN_OVERRIDE_${vlan_id}_netmask"
  eval "override_gateway=\$VLAN_OVERRIDE_${vlan_id}_gateway"
  eval "override_dns=\$VLAN_OVERRIDE_${vlan_id}_dns"
  eval "override_extra=\$VLAN_OVERRIDE_${vlan_id}_extra"

  # Apply overrides if they exist
  [ -n "$override_untagged" ] && VLAN_UNTAGGED="$override_untagged"
  [ -n "$override_proto" ] && VLAN_PROTO="$override_proto"
  [ -n "$override_ipaddr" ] && VLAN_IPADDR="$override_ipaddr"
  [ -n "$override_netmask" ] && VLAN_NETMASK="$override_netmask"
  [ -n "$override_gateway" ] && VLAN_GATEWAY="$override_gateway"
  [ -n "$override_dns" ] && VLAN_DNS="$override_dns"
  [ -n "$override_extra" ] && VLAN_EXTRA="$override_extra"

  # Check if this VLAN should be disabled on this router
  if [ "$override_disabled" = "1" ]; then
    log_warning "VLAN $vlan_id disabled by router override"
    return 1
  fi

  return 0
}

# === BACKUP ===
log_info "Backing up current config..."
if [ "$DRY_RUN" = "true" ]; then
  echo -e "${ROUTER_PREFIX}${YELLOW}[DRY-RUN]${NC} uci export > /etc/config/backup-before-vlan.txt"
else
  if [ "$VERBOSE" = "true" ]; then
    echo -e "${ROUTER_PREFIX}${CYAN}[VERBOSE]${NC} uci export > /etc/config/backup-before-vlan.txt"
  fi
  uci export > /etc/config/backup-before-vlan.txt
fi

# === CLEANUP EXISTING VLANs ===
log_info "Cleaning up existing VLANs from switch config..."
VLAN_COUNT=$(uci show network | grep -c '=switch_vlan' || echo "0")
if [ "$VLAN_COUNT" -gt 0 ]; then
  # Delete in reverse order to avoid index shifting
  i=$((VLAN_COUNT - 1))
  while [ $i -ge 0 ]; do
    log_info "Removing network.@switch_vlan[$i]..."
    run_uci -q delete "network.@switch_vlan[$i]"
    i=$((i - 1))
  done
fi

# === CLEANUP PREVIOUS VLAN/DEV INTERFACES ===
log_info "Cleaning up old VLAN-related config..."
VLAN_DEV_CONFIGS=$(uci show network | grep -E '=(interface|device)' | cut -d. -f2 | cut -d= -f1 | grep -E '^(dev[0-9]+|vlan[0-9]+)$')
for cfg in $VLAN_DEV_CONFIGS; do
  log_verbose "Removing network.${cfg}..."
  run_uci -q delete "network.$cfg"
done

# === DETECT SWITCH ===
HAS_SWITCH=0
if uci show network | grep -q '=switch'; then
  HAS_SWITCH=1
  log_info "Switch detected — configuring VLAN on switch0..."
else
  log_info "No switch detected — using ${MAIN_IFACE} directly"
fi

# === PROCESS EACH VLAN CONFIGURATION ===
log_info "Processing VLAN configurations..."
for FILE in "$CONFIG_DIR"/vlan_*.conf; do
  [ ! -f "$FILE" ] && continue

  log_info "Loading config: $FILE"

  # Load VLAN configuration
  . "$FILE"

  # Set defaults
  VLAN_UNTAGGED=${VLAN_UNTAGGED:-0}
  VLAN_PROTO=${VLAN_PROTO:-none}

  # Apply router-specific overrides for this VLAN
  if ! apply_vlan_overrides "$VLAN_ID"; then
    # VLAN is disabled, skip it
    unset VLAN_ID VLAN_NAME VLAN_DESCRIPTION VLAN_UNTAGGED VLAN_PROTO VLAN_IPADDR VLAN_NETMASK VLAN_GATEWAY VLAN_DNS VLAN_EXTRA
    continue
  fi

  log_info "Configuring VLAN $VLAN_ID ($VLAN_NAME)..."

  # === SWITCH VLAN CONFIGURATION ===
  if [ "$HAS_SWITCH" = "1" ]; then
    VLAN_SECTION=$(run_uci_capture add network switch_vlan)
    run_uci set network."$VLAN_SECTION".device='switch0'
    run_uci set network."$VLAN_SECTION".vlan="$VLAN_ID"

    if [ "$VLAN_UNTAGGED" = "1" ]; then
      log_info "Adding VLAN $VLAN_ID untagged to port $UPLINK_PORT"
      run_uci set network."$VLAN_SECTION".ports="${UPLINK_PORT} ${CPU_PORT}t"
      VLAN_IFACE="$MAIN_IFACE ${MAIN_IFACE}.${VLAN_ID}"
    else
      log_info "Adding VLAN $VLAN_ID tagged to port $UPLINK_PORT"
      run_uci set network."$VLAN_SECTION".ports="${UPLINK_PORT}t ${CPU_PORT}t"
      VLAN_IFACE="${MAIN_IFACE}.${VLAN_ID}"
    fi

    # Create bridge device for VLAN
    BRIDGE_NAME="br-vlan${VLAN_ID}"
    DEVICE_NAME="dev${VLAN_ID}"

    run_uci set network.$DEVICE_NAME=device
    run_uci set network.$DEVICE_NAME.name="$BRIDGE_NAME"
    run_uci set network.$DEVICE_NAME.type='bridge'
    run_uci set network.$DEVICE_NAME.ports="$VLAN_IFACE"

    INTERFACE_DEVICE="$BRIDGE_NAME"
  else
    # No switch - use VLAN interface directly
    if [ "$VLAN_UNTAGGED" = "1" ]; then
      INTERFACE_DEVICE="$MAIN_IFACE"
    else
      # Create bridge device for VLAN
      BRIDGE_NAME="br-vlan${VLAN_ID}"
      DEVICE_NAME="dev${VLAN_ID}"

      run_uci set network.$DEVICE_NAME=device
      run_uci set network.$DEVICE_NAME.name="$BRIDGE_NAME"
      run_uci set network.$DEVICE_NAME.type='bridge'

      INTERFACE_DEVICE="$BRIDGE_NAME"
    fi
  fi

  # === CREATE NETWORK INTERFACE ===
  INTERFACE_NAME="vlan$VLAN_ID"

  run_uci set network.$INTERFACE_NAME=interface
  run_uci set network.$INTERFACE_NAME.device="$INTERFACE_DEVICE"
  run_uci set network.$INTERFACE_NAME.proto="$VLAN_PROTO"

  # Configure static IP if specified
  if [ "$VLAN_PROTO" = "static" ]; then
    [ -n "$VLAN_IPADDR" ] && run_uci set network.$INTERFACE_NAME.ipaddr="$VLAN_IPADDR"
    [ -n "$VLAN_NETMASK" ] && run_uci set network.$INTERFACE_NAME.netmask="$VLAN_NETMASK"
    [ -n "$VLAN_GATEWAY" ] && run_uci set network.$INTERFACE_NAME.gateway="$VLAN_GATEWAY"
    [ -n "$VLAN_DNS" ] && run_uci set network.$INTERFACE_NAME.dns="$VLAN_DNS"
  fi

  # Apply extra UCI options if any
  if [ -n "$VLAN_EXTRA" ]; then
    for ENTRY in $VLAN_EXTRA; do
      KEY=$(echo "$ENTRY" | cut -d= -f1)
      VALUE=$(echo "$ENTRY" | cut -d= -f2-)
      run_uci set network.$INTERFACE_NAME.$KEY="$VALUE"
    done
  fi

  # Clean up variables for next iteration
  unset VLAN_ID VLAN_NAME VLAN_DESCRIPTION VLAN_UNTAGGED VLAN_PROTO VLAN_IPADDR VLAN_NETMASK VLAN_GATEWAY VLAN_DNS VLAN_EXTRA
done

# === Disable services that are not used in dumb AP's ===
log_info "Disabling firewall, dnsmasq, odhcpd..."
for i in firewall dnsmasq odhcpd; do
    log_verbose "Stopping $i if running..."
    if /etc/init.d/"$i" running; then
        run_cmd /etc/init.d/"$i" stop
    fi
    log_verbose "Disabling $i if enabled..."
    if /etc/init.d/"$i" enabled; then
        run_cmd /etc/init.d/"$i" disable
    fi
done

# === APPLY CONFIG ===
log_info "Applying configuration..."
run_uci commit
run_cmd /etc/init.d/network reload

log_success "Done."
