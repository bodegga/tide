# Tor Gateway Configuration - URGENT FIX NEEDED

**Date:** 2025-12-07  
**Status:** 🔴 CRITICAL - Gateway is NOT routing through Tor  
**Issue:** Workstation is leaking real IP address

---

## Problem Statement

- ✅ Debian installed on both VMs
- ✅ Workstation configured and connects to Gateway
- ❌ **Gateway is NOT using Tor - showing home IP address**
- ❌ Traffic is passing through Gateway but going direct to internet

**This defeats the entire purpose of the isolation setup.**

---

## Immediate Diagnostic Commands

Run these on **Tor-Gateway VM** to check current state:

### 1. Check if Tor is installed
```bash
dpkg -l | grep tor
systemctl status tor
```

### 2. Check Tor configuration
```bash
cat /etc/tor/torrc
```

### 3. Check if Tor is listening
```bash
ss -tlnp | grep tor
netstat -tlnp | grep tor
```

### 4. Check current network routing
```bash
ip addr
ip route
```

### 5. Check firewall rules
```bash
sudo nft list ruleset
sudo iptables -L -v -n
```

---

## Required Tor Gateway Configuration

### Step 1: Install Tor on Gateway

```bash
# On Tor-Gateway VM
sudo apt update
sudo apt install -y tor tor-geoipdb
```

### Step 2: Configure Tor as Transparent Proxy

Create `/etc/tor/torrc` with this configuration:

```bash
sudo nano /etc/tor/torrc
```

**Required torrc configuration:**

```
# Tor Gateway Configuration
# Routes all traffic from Workstation through Tor

VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1

# Transparent proxy port
TransPort 10.152.152.10:9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort
DNSPort 10.152.152.10:5353

# SOCKS ports for different isolation streams
SocksPort 10.152.152.10:9050 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort
SocksPort 10.152.152.10:9051 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort
SocksPort 10.152.152.10:9052 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort

# Logging (for debugging, disable in production)
Log notice file /var/log/tor/notices.log

# Security settings
DisableDebuggerAttachment 0
```

