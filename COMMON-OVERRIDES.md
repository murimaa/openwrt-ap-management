# Common Overrides System

The common overrides system allows you to define wireless settings that apply to all routers in your network, while still allowing individual routers to override these settings when needed.

## Overview

The system works with two types of overrides:

1. **Common Overrides** (`wireless-configs/common-overrides.conf`) - Applied to ALL routers
2. **Router-Specific Overrides** (in individual `routers/*.conf` files) - Applied to specific routers

When deploying, the system combines both files with router-specific overrides taking precedence over common ones.

## File Structure

```
openwrt/
├── wireless-configs/
│   ├── common-overrides.conf       # Settings applied to ALL routers
│   └── ssid_*.conf                 # Network definitions
├── routers/
│   ├── main-router.conf            # Router-specific overrides
│   └── bedroom-router.conf         # Router-specific overrides
└── deploy-wireless.sh
```

## How It Works

During deployment:
1. Common overrides are loaded first
2. Router-specific overrides are loaded second
3. Router-specific settings override common ones
4. Combined settings are applied to the router

## When to Use Common Overrides

### ✅ Good Use Cases

- **Hardware-specific optimizations** that apply to router models
- **Country/regulatory settings** that are the same everywhere
- **Security baseline settings** that should be consistent
- **Power management defaults** for energy efficiency
- **Channel width settings** based on hardware capabilities

### ❌ Don't Use For

- **Router location-specific settings** (channels, power levels for specific locations)
- **Network topology settings** (different SSIDs per router)
- **Environment-specific optimizations** (bedroom vs garage settings)

## Common Overrides File Structure

```bash
#!/bin/sh
# Common overrides applied to ALL routers
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
        # Netgear routers generally handle heat well
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
# Individual routers can override if hardware doesn't support it
SSID_OVERRIDE_main_encryption="sae-mixed"
SSID_OVERRIDE_vlan50_encryption="sae-mixed"

# Enable management frame protection where possible
SSID_OVERRIDE_main_extra="ieee80211w=1"

# ===========================================
# POWER MANAGEMENT DEFAULTS
# ===========================================

# Conservative power settings that work for most environments
# Individual routers can increase/decrease as needed
RADIO_OVERRIDE_radio0_txpower="${RADIO_OVERRIDE_radio0_txpower:-15}"
RADIO_OVERRIDE_radio1_txpower="${RADIO_OVERRIDE_radio1_txpower:-18}"

# ===========================================
# REGULATORY/COUNTRY SETTINGS
# ===========================================

# Set country code if needed (optional - no default is set)
# Only uncomment and set if your routers require a specific country code
# COUNTRY_CODE="FI"

# ===========================================
# PERFORMANCE BASELINE
# ===========================================

# Default channel widths that work well for most hardware
RADIO_OVERRIDE_radio0_htmode="${RADIO_OVERRIDE_radio0_htmode:-HT20}"
RADIO_OVERRIDE_radio1_htmode="${RADIO_OVERRIDE_radio1_htmode:-VHT40}"

# Note: Country code has no default and is only applied if explicitly set
# Set COUNTRY_CODE above if your deployment requires it
```

## Router-Specific Override Examples

Individual router configs can override any common setting:

```bash
#!/bin/sh
# routers/high-performance-router.conf

ROUTER_IP="192.168.1.1"
ROUTER_NAME="main-router"

# Override common power settings for this high-performance location
RADIO_OVERRIDE_radio0_txpower="20"  # Higher than common default
RADIO_OVERRIDE_radio1_txpower="23"  # Higher than common default

# Override common channel width for better performance
RADIO_OVERRIDE_radio1_htmode="VHT80"  # Wider than common default

# Location-specific channel selection (not in common overrides)
RADIO_OVERRIDE_radio0_channel="6"
RADIO_OVERRIDE_radio1_channel="36"
```

## Best Practices

### 1. Start with Hardware Optimizations

The most common use case is hardware-specific settings:

```bash
# Good: Hardware-specific optimizations
case "$HARDWARE_MODEL" in
    *"ModelName"*)
        RADIO_OVERRIDE_radio0_txpower="15"
        RADIO_OVERRIDE_radio0_htmode="HT20"
        ;;
esac
```

### 2. Use Fallback Defaults

Provide fallbacks that individual routers can override:

```bash
# Good: Provides default but allows override
RADIO_OVERRIDE_radio0_txpower="${RADIO_OVERRIDE_radio0_txpower:-15}"

# Bad: Forces setting, can't be overridden easily
RADIO_OVERRIDE_radio0_txpower="15"
```

