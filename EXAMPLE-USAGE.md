# Example Usage: OpenWRT Network & Wireless Infrastructure Management

This document provides practical examples of using the unified network and wireless configuration system for OpenWrt access points.

## Quick Start Example

Let's say you have 3 access points and want to set up a complete VLAN-segmented network with wireless access across all of them.

### Step 1: Set Up Your VLAN Network Configurations

Your shared VLAN configs are in `network-configs/`:
- `vlan_10.conf` - Management network
- `vlan_20.conf` - Main user network
- `vlan_30.conf` - Guest network
- `vlan_40.conf` - IoT devices network
- `common-overrides.conf` - Hardware-specific network settings

**Example VLAN configurations:**

**network-configs/vlan_10_mgmt.conf:**
```bash
VLAN_ID="10"
VLAN_NAME="mgmt"
VLAN_DESCRIPTION="Management Network"
# This VLAN is tagged on uplink port (trunk port)
# You can also override this per AP if it varies
VLAN_UNTAGGED="0"
VLAN_PROTO="dhcp"  # Access point gets IP on this VLAN
```

**network-configs/vlan_20_main.conf:**
```bash
#!/bin/sh
# Main User Network
VLAN_ID="20"
VLAN_NAME="main"
VLAN_DESCRIPTION="Main user network"
VLAN_UNTAGGED="0"
VLAN_PROTO="none"  # Dumb AP - no IP configuration (default)
```

**network-configs/vlan_30_guest.conf:**
```bash
#!/bin/sh
# Guest Network
VLAN_ID="30"
VLAN_NAME="guest"
VLAN_DESCRIPTION="Guest network"
VLAN_UNTAGGED="0"
VLAN_PROTO="none"  # Dumb AP - no IP configuration (default)
```

**network-configs/vlan_40_iot.conf**
**other vlans similarly**

### Step 2: Set Up Your SSID Configurations

Your shared SSID configs are in `wireless-configs/`:
- `ssid_main.conf` - Your main home network (VLAN 20)
- `ssid_guest.conf` - Guest network (VLAN 30)
- `ssid_iot.conf` - IoT devices network (VLAN 40)
- `common-overrides.conf` - Hardware-specific wireless settings

**Example SSID configurations:**

**No SSID defined for vlan10 (management)**

**wireless-configs/ssid_vlan20_main.conf:**
```bash
#!/bin/sh
# Main Home Network
SSID_NAME="HomeNetwork"
SSID_KEY="your-secure-password-123"
SSID_NETWORK="vlan20"      # VLAN 20 is main network
SSID_HIDDEN="0"
SSID_ENCRYPTION="sae" # WPA3 for security
SSID_FAST_ROAM="1"
SSID_BANDS="5g" # Just 5GHz for main network
```

**wireless-configs/ssid_vlan30_guest.conf:**
```bash
#!/bin/sh
# Guest Network
SSID_NAME="GuestWifi"
SSID_KEY="guest-password-456"
SSID_NETWORK="vlan30"     # VLAN 30 is guest network
SSID_HIDDEN="0"
SSID_ENCRYPTION="sae"
SSID_FAST_ROAM="1"
SSID_BANDS="2g 5g"
```

**wireless-configs/ssid_vlan40_iot.conf**
```bash
#!/bin/sh
# IoT Devices Network
SSID_NAME="IoTNWifi"
SSID_KEY="iot-password-789"
SSID_NETWORK="vlan40"     # VLAN 40 is IoT network
SSID_HIDDEN="0"
SSID_ENCRYPTION="sae-mixed" # Mixed WPA2/WPA3 for compatibility
SSID_FAST_ROAM="0"
SSID_BANDS="2g" # only 2.4GHz needed for IoT devices
```

**other ssids similarly**

### Step 3: Create Access Point Configuration Files

Create individual config files for each access point in the `aps/` directory. These files contain both network and wireless overrides:

**aps/ap-living-room.conf:**
```bash
#!/bin/sh
# Living Room Access Point (Main AP)
AP_IP="192.168.1.1"
AP_NAME="ap-living-room"
AP_LOCATION="Living room - main access point"
SSH_USER="root"
SSH_PORT="22"

# Network configuration (VLAN setup)
# Device specific - Refer to /etc/board.json!
# CPU port looks something like this:
# "ports": [
#				{
#					"num": 0, <-- CPU_PORT="0"
#					"device": "eth0",
#					"need_tag": false,
#					"want_untag": false
#				},
#       ...
#  ]
MAIN_IFACE="eth0"
UPLINK_PORT="1"
CPU_PORT="0"

# Network overrides - all VLANs enabled on main access point
# No VLAN overrides needed - using defaults

# Wireless configuration
# Main access point gets full power and all networks
# Bands in radio0 and radio1 may be in either order depending on device
RADIO_OVERRIDE_radio0_channel="6"        # 2.4GHz
RADIO_OVERRIDE_radio1_channel="36"       # 5GHz
RADIO_OVERRIDE_radio0_txpower="20"       # Max power
RADIO_OVERRIDE_radio1_txpower="23"       # Max power

# Optimize for performance
SSID_OVERRIDE_vlan20_fast_roam="1"
SSID_OVERRIDE_vlan20_extra="max_inactivity=7200"
```

