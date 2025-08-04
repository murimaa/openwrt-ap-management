# OpenWRT VLAN & Wireless Management Scripts

Easy to deploy and maintain multiple OpenWRT routers wireless configurations. Use case is to setup wireless networks for VLANs, ie. use OpenWRT wifi devices as "dumb" access points that bridge one SSID per VLAN.

Designed to be used on a fresh OpenWRT installation - IF YOU HAVE ANY CONFIGURATIONS ALREADY PROCEED WITH CAUTION! Please backup your current configuration.

Configuration files can be changed and script can be rerun to deploy new configurations.

Recommend that you set up SSH keys beforehand for passwordless deployment.


## Features

- 🏠 **Shared Network Definitions** - Define SSIDs once, deploy everywhere
- 🔧 **Hardware-Specific Optimizations** - Automatic settings based on router model
- 📍 **Router-Specific Customization** - Override settings and enabled networks per router location/purpose
- 🚀 **Automated Deployment** - Deploy to single or multiple routers with one command
- 📦 **Maintainable** - Can be run multiple times to update wifi configuration
- 🔐 **SSH Key Support** - Secure passwordless deployment
- 🧪 **Dry Run Testing** - Test configurations before applying
- 📊 **Verbose Logging** - Detailed deployment information

## Quick Start

1. **Configure your networks** in `wireless-configs/ssid_*.conf`
2. **Create router configs** in `routers/router-name.conf`
3. (optional) **Set hardware optimizations** in `wireless-configs/common-overrides.conf`
4. **Deploy**: `./deploy-wireless.sh routers/router-name.conf`

Example output:
```sh
./deploy-wireless.sh routers/ap-bedroom.conf
[INFO] OpenWRT Wireless Configuration Deployment
[INFO] Starting deployment to 1 router(s)...
[INFO] Processing router config: routers/ap-bedroom.conf
[INFO] Deploying to ap-bedroom (192.168.1.32:22)...
[INFO] Copying wireless setup script...
setup_wireless.sh                             100% 4940   567.4KB/s   00:00
[INFO] Copying configuration files...
ssid_guest.conf                               100%  367    69.0KB/s   00:00
ssid_main.conf                                100%  339    76.5KB/s   00:00
common-overrides.conf                         100%  722   146.6KB/s   00:00
ssid_iot.conf                                 100%  368    71.4KB/s   00:00
[INFO] Creating router-specific overrides...
tmp.pqczxFwrtH                                100% 2012   285.5KB/s   00:00
[INFO] Executing setup script...
[*] Loading router-specific overrides: ./wireless-configs/router-overrides.conf
[*] Cleaning up existing wireless interfaces...
[*] Loading config: ./wireless-configs/ssid_guest.conf
    [-] SSID 'GuestWifi' disabled by router override
[*] Loading config: ./wireless-configs/ssid_main.conf
    [-] Skipping SSID 'MainWifi' on 2g (radio0) - not in specified bands: 5g
    [+] Applying SSID 'MainWifi' to 5g on radio1...
[*] Loading config: ./wireless-configs/ssid_iot.conf
    [-] SSID 'IotWifi' disabled by router override
[*] Enabling radios...
[*] Committing wireless config and reloading...
[SUCCESS] Configuration applied successfully on ap-bedroom (192.168.1.32)

[INFO] Deployment Summary:
[SUCCESS] Successful deployments: 1/1
[SUCCESS] All deployments completed successfully!
```

## System Architecture

```
openwrt/
├── openwrt-scripts/
│   └── setup_wireless.sh           # Setup script (runs on router)
├── wireless-configs/
│   ├── common-overrides.conf       # Hardware-specific settings for ALL routers
│   ├── ssid_main.conf             # Main network definition
│   ├── ssid_guest.conf            # Guest network definition
│   ├── ssid_iot.conf              # IoT network definition
│   └── ssid_vlan*.conf            # VLAN-specific networks
├── routers/
│   ├── main-router.conf           # Main router: IP + specific overrides
│   ├── bedroom-router.conf        # Bedroom router: IP + specific overrides
│   └── office-router.conf         # Office router: IP + specific overrides
├── deploy-wireless.sh             # Deployment script
└── README.md                      # This file
```

## How It Works

### 1. Three-Layer Configuration System

1. **Shared SSID Configs** - Base network definitions
2. **Common Overrides** - Hardware-specific optimizations applied to ALL routers
3. **Router-Specific Configs** - Router names and IP addresses + optional location-specific overrides

### 2. Deployment Process

```bash
./deploy-wireless.sh routers/bedroom-router.conf
```

1. Reads router config for IP/SSH details
2. Combines common overrides + router-specific overrides
3. Copies setup script and configs to router
4. Clears existing wireless configuration on router
5. Executes new wireless configuration on router

### 3. Override Precedence

```
Common Overrides → Router-Specific Overrides → Final Configuration
    (All routers)      (Individual router)         (Applied)
```

## Configuration Examples

### SSID Configuration
```bash
# wireless-configs/ssid_main.conf
SSID_NAME="MyHome-WiFi"
SSID_KEY="secure-password-123"
SSID_NETWORK="vlan10" # VLAN ID for main network
SSID_ENCRYPTION="sae"
SSID_BANDS="2g 5g"
```