**Key points:**
- `TransPort 9040` - Transparent proxy for all TCP traffic
- `DNSPort 5353` - DNS resolver through Tor
- Listening on `10.152.152.10` (Gateway's internal IP)
- Multiple SOCKS ports for stream isolation

### Step 3: Enable and Start Tor

```bash
sudo systemctl enable tor
sudo systemctl restart tor
sudo systemctl status tor
```

**Check logs:**
```bash
sudo journalctl -u tor -f
# Should see: "Bootstrapped 100% (done): Done"
```

### Step 4: Configure Firewall (Critical!)

This is **THE MOST IMPORTANT PART** - ensures only Tor can reach the internet.

**Install nftables:**
```bash
sudo apt install -y nftables
```

**Create firewall rules:**
```bash
sudo nano /etc/nftables.conf
```

**nftables configuration:**

```
#!/usr/sbin/nft -f

# Flush existing rules
flush ruleset

# Define internal network
define INTERNAL_NET = 10.152.152.0/24
define GATEWAY_IP = 10.152.152.10

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        # Allow loopback
        iif lo accept
        
        # Allow established connections
        ct state established,related accept
        
        # Allow SSH from internal network (for management)
        iif eth1 ip saddr $INTERNAL_NET tcp dport 22 accept
        
        # Allow Tor ports from internal network
        iif eth1 ip saddr $INTERNAL_NET tcp dport {9040, 9050, 9051, 9052} accept
        iif eth1 ip saddr $INTERNAL_NET udp dport 5353 accept
    }
    
    chain forward {
        type filter hook forward priority 0; policy drop;
        
        # Allow established connections
        ct state established,related accept
        
        # Forward traffic from internal network through Tor
        iif eth1 ip saddr $INTERNAL_NET accept
    }
    
    chain output {
        type filter hook output priority 0; policy drop;
        
        # Allow loopback
        oif lo accept
        
        # Allow established connections
        ct state established,related accept
        
        # CRITICAL: Only allow Tor user to reach internet
        oif eth0 skuid debian-tor accept
        
        # Allow responses to internal network
        oif eth1 accept
    }
}

table ip nat {
    chain prerouting {
        type nat hook prerouting priority -100; policy accept;
        
        # Redirect DNS to Tor
        iif eth1 ip saddr $INTERNAL_NET udp dport 53 redirect to :5353
        
        # Redirect TCP to Tor transparent proxy
        iif eth1 ip saddr $INTERNAL_NET tcp flags syn tcp dport {80, 443} redirect to :9040
    }
    
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        
        # NAT for Tor traffic
        oif eth0 masquerade
    }
}
```

**Enable nftables:**
```bash
sudo systemctl enable nftables
sudo systemctl restart nftables
```

**Verify rules loaded:**
```bash
sudo nft list ruleset
```

### Step 5: Enable IP Forwarding

```bash
sudo nano /etc/sysctl.conf
```

Add or uncomment:
```
net.ipv4.ip_forward=1
```

Apply:
```bash
sudo sysctl -p
```

### Step 6: Verify Tor User Exists

```bash
id debian-tor
# Should show: uid=XXX(debian-tor) gid=XXX(debian-tor)
```

If not found:
```bash
sudo adduser --system --group --no-create-home debian-tor
```

---

## Testing from Gateway

### 1. Check Tor circuit established
```bash
sudo journalctl -u tor | grep "Bootstrapped 100%"
```

### 2. Test Tor SOCKS proxy locally
```bash
curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
```

Should return Tor exit node IP, NOT your home IP.

### 3. Check what IP Tor sees
```bash
curl --socks5-hostname 127.0.0.1:9050 https://ifconfig.me
```

Should be different from:
```bash
curl https://ifconfig.me  # This will FAIL if firewall is working (good!)
```

---

## Testing from Workstation

Once Gateway is configured, test from **SecuredWorkstation VM:**

### 1. Test DNS through Tor
```bash
nslookup google.com 10.152.152.10
```

### 2. Check public IP
```bash
curl https://ifconfig.me
# Should show Tor exit node IP, NOT home IP
```

### 3. Check Tor Project verification
```bash
curl https://check.torproject.org/api/ip
```

Should return:
```json
{"IsTor":true,"IP":"<tor-exit-ip>"}
```

### 4. DNS leak test
```bash
curl https://www.dnsleaktest.com
```

Should NOT show your ISP's DNS servers.

---

## Current Network Configuration Reference

### Tor-Gateway Expected State

**Interface eth0 (to internet):**
- DHCP from Parallels Shared Network
- Example: 10.211.55.X/24

**Interface eth1 (to Workstation):**
- Static: 10.152.152.10/24
- This is what Workstation talks to

### SecuredWorkstation Expected State

**Interface eth0:**
- Static: 10.152.152.11/24
- Gateway: 10.152.152.10
- DNS: 10.152.152.10

**Routing table should show:**
```
Destination     Gateway         Genmask         Iface
0.0.0.0         10.152.152.10   0.0.0.0         eth0
10.152.152.0    0.0.0.0         255.255.255.0   eth0
```

---

## Common Issues & Fixes

### Issue: Tor won't start
```bash
# Check logs
sudo journalctl -u tor -n 50

# Common fix: permissions
sudo chown -R debian-tor:debian-tor /var/lib/tor
sudo chmod 700 /var/lib/tor
```

### Issue: "Can't establish Tor circuit"
```bash
# Check if Tor can reach internet
sudo -u debian-tor curl https://www.torproject.org

# If this fails, firewall is blocking Tor user (check nftables)
```

### Issue: Workstation still shows home IP
```bash
# On Gateway, check if traffic is hitting Tor
sudo tcpdump -i eth1 -n

# Check NAT rules are working
sudo nft list table ip nat

# Verify Tor TransPort is listening
sudo ss -tlnp | grep 9040
```

### Issue: DNS not working from Workstation
```bash
# On Gateway, check DNSPort
sudo ss -unlp | grep 5353

# Test locally on Gateway
dig @10.152.152.10 -p 5353 google.com

# From Workstation
dig @10.152.152.10 google.com
```

---

## Security Checklist

Before considering this secure:

- [ ] Tor daemon running and bootstrapped to 100%
- [ ] TransPort 9040 listening on 10.152.152.10
- [ ] DNSPort 5353 listening on 10.152.152.10
- [ ] nftables rules loaded (only debian-tor can reach internet)
- [ ] IP forwarding enabled
- [ ] Workstation shows Tor exit IP, not home IP
- [ ] DNS queries go through Tor (check.torproject.org confirms)
- [ ] No DNS leaks (dnsleaktest.com shows Tor, not ISP)
- [ ] Cannot curl directly from Gateway without --socks5

---

## What Went Wrong (Root Cause Analysis)

**The Gateway was acting as a simple NAT router instead of a Tor router.**

Without Tor installed and configured:
1. Workstation sends traffic to Gateway (10.152.152.10)
2. Gateway forwards traffic to internet via eth0
3. Traffic goes out with Gateway's real IP (via Parallels Shared Network)
4. **No anonymization happened**

**The fix:**
1. Install Tor daemon
2. Configure transparent proxy ports
3. Add firewall rules that **only allow Tor user** to reach internet
4. NAT/redirect all Workstation traffic through Tor TransPort

This ensures even a compromised Workstation cannot discover real IP.

---

**Next immediate action: Run diagnostic commands above to see current Gateway state, then apply Tor configuration.**
