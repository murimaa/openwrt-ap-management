# Example Usage: OpenWRT Network & Wireless Infrastructure Management

This document provides practical examples of using the unified network and wireless configuration system for OpenWrt routers.

## Quick Start Example

Let's say you have 3 routers and want to set up a complete VLAN-segmented network with wireless access across all of them.

### Step 1: Set Up Your VLAN Network Configurations

Your shared VLAN configs are in `network-configs/`:
- `vlan_10.conf` - Management network
- `vlan_20.conf` - Main user network
- `vlan_30.conf` - Guest network
- `vlan_40.conf` - IoT devices network
- `common-overrides.conf` - Hardware-specific network settings

**Example VLAN configurations:**

**network-configs/vlan_20.conf:**
```bash
#!/bin/sh
# Main User Network
VLAN_ID="20"
VLAN_NAME="main"
VLAN_DESCRIPTION="Main user network"
VLAN_UNTAGGED="0"
VLAN_PROTO="none"  # Dumb AP - no IP configuration
```

**network-configs/vlan_30.conf:**
```bash
#!/bin/sh
# Guest Network
VLAN_ID="30"
VLAN_NAME="guest"
VLAN_DESCRIPTION="Guest network"
VLAN_UNTAGGED="0"
VLAN_PROTO="none"
```

### Step 2: Set Up Your SSID Configurations

Your shared SSID configs are in `wireless-configs/`:
- `ssid_main.conf` - Your main home network (VLAN 20)
- `ssid_guest.conf` - Guest network (VLAN 30)
- `ssid_iot.conf` - IoT devices network (VLAN 40)
- `common-overrides.conf` - Hardware-specific wireless settings

**Example SSID configurations:**

**wireless-configs/ssid_main.conf:**
```bash
#!/bin/sh
# Main Home Network
SSID_NAME="HomeNetwork"
SSID_KEY="your-secure-password-123"
SSID_NETWORK="vlan20"      # VLAN 20 is main network
SSID_HIDDEN="0"
SSID_ENCRYPTION="sae"
SSID_FAST_ROAM="0"
SSID_BANDS="2g 5g"
```

**wireless-configs/ssid_guest.conf:**
```bash
#!/bin/sh
# Guest Network
SSID_NAME="GuestWifi"
SSID_KEY="guest-password-456"
SSID_NETWORK="vlan30"     # VLAN 30 is guest network
SSID_HIDDEN="0"
SSID_ENCRYPTION="sae"
SSID_FAST_ROAM="0"
SSID_BANDS="2g 5g"
```

### Step 3: Create Router Configuration Files

Create individual config files for each router in the `routers/` directory. These files contain both network and wireless overrides:

**routers/living-room.conf:**
```bash
#!/bin/sh
# Living Room Router (Main AP)
ROUTER_IP="192.168.1.1"
ROUTER_NAME="living-room"
ROUTER_LOCATION="Living room - main access point"
SSH_USER="root"
SSH_PORT="22"

# Network configuration (VLAN setup)
MAIN_IFACE="eth0"
UPLINK_PORT="1"
CPU_PORT="6"

# Network overrides - all VLANs enabled on main router
# No VLAN overrides needed - using defaults

# Wireless configuration
# Main router gets full power and all networks
RADIO_OVERRIDE_radio0_channel="6"        # 2.4GHz
RADIO_OVERRIDE_radio1_channel="36"       # 5GHz
RADIO_OVERRIDE_radio0_txpower="20"       # Max power
RADIO_OVERRIDE_radio1_txpower="23"       # Max power

# Optimize for performance
SSID_OVERRIDE_main_fast_roam="1"
SSID_OVERRIDE_main_extra="max_inactivity=7200"
```

