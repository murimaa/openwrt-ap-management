# OpenWRT Unified Network & Wireless Management

Deploy and maintain both VLAN network configurations and wireless configurations across multiple routers with a unified approach.

Use case: Setup OpenWRT devices as managed access points with VLAN segmentation and corresponding wireless networks, perfect for creating segmented networks (main, guest, IoT, etc.). OpenWRT devices are used as "dumb" Wifi APs, with an IP address on management VLAN only.

Designed to be used on fresh OpenWRT installations - **IF YOU HAVE EXISTING CONFIGURATIONS, PROCEED WITH CAUTION!** Please backup your current configuration. Devices can be maintained using the same deployment scripts, ie. change your VLAN/Wifi setup and rerun the script.

Both systems are designed to be **idempotent** - you can run them multiple times to update configurations.

**Recommend setting up SSH keys beforehand for passwordless deployment.**

## 🏗️ Unified Architecture

This system provides two complementary deployment tools:

### 1. **Network Deployment** (`deploy-networks.sh`)
- 🌐 **VLAN Configuration** - Configure network segmentation and routing
- 🔀 **Switch Management** - Hardware switch VLAN tagging and port configuration
- 🚪 **Interface Management** - Bridge and interface configuration

### 2. **Wireless Deployment** (`deploy-wireless.sh`)
- 📡 **WiFi Networks** - Configure SSIDs mapped to VLANs
- 🎛️ **Radio Optimization** - Hardware-specific radio settings
- 🔐 **Security Settings** - WPA3/SAE, fast roaming, hidden networks
- 📍 **Location-Specific** - Different SSIDs per router location

## ✨ Key Features

- 🏠 **Shared Definitions** - Define VLANs and SSIDs once, deploy everywhere
- 🔧 **Hardware-Specific Optimizations** - Automatic settings based on router model
- 📍 **Router-Specific Customization** - Override settings per router location/purpose
- 🚀 **Automated Deployment** - Deploy to single or multiple routers with one command
- 📦 **Maintainable** - Run multiple times to update configurations
- 🔐 **SSH Key Support** - Secure passwordless deployment
- 🧪 **Dry Run Testing** - Test configurations before applying
- 📊 **Verbose Logging** - Detailed deployment information
- 🔄 **Unified Router Configs** - Single router config file for both systems

## 🚀 Quick Start

### Complete Setup Workflow

1. **Configure your VLANs** in `network-configs/vlan_*.conf`
2. **Configure your SSIDs** in `wireless-configs/ssid_*.conf`
3. **Create router configs** in `routers/router-name.conf`
4. **Deploy networks**: `./deploy-networks.sh routers/router-name.conf`
5. **Deploy wireless**: `./deploy-wireless.sh routers/router-name.conf`

### Single Command Example
```bash
# Deploy both network and wireless to a router
./deploy-networks.sh routers/ap-bedroom.conf
./deploy-wireless.sh routers/ap-bedroom.conf

# Or deploy to multiple routers
./deploy-networks.sh routers/*.conf
./deploy-wireless.sh routers/*.conf
```

### Example Output

**Network Deployment:**
```bash
./deploy-networks.sh routers/ap-bedroom.conf
[INFO] OpenWRT Network Configuration Deployment
[INFO] Starting deployment to 1 router(s)...
[INFO] Processing router config: routers/ap-bedroom.conf
[INFO] Deploying to ap-bedroom (192.168.1.32:22)...
[INFO] Copying network setup script...
[INFO] Copying configuration files...
[INFO] Creating router-specific overrides...
[INFO] Executing setup script...
[192.168.1.32] [INFO] Loading router-specific overrides: ./network-configs/router-overrides.conf
[192.168.1.32] [INFO] Backing up current config...
[192.168.1.32] [INFO] Cleaning up existing VLANs from switch config...
[192.168.1.32] [INFO] Removing network.@switch_vlan[2]...
[192.168.1.32] [INFO] Removing network.@switch_vlan[1]...
[192.168.1.32] [INFO] Removing network.@switch_vlan[0]...
[192.168.1.32] [INFO] Cleaning up old VLAN-related config...
[192.168.1.32] [INFO] Switch detected — configuring VLAN on switch0...
[192.168.1.32] [INFO] Processing VLAN configurations...
[192.168.1.32] [INFO] Loading config: ./network-configs/vlan_10.conf
[192.168.1.32] [SUCCESS] Configuring VLAN 10 (mgmt)...
[192.168.1.32] [SUCCESS] Adding VLAN 10 tagged to port 1
[192.168.1.32] [INFO] Loading config: ./network-configs/vlan_30.conf
[192.168.1.32] [SUCCESS] Configuring VLAN 30 (iot)...
[192.168.1.32] [SUCCESS] Adding VLAN 30 tagged to port 1
[192.168.1.32] [INFO] Disabling firewall, dnsmasq, odhcpd...
[192.168.1.32] [INFO] Applying configuration...
[192.168.1.32] [SUCCESS] Done.
[SUCCESS] Configuration applied successfully on ap-bedroom (192.168.1.32)
```

