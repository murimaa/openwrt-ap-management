# OpenWRT WiFi Access Point Network & Wireless Management

Use case: You already have a network with VLANS and you want to setup/manage wifi SSIDs for those VLANS. Use this tool to provision OpenWRT devices as wifi access points with VLAN segmentation and corresponding wireless networks, perfect for creating segmented wifi networks (main, guest, IoT, etc.). You will end up with "dumb" APs, with an IP address on management VLAN only.

Designed to be used on fresh OpenWRT installations - **IF YOU HAVE EXISTING CONFIGURATIONS, PROCEED WITH CAUTION!** Please backup your current configuration.

## 🏗️ Unified Architecture

This system provides automated deployment and management of **VLAN-segregated WiFi Access Points** running OpenWRT. It's designed for managing dumb APs that provide wireless access to segmented networks, not full routing functionality.

### 1. **Network Deployment** (`deploy-networks.sh`)

Configures VLAN network segmentation on OpenWRT access points, setting up trunk ports and VLAN interfaces for network isolation.

### 2. **Wireless Deployment** (`deploy-wireless.sh`)

Deploys wireless networks (SSIDs) mapped to specific VLANs, creating segmented WiFi networks on your access points.

## ✨ Key Features

- **🎯 VLAN-Segregated WiFi Networks**: Configure access points as dumb APs with VLAN-mapped SSIDs
- **📡 Unified AP Management**: Deploy configurations to multiple OpenWRT access points simultaneously
- **🔧 Hardware-Aware Configuration**: Automatic detection and optimization for different AP models
- **⚙️ Three-Layer Override System**: Global defaults → Common overrides → AP-specific customizations
- **🚀 One-Command Deployment**: Deploy complete infrastructure with a single command
- **🔄 Coordinated Network & Wireless**: Ensures VLANs and SSIDs are properly mapped across all APs
- **🛡️ SSH Key Authentication**: Secure deployment using SSH keys
- **🏠 Location-Specific Optimization**: Per-AP settings for different environments and hardware

## 🚀 Quick Start

### Complete Setup Workflow

1. **Design your network**: Plan VLANs and SSIDs for network segmentation
2. **Configure access points**: Set up AP-specific settings (IP, location, radio optimization)
3. **Deploy everything**: Use one command to configure all APs

```bash
# Deploy complete infrastructure to all access points
./deploy-complete.sh aps/*.conf
```

### Single Command Example

```bash
# Deploy to specific access points with verbose output
./deploy-complete.sh -v aps/ap-livingroom.conf aps/ap-office.conf

# Test configuration without applying changes
./deploy-complete.sh -d aps/*.conf
```

### Example Output