**aps/ap-bedroom.conf:**
```bash
#!/bin/sh
# Bedroom Access Point
AP_IP="192.168.1.2"
AP_NAME="ap-bedroom"
AP_LOCATION="Master bedroom"
SSH_USER="root"
SSH_PORT="22"

MAIN_IFACE="eth0"
UPLINK_PORT="0"
CPU_PORT="6"

VLAN_OVERRIDE_30_disabled="1"    # No guest network in private areas
VLAN_OVERRIDE_10_untagged="1"    # Management VLAN is untagged in bedroom uplink port

# Bedroom access point uses different channels and lower power
# Different channels to avoid interference
RADIO_OVERRIDE_radio0_channel="11"       # 2.4GHz
RADIO_OVERRIDE_radio1_channel="149"      # 5GHz
# Lower power for bedroom
RADIO_OVERRIDE_radio0_txpower="15"
RADIO_OVERRIDE_radio1_txpower="18"

# Disable guest network in private area
SSID_OVERRIDE_vlan30_disabled="1"

```

**aps/ap-garage.conf:**
```bash
#!/bin/sh
# Garage Access Point
AP_IP="192.168.1.10"
AP_NAME="ap-garage"
AP_LOCATION="Garage/workshop area"
SSH_USER="root"
SSH_PORT="22"

# Network configuration
MAIN_IFACE="eth0"
UPLINK_PORT="0"
CPU_PORT="6"

# Network overrides - limited VLANs in garage
VLAN_OVERRIDE_30_disabled="1"  # No guest network in garage

# Wireless configuration
# Industrial environment - different channels
RADIO_OVERRIDE_radio0_channel="1"        # 2.4GHz
RADIO_OVERRIDE_radio1_channel="44"       # 5GHz

# Medium power for garage coverage
RADIO_OVERRIDE_radio0_txpower="18"
RADIO_OVERRIDE_radio1_txpower="20"

# Only main network and IoT in garage
SSID_OVERRIDE_vlan30_disabled="1"
SSID_OVERRIDE_vlan20_extra="max_inactivity=3600"
```

### Step 4: Deploy Complete Infrastructure

Now you can deploy both network and wireless configurations:

```bash
# Deploy complete setings to single access point (dry-run, test first)
./deploy-complete.sh -d aps/ap-living-room.conf

# Deploy complete settings (actual deployment), with backup of current config
./deploy-complete.sh -b aps/ap-living-room.conf

# Deploy to all access points (new vlan and ssid added, enable for all devices)
./deploy-complete.sh aps/*.conf

# Deploy only networks or only wireless
./deploy-networks.sh aps/*.conf     # VLANs only
./deploy-wireless.sh aps/*.conf     # Wireless only

# Deploy to specific access points
./deploy-complete.sh aps/ap-living-room.conf aps/ap-bedroom.conf
```

## Real-World Workflow Examples

### Scenario 1: Adding a New Access Point

You got a new access point for the basement. Here's how to add it:

1. **Create access point config:**
```bash
# aps/ap-basement.conf
#!/bin/sh
AP_IP="192.168.1.15"
AP_NAME="ap-basement"
SSH_USER="root"
SSH_PORT="22"

# Network configuration
MAIN_IFACE="eth0"
UPLINK_PORT="4"  # Different uplink port on this model
CPU_PORT="0"

# Network overrides - basement gets limited VLANs
VLAN_OVERRIDE_30_disabled="1"  # No guest network in basement
VLAN_OVERRIDE_40_disabled="1"  # No separate IoT VLAN

# Wireless configuration
# Basement-specific settings
RADIO_OVERRIDE_radio0_channel="3"
RADIO_OVERRIDE_radio1_channel="157"
RADIO_OVERRIDE_radio0_txpower="20"  # High power for concrete walls
RADIO_OVERRIDE_radio1_txpower="23"

# Only main network needed in basement
SSID_OVERRIDE_vlan30_disabled="1"
SSID_OVERRIDE_vlan40_disabled="1"  # No separate IoT SSID
SSID_OVERRIDE_vlan20_bands="2g 5g"  # Main network on both bands
```

2. **Test and deploy:**
```bash
./deploy-complete.sh -d aps/ap-basement.conf  # Test first
./deploy-complete.sh aps/ap-basement.conf     # Deploy
```

### Scenario 2: Updating Network Infrastructure

You have created a new VLAN for security cameras (you do this in your actual router!), and want to add it across all access points.

1. **Create the new VLAN config:**
**network-configs/vlan_50_cameras.conf:**
```bash
#!/bin/sh
# Security Camera Network
VLAN_ID="50"
VLAN_NAME="cameras"
VLAN_DESCRIPTION="Security camera network"
VLAN_UNTAGGED="0"
VLAN_PROTO="none"
```

