# OpenWRT WiFi Access Point Management Tools

Use case: You already have a network with VLANS and you want to setup/manage wifi SSIDs for those VLANS. Use this tool to provision OpenWRT devices as wifi access points with VLAN segmentation and corresponding wireless networks, perfect for creating segmented wifi networks (main, guest, IoT, etc.). You will end up with "dumb" APs, with an IP address on management VLAN only.

### Caveats

- Designed to be used on fresh OpenWRT installations - **IF YOU HAVE EXISTING CONFIGURATIONS, PROCEED WITH CAUTION!** Please backup your current configuration.

- The script **disables switch ports** except for the uplink port. So if your device has multiple ports and you're using them, the tool as-is will not work for you currently.

## Tools included

### 1. **Backup Existing Configuration** (`backup-config.sh`)

Exports the current network and wireless configurations from all or selected APs.

### 1. **Network Setup** (`deploy-networks.sh`)

Configures VLAN network segmentation on OpenWRT access points, setting up trunk ports and VLAN interfaces for network isolation.

### 2. **Wireless Deployment** (`deploy-wireless.sh`)

Deploys wireless networks (SSIDs) mapped to specific VLANs, creating segmented WiFi networks on your access points. You must do `deploy-networks.sh` first to have VLANs configured.

### 3. **Complete Deployment** (`deploy-complete.sh`)

Deploys both network and wireless configurations simultaneously, ensuring VLANs and SSIDs are properly mapped across all APs. Does both `deploy-networks.sh` and `deploy-wireless.sh`.

## ✨ Key Features

- **📡 Easy AP Management**: Deploy configurations to multiple OpenWRT access points simultaneously
- **🎯 VLAN-Segregated WiFi Networks**: Configure access points as dumb APs with VLAN-mapped SSIDs
- **🔄 Coordinated Network & Wireless**: Ensures VLANs and SSIDs are properly mapped across all APs
- **🔧 Hardware-Aware Configuration**: Optional optimizations for different AP models. Useful if you have plenty of APs with different models.
- **⚙️ Three-Layer Override System**: Global defaults → Common overrides → AP-specific customizations
- **🏠 Location-Specific Optimization**: Per-AP settings for different environments and hardware

## 🚀 Quick Start

### Complete Setup Workflow

1. **Define your network**: VLAN definition in `network-configs/vlan_XX.conf`, wifi configuration in `wireless-configs/ssid_vlanXX.conf`
2. **Configure access points**: Set up AP-specific settings (IP, name, location, optionally static IP, radio channel and optimizations, and other customizations) in `aps/ap-<location>.conf`
3. **Deploy everything**: Use one command to configure all APs

```bash
# Deploy complete infrastructure to all access points
./deploy-complete.sh aps/*.conf
```

### Command Line Parameters

**All scripts:**
| Parameter | Short | Description |
|-----------|-------|-------------|
| `--backup` | `-b` | Create UCI export backup before deployment |
| `--dry-run` | `-d` | Show what would be deployed without making changes |
| `--verbose` | `-v` | Enable verbose output and detailed logging |
| `--help` | `-h` | Show usage information and examples |

**Additional options for `deploy-complete.sh`:**

| Parameter | Short | Description |
|-----------|-------|-------------|
| `--networks-only` | `-n` | Deploy only network configurations (skip wireless) |
| `--wireless-only` | `-w` | Deploy only wireless configurations (skip networks) |


## 📋 Configuration Examples

See more examples and common scenarios in [Example Usage](EXAMPLE-USAGE.md).

### Access Point Configuration
```bash
# aps/ap-livingroom.conf
#!/bin/sh
# Living room access point configuration

# Access Point identification
AP_IP="192.168.1.101"
AP_NAME="ap-livingroom"
AP_LOCATION="livingroom"

# Refer to /etc/board.json or LuCI web interface to find out
UPLINK_PORT="1"  # Uplink on port 1 for this AP
CPU_PORT="0"

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

### VLAN Configuration
```bash
# network-configs/vlan_10.conf
VLAN_ID="10"
VLAN_NAME="mgmt"
VLAN_DESCRIPTION="Management Network"
# This VLAN is tagged on uplink port (trunk port)
# You can also override this per AP if it varies
VLAN_UNTAGGED="0"
VLAN_PROTO="dhcp"  # Access point gets IP on this VLAN