**Wireless Deployment:**
```bash
./deploy-wireless.sh routers/ap-bedroom.conf
[INFO] OpenWRT Wireless Configuration Deployment
[INFO] Starting deployment to 1 router(s)...
[INFO] Processing router config: routers/ap-bedroom.conf
[INFO] Deploying to ap-bedroom (192.168.1.32:22)...
[INFO] Copying wireless setup script...
[INFO] Copying configuration files...
[INFO] Creating router-specific overrides...
[INFO] Executing setup script...
[192.168.1.32] [INFO] Loading router-specific overrides: ./wireless-configs/router-overrides.conf
[192.168.1.32] [INFO] Cleaning up existing wireless interfaces...
[192.168.1.32] [INFO] Loading config: ./wireless-configs/ssid_main.conf
[192.168.1.32] [WARNING] Skipping SSID 'MainWifi' on 2g (radio0) - not in specified bands: 5g
[192.168.1.32] [SUCCESS] Applying SSID 'MainWifi' to 5g on radio1...
[192.168.1.32] [INFO] Loading config: ./wireless-configs/ssid_iot.conf
[192.168.1.32] [SUCCESS] Applying SSID 'IotWifi' to 2g on radio0...
[192.168.1.32] [SUCCESS] Applying SSID 'IotWifi' to 5g on radio1...
[192.168.1.32] [INFO] Enabling radios...
[192.168.1.32] [INFO] Committing wireless config and reloading...
[192.168.1.32] [SUCCESS] Done.
[SUCCESS] Configuration applied successfully on ap-bedroom (192.168.1.32)
```

## 🏗️ System Architecture

```
openwrt/
├── openwrt-scripts/
│   ├── setup_networks.sh          # Network setup script (runs on router)
│   └── setup_wireless.sh          # Wireless setup script (runs on router)
├── network-configs/
│   ├── common-overrides.conf      # Hardware-specific network settings for ALL routers
│   ├── vlan_10.conf              # Management VLAN definition
│   ├── vlan_20.conf              # Guest VLAN definition
│   ├── vlan_30.conf              # IoT VLAN definition
│   └── vlan_*.conf               # Additional VLAN definitions
├── wireless-configs/
│   ├── common-overrides.conf      # Hardware-specific wireless settings for ALL routers
│   ├── ssid_main.conf            # Main WiFi network definition
│   ├── ssid_guest.conf           # Guest WiFi network definition
│   ├── ssid_iot.conf             # IoT WiFi network definition
│   └── ssid_*.conf               # Additional SSID definitions
├── routers/
│   ├── main-router.conf          # Main router: IP + network + wireless overrides
│   ├── bedroom-router.conf       # Bedroom router: IP + specific overrides
│   └── office-router.conf        # Office router: IP + specific overrides
├── deploy-networks.sh            # Network deployment script
├── deploy-wireless.sh            # Wireless deployment script
└── README.md                     # This comprehensive guide
```

## 🔧 How It Works

### 1. Unified Three-Layer Configuration System

Both network and wireless systems use the same configuration architecture:

1. **Shared Configs** - Base VLAN/SSID definitions
2. **Common Overrides** - Hardware-specific optimizations applied to ALL routers
3. **Router-Specific Configs** - Router connection details + location-specific overrides

### 2. Deployment Process

**Network Deployment:**
```bash
./deploy-networks.sh routers/bedroom-router.conf
```

1. Reads router config for IP/SSH details
2. Combines common network overrides + router-specific network overrides
3. Copies network setup script and VLAN configs to router
4. Clears existing VLAN/switch configuration on router
5. Executes new network configuration (VLANs, bridges)
6. Disables firewall, dnsmasq, odhcpd (not needed for dumb AP)

**Wireless Deployment:**
```bash
./deploy-wireless.sh routers/bedroom-router.conf
```

1. Uses same router config for IP/SSH details
2. Combines common wireless overrides + router-specific wireless overrides
3. Copies wireless setup script and SSID configs to router
4. Clears existing wireless configuration on router
5. Executes new wireless configuration (SSIDs, radio settings)

### 3. Override Precedence (Both Systems)

```
Common Overrides → Router-Specific Overrides → Final Configuration
    (All routers)      (Individual router)         (Applied)
```

