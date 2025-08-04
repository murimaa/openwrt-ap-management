#!/bin/sh

CONFIG_DIR="./wireless-configs"
RADIOS=$(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1)


# Load router-specific overrides if they exist
ROUTER_OVERRIDES_FILE="$CONFIG_DIR/router-overrides.conf"
if [ -f "$ROUTER_OVERRIDES_FILE" ]; then
  echo "[*] Loading router-specific overrides: $ROUTER_OVERRIDES_FILE"
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

  # Check if this SSID should be disabled on this router
  if [ "$override_disabled" = "1" ]; then
    echo "    [-] SSID '$SSID_NAME' disabled by router override"
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
  [ -n "$override_channel" ] && uci set wireless.$radio.channel="$override_channel"
  [ -n "$override_txpower" ] && uci set wireless.$radio.txpower="$override_txpower"
  [ -n "$override_htmode" ] && uci set wireless.$radio.htmode="$override_htmode"
  [ -n "$override_country" ] && uci set wireless.$radio.country="$override_country"
}

echo "[*] Cleaning up existing wireless interfaces..."
for iface in $(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1); do
  uci delete wireless.$iface
done

for FILE in "$CONFIG_DIR"/ssid*.conf; do
  # Skip the router overrides file
  [ "$FILE" = "$ROUTER_OVERRIDES_FILE" ] && continue

  echo "[*] Loading config: $FILE"
  . "$FILE"

  SSID_HIDDEN=${SSID_HIDDEN:-0}
  SSID_ENCRYPTION=${SSID_ENCRYPTION:-sae}
  SSID_FAST_ROAM=${SSID_FAST_ROAM:-0}
  SSID_BANDS=${SSID_BANDS:-"2g 5g"}  # Default to both bands if not specified

  # Apply router-specific overrides for this SSID
  if ! apply_ssid_overrides "$SSID_NETWORK"; then
    # SSID is disabled, skip it
    unset SSID_NAME SSID_KEY SSID_NETWORK SSID_HIDDEN SSID_ENCRYPTION SSID_FAST_ROAM SSID_EXTRA SSID_BANDS
    continue
  fi

  for RADIO in $RADIOS; do
    BAND=$(uci get wireless.$RADIO.band 2>/dev/null)

    # Skip this radio if it's not in the specified bands
    if ! echo "$SSID_BANDS" | grep -q "$BAND"; then
      echo "    [-] Skipping SSID '$SSID_NAME' on $BAND ($RADIO) - not in specified bands: $SSID_BANDS"
      continue
    fi

    IFNAME="${SSID_NETWORK}_${BAND:-$(echo $RADIO | tr -cd '0-9')}"

    echo "    [+] Applying SSID '$SSID_NAME' to $BAND on $RADIO..."

    uci set wireless.$IFNAME="wifi-iface"
    uci set wireless.$IFNAME.device="$RADIO"
    uci set wireless.$IFNAME.mode="ap"
    uci set wireless.$IFNAME.ssid="$SSID_NAME"
    uci set wireless.$IFNAME.encryption="$SSID_ENCRYPTION"
    uci set wireless.$IFNAME.key="$SSID_KEY"
    uci set wireless.$IFNAME.network="$SSID_NETWORK"
    uci set wireless.$IFNAME.disabled="0"


    if [ "$SSID_HIDDEN" = "1" ]; then
        uci set wireless.$IFNAME.hidden="$SSID_HIDDEN"
    fi
    if [ "$SSID_FAST_ROAM" = "1" ]; then
      uci set wireless.$IFNAME.ieee80211r="1"
      uci set wireless.$IFNAME.ft_over_ds="0"
      uci set wireless.$IFNAME.ft_psk_generate_local="1"
    fi
    # Apply extra UCI options if any
    if [ -n "$SSID_EXTRA" ]; then
      for ENTRY in $SSID_EXTRA; do
        KEY=$(echo "$ENTRY" | cut -d= -f1)
        VALUE=$(echo "$ENTRY" | cut -d= -f2-)
        uci set wireless.$IFNAME.$KEY="$VALUE"
      done
    fi
  done

  # Clean up vars for safety
  unset SSID_NAME SSID_KEY SSID_NETWORK SSID_HIDDEN SSID_ENCRYPTION SSID_FAST_ROAM SSID_EXTRA SSID_BANDS
done

echo "[*] Enabling radios..."
for RADIO in $RADIOS; do
  uci set wireless.$RADIO.disabled='0'
  [ -n "$COUNTRY_CODE" ] && uci set wireless.$RADIO.country="$COUNTRY_CODE"
  uci set wireless.$RADIO.channel='auto'

  # Apply router-specific radio overrides
  apply_radio_overrides "$RADIO"
done

echo "[*] Committing wireless config and reloading..."
uci commit wireless
wifi reload