# network-configs/vlan_20.conf
VLAN_ID="20"
VLAN_NAME="main"
VLAN_DESCRIPTION="Main Network"
VLAN_UNTAGGED="0" # VLAN is tagged on uplink port
# No IP on this VLAN (default)
```

### SSID Configuration
```bash
# wireless-configs/ssid_vlan10_mgmt.conf
SSID_NAME="Management-WiFi"
SSID_KEY="secure-password-123"
SSID_NETWORK="vlan10"  # mgmt = VLAN 10
SSID_ENCRYPTION="sae"
SSID_BANDS="5g" # Only on 5GHz band - Can override per AP if needed

# wireless-configs/ssid_vlan20_mgmt.conf
SSID_NAME="Main-WiFi"
SSID_KEY="secure-password-123"
SSID_NETWORK="vlan20"  # main = VLAN 20
SSID_ENCRYPTION="sae"
SSID_BANDS="2g 5g" # Both frequencies
```

### Common Hardware Optimizations and Settings
```bash
# wireless-configs/common-overrides.conf
#!/bin/sh
# Wireless settings applied to ALL access points

# Good place to put default values for all AP's in this file

# Country code for regulatory compliance
COUNTRY_CODE="US"
```

```bash
# network-configs/common-overrides.conf
#!/bin/sh
# Optional: Network settings applied to ALL access points

# Defaults, settings/quirks based on AP model, ...
# HARDWARE_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "unknown")
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

## 🏗️ File Structure

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
├── openwrt-scripts/                   # Deployment scripts for OpenWRT - Runs on the APs
│   ├── setup_networks.sh             # Network configuration script
│   └── setup_wireless.sh             # Wireless configuration script
├── deploy-networks.sh                 # Deploy network configs to APs
├── deploy-wireless.sh                 # Deploy wireless configs to APs
└── deploy-complete.sh                 # Deploy both networks + wireless
```

## 🔧 How It Works

### 1. Deployment Process

1. **Network Deployment** (`deploy-networks.sh`):
   - Clears current network configurations
   - Loads base VLAN definitions and common network overrides from .conf files
   - Merges with AP-specific network settings
   - Configures switch ports, VLANs, and interfaces on each AP

2. **Wireless Deployment** (`deploy-wireless.sh`):
   - Clears current wireless configurations
   - Loads base SSID definitions and common wireless overrides from .conf files
   - Merges with AP-specific settings
   - Configures radios, wireless networks, and VLAN-SSID mapping on each AP

3. **Complete Deployment** (`deploy-complete.sh`):
   - Runs network deployment first (VLANs must exist before wireless mapping)
   - Then runs wireless deployment
   - Ensures coordinated configuration across all APs

### 2. Override Precedence

Settings are applied in this order (later overrides earlier):
1. Base configuration files (`vlan_*.conf`, `ssid_*.conf`)
2. Common overrides (`common-overrides.conf`) **optional**
3. AP-specific settings and overrides (variables in `aps/*.conf` files)

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

## Backup and Restore

```bash
# Create UCI backups manually
./backup-aps.sh aps/*.conf

# Deploy with automatic backup
./deploy-complete.sh -b aps/*.conf
./deploy-networks.sh -b aps/ap-main.conf
./deploy-wireless.sh -b aps/ap-main.conf

# Restore from backup with something like (example)
scp -O ap-main.20231215_143022.uciexport root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "uci import < /tmp/ap-main.20231215_143022.uciexport && uci commit"
```

Backup files are created locally as: `{AP_NAME}.{YYYYMMDD_HHMMSS}.uciexport`

## 📚 More Examples

- **[Example Usage](EXAMPLE-USAGE.md)**: Step-by-step examples and common scenarios
- **Configuration Templates**: Example files in each directory showing proper syntax
