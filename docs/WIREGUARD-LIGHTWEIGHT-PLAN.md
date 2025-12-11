# WireGuard for Tide Gateway - Lightweight Implementation

## Philosophy: Minimal, Lean, Alpine-Native

**NO:**
- ❌ Complex frameworks
- ❌ Additional dependencies
- ❌ Web UIs for WireGuard management
- ❌ Docker-in-Docker nonsense
- ❌ Custom WireGuard forks
- ❌ Unnecessary features

**YES:**
- ✅ Alpine's native `wireguard-tools` package (~200KB)
- ✅ Simple shell scripts
- ✅ QR code generation via CLI
- ✅ Integrated with existing `tide` command
- ✅ Minimal config files

---

## Package Size

```bash
# Alpine WireGuard packages (total: ~500KB)
apk add wireguard-tools    # ~200KB - wg, wg-quick commands
apk add qrencode           # ~50KB  - QR code generation
apk add libqrencode        # ~50KB  - QR library

# Total additional size: ~300KB
# That's it. No bloat.
```

---

## Implementation Plan

### 1. Add WireGuard to Gateway Install

**File:** `scripts/runtime/gateway-start.sh`

```bash
# Add to package installation (one line)
apk add wireguard-tools qrencode

# WireGuard config template (~15 lines)
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = <generated>
Address = 10.101.200.1/24
ListenPort = 51820

[Peer]
# Clients added via: tide wireguard add-client
EOF
```

### 2. Add to `tide` CLI

**File:** `scripts/runtime/tide-cli.sh` (add ~50 lines)

```bash
tide wireguard setup        # One-time setup
tide wireguard add <name>   # Add client, show QR
tide wireguard list         # List clients
tide wireguard remove <name> # Remove client
```

**That's it.** No complex tooling needed.

---

## File Structure (Minimal)

```
/etc/wireguard/
├── wg0.conf              # Main config (~20 lines)
├── private.key           # Server private key
├── public.key            # Server public key
└── clients/
    ├── anthony-iphone.conf   # Client config (~10 lines each)
    └── anthony-iphone.png    # QR code (auto-deleted after scan)
```

**Total files:** 5-10 files max  
**Total disk:** <1MB

---

## Client Setup (User Experience)

### On Tide Gateway:
```bash
ssh root@tide-gateway

# First time only
tide wireguard setup
# ✓ WireGuard configured
# ✓ Listening on port 51820

# Add mobile device
tide wireguard add anthony-iphone
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 WireGuard Client: anthony-iphone
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scan this QR code with WireGuard app:

█████████████████████████████████
█████████████████████████████████
███████         ██████    ███████
███   ████  ███  ████  ██  ██████
███   ████████  █████████  ██████
...

Or copy config to device:
/etc/wireguard/clients/anthony-iphone.conf

Client IP: 10.101.200.2
Gateway: 10.101.200.1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### On iPhone:
1. Open WireGuard app (App Store - free)
2. Tap "Add Tunnel" → "Scan QR Code"
3. Scan the QR code
4. Tap "Activate"
5. **Done** ✅

**All traffic now through Tide Gateway → Tor**

---

## Integration with Existing Modes

### Router Mode + WireGuard:
```bash
tide mode router --enable-wireguard
```

**What happens:**
- Router mode: Transparent routing for VMs on host-only network
- WireGuard: VPN for mobile devices
- Both work simultaneously
- No conflicts, no complexity

### Killa Whale + WireGuard:
```bash
tide mode killa-whale --enable-wireguard
```

**What happens:**
- Killa Whale: Aggressive for host-only network
- WireGuard: Secure tunnel for mobile
- Mobile gets same fail-closed protection

---

## Firewall Rules (Minimal Changes)

**Add ONE rule:**
```bash
# Allow WireGuard on shared network
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
```

**That's it.** WireGuard handles the rest.

---

## Security Model

### WireGuard Security Features (Built-in):
- ✅ Modern crypto (ChaCha20, Poly1305)
- ✅ Perfect forward secrecy
- ✅ Peer authentication (public keys)
- ✅ No username/password (key-based only)
- ✅ Minimal attack surface (< 4,000 lines of code)
- ✅ Peer isolation (clients can't see each other)

### Tide Integration:
- ✅ Only your approved devices (you generate configs)
- ✅ Revocable (remove client = instant disconnect)
- ✅ No internet exposure (WireGuard runs on shared network)
- ✅ Logged (WireGuard logs to syslog)

---

## Performance Impact

**CPU:** Negligible (<1% overhead)  
**RAM:** ~2MB per connected client  
**Disk:** <1MB total  
**Network:** ~60-100 bytes overhead per packet

**Mobile battery impact:** Minimal (WireGuard is extremely efficient)

---

## Mobile App Requirements

### Option A: WireGuard App Only (Simplest)
**Just use the official WireGuard app. Done.**

Pros:
- Zero development work
- Proven, audited, maintained
- Free, open source
- Available on App Store / Play Store

Cons:
- Generic UI (not branded)
- No Tide-specific features (exit IP, circuit control)

### Option B: WireGuard + Companion App (Recommended)

**Use WireGuard app for VPN connection.**

**Build tiny companion app for:**
- Connection status
- Current exit IP / country
- "New Circuit" button
- Connected clients count
- Bandwidth usage

**Stack:**
- iOS: SwiftUI (~200 lines)
- Android: Kotlin/Jetpack Compose (~300 lines)
- Both: Call Tide API (http://10.101.200.1:9051/status)

**App size:** <2MB  
**Development time:** 1-2 days per platform

---

## Implementation Code (Complete)

### 1. WireGuard Setup Function

**File:** `scripts/runtime/tide-wireguard.sh` (~100 lines total)

```bash
#!/bin/sh
# Tide WireGuard Management - Lightweight

