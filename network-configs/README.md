# OpenWRT Network Configuration System

This directory contains the network configuration system for OpenWRT routers, focused on VLAN setup, switch configuration, and network segmentation.

## 📁 Directory Structure

```
network-configs/
├── common-overrides.conf      # Hardware-specific settings applied to ALL routers
├── vlan_10.conf              # Management VLAN definition
├── vlan_20.conf              # Guest VLAN definition
├── vlan_30.conf              # IoT VLAN definition
└── vlan_*.conf               # Additional VLAN definitions
```

## 🌐 How It Works

### 1. VLAN Configuration Files (`vlan_*.conf`)

Each VLAN is defined in its own configuration file following the naming pattern `vlan_<ID>.conf`.

**Basic VLAN Configuration:**
```bash
# vlan_10.conf
VLAN_ID="10"                    # VLAN ID (must match filename)
VLAN_NAME="mgmt"                # Network interface name in UCI
VLAN_DESCRIPTION="Management Network"
VLAN_UNTAGGED="0"               # 0=tagged, 1=untagged on uplink port
VLAN_PROTO="dhcp"               # dhcp, static, or none

```

### 2. Common Hardware Overrides (`common-overrides.conf`)

Hardware-specific network settings applied to ALL routers:

```bash
#!/bin/sh
# Get hardware model for detection
HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")

# Default network interface
MAIN_IFACE="${MAIN_IFACE:-eth0}"

# Hardware-specific optimizations
case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        MAIN_IFACE="eth1"
        UPLINK_PORT="1"
        CPU_PORT="0"
        ;;
    *"Archer A7"*)
        MAIN_IFACE="eth0"
        UPLINK_PORT="0"
        CPU_PORT="6"
        ;;
esac
```

### 3. Router-Specific Overrides

Added to individual router configuration files in `routers/`:

```bash
# In routers/bedroom-router.conf
VLAN_OVERRIDE_20_disabled="1"            # Disable guest VLAN
VLAN_OVERRIDE_30_proto="static"          # Use static IP for IoT VLAN
VLAN_OVERRIDE_30_ipaddr="192.168.30.1"
VLAN_OVERRIDE_30_netmask="255.255.255.0"
```

## 📋 Configuration Reference

### VLAN Configuration Variables

| Variable | Description | Values | Default |
|----------|-------------|---------|---------|
| `VLAN_ID` | VLAN ID number | 1-4094 | **Required** |
| `VLAN_NAME` | UCI interface name | string | **Required** |
| `VLAN_DESCRIPTION` | Human-readable description | string | Optional |
| `VLAN_UNTAGGED` | Untagged on uplink port | 0, 1 | 0 |
| `VLAN_PROTO` | Interface protocol | dhcp, static, none | dhcp |
| `VLAN_IPADDR` | Static IP address | IP address | Only if proto=static |
| `VLAN_NETMASK` | Static netmask | Netmask | Only if proto=static |
| `VLAN_GATEWAY` | Static gateway | IP address | Only if proto=static |
| `VLAN_DNS` | DNS servers | Space-separated IPs | Only if proto=static |
| `VLAN_EXTRA` | Extra UCI options | key=value pairs | Optional |

### Hardware Override Variables

| Variable | Description | Values |
|----------|-------------|---------|
| `MAIN_IFACE` | Main network interface | eth0, eth1, etc. |
| `UPLINK_PORT` | Switch uplink port | 0-6 |
| `CPU_PORT` | Switch CPU port | 0-6 |

### Router-Specific Override Variables

| Variable Pattern | Description | Example |
|------------------|-------------|---------|
| `VLAN_OVERRIDE_<ID>_disabled` | Disable VLAN on this router | `VLAN_OVERRIDE_20_disabled="1"` |
| `VLAN_OVERRIDE_<ID>_proto` | Override protocol | `VLAN_OVERRIDE_10_proto="static"` |
| `VLAN_OVERRIDE_<ID>_ipaddr` | Override IP address | `VLAN_OVERRIDE_10_ipaddr="192.168.10.1"` |