2. **Create corresponding wireless network:**
**wireless-configs/ssid_vlan50_cameras.conf:**
```bash
#!/bin/sh
# Camera Management WiFi
SSID_NAME="WifiForCameras"
SSID_KEY="camera-password-789"
SSID_NETWORK="vlan50"  # Maps to cameras VLAN
SSID_HIDDEN="1"         # Hidden network
SSID_ENCRYPTION="sae-mixed" # Mixed WPA2/WPA3 for compatibility
SSID_BANDS="5g"         # High bandwidth for camera access (if cameras support 5GHz)
```

3. **Deploy to all access points:**
```bash
./deploy-complete.sh aps/*.conf
```

### Scenario 3: Updating Multiple Access Points

You want to change the guest network password across all access points:

1. **Update the shared SSID config:**
```bash
# Edit wireless-configs/ssid_guest.conf
SSID_KEY="new-guest-password-456"
```

2. **Deploy wireless only to all access points (faster):**
```bash
./deploy-wireless.sh aps/*.conf
```

### Scenario 4: Updating Hardware-Specific Settings

You want to change power settings for all Archer routers:

1. **Update the common overrides:**
```bash
# Edit wireless-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer"*)
        RADIO_OVERRIDE_radio0_txpower="12"  # Reduced further
        RADIO_OVERRIDE_radio1_txpower="15"
        ;;
esac
```

2. **Deploy to all routers:**
```bash
./deploy-wireless.sh routers/*.conf
```

### Scenario 5: Router-Specific Customization

Your office router needs special settings for work devices:

1. **Update office router config:**
```bash
# routers/office.conf
#!/bin/sh
ROUTER_IP="192.168.1.5"
ROUTER_NAME="office"
SSH_USER="root"
SSH_PORT="22"

# Network configuration
MAIN_IFACE="eth0"
UPLINK_PORT="1"
CPU_PORT="6"

# Network overrides - office security requirements
VLAN_OVERRIDE_30_disabled="1"  # No guest network in office
VLAN_OVERRIDE_40_disabled="1"  # No IoT VLAN for security

# Add static IP for management VLAN
VLAN_OVERRIDE_10_proto="static"
VLAN_OVERRIDE_10_ipaddr="192.168.10.100"
VLAN_OVERRIDE_10_netmask="255.255.255.0"

# Wireless configuration
# Office-optimized settings
RADIO_OVERRIDE_radio0_channel="6"
RADIO_OVERRIDE_radio1_channel="48"  # DFS channel for less congestion
RADIO_OVERRIDE_radio1_htmode="VHT80"  # Max performance on 5GHz

# Disable guest network in office for security
SSID_OVERRIDE_guest_disabled="1"

# Optimize main network for work devices
SSID_OVERRIDE_vlan20_extra="max_inactivity=14400 disassoc_low_ack=0"

# IoT network for office devices (printers, etc.) - only if IoT VLAN enabled
SSID_OVERRIDE_vlan40_extra="isolate=1 max_num_sta=30"
```

2. **Deploy just the bedroom access point:**
```bash
./deploy-complete.sh aps/ap-bedroom.conf
```

### Scenario 6: SSH Key Authentication

For better security, you want to use SSH keys instead of passwords:

1. **Update router config with SSH key:**
```bash
# routers/secure-router.conf
#!/bin/sh
ROUTER_IP="192.168.1.20"
ROUTER_NAME="secure-router"
SSH_USER="root"
SSH_PORT="2222"  # Custom SSH port
SSH_KEY="/home/user/.ssh/openwrt_key"

# Rest of wireless config...
```

2. **Make sure your SSH key is set up on the router:**
```bash
# Copy your public key to the router
ssh-copy-id -p 2222 root@192.168.1.20
```

3. **Deploy using the key:**
```bash
./deploy-complete.sh routers/secure-router.conf
```

## Debugging and Troubleshooting

### Manual Verification

After deployment, verify settings on the access point:

```bash
# SSH to access point and check
ssh root@192.168.1.1

# Check network config
uci show network

# Check wireless config
uci show wireless

# Check if WiFi is running
wifi status

# Check switch configuration
swconfig dev switch0 show

# View logs
logread | grep -E "(network|wireless)"

# Check what overrides were applied
cat /tmp/network-config-*/network-configs/overrides.conf
cat /tmp/wireless-config-*/wireless-configs/overrides.conf
```

## Best Practices

- **Always test first:** Use `-d` (dry run) before actual deployment
- **Use version control:** Keep your access point configs in git
- **Test network first:** Deploy networks before wireless to ensure VLAN structure is correct
- **Set country code if needed:** Country code has no default - set `COUNTRY_CODE` if your area requires it
- **Document changes:** Add comments explaining why you made specific overrides
- **Test incrementally:** Deploy to one access point first, then expand
- **Keep backups:** Access point configs are small, keep backups of working configurations
- **Use descriptive names:** Access point names should match their physical location/purpose
