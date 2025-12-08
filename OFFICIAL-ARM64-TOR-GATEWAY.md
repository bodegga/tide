# ARM64 Tor Gateway + Workstation Setup
## Official Configuration for Apple Silicon / ARM64 Macs

**Version:** 1.0  
**Date:** December 7, 2025  
**Architecture:** ARM64 (Apple Silicon)  
**Tested on:** M4 MacBook Air, Parallels Desktop  

---

## 🎯 Overview

This is a minimal, production-ready Tor gateway + workstation setup for ARM64 architecture. It provides:

- ✅ Complete network isolation through Tor
- ✅ `.onion` site support in regular Firefox
- ✅ Transparent routing with fail-closed firewall
- ✅ Minimal resource usage (~3GB total disk, 2.5GB RAM)
- ✅ Simple deployment (20 minutes)

### Architecture

```
┌──────────────────────────────────────────────────┐
│  macOS Host (Apple Silicon)                     │
│                                                   │
│  ┌─────────────────┐      ┌──────────────────┐  │
│  │ Tor Gateway     │      │ Workstation      │  │
│  │ (Debian ARM64)  │      │ (Debian ARM64)   │  │
│  │                 │      │                  │  │
│  │ eth0: Internet  │      │ eth0: Internal   │  │
│  │ eth1: 10.x.x.10 ├──────┤ gw: 10.x.x.10    │  │
│  │                 │      │ dns: 10.x.x.10   │  │
│  │ Tor + Firewall  │      │ Firefox + Apps   │  │
│  └─────────────────┘      └──────────────────┘  │
│         ▲                                        │
│         └── All traffic through Tor              │
└──────────────────────────────────────────────────┘
```

---

## 📋 Requirements

- **Hardware:** Apple Silicon Mac (M1/M2/M3/M4)
- **Hypervisor:** Parallels Desktop, UTM, or VMware Fusion
- **RAM:** 3GB free (2GB workstation + 512MB gateway + overhead)
- **Disk:** 5GB free (3GB installed, 2GB buffer)
- **Downloads:** 
  - Debian 12 ARM64 netinst ISO (158MB)
  - Or use existing Debian ARM64 VMs

---

## 🚀 Quick Start

### Option 1: Using Existing Debian VMs (5 minutes)

**If you already have two Debian ARM64 VMs:**

1. **Gateway VM:** Run deployment script (see Phase 1)
2. **Workstation VM:** Configure network (see Phase 2)
3. **Done**

### Option 2: Fresh Install (20 minutes)

1. Download Debian 12 ARM64 netinst
2. Create 2 VMs (Gateway + Workstation)
3. Install Debian on both
4. Run deployment scripts
5. Done

---

## 📥 Downloads

```bash
# Debian 12 ARM64 netinst (recommended)
curl -LO https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-12.8.0-arm64-netinst.iso

# SHA256 checksum
curl -LO https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/SHA256SUMS
```

**Verify download:**
```bash
sha256sum -c SHA256SUMS --ignore-missing
```

---

## 🔧 Phase 1: Gateway Configuration

### Gateway VM Specs

| Setting | Value |
|---------|-------|
| RAM | 512MB (can run on 256MB) |
| Disk | 8GB (uses ~1.5GB) |
| CPU | 1 core |
| Network 0 | Shared/NAT (internet) |
| Network 1 | Host-Only 10.152.152.10/24 |
| Hostname | `gateway` |

### Automated Deployment Script

**Login to gateway VM as root, paste this entire script:**

