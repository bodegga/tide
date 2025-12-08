# Alpine Tor Gateway - Complete Setup Guide

**Date:** 2025-12-07  
**VM:** Alpine-Tor-Gateway (running)  
**Status:** Ready to configure

---

## 🎯 Current State

- ✅ Alpine VM created and running
- ✅ Alpine ISO downloaded (68MB)
- ✅ SecuredWorkstation VM ready
- 🔄 **Next:** Install and configure Alpine Gateway

---

## 📋 Phase 1: Alpine Installation (5 minutes)

### Step 1: Open Alpine VM Console

1. **Open Parallels Desktop**
2. **Double-click "Alpine-Tor-Gateway"**
3. You should see Alpine boot screen or login prompt

### Step 2: Check Current State

**If you see a login prompt** `localhost login:`:
- Alpine is already installed! Skip to Phase 2.

**If you see installer/boot menu**:
- Continue with installation below.

### Step 3: Run Alpine Setup

Login as `root` (no password initially), then run:

```bash
setup-alpine
```

### Step 4: Answer Setup Prompts

```
Select keyboard layout [none]: us
Select variant []: us

Enter system hostname [localhost]: gateway

Which one do you want to initialize? [eth0]: eth0
Ip address for eth0? [dhcp]: dhcp
Do you want to do any manual network configuration? [no]: no

New password: <create-strong-password>
Re-type password: <same-password>

Which timezone are you in? [UTC]: UTC

HTTP/FTP proxy URL? [none]: (press Enter)

Enter mirror number or URL: f
(f = find fastest mirror)

Which SSH server? [openssh]: openssh

Which NTP client to run? [chrony]: chrony

Which disk would you like to use? [none]: sda
How would you like to use it? [sys]: sys
WARNING: Erase the above disk(s) and continue? [y/N]: y
```

### Step 5: Reboot

```bash
reboot
```

**Wait 10 seconds for reboot to complete.**

### Step 6: Login After Reboot

```
gateway login: root
Password: <your-password>
```

✅ **Phase 1 Complete!** Alpine is installed.

---

## 📋 Phase 2: Network Configuration (3 minutes)

### Step 1: Configure eth1 (Internal Network to Workstation)

```bash
cat >> /etc/network/interfaces << 'EOF'

auto eth1
iface eth1 inet static
    address 10.152.152.10
    netmask 255.255.255.0
EOF
```

### Step 2: Bring up eth1

```bash
ifup eth1
```

### Step 3: Verify Network Interfaces

```bash
ip addr show
```

**Expected output:**
```
eth0: inet <DHCP-IP>/24 (from Parallels Shared Network)
eth1: inet 10.152.152.10/24
```

### Step 4: Enable IP Forwarding

```bash
cat >> /etc/sysctl.conf << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
EOF

sysctl -p
```

**Should output:**
```
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
```

✅ **Phase 2 Complete!** Network configured.

---

## 📋 Phase 3: Install Tor (2 minutes)

### Step 1: Install Tor and iptables

```bash
apk add tor iptables ip6tables
```

### Step 2: Create Tor Configuration

```bash
cat > /etc/tor/torrc << 'EOF'
# Alpine Tor Gateway - Minimal Configuration
# SOCKS proxy for applications
SocksPort 10.152.152.10:9050

# DNS resolver through Tor
DNSPort 10.152.152.10:5353

# Transparent proxy for iptables redirect
TransPort 10.152.152.10:9040

# .onion support (CRITICAL)
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion

# Logging
Log notice file /var/log/tor/notices.log

# Control port
ControlPort 10.152.152.10:9051
CookieAuthentication 1
EOF
```

### Step 3: Create Log Directory

```bash
mkdir -p /var/log/tor
chown tor:tor /var/log/tor
chmod 700 /var/log/tor
```

### Step 4: Test Tor Configuration

```bash
tor --verify-config -f /etc/tor/torrc
```

