# 🌊 Tide Web Dashboard

## Overview

Tide Gateway now includes a **web-based status dashboard** accessible at:
- **http://tide.bodegga.net** (DNS hijacked - always resolves to gateway)
- **http://10.101.101.10** (direct IP access)

### Features

✅ **Real-time status monitoring**
- Tor connection status (Connected / Bootstrapping / Offline)
- Current deployment mode (Proxy / Router / Killa Whale / Takeover)
- Security profile (Standard / Hardened / Paranoid / Bridges)
- Gateway uptime
- Current Tor exit IP and country
- Connected DHCP clients
- ARP poisoning status (Killa Whale mode)
- Network scanner status

✅ **Auto-refresh** - Dashboard refreshes every 30 seconds

✅ **Mobile-responsive** - Works on phones, tablets, desktops

✅ **Dark theme** - Cyberpunk-inspired terminal aesthetic

---

## Access Methods

### From Client Devices (Automatic)

If you're connected to Tide Gateway (via DHCP in Router/Killa Whale modes):

```bash
# Just open your browser:
http://tide.bodegga.net
```

**How it works:**
- Tide Gateway **hijacks DNS** for `tide.bodegga.net`
- dnsmasq forces it to resolve to `10.101.101.10`
- Even if you try to use external DNS, iptables redirects DNS queries to Tide
- **NO ESCAPE** - Killa Whale mode is aggressive 🐋

### From Gateway VM (Direct)

SSH into the gateway and use the CLI:

```bash
# Show status in terminal
tide status

# Check Tor connectivity
tide check

# View current exit IP
tide circuit

# Request new Tor circuit
tide newcircuit

# List connected clients
tide clients

# Show ARP poisoning status (Killa Whale mode)
tide arp

# View Tor logs
tide logs

# Show dashboard URL
tide web
```

---

## CLI Commands Reference

The `tide` command provides quick access to gateway functions:

| Command | Description |
|---------|-------------|
| `tide status` | Show full gateway status (default) |
| `tide check` | Verify Tor connectivity |
| `tide circuit` | Show current Tor exit IP and country |
| `tide newcircuit` | Request new Tor circuit |
| `tide web` | Show dashboard URL |
| `tide clients` | List connected DHCP clients |
| `tide logs` | Show Tor logs |
| `tide arp` | Show ARP poisoning status |
| `tide help` | Show help message |

---

## Dashboard Sections

### 🟢 Connection Status
Large visual indicator showing:
- 🟢 Green = Tor connected and working
- 🟡 Yellow = Tor bootstrapping
- 🔴 Red = Tor offline or failed

### 📊 Status Cards

**Mode Card**
- Shows deployment mode
- 🔌 Proxy | 🌐 Router | 🐋 Killa Whale | ☠️ Takeover

**Security Card**
- Shows Tor security profile
- 🔐 Standard | 🛡️ Hardened | 🔒 Paranoid | 🌉 Bridges

**Exit IP Card**
- Current Tor exit node IP
- Exit node country code

**Uptime Card**
- Gateway runtime since boot

### 🌐 Network Status

Shows real-time network information:
- Gateway IP (10.101.101.10)
- SOCKS5 port (9050)
- DNS port (5353)
- Connected DHCP clients
- ARP poisoning status (🔥 ACTIVE in Killa Whale mode)
- Network scanner status (👁️ ACTIVE when monitoring)

---

## API Endpoints

The dashboard uses a JSON API (port 9051) that you can also access directly:

### GET /status
```bash
curl http://10.101.101.10:9051/status
```

Returns:
```json
{
  "gateway": "tide",
  "version": "1.2",
  "mode": "killa-whale",
  "security": "hardened",
  "tor": "connected",
  "uptime": 3600,
  "ip": "10.101.101.10",
  "ports": {
    "socks": 9050,
    "dns": 5353,
    "api": 9051
  }
}
```

### GET /circuit
```bash
curl http://10.101.101.10:9051/circuit
```

Returns current Tor exit node info from check.torproject.org

### GET /newcircuit
```bash
# Requires Bearer token authentication
TOKEN=$(curl -s http://10.101.101.10:9051/token | jq -r '.token')
curl -H "Authorization: Bearer $TOKEN" http://10.101.101.10:9051/newcircuit
```

Request new Tor circuit

### GET /check
```bash
curl http://10.101.101.10:9051/check
```

Verify Tor is working (returns 200 if connected via Tor, 503 if not)

### GET /token
```bash
curl http://10.101.101.10:9051/token
```

Get API authentication token for write operations

---

## DNS Hijacking Details

### How It Works

**Router Mode:**
```
# dnsmasq configuration
address=/tide.bodegga.net/10.101.101.10
address=/www.tide.bodegga.net/10.101.101.10
```

**Killa Whale Mode (AGGRESSIVE):**
```
# dnsmasq + iptables enforcement
address=/tide.bodegga.net/10.101.101.10
address=/www.tide.bodegga.net/10.101.101.10

# iptables redirects ALL DNS to us
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j REDIRECT --to-ports 5353
```