**routers/bedroom.conf:**
```bash
#!/bin/sh
# Bedroom Router
ROUTER_IP="192.168.1.2"
ROUTER_NAME="bedroom"
ROUTER_LOCATION="Master bedroom"
SSH_USER="root"
SSH_PORT="22"

# Network configuration
MAIN_IFACE="eth0"
UPLINK_PORT="0"
CPU_PORT="6"

# Network overrides - disable guest VLAN in bedroom
VLAN_OVERRIDE_30_disabled="1"  # No guest network in private area

# Wireless configuration
# Different channels to avoid interference
RADIO_OVERRIDE_radio0_channel="11"       # 2.4GHz
RADIO_OVERRIDE_radio1_channel="149"      # 5GHz

# Lower power for bedroom (health/sleep concerns)
RADIO_OVERRIDE_radio0_txpower="15"
RADIO_OVERRIDE_radio1_txpower="18"

# Disable guest network in private area
SSID_OVERRIDE_guest_disabled="1"

# IoT only on 2.4GHz for better wall penetration
SSID_OVERRIDE_iot_bands="2g"
```

**routers/garage.conf:**
```bash
#!/bin/sh
# Garage Router
ROUTER_IP="192.168.1.10"
ROUTER_NAME="garage"
ROUTER_LOCATION="Garage/workshop area"
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
SSID_OVERRIDE_guest_disabled="1"
SSID_OVERRIDE_main_extra="max_inactivity=3600"
```

### Step 4: Deploy Complete Infrastructure

Now you can deploy both network and wireless configurations:

```bash
# Deploy complete infrastructure to single router (test first)
./deploy-complete.sh -d routers/living-room.conf

# Deploy complete infrastructure (actual deployment)
./deploy-complete.sh routers/living-room.conf

# Deploy to all routers
./deploy-complete.sh routers/*.conf

# Deploy only networks or only wireless
./deploy-networks.sh routers/*.conf     # VLANs only
./deploy-wireless.sh routers/*.conf     # Wireless only

# Deploy to specific routers
./deploy-complete.sh routers/living-room.conf routers/bedroom.conf
```

## Real-World Workflow Examples

### Scenario 1: Adding a New Router

You got a new router for the basement. Here's how to add it:

1. **Create router config:**
```bash
# routers/basement.conf
#!/bin/sh
ROUTER_IP="192.168.1.15"
ROUTER_NAME="basement"
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
SSID_OVERRIDE_guest_disabled="1"
SSID_OVERRIDE_iot_disabled="1"  # No separate IoT SSID
SSID_OVERRIDE_main_bands="2g 5g"  # Main network on both bands
```

2. **Test and deploy:**
```bash
./deploy-complete.sh -d routers/basement.conf  # Test first
./deploy-complete.sh routers/basement.conf     # Deploy
```

### Scenario 2: Updating Network Infrastructure

You want to add a new VLAN for security cameras across all routers:

1. **Create the new VLAN config:**
```bash
# network-configs/vlan_50.conf
#!/bin/sh
# Security Camera Network
VLAN_ID="50"
VLAN_NAME="cameras"
VLAN_DESCRIPTION="Security camera network"
VLAN_UNTAGGED="0"
VLAN_PROTO="none"
```

2. **Create corresponding wireless network:**
```bash
# wireless-configs/ssid_cameras.conf
#!/bin/sh
# Camera Management WiFi
SSID_NAME="CameraAdmin"
SSID_KEY="camera-mgmt-password-789"
SSID_NETWORK="vlan50"  # Maps to cameras VLAN
SSID_HIDDEN="1"         # Hidden network
SSID_ENCRYPTION="sae"
SSID_BANDS="5g"         # High bandwidth for camera access
```

3. **Deploy to all routers:**
```bash
./deploy-complete.sh routers/*.conf
```

### Scenario 3: Updating Multiple Routers

You want to change the guest network password across all routers:

1. **Update the shared SSID config:**
```bash
# Edit wireless-configs/ssid_guest.conf
SSID_KEY="new-guest-password-456"
```