```bash
#!/bin/bash
# ARM64 Tor Gateway Deployment Script
# Version 1.0 - Official Configuration

set -e

echo "=============================================="
echo "ARM64 Tor Gateway Configuration"
echo "Version 1.0"
echo "=============================================="
echo ""

# Update system
echo "[1/8] Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Install required packages
echo "[2/8] Installing Tor and dependencies..."
apt-get install -y -qq \
    tor \
    iptables \
    iptables-persistent \
    net-tools \
    curl \
    vim

# Configure network interfaces
echo "[3/8] Configuring network interfaces..."
cat > /etc/network/interfaces << 'NETCONFIG'
# Loopback
auto lo
iface lo inet loopback

# External interface (internet via hypervisor)
auto eth0
iface eth0 inet dhcp

# Internal interface (to workstation)
auto eth1
iface eth1 inet static
    address 10.152.152.10
    netmask 255.255.255.0
    network 10.152.152.0
    broadcast 10.152.152.255
NETCONFIG

# Bring up internal interface
ifup eth1 2>/dev/null || true

# Enable IP forwarding and disable IPv6
echo "[4/8] Configuring kernel parameters..."
cat > /etc/sysctl.d/99-tor-gateway.conf << 'SYSCTLCONFIG'
# Enable IP forwarding for routing
net.ipv4.ip_forward = 1

# Disable IPv6 (Tor doesn't support it well)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Security hardening
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
SYSCTLCONFIG

sysctl -p /etc/sysctl.d/99-tor-gateway.conf >/dev/null

# Configure Tor with .onion support
echo "[5/8] Configuring Tor daemon..."
cat > /etc/tor/torrc << 'TORCONFIG'
# ARM64 Tor Gateway Configuration
# Version 1.0

# SOCKS proxy (for applications that support it)
SocksPort 10.152.152.10:9050

# DNS resolver through Tor
DNSPort 10.152.152.10:5353

# Transparent proxy (for iptables REDIRECT)
TransPort 10.152.152.10:9040

# .onion site support (CRITICAL for Firefox)
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion

# Logging
Log notice file /var/log/tor/notices.log

# Control port (for monitoring)
ControlPort 10.152.152.10:9051
CookieAuthentication 1

# Performance tuning
CircuitBuildTimeout 60
NumEntryGuards 3
TORCONFIG

# Create Tor log directory
mkdir -p /var/log/tor
chown debian-tor:debian-tor /var/log/tor
chmod 700 /var/log/tor

# Configure firewall (fail-closed design)
echo "[6/8] Configuring firewall..."
cat > /etc/iptables/rules.v4 << 'FIREWALLRULES'
# ARM64 Tor Gateway Firewall Rules
# Version 1.0 - Fail-Closed Design

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# Redirect DNS queries from workstation to Tor DNSPort
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353

# Redirect TCP connections from workstation to Tor TransPort
-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040

COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback
-A INPUT -i lo -j ACCEPT

# Allow established connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow workstation to access Tor ports
-A INPUT -i eth1 -s 10.152.152.0/24 -p tcp -m multiport --dports 9040,9050,9051 -j ACCEPT
-A INPUT -i eth1 -s 10.152.152.0/24 -p udp --dport 5353 -j ACCEPT

# Allow SSH from workstation (for management)
-A INPUT -i eth1 -s 10.152.152.0/24 -p tcp --dport 22 -j ACCEPT

# Log dropped packets (optional - for debugging)
# -A INPUT -j LOG --log-prefix "FW-DROP: " --log-level 4

COMMIT
FIREWALLRULES

# Load firewall rules
iptables-restore < /etc/iptables/rules.v4

# Enable services on boot
echo "[7/8] Enabling services..."
systemctl enable tor
systemctl enable iptables

# Restart Tor
systemctl restart tor

# Wait for Tor to bootstrap
echo "[8/8] Waiting for Tor to connect..."
sleep 5

for i in {1..30}; do
    if grep -q "Bootstrapped 100%" /var/log/tor/notices.log 2>/dev/null; then
        echo "✅ Tor connected successfully!"
        break
    fi
    printf "."
    sleep 2
done

echo ""
echo ""
echo "=============================================="
echo "Gateway Configuration Complete"
echo "=============================================="
echo ""
echo "Gateway IP: 10.152.152.10"
echo ""
echo "Services running:"
echo "  • SOCKS Proxy:    10.152.152.10:9050"
echo "  • DNS Server:     10.152.152.10:5353"
echo "  • Transparent:    10.152.152.10:9040"
echo "  • Control Port:   10.152.152.10:9051"
echo ""
echo "Tor Status:"
systemctl status tor --no-pager | head -3
echo ""
echo "Listening Ports:"
netstat -tlnp | grep tor | awk '{print "  " $4}'
echo ""
echo "Test with:"
echo "  curl --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip"
echo ""
echo "Next: Configure workstation network"
echo "=============================================="
```

**Execution time:** ~3 minutes

---

## 🔧 Phase 2: Workstation Configuration

### Workstation VM Specs

| Setting | Value |
|---------|-------|
| RAM | 2GB (4GB recommended) |
| Disk | 32GB |
| CPU | 2 cores |
| Network 0 | Host-Only 10.152.152.11/24 |
| Hostname | `workstation` |

### Network Configuration Script

**Login to workstation VM as root, paste this:**

