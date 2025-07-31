#!/bin/sh

CONFIG_FILE="./setup_networks.conf"

if [ -f "$CONFIG_FILE" ]; then
  echo "[*] Loading configuration from $CONFIG_FILE"
  . "$CONFIG_FILE"
else
  echo "[!] Config file $CONFIG_FILE not found ... aborting"
  exit 1
fi

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

# === CLEANUP ALL MGMT FIREWALL ZONES ===
echo "[*] Removing all 'mgmt' firewall zones..."
for rid in $(uci show firewall | grep "mgmt" | cut -d= -f1 | grep -E '^[^.]+\.[^.]+\.name' | cut -d. -f1-2); do
  echo "[-] Deleting firewall section $rid"
  uci -q delete "$rid"
done

# === DETECT SWITCH AND ADD VLAN TAGGING IF NEEDED ===
# === MGMT VLAN ===
if uci show network | grep -q '=switch'; then
  echo "[*] Switch detected — configuring VLAN on switch0..."

  VLAN_SECTION=$(uci add network switch_vlan)
  uci set network."$VLAN_SECTION".device='switch0'
  uci set network."$VLAN_SECTION".vlan="$MGMT_VLAN"
  if [ "$MGMT_UNTAGGED" = "1" ]; then
    echo "[+] Adding mgmt VLAN $MGMT_VLAN untagged to port $UPLINK_PORT"
    uci set network."$VLAN_SECTION".ports="${UPLINK_PORT} ${CPU_PORT}t"
  else
    echo "[+] Adding mgmt VLAN $MGMT_VLAN tagged to port $UPLINK_PORT"
    uci set network."$VLAN_SECTION".ports="${UPLINK_PORT}t ${CPU_PORT}t"
  fi
  MGMT_IFACE="br-mgmt"
  # === CREATE MGMT BRIDGE DEVICE (devmgmt) ===
  echo "[*] Creating bridge br-mgmt with $MAIN_IFACE and $MAIN_IFACE.$MGMT_VLAN"
  uci set network.devmgmt=device
  uci set network.devmgmt.name="$MGMT_IFACE"
  uci set network.devmgmt.type='bridge'
  uci set network.devmgmt.ports="$MAIN_IFACE ${MAIN_IFACE}.${MGMT_VLAN}"
else
  echo "[*] No switch detected — using $MAIN_IFACE directly"
  MGMT_IFACE=$([ "$MGMT_UNTAGGED" = "1" ] && echo "$MAIN_IFACE" || echo "${MAIN_IFACE}.${MGMT_VLAN}")
fi

# === CONFIGURE MGMT INTERFACE ===
echo "[*] Setting up management interface on br-mgmt..."
uci set network.mgmt=interface
uci set network.mgmt.device="$MGMT_IFACE"
uci set network.mgmt.proto='dhcp'

# === CONFIGURE FIREWALL FOR MGMT ===
uci add firewall zone
uci set firewall.@zone[-1].name='mgmt'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='REJECT'
uci add_list firewall.@zone[-1].network='mgmt'

# === CONFIGURE OTHER VLANs ===
echo "[*] Configuring VLANs: $VLAN_LIST"
for VLAN in $VLAN_LIST; do
  BRIDGE_NAME="br-vlan$VLAN"
  DEVICE_NAME="dev$VLAN"
  INTERFACE_NAME="vlan$VLAN"
  TAGGED_IFACE="${MAIN_IFACE}.${VLAN}"

  # Add switch VLAN tagging (CPU only, you can extend this)
  if uci show network | grep -q '=switch'; then
    VLAN_SECTION=$(uci add network switch_vlan)
    uci set network."$VLAN_SECTION".device='switch0'
    uci set network."$VLAN_SECTION".vlan="$VLAN"
    uci set network."$VLAN_SECTION".ports="${UPLINK_PORT}t ${CPU_PORT}t"
  fi

  uci set network.$DEVICE_NAME=device
  uci set network.$DEVICE_NAME.name="$BRIDGE_NAME"
  uci set network.$DEVICE_NAME.type='bridge'
  uci add_list network.$DEVICE_NAME.ports="$TAGGED_IFACE"

  uci set network.$INTERFACE_NAME=interface
  uci set network.$INTERFACE_NAME.device="$BRIDGE_NAME"
  uci set network.$INTERFACE_NAME.proto='none'
done

# === Disable dnsmasq ===
/etc/init.d/dnsmasq stop
/etc/init.d/dnsmasq disable

# === APPLY CONFIG ===
echo "[*] Applying configuration..."
uci commit
# /etc/init.d/network reload
# /etc/init.d/firewall restart

echo "[+] Done. Please reboot to apply cleanly."
echo "    Or run: /etc/init.d/network reload && /etc/init.d/firewall restart"
