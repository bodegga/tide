# Tide Gateway - Mobile App Design

## The Idea

Mobile apps (iOS/Android) that connect to Tide Gateway for Tor access when on the same network.

---

## The Problem

**Current modes:**
- **Proxy mode** - Only SOCKS5, no routing (works for apps, but manual config)
- **Router mode** - Transparent routing via DHCP (only works for VMs/computers)
- **Killa Whale** - Router + fail-closed (same limitation)

**Mobile devices can't:**
- Use transparent routing (they're not VMs getting DHCP from Tide)
- Easily configure system-wide SOCKS5 (iOS especially locked down)
- Connect to Tide Gateway securely over WiFi

---

## Security Analysis

### Current Security Model

**Router/Killa Whale modes:**
```
Clients on eth1 (host-only) → Full access to Tide services
Clients on WAN/internet      → No access (firewalled)
```

**Threat model:**
- Tide Gateway is on **isolated host-only network**
- Only trusted VMs can reach it
- No internet exposure

**If we expose SOCKS5 to LAN:**
```
Anyone on your home WiFi → Could use your Tor gateway
                         → Could generate Tor traffic under your IP
                         → Could access illegal content via your exit nodes
                         → Could exhaust your bandwidth
```

### ⚠️ **Risk: Exposing SOCKS5 to LAN without auth = Security hole**

---

## Solution Options

### Option 1: **Hybrid Mode with Authentication** (RECOMMENDED)

**Concept:**
- New mode: `hybrid` (router + authenticated SOCKS5)
- Transparent routing for trusted VMs (current behavior)
- SOCKS5 exposed to LAN **with username/password**
- Mobile apps authenticate before using proxy

**Implementation:**
```bash
# New mode
tide mode hybrid

# Generates credentials
Username: tide-mobile
Password: <random-32-char>
```

**Security features:**
- SOCKS5 requires authentication (RFC 1929)
- Credentials stored in `/etc/tide/socks-auth`
- Mobile app requires credentials to connect
- Can rotate credentials: `tide proxy rotate-password`
- Optional: Rate limiting per client
- Optional: IP whitelist (only your mobile devices)

**Firewall rules:**
```bash
# Allow SOCKS5 from LAN with auth required
iptables -A INPUT -i eth0 -s 192.168.1.0/24 -p tcp --dport 9050 -j ACCEPT

# Tor configured with:
SocksPort 0.0.0.0:9050 # Auth required via separate module
```

**Tor SOCKS authentication:**
```
# /etc/tor/torrc-hybrid
SocksPort 0.0.0.0:9050
SocksPolicy accept 192.168.1.0/24
SocksPolicy reject *

# Use stunnel or custom auth proxy in front of Tor
```

### Option 2: **VPN Approach (WireGuard)** (MORE SECURE)

**Concept:**
- Mobile apps connect via WireGuard VPN
- Get IP on Tide's internal network (10.101.101.x)
- Use transparent routing like any other client
- No SOCKS5 exposure needed

**Implementation:**
```bash
# New mode (or addon to router/killa-whale)
tide wireguard setup

# Generates config for mobile
tide wireguard add-client "anthony-iphone"
# Outputs QR code to scan in WireGuard app
```

**Security features:**
- ✅ Strong crypto (WireGuard = modern, audited)
- ✅ No SOCKS5 exposure to LAN
- ✅ Mobile device gets full transparent Tor routing
- ✅ Can revoke specific clients
- ✅ Works from anywhere (not just home WiFi)

**Network topology:**
```
Mobile Device (cellular/WiFi)
    ↓
    WireGuard tunnel (encrypted)
    ↓
Tide Gateway (10.101.101.10)
    ↓
Transparent Tor routing
    ↓
Internet via Tor
```

**Advantages:**
- Works on any network (home, coffee shop, cellular)
- Same transparent routing as VMs
- No app-side proxy configuration needed
- Extremely secure (WireGuard is battle-tested)

**Disadvantages:**
- Requires WireGuard app (not your custom app)
- More complex setup
- Might be overkill for home-only use

### Option 3: **Separate Proxy Mode Port** (SIMPLEST)

**Concept:**
- Keep router/killa-whale on host-only (secure)
- Run SOCKS5 on **different port** for mobile
- Mobile-specific port has restrictions

**Implementation:**
```bash
# Router mode stays on eth1 (host-only)
# Add SOCKS5 on eth0 (LAN) port 9150
tide mode router --enable-mobile-proxy

# Firewall rules
iptables -A INPUT -i eth0 -s 192.168.1.0/24 -p tcp --dport 9150 -j ACCEPT
```

**Tor config:**
```
# Host-only network (VMs)
SocksPort 10.101.101.10:9050

# LAN network (mobile devices)
SocksPort 192.168.1.x:9150
SocksPolicy accept 192.168.1.0/24
SocksPolicy reject *
```

**Security:**
- Limited to your LAN subnet
- Optional: Add authentication
- Optional: Rate limiting
- Separate port = easy to monitor/disable

---

## Recommendation

### Best Approach: **WireGuard VPN** (Option 2)

**Why:**
1. ✅ **Most secure** - No SOCKS5 exposure, strong crypto
2. ✅ **Works anywhere** - Home, coffee shop, cellular
3. ✅ **Transparent** - Mobile device gets full Tor routing
4. ✅ **Revocable** - Can remove specific clients
5. ✅ **Industry standard** - WireGuard is proven
6. ✅ **Future-proof** - Can add more clients (laptop, tablet, etc.)

**User experience:**
```
1. On Tide Gateway: tide wireguard add-client "iphone"
2. Scan QR code with WireGuard app
3. Tap connect
4. All traffic automatically goes through Tor
5. Mobile app can show status (optional)
```

### Fallback: **Hybrid Mode with Auth** (Option 1)

**When to use:**
- Only home network access needed
- Want to build custom mobile app (not use WireGuard app)
- Simpler mental model for users

**Security requirements:**
- ⚠️ **MUST have authentication** (username/password)
- ⚠️ **MUST restrict to LAN subnet only**
- ⚠️ **SHOULD have rate limiting**
- ⚠️ **SHOULD log connection attempts**

---

## Mobile App Features (Either Approach)

### Core Features:
- ✅ Connect/disconnect toggle
- ✅ Current Tor circuit info (exit IP, country)
- ✅ Connection status (connected/disconnected/connecting)
- ✅ Bandwidth usage
- ✅ New circuit button
- ✅ Connection history

### Advanced Features:
- ⚠️ Gateway discovery (find Tide Gateway on network)
- ⚠️ QR code config import (WireGuard model)
- ⚠️ Auto-connect when on home WiFi
- ⚠️ Per-app routing (Android only, requires root)
- ⚠️ Kill switch (disconnect if Tor fails)

### Technical Stack:

**iOS:**
- Swift/SwiftUI
- NetworkExtension framework (for VPN if WireGuard)
- Or just WireGuard app + companion status app

**Android:**
- Kotlin
- VpnService API (if WireGuard approach)
- Or just WireGuard app + companion status app

---

## Implementation Phases

### Phase 1: Backend (Tide Gateway)
```bash
# Add WireGuard support to Tide Gateway
tide mode router --enable-wireguard

# Or add SOCKS5 auth
tide mode hybrid
```

**Tasks:**
- [ ] Install WireGuard on Alpine
- [ ] Create `tide wireguard` CLI commands
- [ ] Generate client configs with QR codes
- [ ] Update firewall rules
- [ ] Test with WireGuard app

### Phase 2: Mobile App (Status Monitor)
**Tasks:**
- [ ] Simple SwiftUI app (iOS)
- [ ] Shows: Connected, Exit IP, Bandwidth
- [ ] Actions: New circuit, disconnect
- [ ] Uses Tide API (port 9051)

**Not needed:**
- Custom VPN implementation (use WireGuard app)
- Custom proxy (use WireGuard transparent routing)

### Phase 3: Distribution
**iOS:**
- TestFlight for testing
- App Store (requires Apple Developer account)

**Android:**
- F-Droid for open source
- Google Play Store

---

## Architecture Diagram

### WireGuard Approach (Recommended)
```
┌─────────────────────────────────────────────────┐
│ Mobile Device (iPhone/Android)                   │
│                                                   │
│ ┌──────────────┐      ┌─────────────────────┐   │
│ │ WireGuard    │      │ Tide Status App     │   │
│ │ App          │      │ (shows exit IP,     │   │
│ │ (VPN tunnel) │      │  controls circuit)  │   │
│ └───────┬──────┘      └──────┬──────────────┘   │
└─────────┼────────────────────┼──────────────────┘
          │                    │
          │ Encrypted tunnel   │ HTTPS (API calls)
          │                    │
┌─────────▼────────────────────▼──────────────────┐
│ Tide Gateway (10.101.101.10)                     │
│                                                   │
│ ┌──────────────┐      ┌─────────────────────┐   │
│ │ WireGuard    │      │ Web Dashboard/API   │   │
│ │ Server       │      │ (port 9051)         │   │
│ │ (port 51820) │      │                     │   │
│ └───────┬──────┘      └──────┬──────────────┘   │
│         │                    │                   │
│         └─────────┬──────────┘                   │
│                   ▼                               │
│         ┌──────────────────┐                     │
│         │ Transparent Tor  │                     │
│         │ Routing          │                     │
│         └─────────┬────────┘                     │
└───────────────────┼──────────────────────────────┘
                    ▼
              Tor Network
                    ▼
                Internet
```

### Hybrid Mode (Alternative)
```
┌─────────────────────────────────────────────────┐
│ Mobile Device                                    │
│                                                   │
│ ┌─────────────────────────────────────────────┐ │
│ │ Tide Mobile App                              │ │
│ │ - SOCKS5 client (with auth)                  │ │
│ │ - Shows status                               │ │
│ │ - Manages connections                        │ │
│ └──────────────────┬──────────────────────────┘ │
└────────────────────┼──────────────────────────────┘
                     │
                     │ SOCKS5 + Auth
                     │ (username/password)
┌────────────────────▼──────────────────────────────┐
│ Tide Gateway (192.168.1.x on LAN)                 │
│                                                    │
│ ┌──────────────────────────────────────────────┐ │
│ │ SOCKS5 Proxy (port 9150)                     │ │
│ │ - Requires authentication                     │ │
│ │ - Rate limited                                │ │
│ │ - LAN subnet only                             │ │
│ └──────────────────┬───────────────────────────┘ │
│                    ▼                              │
│          Tor Transparent Proxy                    │
└───────────────────┼───────────────────────────────┘
                    ▼
              Tor Network
```

---

## Security Best Practices

### ✅ DO:
- Use WireGuard if possible (most secure)
- Require authentication for SOCKS5
- Restrict to LAN subnet only
- Rate limit connections
- Log connection attempts
- Use strong random passwords
- Provide rotation mechanism
- Monitor for abuse

### ❌ DON'T:
- Expose unauthenticated SOCKS5 to internet
- Use weak/default passwords
- Allow unlimited connections
- Skip logging
- Expose to public WiFi without VPN
- Trust client-side security alone

---

## Next Steps

1. **Decide approach:**
   - WireGuard (recommended) - More work, better security
   - Hybrid mode - Less work, requires careful auth

2. **Implement backend:**
   - Add WireGuard support to Tide Gateway
   - Or add SOCKS5 authentication

3. **Test with existing apps:**
   - iOS: WireGuard app + Safari
   - Android: WireGuard app + Chrome
   - Verify Tor routing works

4. **Build companion app:**
   - Status monitor
   - Circuit control
   - Connection management

5. **Document:**
   - Setup guide
   - Security model
   - Troubleshooting

---

## References

- WireGuard: https://www.wireguard.com/
- Tor SOCKS authentication: https://2019.www.torproject.org/docs/tor-manual.html.en#SocksPort
- RFC 1929 (SOCKS5 auth): https://www.rfc-editor.org/rfc/rfc1929

---

**Recommendation: Start with WireGuard approach. It's more work upfront but provides better security and user experience.**
