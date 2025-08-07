# Common Overrides System

The common overrides system allows you to define network and wireless settings that apply to all access points in your infrastructure, while still allowing individual access points to override these settings when needed.

## Overview

The system works with two parallel override systems:

1. **Network Common Overrides** (`network-configs/common-overrides.conf`) - Applied to ALL access points' network/VLAN configuration
2. **Wireless Common Overrides** (`wireless-configs/common-overrides.conf`) - Applied to ALL access points' wireless configuration
3. **AP-Specific Overrides** (in individual `aps/*.conf` files) - Applied to specific access points for both network and wireless

When deploying, the system combines all files with AP-specific overrides taking precedence over common ones.

## File Structure

```
openwrt/
├── network-configs/
│   ├── common-overrides.conf       # Network settings applied to ALL access points
│   └── vlan_*.conf                 # VLAN definitions
├── wireless-configs/
│   ├── common-overrides.conf       # Wireless settings applied to ALL access points
│   └── ssid_*.conf                 # SSID definitions
├── aps/
│   ├── ap-main.conf                # AP-specific overrides (network + wireless)
│   └── ap-bedroom.conf             # AP-specific overrides (network + wireless)
├── deploy-networks.sh
├── deploy-wireless.sh
└── deploy-complete.sh
```

## How It Works

During deployment:
1. **Network Deployment**: Network common overrides → AP-specific network overrides → Applied to access point
2. **Wireless Deployment**: Wireless common overrides → AP-specific wireless overrides → Applied to access point
3. **Complete Deployment**: Both systems in sequence (networks first, then wireless)
4. AP-specific settings always override common ones

## When to Use Common Overrides

### ✅ Good Use Cases

**Network Common Overrides:**
- **Hardware-specific switch configurations** (port mappings, interface names)
- **Standard VLAN behaviors** that apply across all access points
- **Switch optimization settings** for access point families
- **Network interface defaults** based on hardware detection

**Wireless Common Overrides:**
- **Hardware-specific wireless optimizations** that apply to access point models
- **Country/regulatory settings** that are the same everywhere
- **Security baseline settings** that should be consistent
- **Power management defaults** for energy efficiency
- **Channel width settings** based on hardware capabilities

### ❌ Don't Use For

- **AP location-specific settings** (channels, power levels, specific port assignments)
- **Network topology settings** (different VLANs per access point, specific uplink ports)
- **Environment-specific optimizations** (bedroom vs garage settings)
- **Site-specific static IPs** or network configurations

## Network Common Overrides File Structure

```bash
#!/bin/sh
# Network common overrides applied to ALL access points
# These settings provide baseline network configurations and hardware optimizations

# ===========================================
# HARDWARE-SPECIFIC SWITCH CONFIGURATIONS
# ===========================================

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
    *"Netgear R7800"*)
        # Netgear R7800 switch configuration
        MAIN_IFACE="eth0"
        UPLINK_PORT="0"
        CPU_PORT="5"
        ;;
    *"Linksys WRT"*)
        # Linksys WRT series
        MAIN_IFACE="eth0"
        UPLINK_PORT="4"
        CPU_PORT="8"
        ;;
    *)
        # Default fallback configuration
        MAIN_IFACE="eth0"
        UPLINK_PORT="1"
        CPU_PORT="6"
        ;;
esac

# ===========================================
# GLOBAL VLAN BEHAVIOR DEFAULTS
# ===========================================

# Default VLAN protocols (access points can override per-VLAN)
# Most APs should use "none" for dumb AP operation
VLAN_OVERRIDE_10_proto="${VLAN_OVERRIDE_10_proto:-none}"  # Management
VLAN_OVERRIDE_20_proto="${VLAN_OVERRIDE_20_proto:-none}"  # Main
VLAN_OVERRIDE_30_proto="${VLAN_OVERRIDE_30_proto:-none}"  # Guest
VLAN_OVERRIDE_40_proto="${VLAN_OVERRIDE_40_proto:-none}"  # IoT

# ===========================================
# HARDWARE-SPECIFIC NETWORK OPTIMIZATIONS
# ===========================================

case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        # C7 series specific network optimizations
        # Use conservative settings for older hardware
        ;;
    *"Archer AX"*)
        # AX series can handle more aggressive settings
        # Enable hardware offloading if available
        ;;
esac
```