### 4. Typical Workflow

1. **Design your network** - Define VLANs and corresponding SSIDs
2. **Configure hardware optimizations** - Set common overrides for your router models
3. **Create router-specific configs** - Set IP addresses and location-specific overrides
4. **Deploy networks first** - Establish VLAN infrastructure
5. **Deploy wireless second** - Configure WiFi networks on top of VLANs
6. **Maintain** - Update configs and redeploy as needed

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

**Network:**
```bash
# network-configs/common-overrides.conf
HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")

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

**Wireless:**
```bash
# wireless-configs/common-overrides.conf
COUNTRY_CODE="FI"  # Set if required

case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        RADIO_OVERRIDE_radio0_txpower="17"  # 5GHz
        RADIO_OVERRIDE_radio1_txpower="20"  # 2.4GHz
        ;;
    *"Netgear"*)
        RADIO_OVERRIDE_radio0_txpower="18"
        RADIO_OVERRIDE_radio1_txpower="21"
        ;;
esac
```

### Unified Router Configuration
```bash
# routers/bedroom-router.conf
ROUTER_IP="192.168.1.32"  # mandatory
ROUTER_NAME="bedroom-router"
SSH_USER="root"
SSH_PORT="22"

# Network-specific overrides
UPLINK_PORT="0"                          # Override hardware defaults
VLAN_OVERRIDE_20_disabled="1"            # No guest VLAN in bedroom

# Wireless-specific overrides
RADIO_OVERRIDE_radio0_channel="149"      # 5GHz - avoid interference
RADIO_OVERRIDE_radio1_channel="1"        # 2.4GHz
SSID_OVERRIDE_guest_disabled="1"         # No guest WiFi in bedroom
SSID_OVERRIDE_iot_bands="2g"             # IoT on 2.4GHz only
```

## 🎯 Common Use Cases

### Different Router Locations
- **Main Router**: Full power, all VLANs/SSIDs, optimal channels
- **Bedroom Router**: Reduced power, no guest networks, different channels
- **Office Router**: High performance, work VLANs only, WPA3 enterprise
- **Garage Router**: Industrial settings, limited networks, weatherproof setup

### Hardware Variations
- **Archer C7**: Reduced power (thermal), conservative modes, port mapping
- **Archer AX Series**: WiFi 6 optimization, higher power, modern features
- **Netgear Models**: Standard optimization, good thermal, reliable defaults
- **GL.iNet Travel**: Compact settings, limited VLANs, battery optimization

### Network Scenarios
- **Home Segmentation**: Main (VLAN 10), Guest (VLAN 20), IoT (VLAN 30)
- **Small Business**: Admin (VLAN 10), Employee (VLAN 20), Guest (VLAN 30), Servers (VLAN 40)
- **Airbnb/Hotel**: Management (VLAN 10), Guest rooms (VLAN 20-29), Services (VLAN 30)

## 🚀 Deployment Commands

### Complete Deployment
```bash
# Deploy both network and wireless to single router
./deploy-networks.sh routers/main-router.conf
./deploy-wireless.sh routers/main-router.conf