## 🎯 Common VLAN Scenarios

### 1. Management VLAN (Typical VLAN 10)
```bash
# vlan_10.conf
VLAN_ID="10"
VLAN_NAME="mgmt"
VLAN_DESCRIPTION="Network Management"
VLAN_UNTAGGED="0"               # Tagged - for management isolation
VLAN_PROTO="dhcp"               # Get IP from upstream DHCP
```

### 2. Guest VLAN (Typical VLAN 20)
```bash
# vlan_20.conf
VLAN_ID="20"
VLAN_NAME="guest"
VLAN_DESCRIPTION="Guest Network"
VLAN_UNTAGGED="0"               # Tagged for isolation
VLAN_PROTO="dhcp"
```

### 3. IoT VLAN (Typical VLAN 30)
```bash
# vlan_30.conf
VLAN_ID="30"
VLAN_NAME="iot"
VLAN_DESCRIPTION="IoT Devices"
VLAN_UNTAGGED="0"
VLAN_PROTO="dhcp"
VLAN_EXTRA="igmp_snooping=1"     # Enable multicast for smart home
```

### 4. Server VLAN (Typical VLAN 40)
```bash
# vlan_40.conf
VLAN_ID="40"
VLAN_NAME="servers"
VLAN_DESCRIPTION="Server Network"
VLAN_UNTAGGED="0"
VLAN_PROTO="static"             # Static configuration
VLAN_IPADDR="192.168.40.10"
VLAN_NETMASK="255.255.255.0"
VLAN_GATEWAY="192.168.40.1"
VLAN_DNS="8.8.8.8 8.8.4.4"
```

### 5. Untagged VLAN (Native VLAN)
```bash
# vlan_99.conf - Native/Default VLAN
VLAN_ID="99"
VLAN_NAME="native"
VLAN_DESCRIPTION="Native VLAN"
VLAN_UNTAGGED="1"               # Untagged on uplink port
VLAN_PROTO="dhcp"
```

## 🔧 Hardware-Specific Examples

### TP-Link Archer C7
```bash
# common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        echo "[*] Applying TP-Link Archer C7 network optimizations"
        MAIN_IFACE="eth1"           # C7 uses eth1 as main interface
        UPLINK_PORT="1"             # Port 1 is uplink
        CPU_PORT="0"                # CPU port is 0

        # C7-specific optimizations
        DEFAULT_MGMT_VLAN="10"      # Standard management VLAN
        ;;
esac
```

### TP-Link Archer A7
```bash
case "$HARDWARE_MODEL" in
    *"Archer A7"*)
        echo "[*] Applying TP-Link Archer A7 network optimizations"
        MAIN_IFACE="eth0"           # A7 uses eth0
        UPLINK_PORT="0"             # Port 0 is uplink
        CPU_PORT="6"                # CPU port is 6
        ;;
esac
```

### Netgear R7800
```bash
case "$HARDWARE_MODEL" in
    *"R7800"*)
        echo "[*] Applying Netgear R7800 network optimizations"
        MAIN_IFACE="eth0"
        UPLINK_PORT="0"
        CPU_PORT="0"

        # R7800 has good switching performance
        DEFAULT_MGMT_VLAN="1"       # Use VLAN 1 as management
        ;;
esac
```

## 📍 Location-Specific Configurations

### Main Router (Full Configuration)
```bash
# routers/main-router.conf
ROUTER_IP="192.168.1.1"
ROUTER_NAME="main-router"

# Enable all VLANs with optimized settings
VLAN_OVERRIDE_10_proto="static"
VLAN_OVERRIDE_10_ipaddr="192.168.10.1"
VLAN_OVERRIDE_10_netmask="255.255.255.0"

# Guest network with time restrictions
VLAN_OVERRIDE_20_extra="multicast_querier=1"
```

### Access Point (Limited Configuration)
```bash
# routers/bedroom-ap.conf
ROUTER_IP="192.168.1.32"
ROUTER_NAME="bedroom-ap"

# Disable guest network in bedroom
VLAN_OVERRIDE_20_disabled="1"

# IoT network on 2.4GHz only (better range)
VLAN_OVERRIDE_30_extra="igmp_snooping=1 multicast_querier=0"

# Reduce management complexity
VLAN_OVERRIDE_10_proto="dhcp"
```