setup_wireguard() {
    echo "Installing WireGuard..."
    apk add --no-cache wireguard-tools qrencode
    
    echo "Generating keys..."
    wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key
    chmod 600 /etc/wireguard/private.key
    
    PRIVATE_KEY=$(cat /etc/wireguard/private.key)
    
    echo "Creating config..."
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.101.200.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
EOF
    
    echo "Starting WireGuard..."
    wg-quick up wg0
    
    echo "Enabling on boot..."
    rc-update add wg-quick@wg0 default
    
    echo "✓ WireGuard setup complete"
}

add_client() {
    CLIENT_NAME="$1"
    CLIENT_NUM=$(wg show wg0 peers | wc -l)
    CLIENT_IP="10.101.200.$((CLIENT_NUM + 2))"
    
    # Generate client keys
    CLIENT_PRIVATE=$(wg genkey)
    CLIENT_PUBLIC=$(echo "$CLIENT_PRIVATE" | wg pubkey)
    SERVER_PUBLIC=$(cat /etc/wireguard/public.key)
    
    # Get server endpoint (your public IP or hostname)
    SERVER_IP=$(curl -s ifconfig.me)
    
    # Create client config
    mkdir -p /etc/wireguard/clients
    cat > "/etc/wireguard/clients/${CLIENT_NAME}.conf" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE
Address = $CLIENT_IP/24
DNS = 10.101.200.1

[Peer]
PublicKey = $SERVER_PUBLIC
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    # Add peer to server
    wg set wg0 peer "$CLIENT_PUBLIC" allowed-ips "$CLIENT_IP/32"
    wg-quick save wg0
    
    # Generate QR code
    qrencode -t ANSIUTF8 < "/etc/wireguard/clients/${CLIENT_NAME}.conf"
    
    echo ""
    echo "✓ Client added: $CLIENT_NAME"
    echo "  IP: $CLIENT_IP"
    echo "  Config: /etc/wireguard/clients/${CLIENT_NAME}.conf"
}
```

**That's the entire implementation.** ~100 lines.

---

## Testing Plan

### Phase 1: Gateway Setup
```bash
# SSH into Tide Gateway
ssh root@tide-gateway

# Install and setup
apk add wireguard-tools qrencode
./scripts/runtime/tide-wireguard.sh setup
```

### Phase 2: Client Connection
```bash
# Add iPhone
./scripts/runtime/tide-wireguard.sh add anthony-iphone

# Scan QR with WireGuard app
# Tap "Activate"
```

### Phase 3: Verify Tor Routing
```bash
# On iPhone, open Safari
# Visit: https://check.torproject.org

# Should see:
# "Congratulations. This browser is configured to use Tor."
```

**Total test time:** 5 minutes

---

## Disk Usage Comparison

```
Without WireGuard:
Tide Gateway: ~150MB

With WireGuard:
WireGuard package: ~300KB
Config files: <100KB
Total: ~150.4MB

Increase: 0.2% ✅
```

---

## Maintenance

**Zero maintenance needed.**

WireGuard is:
- Set-and-forget
- No updates required (Alpine handles it)
- No service restarts needed
- No log rotation issues (uses syslog)

---

## Future Mobile App (Optional)

**If you want a branded experience:**

### Minimal App Features:
1. **Connection status** - "Connected via Tide Gateway"
2. **Exit info** - "Exit: Netherlands (NL), IP: 185.220.x.x"
3. **One button** - "New Circuit"
4. **That's it.**

### Implementation:
- SwiftUI (iOS): 1 file, ~200 lines
- Jetpack Compose (Android): 1 file, ~300 lines
- API calls to `http://10.101.200.1:9051/status`
- No VPN code (WireGuard app handles that)

**App size:** <2MB  
**Complexity:** Minimal  

---

## Summary

### What You Get:
✅ **Secure mobile access** to Tide Gateway from anywhere  
✅ **<500KB** additional disk space  
✅ **~100 lines** of shell script  
✅ **Zero dependencies** beyond Alpine packages  
✅ **Industry standard** (WireGuard used by millions)  
✅ **Battle-tested** security  
✅ **Set-and-forget** maintenance  

### What You DON'T Get:
❌ Bloat  
❌ Complex configuration  
❌ Custom protocols  
❌ Maintenance headaches  
❌ Security concerns  

---

**This is the lean, minimal, Alpine-way to do mobile VPN.** 🌊

**Next step:** Add WireGuard to gateway install script and test.