## Wireless Common Overrides File Structure

```bash
#!/bin/sh
# Wireless common overrides applied to ALL access points
# These settings provide baseline configurations and hardware optimizations

# ===========================================
# GLOBAL SETTINGS
# ===========================================

# Set country code if needed (optional - no default is set)
# Uncomment and set to your country code if required
# COUNTRY_CODE="FI"

# ===========================================
# HARDWARE-SPECIFIC OPTIMIZATIONS
# ===========================================

HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")

case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        # Archer C7 runs hot, use conservative settings
        RADIO_OVERRIDE_radio0_txpower="17"
        RADIO_OVERRIDE_radio1_txpower="20"
        RADIO_OVERRIDE_radio0_htmode="HT20"  # More stable
        ;;
    *"Archer AX"*)
        # AX series supports WiFi 6, optimize accordingly
        RADIO_OVERRIDE_radio0_txpower="20"
        RADIO_OVERRIDE_radio1_txpower="23"
        RADIO_OVERRIDE_radio1_htmode="HE80"
        ;;
    *"Netgear"*)
        # Netgear access points generally handle heat well
        RADIO_OVERRIDE_radio0_txpower="18"
        RADIO_OVERRIDE_radio1_txpower="21"
        ;;
    *"Linksys"*)
        # Some Linksys models prefer HT20 for stability
        RADIO_OVERRIDE_radio0_htmode="HT20"
        RADIO_OVERRIDE_radio1_htmode="VHT40"
        ;;
esac

# ===========================================
# GLOBAL SECURITY BASELINE
# ===========================================

# Ensure WPA3 is used where supported, fallback to WPA2
SSID_OVERRIDE_main_encryption="sae-mixed"
SSID_OVERRIDE_guest_encryption="sae-mixed"

# Enable management frame protection where possible
SSID_OVERRIDE_main_extra="ieee80211w=1"

# ===========================================
# POWER MANAGEMENT DEFAULTS
# ===========================================

# Conservative power settings that work for most environments
# Individual access points can increase/decrease as needed
RADIO_OVERRIDE_radio0_txpower="${RADIO_OVERRIDE_radio0_txpower:-15}"
RADIO_OVERRIDE_radio1_txpower="${RADIO_OVERRIDE_radio1_txpower:-18}"

# ===========================================
# PERFORMANCE BASELINE
# ===========================================

# Default channel widths that work well for most hardware
RADIO_OVERRIDE_radio0_htmode="${RADIO_OVERRIDE_radio0_htmode:-HT20}"
RADIO_OVERRIDE_radio1_htmode="${RADIO_OVERRIDE_radio1_htmode:-VHT40}"
```

## Access Point-Specific Override Examples

Individual access point configs can override settings from both common override systems:

```bash
#!/bin/sh
# aps/ap-high-performance.conf

AP_IP="192.168.1.1"
AP_NAME="ap-main"

# ===========================================
# NETWORK OVERRIDES
# ===========================================

# Override network hardware detection if needed
MAIN_IFACE="eth0"        # Override common detection
UPLINK_PORT="2"          # Different uplink port for this router

# AP-specific VLAN configuration
VLAN_OVERRIDE_10_proto="static"     # Management VLAN gets static IP
VLAN_OVERRIDE_10_ipaddr="192.168.10.100"
VLAN_OVERRIDE_10_netmask="255.255.255.0"

VLAN_OVERRIDE_30_disabled="1"       # Disable guest VLAN on this access point

# ===========================================
# WIRELESS OVERRIDES
# ===========================================

# Override common power settings for this high-performance location
RADIO_OVERRIDE_radio0_txpower="20"  # Higher than common default
RADIO_OVERRIDE_radio1_txpower="23"  # Higher than common default

# Override common channel width for better performance
RADIO_OVERRIDE_radio1_htmode="VHT80"  # Wider than common default

# Location-specific channel selection (not in common overrides)
RADIO_OVERRIDE_radio0_channel="6"
RADIO_OVERRIDE_radio1_channel="36"

# SSID-specific overrides
SSID_OVERRIDE_guest_disabled="1"    # No guest SSID
SSID_OVERRIDE_main_fast_roam="1"    # Enable fast roaming
```

