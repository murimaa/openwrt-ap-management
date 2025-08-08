#!/bin/sh

CONFIG_DIR="./wireless-configs"

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

# Get access point identification for logging (supports legacy ROUTER_ variables)
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

RADIOS=$(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1)


# Load access point-specific overrides if they exist
ROUTER_OVERRIDES_FILE="$CONFIG_DIR/overrides.conf"  # Access point-specific overrides
if [ -f "$ROUTER_OVERRIDES_FILE" ]; then
  log_info "Loading access point-specific overrides: $ROUTER_OVERRIDES_FILE"
  . "$ROUTER_OVERRIDES_FILE"
  # Apply global overrides
fi

# Function to apply SSID overrides
apply_ssid_overrides() {
  local network="$1"

  # Apply SSID-specific overrides using variable indirection
  eval "override_disabled=\$SSID_OVERRIDE_${network}_disabled"
  eval "override_bands=\$SSID_OVERRIDE_${network}_bands"
  eval "override_hidden=\$SSID_OVERRIDE_${network}_hidden"
  eval "override_encryption=\$SSID_OVERRIDE_${network}_encryption"
  eval "override_fast_roam=\$SSID_OVERRIDE_${network}_fast_roam"
  eval "override_extra=\$SSID_OVERRIDE_${network}_extra"

  # Apply overrides if they exist
  [ -n "$override_bands" ] && SSID_BANDS="$override_bands"
  [ -n "$override_hidden" ] && SSID_HIDDEN="$override_hidden"
  [ -n "$override_encryption" ] && SSID_ENCRYPTION="$override_encryption"
  [ -n "$override_fast_roam" ] && SSID_FAST_ROAM="$override_fast_roam"
  [ -n "$override_extra" ] && SSID_EXTRA="$override_extra"

  # Check if this SSID should be disabled on this access point
  if [ "$override_disabled" = "1" ]; then
    log_warning "SSID '$ssid_name' disabled by access point override"
    return 1
  fi

  return 0
}

# Function to apply radio overrides
apply_radio_overrides() {
  local radio="$1"

  # Apply radio-specific overrides using variable indirection
  eval "override_channel=\$RADIO_OVERRIDE_${radio}_channel"
  eval "override_txpower=\$RADIO_OVERRIDE_${radio}_txpower"
  eval "override_htmode=\$RADIO_OVERRIDE_${radio}_htmode"
  eval "override_country=\$RADIO_OVERRIDE_${radio}_country"

  # Apply overrides if they exist
  [ -n "$override_channel" ] && run_uci set wireless.$radio.channel="$override_channel"
  [ -n "$override_txpower" ] && run_uci set wireless.$radio.txpower="$override_txpower"
  [ -n "$override_htmode" ] && run_uci set wireless.$radio.htmode="$override_htmode"
  [ -n "$override_country" ] && run_uci set wireless.$radio.country="$override_country"
}

log_info "Cleaning up existing wireless interfaces..."
for iface in $(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1); do
  log_verbose "Deleting interface wireless.$iface"
  run_uci delete wireless.$iface
done

for FILE in "$CONFIG_DIR"/ssid*.conf; do
  # Skip the router overrides file
  [ "$FILE" = "$ROUTER_OVERRIDES_FILE" ] && continue

  log_info "Loading config: $FILE"
  . "$FILE"

  SSID_HIDDEN=${SSID_HIDDEN:-0}
  SSID_ENCRYPTION=${SSID_ENCRYPTION:-sae}
  SSID_FAST_ROAM=${SSID_FAST_ROAM:-0}
  SSID_BANDS=${SSID_BANDS:-"2g 5g"}  # Default to both bands if not specified

  # Apply access point-specific overrides for this SSID
  if ! apply_ssid_overrides "$SSID_NETWORK"; then
    # SSID is disabled, skip it
    unset SSID_NAME SSID_KEY SSID_NETWORK SSID_HIDDEN SSID_ENCRYPTION SSID_FAST_ROAM SSID_EXTRA SSID_BANDS
    continue
  fi

  for RADIO in $RADIOS; do
    BAND=$(uci get wireless.$RADIO.band 2>/dev/null)

    # Skip this radio if it's not in the specified bands
    if ! echo "$SSID_BANDS" | grep -q "$BAND"; then
      log_warning "Skipping SSID '$SSID_NAME' on $BAND ($RADIO) - not in specified bands: $SSID_BANDS"
      continue
    fi

    IFNAME="${SSID_NETWORK}_${BAND:-$(echo $RADIO | tr -cd '0-9')}"

    log_info "Applying SSID '$SSID_NAME' to $BAND on $RADIO..."

    run_uci set wireless.$IFNAME="wifi-iface"
    run_uci set wireless.$IFNAME.device="$RADIO"
    run_uci set wireless.$IFNAME.mode="ap"
    run_uci set wireless.$IFNAME.ssid="$SSID_NAME"
    run_uci set wireless.$IFNAME.encryption="$SSID_ENCRYPTION"
    run_uci set wireless.$IFNAME.key="$SSID_KEY"
    run_uci set wireless.$IFNAME.network="$SSID_NETWORK"
    run_uci set wireless.$IFNAME.disabled="0"


    if [ "$SSID_HIDDEN" = "1" ]; then
        run_uci set wireless.$IFNAME.hidden="$SSID_HIDDEN"
    fi
    if [ "$SSID_FAST_ROAM" = "1" ]; then
      run_uci set wireless.$IFNAME.ieee80211r="1"
      run_uci set wireless.$IFNAME.ft_over_ds="0"
      run_uci set wireless.$IFNAME.ft_psk_generate_local="1"
    fi
    # Apply extra UCI options if any
    if [ -n "$SSID_EXTRA" ]; then
      for ENTRY in $SSID_EXTRA; do
        KEY=$(echo "$ENTRY" | cut -d= -f1)
        VALUE=$(echo "$ENTRY" | cut -d= -f2-)
        run_uci set wireless.$IFNAME.$KEY="$VALUE"
      done
    fi
  done

  # Clean up vars for safety
  unset SSID_NAME SSID_KEY SSID_NETWORK SSID_HIDDEN SSID_ENCRYPTION SSID_FAST_ROAM SSID_EXTRA SSID_BANDS
done

log_info "Enabling radios..."
for RADIO in $RADIOS; do
  run_uci set wireless.$RADIO.disabled='0'
  [ -n "$COUNTRY_CODE" ] && run_uci set wireless.$RADIO.country="$COUNTRY_CODE"
  run_uci set wireless.$RADIO.channel='auto'

  # Apply router-specific radio overrides
  apply_radio_overrides "$RADIO"
done

log_info "Committing wireless config and reloading..."
run_uci commit wireless
run_cmd wifi reload

log_success "Done."