```
./deploy-complete.sh aps/ap-bedroom.conf
[INFO] Mode: Complete Infrastructure (Networks + Wireless)
[INFO] OpenWRT Complete Infrastructure Deployment
[INFO] Deploying to 1 access point(s): ap-bedroom.conf
[STAGE] Starting Network Deployment Phase
[INFO] OpenWRT Network Configuration Deployment
[INFO] Starting deployment to 1 access point(s)...
[INFO] Processing access point config: aps/ap-bedroom.conf
[INFO] Deploying to ap-bedroom (192.168.1.30:22)...
[INFO] Copying network setup script...
[INFO] Copying configuration files...
[INFO] Creating access point-specific overrides...
[INFO] Executing setup script...
[ap-bedroom] [INFO] Loading access point-specific overrides: ./network-configs/common-overrides.conf
[ap-bedroom] [*] Hardware detected: ASUS RT-AC1200 V2
[ap-bedroom] [*] Applying ASUS RT-AC1200 V2 port settings
[ap-bedroom] [INFO] Backing up current config...
[ap-bedroom] [INFO] Cleaning up existing VLANs from switch config...
[ap-bedroom] [INFO] Cleaning up old VLAN-related config...
[ap-bedroom] [INFO] Switch detected — configuring VLAN on switch0...
[ap-bedroom] [INFO] Processing VLAN configurations...
[ap-bedroom] [INFO] Loading config: ./network-configs/vlan_10.conf
[ap-bedroom] [INFO] Configuring VLAN 10 (mgmt)...
[ap-bedroom] [INFO] Adding VLAN 10 untagged to port 1
[ap-bedroom] [INFO] Loading config: ./network-configs/vlan_20.conf
[ap-bedroom] [INFO] Configuring VLAN 20 (guest)...
[ap-bedroom] [INFO] Adding VLAN 50 tagged to port 1
[ap-bedroom] [INFO] Loading config: ./network-configs/vlan_30.conf
[ap-bedroom] [INFO] Configuring VLAN 30 (iot)...
[ap-bedroom] [INFO] Adding VLAN 30 tagged to port 1
[ap-bedroom] [INFO] Disabling firewall, dnsmasq, odhcpd...
[ap-bedroom] [INFO] Applying configuration...
[ap-bedroom] [SUCCESS] Done.
[SUCCESS] Configuration applied successfully on ap-bedroom (192.168.1.30)

[INFO] Deployment Summary:
[SUCCESS] Successful deployments: 1/1
[SUCCESS] All deployments completed successfully!
[SUCCESS] Network deployment completed successfully

[STAGE] Starting Wireless Deployment Phase
[INFO] OpenWRT Wireless Configuration Deployment
[INFO] Starting deployment to 1 access point(s)...
[INFO] Processing access point config: aps/ap-bedroom.conf
[INFO] Deploying to ap-bedroom (192.168.1.30:22)...
[INFO] [DRY RUN] Would copy configuration files to 192.168.1.30
[INFO] [DRY RUN] Would create access point overrides with       62 lines
[INFO] [DRY RUN] Would execute setup script on 192.168.1.30
[INFO] Copying wireless setup script...
[INFO] Copying configuration files...
[INFO] Creating access point-specific overrides...
[INFO] Executing setup script...
[ap-bedroom] [INFO] Loading access point-specific overrides: ./wireless-configs/common-overrides.conf
[ap-bedroom] [INFO] Cleaning up existing wireless interfaces...
[ap-bedroom] [INFO] Loading config: ./wireless-configs/ssid_vlan10.conf
[ap-bedroom] [INFO] Applying SSID 'MgmtWifi' to 2g on radio0...
[ap-bedroom] [INFO] Applying SSID 'MgmtWifi' to 5g on radio1...
[ap-bedroom] [INFO] Loading config: ./wireless-configs/ssid_vlan20.conf
[ap-bedroom] [INFO] Applying SSID 'GuestWifi' to 2g on radio0...
[ap-bedroom] [INFO] Applying SSID 'GuestWifi' to 5g on radio1...
[ap-bedroom] [INFO] Loading config: ./wireless-configs/ssid_vlan30.conf
[ap-bedroom] [INFO] Applying SSID 'IoT' to 2g on radio0...
[ap-bedroom] [WARNING] Skipping SSID 'IoT' on 5g (radio1) - not in specified bands: 2g
[ap-bedroom] [INFO] Enabling radios...
[ap-bedroom] [INFO] Committing wireless config and reloading...
[ap-bedroom] [SUCCESS] Done.
[SUCCESS] Configuration applied successfully on ap-bedroom (192.168.1.30)

[INFO] Deployment Summary:
[SUCCESS] Successful deployments: 1/1
[SUCCESS] All deployments completed successfully!
[SUCCESS] Wireless deployment completed successfully

[INFO] Complete Deployment Summary:
[SUCCESS] ✓ Network deployment: SUCCESS
[SUCCESS] ✓ Wireless deployment: SUCCESS
[SUCCESS] 🎉 Complete infrastructure deployment successful!

[INFO] Your OpenWRT access points are now configured with:
[INFO]   • VLAN network segmentation
[INFO]   • Wireless networks mapped to VLANs
[INFO]   • Optimized radio settings

[INFO] Next steps:
[INFO]   • Verify connectivity to each VLAN/SSID
[INFO]   • Monitor access point performance and adjust as needed
[INFO]   • Test client connectivity across network segments

[INFO] Deployment Summary:
[SUCCESS] Successful deployments: 3/3
[SUCCESS] All deployments completed successfully!
```