## Deployment Integration

The common overrides work with all deployment methods:

```bash
# Complete infrastructure deployment (uses both common override systems)
./deploy-complete.sh aps/*.conf

# Network only (uses network common overrides)
./deploy-networks.sh aps/*.conf

# Wireless only (uses wireless common overrides)
./deploy-wireless.sh aps/*.conf
```

## Best Practices

### 1. Separate Network and Wireless Concerns

```bash
# Good: Keep network settings in network common overrides
# network-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer"*) MAIN_IFACE="eth0"; UPLINK_PORT="1" ;;
esac

# Good: Keep wireless settings in wireless common overrides
# wireless-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer"*) RADIO_OVERRIDE_radio0_txpower="17" ;;
esac
```

### 2. Use Hardware Detection Consistently

Both common override files should use the same hardware detection:

```bash
# Both files should use identical detection logic
HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")

case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        # Network settings in network common overrides
        # Wireless settings in wireless common overrides
        ;;
esac
```

### 3. Provide Fallback Defaults

```bash
# Good: Provides default but allows override
RADIO_OVERRIDE_radio0_txpower="${RADIO_OVERRIDE_radio0_txpower:-15}"
VLAN_OVERRIDE_20_proto="${VLAN_OVERRIDE_20_proto:-none}"

# Bad: Forces setting, can't be overridden easily
RADIO_OVERRIDE_radio0_txpower="15"
VLAN_OVERRIDE_20_proto="none"
```

### 4. Document Hardware-Specific Reasoning

```bash
# Good: Explains why settings exist
case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        # C7 switch has unusual port mapping
        MAIN_IFACE="eth1"    # Main interface is eth1, not eth0
        CPU_PORT="0"         # CPU port is 0, not 6

        # C7 also runs hot, reduce wireless power
        RADIO_OVERRIDE_radio0_txpower="17"  # Prevent thermal throttling
        ;;
esac
```

### 5. Group Related Settings Logically

```bash
# ===========================================
# SWITCH CONFIGURATION
# ===========================================
MAIN_IFACE="eth0"
UPLINK_PORT="1"
CPU_PORT="6"

# ===========================================
# VLAN DEFAULTS
# ===========================================
VLAN_OVERRIDE_10_proto="none"
VLAN_OVERRIDE_20_proto="none"
```

## Testing Common Overrides

### Test Complete Infrastructure

```bash
# Test how all overrides combine
./deploy-complete.sh -v -d aps/ap-test.conf
```

### Test Individual Systems

```bash
# Test network overrides only
./deploy-networks.sh -v -d aps/ap-test.conf

# Test wireless overrides only
./deploy-wireless.sh -v -d aps/ap-test.conf
```

### Verify Override Precedence

Create a test router config that overrides settings from both systems:

```bash
# routers/test-override.conf
ROUTER_IP="192.168.1.100"
ROUTER_NAME="test"

# Override network common setting
UPLINK_PORT="0"  # Should override common detection

# Override wireless common setting
RADIO_OVERRIDE_radio0_txpower="10"  # Should override common default
```

### Check Applied Settings

After deployment, verify on the router:

```bash
# Check network settings
ssh root@192.168.1.1 "uci show network | grep -E '(switch|device)'"

# Check wireless settings
ssh root@192.168.1.1 "uci show wireless | grep txpower"

# Check what overrides were applied
ssh root@192.168.1.1 "cat /tmp/*-config-*/*/router-overrides.conf"
```

## Common Patterns

### Pattern 1: Hardware Family Optimizations

