# Tide Mode Selection Implementation

**Date:** December 9, 2025  
**Summary:** Implemented full mode selection logic and security profile support

---

## Problem

The Tide gateway had `.env` configuration variables for different modes (`TIDE_MODE`, `TIDE_SECURITY`) but the startup script **ignored them**. Setting `TIDE_MODE=killa-whale` did nothing.

### What Wasn't Working

1. **Mode Selection**: `gateway-start.sh` didn't check `TIDE_MODE` environment variable
2. **Killa Whale Mode**: Leak-proof iptables rules existed in `config/iptables-leak-proof.rules` but were never loaded
3. **Security Profiles**: Torrc configs for hardened/paranoid/bridges modes weren't wired up
4. **Takeover Mode**: No ARP hijacking code existed

---

## Solution Implemented

### 1. Rewrote `gateway-start.sh` with Mode Logic

**Added:**
- Environment variable loading (`TIDE_MODE`, `TIDE_SECURITY`, etc.)
- Mode-specific firewall configuration
- Security profile torrc selection
- Comprehensive logging of active configuration

**Modes Now Functional:**
- ✅ **Proxy Mode**: SOCKS5 only, no DHCP, no transparent routing
- ✅ **Router Mode**: Transparent routing + DHCP (default)
- ✅ **Killa Whale Mode**: Router + fail-closed OUTPUT firewall
- 🚧 **Takeover Mode**: Placeholder (falls back to Killa Whale mode)

### 2. Created Security Profile Torrc Files

**New Files:**
- `config/torrc-hardened`: Excludes 14-eyes countries (US, UK, CA, AU, NZ, DK, FR, NL, NO, DE, BE, IT, ES, SE)
- `config/torrc-paranoid`: Maximum isolation, excludes all surveillance states
- `config/torrc-bridges`: obfs4 bridge support for censorship bypass

**Selection Logic:**
- `TIDE_SECURITY=standard` → Uses default `torrc-gateway`
- `TIDE_SECURITY=hardened` → Uses `torrc-hardened`
- `TIDE_SECURITY=paranoid` → Uses `torrc-paranoid`
- `TIDE_SECURITY=bridges` → Uses `torrc-bridges`

### 3. Updated Dockerfile

**Changes:**
- Copies all torrc configurations to container
- Copies leak-proof iptables rules to `/etc/tide/`
- Makes all configs available for mode selection

---

## Technical Details

### Killa Whale Mode Firewall Rules

The key difference between Router and Killa Whale mode is the OUTPUT chain:

**Router Mode (Fail-Open):**
```bash
iptables -P OUTPUT ACCEPT  # Default policy: ACCEPT
# If Tor dies, gateway can still leak traffic
```

**Killa Whale Mode (Fail-Closed):**
```bash
iptables -P OUTPUT DROP  # Default policy: DROP
iptables -A OUTPUT -m owner --uid-owner tor -p tcp -j ACCEPT  # ONLY Tor allowed
iptables -A OUTPUT -o eth0 -j DROP  # Everything else BLOCKED
# If Tor dies, ALL traffic is BLOCKED
```

###Verification

Test showed correct OUTPUT chain:
```
Chain OUTPUT (policy DROP 0 packets, 0 bytes)
  ACCEPT     tcp  --  *      eth0    owner UID match 101  ← Tor only
  DROP       all  --  *      eth0                          ← Block all else
```

---

## Usage

### Set Mode in `.env`

```bash
# Deployment mode
TIDE_MODE=killa-whale  # proxy, router, killa-whale, takeover

# Security profile  
TIDE_SECURITY=hardened  # standard, hardened, paranoid, bridges

# Network settings
TIDE_GATEWAY_IP=10.101.101.10
TIDE_SUBNET=10.101.101.0/24
```

### Start Gateway

```bash
docker-compose up -d
```

The gateway will read `.env` and configure itself accordingly.

### Verify Mode

```bash
docker logs tide-gateway-router | head -20
```

You'll see:
```
📋 Configuration:
   Mode: killa-whale
   Security: hardened
   Gateway IP: 10.101.101.10
🔒 Loading fail-closed firewall rules...
✅ Fail-closed firewall active
🔐 Security: Hardened (excluding 14-eyes countries)
```

---

## What's Still Missing

1. **Takeover Mode**: ARP hijacking not implemented (placeholder exists)
2. **Bridge Configuration**: Users must add their own bridge lines to `torrc-bridges`
3. **Dynamic Mode Switching**: Can't change mode without restarting container
4. **Health Monitoring**: No automatic Tor health checks

---

## Files Changed

| File | Change |
|------|--------|
| `scripts/runtime/gateway-start.sh` | Complete rewrite with mode logic |
| `config/torrc-hardened` | NEW - 14-eyes exclusion |
| `config/torrc-paranoid` | NEW - Maximum isolation |
| `config/torrc-bridges` | NEW - obfs4 bridge support |
| `docker/Dockerfile.gateway` | Copy new torrc files and leak-proof rules |

---

## Testing

✅ **Tested Killa Whale Mode:**
- Built new image
- Started container with `TIDE_MODE=killa-whale`
- Verified OUTPUT chain has DROP policy
- Verified only Tor UID can connect out
- Tor bootstrap successful

✅ **Tested Standard/Router Mode:**
- Existing functionality unchanged
- DHCP + transparent routing still works

---

## Next Steps

1. **Implement ARP Hijacking** for Takeover mode
2. **Add Tor Health Monitoring** (auto-restart if dead)
3. **Create Mode Switching API** (change mode without restart)
4. **Document Bridge Setup** for users in censored regions

---

**Status:** ✅ Mode selection fully functional  
**Version:** v1.2.1 (mode selection implementation)  
**Ready for:** Testing in production VM environment

---

*Implemented by OpenCode on 2025-12-09*