### Common Hardware Optimizations
```bash
# wireless-configs/common-overrides.conf
# Set country code if needed (optional - only set if required)
COUNTRY_CODE="FI"

case "$HARDWARE_MODEL" in
    *"Archer"*)
        RADIO_OVERRIDE_radio0_txpower="17"
        RADIO_OVERRIDE_radio1_txpower="20"
        ;;
    *"Netgear"*)
        RADIO_OVERRIDE_radio0_txpower="18"
        RADIO_OVERRIDE_radio1_txpower="21"
        ;;
esac
```

### Router-Specific Configuration
```bash
# routers/bedroom-router.conf
ROUTER_IP="192.168.1.2" # mandatory
ROUTER_NAME="bedroom-router"
SSH_USER="root"
SSH_PORT="22"

# Optional bedroom-specific settings
RADIO_OVERRIDE_radio0_channel="11"
RADIO_OVERRIDE_radio1_channel="149"
SSID_OVERRIDE_guest_disabled="1"  # No guest network in bedroom
SSID_OVERRIDE_iot_bands="2g"      # IoT on 2.4GHz only for better penetration
```

## Common Use Cases

### Different Router Locations
- **Main Router**: Full power, all networks, optimal channels
- **Bedroom Router**: Reduced power, no guest network, different channels
- **Office Router**: High performance, WPA3, work-optimized settings
- **Garage Router**: Industrial settings, limited networks

### Hardware Variations
- **Archer C7**: Reduced power (runs hot), conservative HT modes
- **Archer AX Series**: WiFi 6 optimization, higher power capability
- **Netgear Models**: Standard optimization, good thermal management
- **Older Hardware**: PSK2 fallback, reduced feature set

## Deployment Commands

### Basic Deployment
```bash
# Single router
./deploy-wireless.sh routers/main-router.conf

# Multiple routers
./deploy-wireless.sh routers/main-router.conf routers/bedroom-router.conf

# All routers
./deploy-wireless.sh routers/*.conf
```

### Testing and Debugging
```bash
# Dry run (test without changes)
./deploy-wireless.sh -d routers/main-router.conf

# Verbose output
./deploy-wireless.sh -v routers/main-router.conf

# Dry run with verbose output
./deploy-wireless.sh -v -d routers/*.conf
```

## Key Features Explained

### 🔧 Common Overrides System
- **Purpose**: Apply hardware-specific optimizations to all routers automatically
- **Benefits**: No duplicate configuration, consistent hardware optimization
- **Usage**: Put hardware detection and optimization in `wireless-configs/common-overrides.conf`

### 📍 Router-Specific Overrides
- **Purpose**: Customize settings for specific router locations or purposes
- **Benefits**: Fine-tune each router while maintaining shared network definitions
- **Usage**: Add overrides to individual `routers/*.conf` files

### 🚀 Automated Deployment
- **Purpose**: Deploy configurations to multiple routers efficiently
- **Benefits**: Consistent deployment, error handling, rollback capability
- **Usage**: Single command deploys to any number of routers

## Documentation

- **[wireless-configs/README.md](wireless-configs/README.md)** - Detailed system documentation
- **[EXAMPLE-USAGE.md](EXAMPLE-USAGE.md)** - Real-world usage examples and scenarios
- **[COMMON-OVERRIDES.md](COMMON-OVERRIDES.md)** - Common overrides system explained
- **[MIGRATION.md](MIGRATION.md)** - Migration guide from older systems

## Quick Setup Guide

### 1. Create Your Network Definitions
```bash
# Copy examples and customize
cp wireless-configs/ssid_main.conf.example wireless-configs/ssid_main.conf
cp wireless-configs/ssid_guest.conf.example wireless-configs/ssid_guest.conf
# Edit with your network names and passwords
```

### 2. Set Up Hardware Optimizations
```bash
# Copy and customize common overrides
cp wireless-configs/common-overrides.conf.example wireless-configs/common-overrides.conf
# Add your router models and optimizations
```

### 3. Create Router Configurations
```bash
# Copy examples and customize
cp routers/main-router.conf.example routers/my-main-router.conf
cp routers/bedroom-router.conf.example routers/my-bedroom-router.conf
# Edit with your router IPs and specific settings
```

### 4. Test and Deploy
```bash
# Test first
./deploy-wireless.sh -d routers/my-main-router.conf

# Deploy if test looks good
./deploy-wireless.sh routers/my-main-router.conf
```

## Advanced Features

### SSH Key Authentication
```bash
# In router config
SSH_KEY="/home/user/.ssh/openwrt_key"
SSH_PORT="2222"
```

### Hardware Detection
```bash
# In common-overrides.conf
HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")
case "$HARDWARE_MODEL" in
    *"Your-Router-Model"*)
        # Your optimizations here
        ;;
esac
```

## Configuration Notes

### Country Code Setting
- **No default country code** is set by the system
- Country code is only applied if explicitly defined via `COUNTRY_CODE`
- Set `COUNTRY_CODE="XX"` in `common-overrides.conf` or individual router configs
- Each router will use its existing country setting if none is specified

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