**What this means:**
- Client tries to resolve `tide.bodegga.net`
- DNS query hits Tide Gateway (forced by iptables)
- dnsmasq responds with `10.101.101.10`
- Client connects to web dashboard
- **NO ESCAPE** - Even if client manually sets DNS to 8.8.8.8, iptables intercepts and redirects

### Why This Works

This is how commercial routers (Ubiquiti, Netgear, TP-Link) provide web interfaces:
- Router runs HTTP server on port 80
- Router hijacks DNS for branded domain (e.g., `unifi.ui.com`, `routerlogin.net`)
- Client accesses router via memorable URL instead of IP

**Tide does the same, but more aggressive:**
- ✅ DNS hijacking via dnsmasq
- ✅ iptables enforcement (can't bypass with external DNS)
- ✅ Works on ANY device connected to Tide network
- ✅ No client configuration needed

---

## Installation

These features are included in **Tide Gateway v1.2.0+**.

### New Files Added

1. **`/usr/local/bin/tide-web-dashboard.py`** - Web dashboard server (port 80)
2. **`/usr/local/bin/tide-cli.sh`** - CLI tool (symlinked to `/usr/local/bin/tide`)
3. **Updated `/usr/local/bin/gateway-start.sh`** - Now starts web dashboard
4. **Updated dnsmasq config** - DNS hijacking for tide.bodegga.net

### Deploy to Existing VM

SSH into your Tide Gateway VM:

```bash
# Download new scripts
wget -O /usr/local/bin/tide-web-dashboard.py \
  https://raw.githubusercontent.com/bodegga/tide/main/scripts/runtime/tide-web-dashboard.py

wget -O /usr/local/bin/tide-cli.sh \
  https://raw.githubusercontent.com/bodegga/tide/main/scripts/runtime/tide-cli.sh

wget -O /usr/local/bin/gateway-start.sh \
  https://raw.githubusercontent.com/bodegga/tide/main/scripts/runtime/gateway-start.sh

# Make executable
chmod +x /usr/local/bin/tide-web-dashboard.py
chmod +x /usr/local/bin/tide-cli.sh
chmod +x /usr/local/bin/gateway-start.sh

# Create CLI symlink
ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide

# Restart gateway
reboot
```

---

## Troubleshooting

### Dashboard not loading

```bash
# Check if web server is running
ps aux | grep tide-web-dashboard

# Check if port 80 is listening
netstat -tulpn | grep :80

# Check logs
tide logs
```

### DNS not resolving tide.bodegga.net

```bash
# Check dnsmasq config
cat /etc/dnsmasq.conf | grep tide.bodegga.net

# Test DNS resolution
nslookup tide.bodegga.net 10.101.101.10

# Should return: 10.101.101.10
```

### CLI command not found

```bash
# Check if symlink exists
ls -l /usr/local/bin/tide

# Create it manually
ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide
```

---

## Security Notes

### Is DNS hijacking safe?

**YES** - This is standard practice for router management interfaces:
- Ubiquiti: `unifi.ui.com`
- Netgear: `routerlogin.net`
- TP-Link: `tplinkwifi.net`

**Tide's approach:**
- Only hijacks `tide.bodegga.net` and `www.tide.bodegga.net`
- Only resolves on Tide's private subnet (10.101.101.0/24)
- Doesn't affect external traffic or other domains
- Open source - you can audit the code

### Can clients bypass it?

**Router Mode:** Yes, if they manually set external DNS

**Killa Whale Mode:** NO
- iptables forces ALL DNS through Tide
- Even 8.8.8.8 or 1.1.1.1 gets intercepted
- This is the POINT of Killa Whale mode - total control

---

## Screenshots

### Desktop View
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          🌊 TIDE
   Transparent Internet Defense Engine
      freedom within the shell
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

          🟢
       CONNECTED

┌─────────────┬─────────────┬─────────────┬─────────────┐
│ Mode        │ Security    │ Exit IP     │ Uptime      │
│ 🐋 KILLA-   │ 🛡️ HARDENED │ 185.220... │ 2h 34m      │
│ WHALE       │             │ NL          │             │
└─────────────┴─────────────┴─────────────┴─────────────┘

🌐 Network Status
Gateway IP:      10.101.101.10
Connected Clients: 3
ARP Poisoning:   ACTIVE 🔥
```

### Mobile View
Same layout, responsive columns stack vertically

---

## Future Enhancements

Planned for v1.3.0+:
- [ ] Interactive Tor circuit control (select exit country)
- [ ] Bandwidth usage graphs
- [ ] Client device management (view/block specific clients)
- [ ] Tor bridge configuration UI
- [ ] Real-time traffic monitoring
- [ ] Export statistics (CSV/JSON)
- [ ] Dark/light theme toggle
- [ ] WebSocket live updates (no 30s refresh delay)

---

**Tide Gateway - freedom within the shell** 🌊

*Web dashboard added in v1.2.0*