## 🏗️ System Architecture

```
openwrt/
├── network-configs/                    # VLAN network definitions
│   ├── common-overrides.conf          # Network settings for ALL access points
│   ├── vlan_10_management.conf        # Management VLAN
│   ├── vlan_20_trusted.conf           # Trusted devices VLAN
│   ├── vlan_30_guest.conf             # Guest network VLAN
│   └── vlan_40_iot.conf               # IoT devices VLAN
├── wireless-configs/                   # Wireless network definitions
│   ├── common-overrides.conf          # Wireless settings for ALL access points
│   ├── ssid_main.conf                 # Primary network SSID
│   ├── ssid_guest.conf                # Guest network SSID
│   └── ssid_iot.conf                  # IoT network SSID
├── aps/                               # Access point configurations
│   ├── ap-livingroom.conf             # Living room AP settings
│   ├── ap-office.conf                 # Office AP settings
│   └── ap-garage.conf                 # Garage AP settings
├── openwrt-scripts/                   # Deployment scripts for OpenWRT
│   ├── setup_networks.sh             # Network configuration script
│   └── setup_wireless.sh             # Wireless configuration script
├── deploy-networks.sh                 # Deploy network configs to APs
├── deploy-wireless.sh                 # Deploy wireless configs to APs
└── deploy-complete.sh                 # Deploy both networks + wireless
```

## 🔧 How It Works

### 1. Unified Three-Layer Configuration System

The system uses a three-layer approach for maximum flexibility while minimizing configuration duplication:

1. **Base Configuration Files**: Define VLANs (`vlan_*.conf`) and SSIDs (`ssid_*.conf`)
2. **Common Overrides**: Settings applied to ALL access points (`common-overrides.conf` in both directories)
3. **AP-Specific Overrides**: Individual access point customizations (in `aps/*.conf` files)

### 2. Deployment Process

1. **Network Deployment** (`deploy-networks.sh`):
   - Loads VLAN definitions and common network overrides
   - Merges with AP-specific network settings
   - Configures switch ports, VLANs, and interfaces on each AP

2. **Wireless Deployment** (`deploy-wireless.sh`):
   - Loads SSID definitions and common wireless overrides
   - Merges with AP-specific wireless settings
   - Configures radios, wireless networks, and VLAN mapping on each AP

3. **Complete Deployment** (`deploy-complete.sh`):
   - Runs network deployment first (VLANs must exist before wireless mapping)
   - Then runs wireless deployment
   - Ensures coordinated configuration across all APs

### 3. Override Precedence (Both Systems)

Settings are applied in this order (later overrides earlier):
1. Base configuration files (`vlan_*.conf`, `ssid_*.conf`)
2. Common overrides (`common-overrides.conf`)
3. AP-specific overrides (variables in `aps/*.conf` files)

### 4. Typical Workflow

1. Define your network architecture (VLANs and SSIDs)
2. Create base configuration files
3. Set up common optimizations in override files
4. Create AP-specific configurations
5. Deploy with a single command

## 📋 Configuration Examples

### VLAN Configuration

```bash
# network-configs/vlan_10.conf
VLAN_ID="10"
VLAN_NAME="mgmt"
VLAN_DESCRIPTION="Management Network"
VLAN_UNTAGGED="0"  # Tagged on uplink
VLAN_PROTO="dhcp"
```

### SSID Configuration

```bash
# wireless-configs/ssid_main.conf
SSID_NAME="MyHome-WiFi"
SSID_KEY="secure-password-123"
SSID_NETWORK="mgmt"  # Maps to VLAN name (mgmt = VLAN 10)
SSID_ENCRYPTION="sae"
SSID_BANDS="2g 5g"
```

