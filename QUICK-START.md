# 🌊 Tide Gateway - Quick Start Guide

## For New Users

### What You'll Get

- **Web Dashboard**: Open any browser → http://tide.bodegga.net
- **Automatic Tor**: All traffic goes through Tor (no client config needed)
- **Network Takeover**: Killa Whale mode forces everything through gateway
- **No Leaks**: Fail-closed firewall - if Tor dies, traffic stops

---

## 5-Minute Setup

### Option 1: Parallels Desktop (macOS - Easiest)

```bash
# Download and deploy in ONE command:
curl -sSL https://tide.bodegga.net/deploy | bash
```

That's it. VM will start automatically.

### Option 2: Manual VM Import

1. Download from [Releases](https://github.com/bodegga/tide/releases)
2. Import `Tide-Gateway-Template-v1.x.x.tar.gz` into Parallels
3. Start the VM
4. Done

### Option 3: Fresh Install

Boot Alpine Linux ISO, login as root, run:

```bash
wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
```

---

## First Steps After Deployment

### 1. Find Your Client

Connect a client VM (or use your host Mac) to the **host-only network**.

### 2. Get IP via DHCP

Your client should automatically get an IP like `10.101.101.xxx`

Check:
```bash
# On client
ip addr show
# Look for 10.101.101.x address
```

### 3. Access Web Dashboard

Open browser:
```
http://tide.bodegga.net
```

You should see the Tide status dashboard with:
- 🟢 Tor connection status
- Current exit IP and country
- Gateway mode and security profile
- Network health stats

### 4. Test Tor Connectivity

From client:
```bash
curl https://check.torproject.org/api/ip
```

Should return:
```json
{"IsTor": true, "IP": "x.x.x.x"}
```

---

## CLI Commands (SSH into Gateway)

SSH into the Tide Gateway VM:
```bash
ssh root@10.101.101.10
# Password: tide (change this!)
```

Then use the `tide` CLI:

```bash
# Show full status
tide status

# Check Tor connectivity
tide check

# View current exit IP
tide circuit

# List connected clients
tide clients

# Request new Tor circuit
tide newcircuit

# Show ARP poisoning status (Killa Whale mode)
tide arp

# View Tor logs
tide logs

# Help
tide help
```

---

## Modes Explained

| Mode | Description | Use Case |
|------|-------------|----------|
| **Proxy** | SOCKS5 only | Single client, manual config |
| **Router** | DHCP + transparent proxy | Lab network, auto-config |
| **Killa Whale** | Router + fail-closed | High security, no leaks |
| **Takeover** | Killa Whale + ARP hijack | Full subnet control |

**Default**: Killa Whale mode (recommended)

---

## Network Topology

```
┌─────────────────────────────────────────┐
│          HOST MACHINE (macOS)           │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │    Host-Only Network (vmnet)      │  │
│  │                                   │  │
│  │   ┌────────────┐   ┌──────────┐  │  │
│  │   │   TIDE     │   │  Client  │  │  │
│  │   │  Gateway   │   │   VM     │  │  │
│  │   │            │◀──│          │  │  │
│  │   │10.101.101.10  │  │ Auto DHCP │  │
│  │   └──────┬─────┘   └──────────┘  │  │
│  └──────────┼─────────────────────┘  │
│             │ Shared Network         │
│             ▼                        │
│        [ Tor Network ]               │
│             │                        │
└─────────────┼────────────────────────┘
              ▼
          Internet
```

---

## Web Dashboard Features

### Real-Time Status
- **Connection Status**: 🟢 Connected | 🟡 Bootstrapping | 🔴 Offline
- **Mode Display**: Shows current deployment mode
- **Security Profile**: Standard | Hardened | Paranoid | Bridges
- **Uptime**: Gateway runtime since boot

### Network Info
- **Exit IP**: Current Tor exit node IP and country
- **Connected Clients**: DHCP lease count
- **ARP Status**: Poisoning active/inactive (Killa Whale)
- **Gateway IP**: Always 10.101.101.10

### Auto-Refresh
Dashboard refreshes every 30 seconds automatically.

---

## DNS Hijacking (How tide.bodegga.net Works)

**Router Mode:**
- dnsmasq hijacks `tide.bodegga.net` → `10.101.101.10`
- Clients using Tide's DNS (10.101.101.10) see the dashboard

**Killa Whale Mode (Aggressive):**
- dnsmasq hijacks DNS
- **PLUS** iptables forces ALL DNS through Tide
- Even if client sets DNS to 8.8.8.8, iptables intercepts and redirects
- **NO ESCAPE** - total DNS control

This is how commercial routers work:
- Ubiquiti: `unifi.ui.com`
- Netgear: `routerlogin.net`
- TP-Link: `tplinkwifi.net`

Tide does the same for `tide.bodegga.net`

---

## Security Profiles

Change in `.env` file before deployment:

### Standard (Default)
```bash
TIDE_SECURITY=standard
```
- Default Tor settings
- Fast, uses all relays
- Good for most use cases

### Hardened
```bash
TIDE_SECURITY=hardened
```
- Excludes 14-eyes countries
- Moderate speed
- Better privacy

### Paranoid
```bash
TIDE_SECURITY=paranoid
```
- Maximum isolation
- Excludes hostile countries
- Slowest, highest anonymity

### Bridges
```bash
TIDE_SECURITY=bridges
```
- Uses obfs4 bridges
- Bypasses censorship
- For blocked regions

---

## Common Tasks

### Change Default Password

```bash
# SSH into gateway
ssh root@10.101.101.10

# Change password
passwd

# Enter new password twice
```

### Request New Tor Circuit

**From Client (browser):**
1. Go to http://tide.bodegga.net
2. Click "Refresh Status"
3. Check if exit IP changed

**From Client (CLI):**
```bash
# Get API token
TOKEN=$(curl -s http://10.101.101.10:9051/token | jq -r '.token')

# Request new circuit
curl -H "Authorization: Bearer $TOKEN" http://10.101.101.10:9051/newcircuit

# Verify new IP
curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip
```

**From Gateway SSH:**
```bash
tide newcircuit
tide circuit  # Verify new IP
```

### View Connected Clients

**Web Dashboard:**
- Open http://tide.bodegga.net
- Look at "Connected Clients" in Network Status section

**CLI:**
```bash
ssh root@10.101.101.10
tide clients
```

Shows:
```
IP              MAC               HOSTNAME
10.101.101.100  00:1c:42:xx:xx:xx kali-vm
10.101.101.101  00:1c:42:yy:yy:yy windows11

Total: 2 client(s)
```

### Check If Tor Is Working

**Quick Test:**
```bash
curl https://check.torproject.org/api/ip
```

**Detailed Check:**
```bash
ssh root@10.101.101.10
tide check
```

Output:
```
✅ Connected via Tor
   Exit IP: 185.220.101.x
   Country: NL
```

---

## Troubleshooting

### Dashboard Not Loading

```bash
# Check if web server is running
ssh root@10.101.101.10
ps aux | grep tide-web-dashboard

# Restart gateway
reboot
```

### No Internet on Client

```bash
# Check Tor status
ssh root@10.101.101.10
tide status

# Look for:
# Tor: 🟢 connected

# If offline, check logs
tide logs
```

### Client Not Getting DHCP

```bash
# On gateway, check dnsmasq
ssh root@10.101.101.10
ps aux | grep dnsmasq

# Check DHCP leases
cat /var/lib/misc/dnsmasq.leases

# Restart dnsmasq
killall dnsmasq
dnsmasq --no-daemon --log-facility=-
```

### DNS Not Resolving

```bash
# Test DNS from client
nslookup google.com 10.101.101.10

# Should return Tor exit node IP

# Test tide.bodegga.net
nslookup tide.bodegga.net 10.101.101.10

# Should return: 10.101.101.10
```

---

## Upgrading to v1.2.0

If you're running v1.1.x and want the web dashboard:

```bash
# SSH into gateway
ssh root@10.101.101.10

# Run upgrade script
wget -O- https://raw.githubusercontent.com/bodegga/tide/main/UPDATE-TO-V1.2.sh | sh

# Reboot
reboot
```

After reboot:
- Web dashboard at http://tide.bodegga.net
- CLI: `tide status`, `tide clients`, etc.

---

## Next Steps

### Learn More
- [Full README](README.md) - Architecture and deployment options
- [Web Dashboard Guide](WEB-DASHBOARD-README.md) - Complete dashboard features
- [ROADMAP](ROADMAP.md) - Planned features

### Advanced Topics
- Security profiles and custom Tor configs
- ARP takeover mode for subnet control
- Bridge configuration for censorship bypass
- Custom firewall rules

### Get Involved
- [GitHub Issues](https://github.com/bodegga/tide/issues)
- [Contributing Guide](CONTRIBUTING.md)
- Report bugs or suggest features

---

**Tide Gateway - freedom within the shell** 🌊

*Quick Start Guide v1.2.0*