### 3. Document Your Reasoning

```bash
# Good: Explains why the setting exists
case "$HARDWARE_MODEL" in
    *"Archer C7"*)
        # C7 series runs hot under load, reduce power to prevent thermal throttling
        RADIO_OVERRIDE_radio0_txpower="17"
        ;;
esac
```

### 4. Group Related Settings

```bash
# Good: Logical grouping
# ===========================================
# SECURITY BASELINE
# ===========================================
SSID_OVERRIDE_main_encryption="sae-mixed"
SSID_OVERRIDE_main_extra="ieee80211w=1"

# ===========================================
# POWER MANAGEMENT
# ===========================================
RADIO_OVERRIDE_radio0_txpower="15"
RADIO_OVERRIDE_radio1_txpower="18"
```

## Testing Common Overrides

### Test with Dry Run

```bash
# Test how common overrides combine with router-specific ones
./deploy-wireless.sh -v -d routers/test-router.conf
```

### Verify Override Precedence

Create a test router config that overrides a common setting:

```bash
# routers/test-override.conf
ROUTER_IP="192.168.1.100"
ROUTER_NAME="test"

# Override a common setting to verify precedence works
RADIO_OVERRIDE_radio0_txpower="10"  # Should override common default
```

### Check Applied Settings

After deployment, verify on the router:

```bash
ssh root@192.168.1.1 "uci show wireless | grep txpower"
```

## Common Patterns

### Pattern 1: Hardware Family Optimizations

```bash
# Optimize entire hardware families
case "$HARDWARE_MODEL" in
    *"Archer C"*)
        # All Archer C series
        RADIO_OVERRIDE_radio0_txpower="17"
        ;;
    *"Archer AX"*)
        # All Archer AX series (WiFi 6)
        RADIO_OVERRIDE_radio1_htmode="HE80"
        ;;
esac
```

### Pattern 2: Feature Detection

```bash
# Enable features based on hardware capabilities
if grep -q "802.11ax" /proc/net/wireless 2>/dev/null; then
    # Hardware supports WiFi 6
    RADIO_OVERRIDE_radio1_htmode="HE80"
else
    # Fallback for older hardware
    RADIO_OVERRIDE_radio1_htmode="VHT40"
fi
```

### Pattern 3: Progressive Defaults

```bash
# Set conservative defaults that routers can increase
RADIO_OVERRIDE_radio0_txpower="12"  # Conservative baseline
RADIO_OVERRIDE_radio1_txpower="15"  # Conservative baseline

# High-performance routers will override with higher values
# Low-power routers might override with even lower values
```

## Troubleshooting

### Override Not Applied

1. Check if router-specific config overrides the common setting
2. Verify syntax in common-overrides.conf
3. Test with verbose mode: `./deploy-wireless.sh -v -d router.conf`

### Conflicting Settings

1. Remember router-specific overrides take precedence
2. Use conditional logic in common overrides when needed
3. Document any complex interactions

### Hardware Detection Issues

```bash
# Add debugging to see what hardware is detected
echo "Hardware detected: $HARDWARE_MODEL" >&2
case "$HARDWARE_MODEL" in
    *"Expected"*)
        echo "Applying expected optimizations" >&2
        ;;
    *)
        echo "Unknown hardware, using defaults" >&2
        ;;
esac
```

## Migration to Common Overrides

If you have duplicate settings across multiple router configs:

1. **Identify common patterns** across your router configs
2. **Move hardware-specific settings** to common-overrides.conf
3. **Keep location-specific settings** in individual router configs
4. **Test thoroughly** with dry runs before deploying

### Example Migration

**Before:** Duplicate in every router config
```bash
# routers/router1.conf
case "$HARDWARE_MODEL" in
    *"Archer"*) RADIO_OVERRIDE_radio0_txpower="17" ;;
esac

# routers/router2.conf
case "$HARDWARE_MODEL" in
    *"Archer"*) RADIO_OVERRIDE_radio0_txpower="17" ;;
esac
```

**After:** Centralized in common overrides
```bash
# wireless-configs/common-overrides.conf
case "$HARDWARE_MODEL" in
    *"Archer"*) RADIO_OVERRIDE_radio0_txpower="17" ;;
esac

# routers/router1.conf - hardware settings removed, only location-specific
RADIO_OVERRIDE_radio0_channel="6"

# routers/router2.conf - hardware settings removed, only location-specific
RADIO_OVERRIDE_radio0_channel="11"
```

This system provides a clean separation between hardware optimizations (common to all) and deployment-specific settings (unique per router).