2. **Deploy wireless only to all routers:**
```bash
./deploy-complete.sh routers/*.conf
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
SSID_OVERRIDE_main_encryption="sae"  # WPA3 for security
SSID_OVERRIDE_main_fast_roam="1"     # Seamless roaming for laptops
SSID_OVERRIDE_main_extra="max_inactivity=14400 disassoc_low_ack=0"

# IoT network for office devices (printers, etc.) - only if IoT VLAN enabled
SSID_OVERRIDE_iot_extra="isolate=1 max_num_sta=30"
```

2. **Deploy just the office router:**
```bash
./deploy-complete.sh routers/office.conf
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

## Advanced Examples

### Network Hardware-Specific Optimizations

Different router models have different switch configurations. Network-specific optimizations should go in `network-configs/common-overrides.conf`:

**Global network optimizations** (`network-configs/common-overrides.conf`):
```bash
#!/bin/sh
# Hardware-specific network adjustments applied to all routers

HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")

case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        # Archer C7 switch configuration
        MAIN_IFACE="eth1"
        UPLINK_PORT="1"
        CPU_PORT="0"
        ;;
    *"Archer AX"*)
        # AX series switch configuration
        MAIN_IFACE="eth0"
        UPLINK_PORT="1"
        CPU_PORT="6"
        ;;
    *"Netgear"*)
        # Netgear switch configuration
        MAIN_IFACE="eth0"
        UPLINK_PORT="0"
        CPU_PORT="5"
        ;;
esac
```

### Wireless Hardware-Specific Optimizations

Different router models need different wireless settings. Most hardware-specific optimizations should go in `wireless-configs/common-overrides.conf` to apply to all routers:

**Global wireless optimizations** (`wireless-configs/common-overrides.conf`):
```bash
#!/bin/sh
# Hardware-specific adjustments applied to all routers

# Set country code if needed (optional - no default is set)
# COUNTRY_CODE="FI"

HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")

case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        # Archer C7 specific settings
        RADIO_OVERRIDE_radio0_txpower="17"  # C7 runs hot
        RADIO_OVERRIDE_radio1_txpower="20"
        RADIO_OVERRIDE_radio0_htmode="HT20" # More stable
        ;;
    *"Archer AX"*)
        # AX series can handle more
        RADIO_OVERRIDE_radio0_txpower="20"
        RADIO_OVERRIDE_radio1_txpower="23"
        RADIO_OVERRIDE_radio1_htmode="HE80"  # WiFi 6
        ;;
    *"Netgear"*)
        # Netgear routers - good thermal management
        RADIO_OVERRIDE_radio0_txpower="18"
        RADIO_OVERRIDE_radio1_txpower="21"
        ;;
esac
```

**Router-specific overrides** (only if this router needs different settings):
```bash
# routers/special-archer.conf
#!/bin/sh
ROUTER_IP="192.168.1.25"
ROUTER_NAME="special-archer"
SSH_USER="root"
SSH_PORT="22"

# Base settings
RADIO_OVERRIDE_radio0_channel="11"
RADIO_OVERRIDE_radio1_channel="149"

# Override the common settings for this specific router
RADIO_OVERRIDE_radio0_txpower="14"  # Even lower for this location
```

## Debugging and Troubleshooting

### Verbose Deployment

See exactly what's happening during deployment:

```bash
./deploy-complete.sh -v routers/problem-router.conf
./deploy-networks.sh -v routers/problem-router.conf   # Networks only
./deploy-wireless.sh -v routers/problem-router.conf   # Wireless only
```

### Dry Run Testing

Always test before deploying:

```bash
# Test complete infrastructure on single router
./deploy-complete.sh -d routers/new-router.conf

# Test networks only
./deploy-networks.sh -d routers/new-router.conf

# Test wireless only
./deploy-wireless.sh -d routers/new-router.conf