### Common Hardware Optimizations

```bash
# network-configs/common-overrides.conf
#!/bin/sh
# Network settings applied to ALL access points

# Hardware detection for switch configuration
HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")

case "$HARDWARE_MODEL" in
    *"Ubiquiti UniFi AC Pro"*)
        echo "[*] Applying Ubiquiti UniFi AC Pro port settings"
        MAIN_IFACE="eth0"
        UPLINK_PORT="2"
        CPU_PORT="0"
        ;;
    *"Ubiquiti UniFi AC Lite"*)
        echo "[*] Applying Ubiquiti UniFi AC Lite port settings"
        # No switch on this device, no ports to configure
        MAIN_IFACE="eth0"
        ;;
esac

```

```bash
# wireless-configs/common-overrides.conf
#!/bin/sh
# Wireless settings applied to ALL access points

# Country code for regulatory compliance
COUNTRY_CODE="US"
```

### Unified Access Point Configuration

```bash
# aps/ap-livingroom.conf
#!/bin/sh
# Living room access point configuration

# Access Point identification
AP_IP="192.168.1.101"
AP_NAME="ap-livingroom"
AP_LOCATION="livingroom"

# SSH connection settings
SSH_USER="root"
SSH_PORT="22"
SSH_KEY="/home/user/.ssh/openwrt_key"

# ===========================================
# NETWORK OVERRIDES
# ===========================================

# Hardware-specific network settings
UPLINK_PORT="4"  # Uplink on port 4 for this location

# ===========================================
# WIRELESS OVERRIDES
# ===========================================

# Location-optimized radio settings
RADIO_OVERRIDE_radio0_channel="36"      # 5GHz - Channel 36
RADIO_OVERRIDE_radio1_channel="1"       # 2.4GHz - Channel 1

# Higher power for large living room coverage
RADIO_OVERRIDE_radio0_txpower="20"      # 5GHz
RADIO_OVERRIDE_radio1_txpower="22"      # 2.4GHz
```

## 🎯 Common Use Cases

### Different Access Point Locations

- **Living Room AP**: Higher power, optimal channels for main coverage
- **Office AP**: Moderate power, channels avoiding interference
- **Garage AP**: Lower power, weatherproof considerations

### Hardware Variations

- **TP-Link APs**: Specific switch port configurations
- **Ubiquiti APs**: Different interface naming and capabilities
- **Generic APs**: Conservative settings that work everywhere

### Network Scenarios

- **Home Network**: Management, trusted devices, guest, and IoT VLANs
- **Small Office**: Departmental segmentation with guest access
- **Multi-tenant**: Isolated networks per tenant or area

## 🚀 Deployment Commands

### Complete Deployment

```bash
# Deploy everything to all access points
./deploy-complete.sh aps/*.conf

# Deploy to specific access points
./deploy-complete.sh aps/ap-livingroom.conf aps/ap-office.conf

# Deploy with verbose output
./deploy-complete.sh -v aps/*.conf

# Test deployment without making changes
./deploy-complete.sh -d aps/*.conf
```

### Testing and Debugging

```bash
# Test network configuration only
./deploy-networks.sh -d -v aps/ap-livingroom.conf

# Test wireless configuration only
./deploy-wireless.sh -d -v aps/ap-livingroom.conf

# Deploy networks only (no wireless)
./deploy-complete.sh -n aps/*.conf

# Deploy wireless only (networks must exist)
./deploy-complete.sh -w aps/*.conf
```

### Maintenance Workflows

```bash
# Update wireless settings across all APs
./deploy-wireless.sh aps/*.conf

# Deploy to single AP for testing
./deploy-complete.sh aps/ap-testlab.conf

# Check what would change before applying
./deploy-complete.sh -d aps/*.conf | grep -E "(would|UCI)"
```

## 🔑 Key Features Explained

### 🔧 Dual Common Overrides System