# Deploy to multiple routers
./deploy-networks.sh routers/*.conf
./deploy-wireless.sh routers/*.conf

# Deploy specific configurations
./deploy-networks.sh routers/main-router.conf routers/bedroom-router.conf
./deploy-wireless.sh routers/main-router.conf routers/bedroom-router.conf
```

### Testing and Debugging
```bash
# Test network deployment (dry run)
./deploy-networks.sh -d routers/main-router.conf

# Test wireless deployment with verbose output
./deploy-wireless.sh -v -d routers/main-router.conf

# Test all routers with both systems
./deploy-networks.sh -d -v routers/*.conf
./deploy-wireless.sh -d -v routers/*.conf
```

### Maintenance Workflows
```bash
# Update only wireless configurations
./deploy-wireless.sh routers/*.conf

# Update only network configurations
./deploy-networks.sh routers/*.conf

# Full infrastructure update
./deploy-networks.sh routers/*.conf && ./deploy-wireless.sh routers/*.conf
```

## 🔑 Key Features Explained

### 🔧 Dual Common Overrides System
- **Network Overrides**: Hardware-specific network settings (interfaces, ports, switch config)
- **Wireless Overrides**: Hardware-specific radio settings (power, channels, capabilities)
- **Benefits**: No duplicate configuration, consistent hardware optimization across both systems
- **Usage**: Configure in `network-configs/common-overrides.conf` and `wireless-configs/common-overrides.conf`

### 📍 Unified Router-Specific Overrides
- **Single Config File**: One router config handles both network and wireless overrides
- **Purpose**: Customize settings for specific router locations or purposes
- **Benefits**: Fine-tune each router while maintaining shared definitions
- **Usage**: Add both `VLAN_OVERRIDE_*` and `SSID_OVERRIDE_*` variables to `routers/*.conf` files

### 🚀 Coordinated Deployment
- **Two-Stage Process**: Deploy networks first, then wireless on top
- **Independent Operation**: Each system can be deployed separately for updates
- **Benefits**: Consistent deployment, error handling, infrastructure-as-code approach
- **Usage**: Use both deployment scripts with the same router config files

### 🔄 Configuration Synchronization
- **VLAN-to-SSID Mapping**: SSIDs automatically map to configured VLAN names
- **Consistent Naming**: VLAN names become wireless network names in UCI
- **Override Coordination**: Router configs can override both network and wireless for same router
- **Benefits**: Ensures network and wireless configurations stay aligned

## 📚 Documentation

- **[network-configs/README.md](network-configs/README.md)** - Network system detailed documentation
- **[wireless-configs/README.md](wireless-configs/README.md)** - Wireless system detailed documentation
- **[EXAMPLE-USAGE.md](EXAMPLE-USAGE.md)** - Real-world usage examples and scenarios
- **[COMMON-OVERRIDES.md](COMMON-OVERRIDES.md)** - Common overrides system explained
- **[MIGRATION.md](MIGRATION.md)** - Migration guide from older systems
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions

## 🚀 Quick Setup Guide

### 1. Design Your Network Architecture
```bash
# Plan your VLANs and corresponding SSIDs
# Example: VLAN 10 (mgmt) → MainWiFi, VLAN 20 (guest) → GuestWiFi, VLAN 30 (iot) → IoTWiFi
```

### 2. Create Your VLAN Definitions
```bash
# Copy examples and customize
cp network-configs/vlan_10.conf.example network-configs/vlan_10.conf
cp network-configs/vlan_20.conf.example network-configs/vlan_20.conf
cp network-configs/vlan_30.conf.example network-configs/vlan_30.conf
# Edit with your VLAN settings, etc.
```

### 3. Create Your SSID Definitions
```bash
# Copy examples and customize
cp wireless-configs/ssid_main.conf.example wireless-configs/ssid_main.conf
cp wireless-configs/ssid_guest.conf.example wireless-configs/ssid_guest.conf
cp wireless-configs/ssid_iot.conf.example wireless-configs/ssid_iot.conf
# Edit with your network names, passwords, and VLAN mappings
```

### 4. Set Up Hardware Optimizations
```bash
# Copy and customize common overrides for both systems
cp network-configs/common-overrides.conf.example network-configs/common-overrides.conf
cp wireless-configs/common-overrides.conf.example wireless-configs/common-overrides.conf
# Add your router models and optimizations
```

### 5. Create Router Configurations
```bash
# Copy examples and customize
cp routers/main-router.conf.example routers/my-main-router.conf
cp routers/bedroom-router.conf.example routers/my-bedroom-router.conf
# Edit with your router IPs and location-specific settings
```

### 6. Test and Deploy
```bash
# Test network deployment first
./deploy-networks.sh -d routers/my-main-router.conf

# Test wireless deployment
./deploy-wireless.sh -d routers/my-main-router.conf

# Deploy if tests look good
./deploy-networks.sh routers/my-main-router.conf
./deploy-wireless.sh routers/my-main-router.conf
```

## 🔬 Advanced Features

### SSH Key Authentication
```bash
# In router config - works for both deployment systems
SSH_KEY="/home/user/.ssh/openwrt_key"
SSH_PORT="2222"
```

### Hardware Detection (Both Systems)
```bash

## Requirements

- OpenWRT routers with UCI wireless configuration
- SSH access to routers
- Bash shell for deployment script
- SCP support for file transfers

## Troubleshooting

### Common Issues
- **SSH Connection Failed**: Check IP, port, and authentication
- **Override Not Applied**: Verify syntax and precedence rules
- **Hardware Not Detected**: Add debug output to common-overrides.conf

### Debug Commands
```bash
# Check applied configuration on router
ssh root@192.168.1.1 "uci show wireless"

# View deployment logs
./deploy-wireless.sh -v routers/router.conf

# Check override file on router
ssh root@192.168.1.1 "cat /tmp/wireless-config-*/wireless-configs/router-overrides.conf"
```

## Contributing

When adding new features or router support:
1. Test with dry run first
2. Update documentation
3. Add examples for new hardware
4. Follow existing naming conventions

## License

This wireless configuration management system is provided as-is for OpenWRT router management.