```bash
# Network optimizations for hardware families
# network-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer C"*)
        # All Archer C series have similar switch layouts
        MAIN_IFACE="eth1"
        CPU_PORT="0"
        ;;
    *"Archer AX"*)
        # All Archer AX series have modern switch layouts
        MAIN_IFACE="eth0"
        CPU_PORT="6"
        ;;
esac

# Wireless optimizations for hardware families
# wireless-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer C"*)
        # Conservative wireless settings for older hardware
        RADIO_OVERRIDE_radio0_txpower="17"
        ;;
    *"Archer AX"*)
        # Modern hardware can handle more aggressive settings
        RADIO_OVERRIDE_radio1_htmode="HE80"
        ;;
esac
```

### Pattern 2: Coordinated Defaults

```bash
# Ensure network and wireless settings work together
# network-configs/common-overrides.conf - VLAN defaults
VLAN_OVERRIDE_20_proto="none"  # Main network as dumb AP
VLAN_OVERRIDE_30_proto="none"  # Guest network as dumb AP

# wireless-configs/common-overrides.conf - SSID mappings
SSID_OVERRIDE_main_network="main"      # Maps to VLAN 20
SSID_OVERRIDE_guest_network="guest"    # Maps to VLAN 30
```

### Pattern 3: Environment-Based Defaults

```bash
# Set conservative defaults that specific environments can override
# wireless-configs/common-overrides.conf
RADIO_OVERRIDE_radio0_txpower="15"  # Conservative for bedrooms
RADIO_OVERRIDE_radio1_txpower="18"  # Conservative for bedrooms

# High-traffic areas override with higher power
# routers/living-room.conf
RADIO_OVERRIDE_radio0_txpower="20"  # Override for main area
RADIO_OVERRIDE_radio1_txpower="23"  # Override for main area
```

## Migration to Dual Common Overrides

If you have settings scattered across router configs:

### 1. Identify Network vs Wireless Settings

**Network Settings** (move to `network-configs/common-overrides.conf`):
- `MAIN_IFACE`, `UPLINK_PORT`, `CPU_PORT`
- `VLAN_OVERRIDE_*` settings that apply globally
- Switch-related optimizations

**Wireless Settings** (move to `wireless-configs/common-overrides.conf`):
- `RADIO_OVERRIDE_*` settings
- `SSID_OVERRIDE_*` settings that apply globally
- Country codes and regulatory settings

### 2. Example Migration

**Before:** Duplicate across router configs
```bash
# routers/router1.conf
case "$HARDWARE_MODEL" in
    *"Archer"*)
        MAIN_IFACE="eth1"
        RADIO_OVERRIDE_radio0_txpower="17"
        ;;
esac

# routers/router2.conf
case "$HARDWARE_MODEL" in
    *"Archer"*)
        MAIN_IFACE="eth1"
        RADIO_OVERRIDE_radio0_txpower="17"
        ;;
esac
```

**After:** Centralized in appropriate common overrides
```bash
# network-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer"*) MAIN_IFACE="eth1" ;;
esac

# wireless-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer"*) RADIO_OVERRIDE_radio0_txpower="17" ;;
esac

# routers/router1.conf - only location-specific settings
RADIO_OVERRIDE_radio0_channel="6"
UPLINK_PORT="1"

# routers/router2.conf - only location-specific settings
RADIO_OVERRIDE_radio0_channel="11"
UPLINK_PORT="2"
```

## Troubleshooting

### Network Override Issues

```bash
# Check network hardware detection
ssh root@router "cat /tmp/sysinfo/model"

# Verify network overrides applied
ssh root@router "uci show network | grep -E '(switch|device|interface)'"

# Check network override file
ssh root@router "cat /tmp/network-config-*/network-configs/router-overrides.conf"
```

### Wireless Override Issues

```bash
# Check wireless overrides applied
ssh root@router "uci show wireless | grep -E '(txpower|htmode|channel)'"

# Check wireless override file
ssh root@router "cat /tmp/wireless-config-*/wireless-configs/router-overrides.conf"
```

### Override Precedence Issues

1. **Router-specific always wins**: Check if router config overrides common setting
2. **Syntax errors**: Verify shell syntax in override files
3. **Hardware detection**: Ensure hardware model detection works correctly
4. **Variable conflicts**: Check for conflicting variable assignments

This dual common overrides system provides clean separation between network infrastructure and wireless configuration while maintaining hardware-specific optimizations and allowing complete per-router customization when needed.