- **Network Common Overrides**: VLAN configurations, switch settings, hardware detection
- **Wireless Common Overrides**: Radio settings, country codes, power levels
- Applied automatically to ALL access points, with AP-specific override capability

### 📍 Unified Access Point-Specific Overrides

- **Single Configuration File**: Each AP has one file containing both network and wireless overrides
- **Deployment Coordination**: Both systems use the same AP configuration files
- **Consistent Naming**: AP_IP, AP_NAME variables used by both deployment scripts

### 🚀 Coordinated Deployment

- **Proper Sequence**: Network deployment creates VLANs before wireless maps SSIDs to them
- **Shared Configuration**: Both systems access the same AP configuration files
- **Synchronized State**: Ensures VLANs and wireless networks are properly aligned

### 🔄 Configuration Synchronization

- **Atomic Operations**: Each deployment is all-or-nothing per access point
- **Rollback Capability**: Failed deployments leave previous configuration intact
- **Validation**: SSH connectivity tested before attempting configuration

## 📚 Documentation

- **[Common Overrides System](COMMON-OVERRIDES.md)**: Detailed guide to the three-layer configuration system
- **[Example Usage](EXAMPLE-USAGE.md)**: Step-by-step examples and common scenarios
- **Configuration Templates**: Example files in each directory showing proper syntax

## 🚀 Quick Setup Guide

### 1. Design Your Network Architecture

Plan your VLAN segmentation and wireless networks:
- Management VLAN (AP management)
- Trusted devices (computers, phones)
- Guest network (visitor access)
- IoT devices (smart home, sensors)

### 2. Create Your VLAN Definitions

```bash
# Create files in network-configs/ for each VLAN
cp network-configs/vlan_10_management.conf.example network-configs/vlan_10_management.conf
# Edit VLAN_ID, VLAN_NAME, and port configurations
```

### 3. Create Your SSID Definitions

```bash
# Create files in wireless-configs/ for each SSID
cp wireless-configs/ssid_main.conf.example wireless-configs/ssid_main.conf
# Edit SSID, VLAN_ID, encryption, and radio settings
```

### 4. Set Up Hardware Optimizations

```bash
# Edit common override files for your AP models
vim network-configs/common-overrides.conf    # Network/switch settings
vim wireless-configs/common-overrides.conf   # Radio/wireless settings
```

### 5. Create Access Point Configurations

```bash
# Create configuration file for each access point
cp aps/ap-example.conf.example aps/ap-livingroom.conf
# Edit AP_IP, AP_NAME, and location-specific settings
```

### 6. Test and Deploy

```bash
# Test configuration first
./deploy-complete.sh -d aps/*.conf

# Deploy to access points
./deploy-complete.sh aps/*.conf
```

## 🔬 Advanced Features

### SSH Key Authentication

Configure SSH keys for secure, passwordless deployment:

```bash
# Generate SSH key for OpenWRT access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/openwrt_key

# Add to access point configuration
echo 'SSH_KEY="/home/user/.ssh/openwrt_key"' >> aps/ap-livingroom.conf
```

### Hardware Detection (Both Systems)

Both network and wireless systems automatically detect hardware and apply optimizations:

```bash
# Network system detects:
- Switch port configurations
- Interface naming schemes
- VLAN capabilities

# Wireless system detects:
- Radio capabilities
- Antenna configurations
- Power limitations
- Channel restrictions
```

Example hardware-specific settings:

```bash
# In common-overrides.conf files
case "$HARDWARE_MODEL" in
    *"TP-Link Archer"*)
        # TP-Link specific optimizations
        RADIO_OVERRIDE_radio0_htmode="VHT80"
        VLAN_PORT_CONFIG="switch0"
        ;;
    *"Ubiquiti"*)
        # Ubiquiti specific optimizations
        RADIO_OVERRIDE_radio0_txpower="23"
        MAIN_IFACE="eth0"
        ;;
esac
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with `-d` (dry run) mode
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