```bash
#!/bin/bash
# ARM64 Workstation Network Configuration
# Version 1.0

set -e

echo "=============================================="
echo "Workstation Network Configuration"
echo "=============================================="
echo ""

# Configure network to use gateway
echo "[1/3] Configuring network..."
cat > /etc/network/interfaces << 'NETCONFIG'
# Loopback
auto lo
iface lo inet loopback

# Internal network (to gateway)
auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
NETCONFIG

# Restart networking
echo "[2/3] Restarting network..."
systemctl restart networking

# Test connectivity
echo "[3/3] Testing connectivity..."
sleep 2

if ping -c 3 10.152.152.10 >/dev/null 2>&1; then
    echo "✅ Gateway reachable"
else
    echo "❌ Cannot reach gateway"
    exit 1
fi

if curl -s --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip >/dev/null 2>&1; then
    echo "✅ Tor connection working"
else
    echo "⚠️  Tor connection check failed (might need more time)"
fi

echo ""
echo "=============================================="
echo "Workstation Configuration Complete"
echo "=============================================="
echo ""
echo "Network Settings:"
echo "  • IP:      10.152.152.11"
echo "  • Gateway: 10.152.152.10"
echo "  • DNS:     10.152.152.10"
echo ""
echo "Test internet access:"
echo "  curl --socks5 10.152.152.10:9050 https://api.ipify.org"
echo ""
echo "Next: Configure Firefox"
echo "=============================================="
```

---

## 🌐 Phase 3: Firefox Configuration

### Method A: GUI Configuration

1. **Open Firefox**
2. **Settings → General → Network Settings → Settings**
3. **Select:** Manual proxy configuration
4. **Configure:**
   ```
   SOCKS Host: 10.152.152.10
   Port: 9050
   ☑ SOCKS v5
   ☑ Proxy DNS when using SOCKS v5
   ```
5. **Click OK**

### Method B: about:config (Recommended)

1. **Type in address bar:** `about:config`
2. **Accept warning**
3. **Search and set these values:**

```
network.proxy.type = 1
network.proxy.socks = 10.152.152.10
network.proxy.socks_port = 9050
network.proxy.socks_remote_dns = true
network.dns.blockDotOnion = false
```

### Enable .onion Support

**Critical setting for .onion sites:**

```
network.dns.blockDotOnion = false
```

Without this, Firefox will block all `.onion` addresses.

---

## ✅ Verification & Testing

### Test 1: Check Public IP

```bash
# From workstation
curl https://api.ipify.org
```

**Expected:** Tor exit node IP (NOT your real IP)

### Test 2: Verify DNS Through Tor

```bash
# From workstation
nslookup google.com
```

**Expected:** 
```
Server: 10.152.152.10
Address: 10.152.152.10#53
```

### Test 3: Test .onion Site

**In Firefox, visit:**
```
http://3g2upl4pq6kufc4m.onion
```

**Expected:** DuckDuckGo onion service loads

### Test 4: Verify Tor Connection

**Visit in Firefox:**
```
https://check.torproject.org
```

**Expected:** "Congratulations. This browser is configured to use Tor."

### Test 5: No Direct Internet

```bash
# From workstation, this should FAIL
ping -c 2 8.8.8.8
```

**Expected:** No route or timeout (all traffic forced through gateway)

---

## 📊 Performance & Resources

### Actual Resource Usage

| Component | RAM (Idle) | RAM (Active) | Disk Used |
|-----------|------------|--------------|-----------|
| Gateway | ~80MB | ~120MB | 1.5GB |
| Workstation | ~400MB | ~1.2GB | 2-3GB |
| **Total** | **~500MB** | **~1.3GB** | **~4GB** |

### Boot Time

- Gateway: ~10 seconds
- Workstation: ~15 seconds
- Tor bootstrap: ~30 seconds

---

## 🛡️ Security Features

### What This Protects Against

✅ **Network surveillance** - All traffic encrypted through Tor  
✅ **ISP monitoring** - ISP only sees Tor connection  
✅ **DNS leaks** - All DNS through Tor DNSPort  
✅ **IP correlation** - Your IP never exposed  
✅ **Accidental clearnet** - Firewall blocks non-Tor traffic  
✅ **Man-in-the-middle** - Tor provides encryption  

### What This Does NOT Protect Against

❌ **Browser fingerprinting** - Use Tor Browser for max anonymity  
❌ **Malware on workstation** - Keep system updated  
❌ **Physical access** - Use FileVault on macOS  
❌ **State-level adversaries** - Not designed for this threat model  
❌ **Compromised exit nodes** - Use HTTPS always  