# Test all routers
./deploy-complete.sh -d routers/*.conf

# Test with verbose output
./deploy-complete.sh -v -d routers/*.conf
```

### Manual Verification

After deployment, verify settings on the router:

```bash
# SSH to router and check
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
cat /tmp/network-config-*/network-configs/router-overrides.conf
cat /tmp/wireless-config-*/wireless-configs/router-overrides.conf
```

## Best Practices

1. **Always test first:** Use `-d` (dry run) before actual deployment
2. **Use version control:** Keep your router configs in git
3. **Use common overrides wisely:** Put hardware-specific settings in `common-overrides.conf`, router-specific settings in individual router configs
4. **Plan your VLANs:** Design your VLAN structure before deployment - changing VLANs later requires network reconfiguration
5. **Test network first:** Deploy networks before wireless to ensure VLAN structure is correct
6. **Set country code only if needed:** Country code has no default - only set `COUNTRY_CODE` if your deployment requires it
7. **Document changes:** Add comments explaining why you made specific overrides
8. **Test incrementally:** Deploy to one router first, then expand
9. **Keep backups:** Router configs are small, keep backups of working configurations
10. **Use descriptive names:** Router names should match their physical location/purpose
11. **Consistent naming:** Use consistent naming schemes for easy management
12. **Map SSIDs to VLANs:** Ensure wireless network names match VLAN network names for proper mapping

## Common Patterns

In these examples radio0 is the 2.4GHz radio and radio1 is the 5GHz radio. This may vary depending on the AP model.

### Complete Infrastructure Setup
```bash
# Network and wireless with optimized settings
# Network settings
MAIN_IFACE="eth0"
UPLINK_PORT="1"
CPU_PORT="6"

# Wireless settings
RADIO_OVERRIDE_radio0_htmode="HT40"
RADIO_OVERRIDE_radio1_htmode="VHT80"
RADIO_OVERRIDE_radio0_txpower="20"
RADIO_OVERRIDE_radio1_txpower="23"
SSID_OVERRIDE_main_fast_roam="1"

# Ensure SSID maps to VLAN
SSID_OVERRIDE_main_network="vlan20"     # Maps to main network
SSID_OVERRIDE_guest_network="vlan30"   # Maps to guest network
```

### VLAN-Only Setup (No Wireless)
```bash
# Pure switching setup - disable all wireless
SSID_OVERRIDE_main_disabled="1"
SSID_OVERRIDE_guest_disabled="1"
SSID_OVERRIDE_iot_disabled="1"

# Network configuration only
MAIN_IFACE="eth0"
UPLINK_PORT="1"
CPU_PORT="6"
```

### High-Performance Setup
```bash
# Maximum performance settings
RADIO_OVERRIDE_radio0_htmode="HT40"
RADIO_OVERRIDE_radio1_htmode="VHT80"
RADIO_OVERRIDE_radio0_txpower="20"
RADIO_OVERRIDE_radio1_txpower="23"
SSID_OVERRIDE_main_fast_roam="1"
```

### Low-Power Setup
```bash
# Reduced power settings
RADIO_OVERRIDE_radio0_txpower="12"
RADIO_OVERRIDE_radio1_txpower="15"
RADIO_OVERRIDE_radio0_htmode="HT20"
RADIO_OVERRIDE_radio1_htmode="VHT40"
```

### Guest-Network-Only Setup
```bash
# Network: only guest VLAN
VLAN_OVERRIDE_20_disabled="1"  # Disable main network VLAN
VLAN_OVERRIDE_40_disabled="1"  # Disable IoT VLAN

# Wireless: only guest SSID
SSID_OVERRIDE_main_disabled="1"
SSID_OVERRIDE_iot_disabled="1"
SSID_OVERRIDE_guest_extra="isolate=1 max_num_sta=10 max_inactivity=1800"
```

This unified approach gives you complete control over both network infrastructure (VLANs) and wireless access across all routers while maintaining shared configurations and simple deployment workflows. The system ensures wireless networks are properly mapped to VLANs for complete network segmentation.