**Expected output:**
```
Configuration was valid
```

✅ **Phase 3 Complete!** Tor is configured.

---

## 📋 Phase 4: Firewall Configuration (2 minutes)

### Step 1: Create iptables Rules

```bash
cat > /etc/iptables/rules-save << 'EOF'
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# Redirect DNS from workstation to Tor DNSPort
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353

# Redirect TCP from workstation to Tor TransPort
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

# Allow from workstation to Tor SOCKS
-A INPUT -i eth1 -s 10.152.152.0/24 -p tcp --dport 9050 -j ACCEPT

# Allow from workstation to Tor TransPort
-A INPUT -i eth1 -s 10.152.152.0/24 -p tcp --dport 9040 -j ACCEPT

# Allow from workstation to Tor DNSPort
-A INPUT -i eth1 -s 10.152.152.0/24 -p udp --dport 5353 -j ACCEPT

# Allow SSH from workstation
-A INPUT -i eth1 -s 10.152.152.0/24 -p tcp --dport 22 -j ACCEPT

# Allow from workstation to Tor ControlPort
-A INPUT -i eth1 -s 10.152.152.0/24 -p tcp --dport 9051 -j ACCEPT

COMMIT
EOF
```

### Step 2: Load Firewall Rules

```bash
iptables-restore < /etc/iptables/rules-save
```

### Step 3: Verify Rules

```bash
iptables -L -n -v
```

**Should show the rules listed above.**

✅ **Phase 4 Complete!** Firewall is configured.

---

## 📋 Phase 5: Start Services (2 minutes)

### Step 1: Enable Services on Boot

```bash
rc-update add tor
rc-update add iptables
```

### Step 2: Start Tor

```bash
rc-service tor start
```

### Step 3: Monitor Tor Bootstrap

```bash
tail -f /var/log/tor/notices.log
```

**Wait for this message:**
```
Bootstrapped 100% (done): Done
```

**Press Ctrl+C** to exit.

### Step 4: Verify Tor is Running

```bash
rc-service tor status
```

**Should say:** `* status: started`

```bash
netstat -tlnp | grep tor
```

**Should show Tor listening on:**
- `10.152.152.10:9050` (SOCKS)
- `10.152.152.10:9040` (TransPort)
- `10.152.152.10:5353` (DNS)
- `10.152.152.10:9051` (Control)

✅ **Phase 5 Complete!** Gateway is operational!

---

## 📋 Phase 6: Configure Workstation (5 minutes)

### Step 1: Switch to SecuredWorkstation VM

In Parallels, open the **SecuredWorkstation** VM console.

### Step 2: Update Network Configuration

Login to SecuredWorkstation, then:

```bash
sudo nano /etc/network/interfaces
```

**Replace contents with:**
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

**Save and exit** (Ctrl+X, Y, Enter)

### Step 3: Restart Networking

```bash
sudo systemctl restart networking
```

### Step 4: Test Connectivity to Gateway

```bash
ping -c 3 10.152.152.10
```

**Should get replies!**

### Step 5: Test Internet Through Tor

```bash
curl --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip
```

**Should return:**
```json
{"IsTor":true,"IP":"<tor-exit-node-ip>"}
```

### Step 6: Test Public IP

```bash
curl https://api.ipify.org
```

**Should show Tor exit node IP (NOT your home IP)!**

✅ **Phase 6 Complete!** Workstation is anonymized!

---

## 📋 Phase 7: Firefox .onion Configuration (Optional)

### Step 1: Configure Firefox Proxy

In Firefox on SecuredWorkstation:

1. **Menu → Settings → General**
2. **Scroll to "Network Settings" → Settings**
3. **Select "Manual proxy configuration"**
4. **Configure:**
   ```
   SOCKS Host: 10.152.152.10
   Port: 9050
   ☑ SOCKS v5
   ☑ Proxy DNS when using SOCKS v5
   ```
