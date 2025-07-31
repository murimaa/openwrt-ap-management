#!/bin/sh

CONFIG_DIR="./wireless-configs"
RADIOS=$(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1)
COUNTRY_CODE="FI"

echo "[*] Cleaning up existing wireless interfaces..."
for iface in $(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1); do
  uci delete wireless.$iface
done

for FILE in "$CONFIG_DIR"/*.conf; do
  echo "[*] Loading config: $FILE"
  . "$FILE"

  SSID_HIDDEN=${SSID_HIDDEN:-0}
  SSID_ENCRYPTION=${SSID_ENCRYPTION:-sae}
  SSID_FAST_ROAM=${SSID_FAST_ROAM:-0}

  for RADIO in $RADIOS; do
    BAND=$(uci get wireless.$RADIO.band 2>/dev/null)
    IFNAME="${SSID_NETWORK}_${BAND:-$(echo $RADIO | tr -cd '0-9')}"

    echo "[+] Applying SSID '$SSID_NAME' to $BAND on $RADIO..."

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
  unset SSID_NAME SSID_KEY SSID_NETWORK SSID_HIDDEN SSID_ENCRYPTION SSID_FAST_ROAM SSID_EXTRA
done

echo "[*] Enabling radios..."
for RADIO in $RADIOS; do
  uci set wireless.$RADIO.disabled='0'
  uci set wireless.$RADIO.country="$COUNTRY_CODE"
done

echo "[*] Committing wireless config and reloading..."
uci commit wireless
wifi reload