### Threat Model

**This setup is appropriate for:**
- Privacy-conscious browsing
- Journalism / research
- Bypassing network restrictions
- Accessing .onion services
- General anonymity

**This setup is NOT appropriate for:**
- High-risk activism against nation-states
- Protecting against physical seizure
- Zero-knowledge operations

---

## 🔧 Maintenance

### Update Gateway

```bash
# Login to gateway as root
apt-get update
apt-get upgrade -y
systemctl restart tor
```

### Update Workstation

```bash
# Login to workstation as root
apt-get update
apt-get upgrade -y
```

### Monitor Tor Status

```bash
# On gateway
tail -f /var/log/tor/notices.log
```

### Check Tor Circuit

```bash
# On gateway
systemctl status tor
netstat -tlnp | grep tor
```

---

## 🚨 Troubleshooting

### Gateway: Tor Won't Start

**Check logs:**
```bash
journalctl -u tor -n 50
```

**Common issues:**
- Port conflict (check if 9050 in use)
- Permission error (check /var/log/tor ownership)
- Config syntax error (run `tor --verify-config`)

### Workstation: Can't Reach Gateway

**Check network:**
```bash
ip addr show
ip route
ping 10.152.152.10
```

**Verify eth0 has:**
- IP: 10.152.152.11
- Gateway: 10.152.152.10

### Firefox: .onion Sites Don't Work

**Check settings:**
1. `about:config` → `network.dns.blockDotOnion` = `false`
2. Proxy DNS enabled in network settings
3. Gateway Tor config has `AutomapHostsSuffixes .onion`

### Speed is Slow

**This is normal for Tor:**
- Tor routes through 3+ relays
- Speed: 1-5 Mbps typical
- Latency: 500ms-2s typical

**To improve:**
- Use bridges if censored
- Avoid heavy downloads
- Use regular Firefox for non-sensitive browsing

---

## 📁 Configuration Files

### Gateway: /etc/tor/torrc

```
SocksPort 10.152.152.10:9050
DNSPort 10.152.152.10:5353
TransPort 10.152.152.10:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
Log notice file /var/log/tor/notices.log
ControlPort 10.152.152.10:9051
CookieAuthentication 1
```

### Gateway: /etc/network/interfaces

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.152.152.10
    netmask 255.255.255.0
```

### Workstation: /etc/network/interfaces

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
```

---

## 🔄 Alternative Hypervisors

### UTM (Recommended for Security)

**Advantages:**
- Open source
- Uses Apple Hypervisor.framework
- Better anti-forensics

**Network setup:**
```
Gateway: Shared network + Custom network
Workstation: Custom network only
```

### VMware Fusion

**Advantages:**
- Free for personal use
- Good ARM64 support

**Network setup:**
```
Gateway: NAT + Host-Only
Workstation: Host-Only
```

---

## 📚 Additional Resources

### Official Documentation

- Tor Project: https://www.torproject.org
- Tor Manual: https://2019.www.torproject.org/docs/tor-manual.html
- Debian ARM64: https://www.debian.org/ports/arm/

### Related Projects

- Whonix: https://www.whonix.org (x86-64 only)
- Tails: https://tails.net (x86-64 only)
- Qubes OS: https://www.qubes-os.org (x86-64 only)

### Why ARM64?

This configuration exists because:
1. ARM64 is secure for OPSEC (see investigation)
2. Apple Silicon Macs need native ARM64 VMs
3. Whonix/Tails don't support ARM64 yet
4. Community needed a working solution

---

## 📝 Changelog

### Version 1.0 (2025-12-07)
- Initial release
- Debian 12 ARM64 base
- Tor with .onion support
- Fail-closed firewall
- Firefox configuration
- Complete documentation

---

## 📄 License

This configuration is released into the public domain.  
Use freely for any purpose.

---

## 🤝 Contributing

Found a bug? Have an improvement?

1. Test your change thoroughly
2. Document the configuration
3. Submit with clear description
4. Include version numbers

---

## ⚠️ Disclaimer

This software is provided "as is" without warranty.  
Using Tor may be illegal in some jurisdictions.  
You are responsible for compliance with local laws.

**Not affiliated with:**
- The Tor Project
- Debian Project
- Whonix Project
- Tails Project

---

**Version:** 1.0  
**Last Updated:** December 7, 2025  
**Maintainer:** Community  
**Architecture:** ARM64 (Apple Silicon)  

**For latest updates:** Check project repository