5. **Click OK**

### Step 2: Enable .onion Support

1. In Firefox, type: `about:config`
2. Accept warning
3. Search for: `network.dns.blockDotOnion`
4. Double-click to set to: `false`

### Step 3: Test .onion Access

Visit in Firefox:
```
http://3g2upl4pq6kufc4m.onion
```

**Should load DuckDuckGo onion service!** 🧅

✅ **Phase 7 Complete!** .onion sites working!

---

## ✅ DEPLOYMENT COMPLETE!

### What You Now Have:

```
┌─────────────────────────────────────────────┐
│  Alpine-Tor-Gateway (150MB, 512MB RAM)     │
│  ✅ Tor routing all traffic                │
│  ✅ .onion support                         │
│  ✅ Firewall (fail-closed)                 │
│  ✅ 10.152.152.10                          │
└─────────────────┬───────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────┐
│  SecuredWorkstation (Debian)                │
│  ✅ All traffic through gateway             │
│  ✅ Firefox with .onion access              │
│  ✅ 10.152.152.11                           │
└─────────────────────────────────────────────┘
```

### Final Tests (Run on Workstation):

```bash
# 1. Check public IP (should show Tor exit)
curl https://api.ipify.org

# 2. Verify Tor usage
curl https://check.torproject.org/api/ip
# Should return: {"IsTor":true}

# 3. Check DNS resolution
nslookup google.com
# Server should be 10.152.152.10

# 4. Test .onion in Firefox
# Visit: http://3g2upl4pq6kufc4m.onion
```

---

## 🔧 Useful Maintenance Commands

### On Gateway:

```bash
# Check Tor status
rc-service tor status

# View Tor log
tail -f /var/log/tor/notices.log

# Restart Tor
rc-service tor restart

# Check firewall
iptables -L -n -v

# Update Alpine
apk update && apk upgrade
```

### On Workstation:

```bash
# Check IP (should show Tor)
curl https://api.ipify.org

# Test SOCKS proxy
curl --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip

# Check routing
ip route
# Should show: default via 10.152.152.10
```

---

## 📊 Resource Usage

| Component | RAM | Disk | Status |
|-----------|-----|------|--------|
| Alpine Gateway | ~100MB | 150MB | ✅ Minimal |
| Debian Workstation | ~600MB | 2-3GB | ✅ Normal |
| **Total** | **~700MB** | **~3GB** | ✅ Efficient |

**Compare to Debian Gateway:** Would use 1.4GB RAM + 64GB disk

**Savings:** 82% RAM, 97% disk space

---

## 🛡️ Security Notes

### Protected Against:
✅ ISP monitoring  
✅ Network surveillance  
✅ IP correlation  
✅ DNS leaks  
✅ Accidental clearnet connections  

### NOT Protected Against:
⚠️ Browser fingerprinting (use Tor Browser)  
⚠️ Malware on Workstation  
⚠️ Physical access to Mac  
⚠️ State-level adversaries  

### Best Practices:
- Update both VMs monthly
- Create snapshots before updates
- Use Tor Browser for sensitive activities
- Regular Firefox for normal browsing (both go through Tor)

---

## 📸 Create Snapshot (Recommended)

### After Everything Works:

1. **Shutdown both VMs:**
   ```bash
   # On Gateway:
   poweroff
   
   # On Workstation:
   sudo poweroff
   ```

2. **In Parallels:**
   - Right-click each VM → Manage Snapshots
   - Take Snapshot → Name: "Clean Install - Tor Working"

3. **Restart VMs and verify Tor still works**

---

## 🎉 Success!

**Total deployment time:** ~20 minutes  
**Total complexity:** Minimal  
**Total bloat:** Zero  

Your Alpine Tor Gateway is complete and running!

---

*Deployment guide created: 2025-12-07*  
*Alpine Linux 3.19.1 ARM64*  
*Tor transparent proxy architecture*