### Garage/Industrial (Minimal Configuration)
```bash
# routers/garage-ap.conf
ROUTER_IP="192.168.1.33"
ROUTER_NAME="garage-ap"

# Only management and IoT networks
VLAN_OVERRIDE_20_disabled="1"   # No guest network
VLAN_OVERRIDE_40_disabled="1"   # No server network

```

## 🔄 Integration with Wireless System

The network system is designed to work seamlessly with the wireless system:

### VLAN-to-SSID Mapping
```bash
# Network side (vlan_10.conf)
VLAN_NAME="mgmt"        # Creates UCI interface "mgmt"

# Wireless side (ssid_main.conf)
SSID_NETWORK="mgmt"     # Maps SSID to "mgmt" interface
```

### Coordinated Deployment
```bash
# Deploy networks first (creates VLANs and interfaces)
./deploy-networks.sh routers/main-router.conf

# Deploy wireless second (maps SSIDs to VLANs)
./deploy-wireless.sh routers/main-router.conf

# Or use unified deployment
./deploy-complete.sh routers/main-router.conf
```

## 🐛 Troubleshooting

### Common Issues

**1. VLAN not appearing in wireless system:**
```bash
# Check VLAN interface was created
ssh root@router "uci show network | grep mgmt"

# Check SSID is mapping to correct interface
ssh root@router "uci show wireless | grep network"
```

**2. Switch ports not configured correctly:**
```bash
# Check switch VLAN configuration
ssh root@router "uci show network | grep switch_vlan"

# Verify hardware detection
ssh root@router "cat /tmp/sysinfo/model"
```

**3. Override not taking effect:**
```bash
# Check override file was created correctly
ssh root@router "cat /tmp/network-config-*/network-configs/router-overrides.conf"

# Verify override syntax (no spaces around =)
VLAN_OVERRIDE_20_disabled="1"  # Correct
VLAN_OVERRIDE_20_disabled = "1"  # Wrong
```

### Debug Commands

```bash
# Check what VLANs are configured
ssh root@router "uci show network | grep -E '(switch_vlan|interface)'"

# Check bridge configuration
ssh root@router "uci show network | grep device"

# Check applied configuration after deployment
ssh root@router "uci export network"
```

### Validation

```bash
# Test VLAN connectivity
ping -I br-vlan10 8.8.8.8

# Check VLAN interfaces are up
ip link show | grep br-

```

## 🚀 Best Practices

### 1. VLAN Planning
- **Use standard VLAN ranges**: 10-19 (management), 20-29 (guest), 30-39 (IoT), 40-49 (servers)
- **Document your VLANs**: Use descriptive names and comments

### 2. Configuration Management
- **Test with dry runs**: Always use `-d` flag first
- **One VLAN per file**: Don't combine multiple VLANs in one config
- **Consistent naming**: Use lowercase, descriptive VLAN names

### 3. Hardware Optimization
- **Know your hardware**: Check port mapping and CPU port assignment
- **Use common overrides**: Centralize hardware-specific settings
- **Test on target hardware**: Verify switch configuration works correctly

### 4. Security Considerations
- **Firewall is disabled**: Restrict access to router management on VLAN level
- **Limit management access**: Enable ip address only for management VLAN: VLAN_PROTO="none" for others


## 📚 Related Documentation

- **[../README.md](../README.md)** - Complete system overview
- **[../wireless-configs/README.md](../wireless-configs/README.md)** - Wireless configuration system
- **[../EXAMPLE-USAGE.md](../EXAMPLE-USAGE.md)** - Real-world usage examples
- **[../TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** - Common issues and solutions

## 🔗 External References

- **[OpenWrt VLAN Documentation](https://openwrt.org/docs/guide-user/network/vlan/switch_configuration)**
- **[UCI System Documentation](https://openwrt.org/docs/guide-user/base-system/uci)**
