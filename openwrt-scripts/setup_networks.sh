#!/bin/sh

CONFIG_DIR="./network-configs"
ROUTER_OVERRIDES_FILE="$CONFIG_DIR/router-overrides.conf"

# Load router-specific overrides if they exist
if [ -f "$ROUTER_OVERRIDES_FILE" ]; then
  echo "[*] Loading router-specific overrides: $ROUTER_OVERRIDES_FILE"
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
    echo "    [-] VLAN $vlan_id disabled by router override"
    return 1
  fi

  return 0
}

# === BACKUP ===
echo "[*] Backing up current config..."
uci export > /etc/config/backup-before-vlan.txt

# === CLEANUP EXISTING VLANs ===
echo "[*] Cleaning up existing VLANs from switch config..."
while uci show network | grep -q '=switch_vlan'; do
  SECTION=$(uci show network | grep '=switch_vlan' | head -n1 | cut -d. -f2 | cut -d= -f1)
  echo "[*] Removing network.${SECTION}..."
  uci -q delete "network.${SECTION}"
done

# === CLEANUP PREVIOUS VLAN/DEV INTERFACES ===
echo "[*] Cleaning up old VLAN-related config..."
for cfg in $(uci show network | grep -E '=(interface|device)' | cut -d. -f2 | cut -d= -f1); do
  # Only delete if it matches devNN or vlanNN pattern
  if echo "$cfg" | grep -Eq '^(dev[0-9]+|vlan[0-9]+)$'; then
    uci -q delete "network.$cfg"
  fi
done

# === DETECT SWITCH ===
HAS_SWITCH=0
if uci show network | grep -q '=switch'; then
  HAS_SWITCH=1
  echo "[*] Switch detected — configuring VLAN on switch0..."
else
  echo "[*] No switch detected — using ${MAIN_IFACE} directly"
fi

# === PROCESS EACH VLAN CONFIGURATION ===
echo "[*] Processing VLAN configurations..."
for FILE in "$CONFIG_DIR"/vlan_*.conf; do
  [ ! -f "$FILE" ] && continue

  echo "[*] Loading config: $FILE"

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

  echo "    [+] Configuring VLAN $VLAN_ID ($VLAN_NAME)..."

  # === SWITCH VLAN CONFIGURATION ===
  if [ "$HAS_SWITCH" = "1" ]; then
    VLAN_SECTION=$(uci add network switch_vlan)
    uci set network."$VLAN_SECTION".device='switch0'
    uci set network."$VLAN_SECTION".vlan="$VLAN_ID"

    if [ "$VLAN_UNTAGGED" = "1" ]; then
      echo "        [+] Adding VLAN $VLAN_ID untagged to port $UPLINK_PORT"
      uci set network."$VLAN_SECTION".ports="${UPLINK_PORT} ${CPU_PORT}t"
      VLAN_IFACE="$MAIN_IFACE ${MAIN_IFACE}.${VLAN_ID}"
    else
      echo "        [+] Adding VLAN $VLAN_ID tagged to port $UPLINK_PORT"
      uci set network."$VLAN_SECTION".ports="${UPLINK_PORT}t ${CPU_PORT}t"
      VLAN_IFACE="${MAIN_IFACE}.${VLAN_ID}"
    fi

    # Create bridge device for VLAN
    BRIDGE_NAME="br-vlan${VLAN_ID}"
    DEVICE_NAME="dev${VLAN_ID}"

    uci set network.$DEVICE_NAME=device
    uci set network.$DEVICE_NAME.name="$BRIDGE_NAME"
    uci set network.$DEVICE_NAME.type='bridge'
    uci set network.$DEVICE_NAME.ports="$VLAN_IFACE"

    INTERFACE_DEVICE="$BRIDGE_NAME"
  else
    # No switch - use VLAN interface directly
    if [ "$VLAN_UNTAGGED" = "1" ]; then
      INTERFACE_DEVICE="$MAIN_IFACE"
    else
      # Create bridge device for VLAN
      BRIDGE_NAME="br-vlan${VLAN_ID}"
      DEVICE_NAME="dev${VLAN_ID}"

      uci set network.$DEVICE_NAME=device
      uci set network.$DEVICE_NAME.name="$BRIDGE_NAME"
      uci set network.$DEVICE_NAME.type='bridge'

      INTERFACE_DEVICE="$BRIDGE_NAME"
    fi
  fi

  # === CREATE NETWORK INTERFACE ===
  INTERFACE_NAME="vlan$VLAN_ID"

  uci set network.$INTERFACE_NAME=interface
  uci set network.$INTERFACE_NAME.device="$INTERFACE_DEVICE"
  uci set network.$INTERFACE_NAME.proto="$VLAN_PROTO"

  # Configure static IP if specified
  if [ "$VLAN_PROTO" = "static" ]; then
    [ -n "$VLAN_IPADDR" ] && uci set network.$INTERFACE_NAME.ipaddr="$VLAN_IPADDR"
    [ -n "$VLAN_NETMASK" ] && uci set network.$INTERFACE_NAME.netmask="$VLAN_NETMASK"
    [ -n "$VLAN_GATEWAY" ] && uci set network.$INTERFACE_NAME.gateway="$VLAN_GATEWAY"
    [ -n "$VLAN_DNS" ] && uci set network.$INTERFACE_NAME.dns="$VLAN_DNS"
  fi

  # Apply extra UCI options if any
  if [ -n "$VLAN_EXTRA" ]; then
    for ENTRY in $VLAN_EXTRA; do
      KEY=$(echo "$ENTRY" | cut -d= -f1)
      VALUE=$(echo "$ENTRY" | cut -d= -f2-)
      uci set network.$INTERFACE_NAME.$KEY="$VALUE"
    done
  fi

  # Clean up variables for next iteration
  unset VLAN_ID VLAN_NAME VLAN_DESCRIPTION VLAN_UNTAGGED VLAN_PROTO VLAN_IPADDR VLAN_NETMASK VLAN_GATEWAY VLAN_DNS VLAN_EXTRA
done

# === Disable services that are not used in dumb AP's ===
for i in firewall dnsmasq odhcpd; do
    echo "[*] Disabling $i..."
    if /etc/init.d/"$i" enabled; then
        /etc/init.d/"$i" disable
    fi
    if /etc/init.d/"$i" running; then
        /etc/init.d/"$i" stop
    fi
done

# === APPLY CONFIG ===
echo "[*] Applying configuration..."
uci commit
/etc/init.d/network reload

echo "[+] Done."
