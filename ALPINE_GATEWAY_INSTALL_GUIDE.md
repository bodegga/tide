# Alpine Tor Gateway - Complete Installation Guide

**VM Created:** ✅ Alpine-Tor-Gateway  
**Status:** Booting Alpine Linux  
**Next:** Follow this guide step-by-step

---

## 🎯 **Phase 1: Alpine Installation (5 minutes)**

### Step 1: Login to VM Console

1. **Open Parallels Desktop**
2. **Double-click Alpine-Tor-Gateway**
3. **Wait for boot to finish** (shows login prompt)
4. **Login as:** `root` (no password required)

### Step 2: Run Alpine Setup

```bash
setup-alpine
```

### Step 3: Answer Setup Prompts

**Follow these EXACT answers:**

```
Select keyboard layout: us
Select variant: us

Enter system hostname: gateway

Which interface for management: eth0
IP address for eth0: dhcp
Do you want any manual network: n

New password: <create-strong-password>
Re-type password: <same-password>

Which timezone: UTC

HTTP/FTP proxy URL: none

Which mirror number: f (find fastest)

Which SSH server: openssh

Allow root ssh login: yes

Enter ssh key: (just press Enter)

Which disk for install: sda
How would you like to use it: sys
WARNING: Erase the above disk: y
```

### Step 4: Wait for Installation

Installation takes 2-3 minutes. When finished:

```bash
reboot
```

### Step 5: Login After Reboot

After reboot, login:
```
Username: root
Password: <your-password>
```

**✅ Phase 1 Complete!** Alpine is installed.

---

## 🎯 **Phase 2: Network Configuration (3 minutes)**

### Step 1: Configure eth1 (Internal Network)

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

### Step 3: Verify Network

```bash
ip addr show
```

**Should show:**
```
eth0: inet <DHCP-assigned-IP>
eth1: inet 10.152.152.10/24
```

### Step 4: Enable IP Forwarding

```bash
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

**✅ Phase 2 Complete!** Network is configured.

---

## 🎯 **Phase 3: Install Tor (2 minutes)**

### Step 1: Install Tor and iptables

```bash
apk add tor iptables ip6tables
```

### Step 2: Create Tor Configuration

```bash
cat > /etc/tor/torrc << 'EOF'
# Tor Gateway Configuration
# SOCKS proxy for applications
SocksPort 10.152.152.10:9050

# DNS resolver through Tor
DNSPort 10.152.152.10:5353

# Transparent proxy for iptables redirect
TransPort 10.152.152.10:9040

# .onion support (CRITICAL FOR FIREFOX)
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion

# Logging
Log notice file /var/log/tor/notices.log

# Control port for monitoring
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

**Should say:** "Configuration was valid"

**✅ Phase 3 Complete!** Tor is configured.

---

## 🎯 **Phase 4: Firewall Configuration (3 minutes)**

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

# Log dropped packets (debugging)
-A INPUT -j LOG --log-prefix "GATEWAY-INPUT-DROP: " --log-level 4

COMMIT
EOF
```

### Step 2: Load Firewall Rules

```bash
iptables-restore < /etc/iptables/rules-save
```

### Step 3: Verify Rules Loaded

```bash
iptables -L -n -v
```

**Should show rules listed above**

### Step 4: Enable Firewall on Boot

```bash
rc-update add iptables
```

**✅ Phase 4 Complete!** Firewall is configured.

---

## 🎯 **Phase 5: Start Services (2 minutes)**

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

**Press Ctrl+C** to exit log view.

### Step 4: Verify Tor is Running

```bash
rc-service tor status
```

**Should say:** "started"

```bash
netstat -tlnp | grep tor
```

**Should show Tor listening on:**
- `10.152.152.10:9050` (SOCKS)
- `10.152.152.10:9040` (TransPort)
- `10.152.152.10:5353` (DNS)
- `10.152.152.10:9051` (Control)

**✅ Phase 5 Complete!** Gateway is fully operational!

---

## 🎯 **Phase 6: Create Snapshot (1 minute)**

### Step 1: Shutdown Gateway

```bash
poweroff
```

### Step 2: Create Snapshot in Parallels

1. **Open Parallels Desktop**
2. **Right-click Alpine-Tor-Gateway**
3. **Manage Snapshots → Take Snapshot**
4. **Name:** `Clean Gateway - Tor Configured`
5. **Click OK**

### Step 3: Restart Gateway

1. **Start Alpine-Tor-Gateway**
2. **Login as root**
3. **Verify Tor is running:**

```bash
rc-service tor status
tail /var/log/tor/notices.log
```

**✅ Phase 6 Complete!** Snapshot created.

---

## 🎯 **Phase 7: Configure Workstation (5 minutes)**

### Step 1: Update Workstation Network

**On SecuredWorkstation VM:**

1. **Login as root (or use sudo)**

2. **Edit network config:**
```bash
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
EOF
```

3. **Restart networking:**
```bash
systemctl restart networking
```

4. **Test connectivity to gateway:**
```bash
ping -c 3 10.152.152.10
```

**Should get replies!**

5. **Test internet through Tor:**
```bash
curl --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip
```

**Should return Tor exit IP (not your real IP)**

### Step 2: Configure Firefox for .onion Support

**In Firefox on Workstation:**

1. **Settings → General → Network Settings → Settings**

2. **Select "Manual proxy configuration"**

3. **Configure:**
   ```
   SOCKS Host: 10.152.152.10
   Port: 9050
   ☑ SOCKS v5
   ☑ Proxy DNS when using SOCKS v5
   ```

4. **Click OK**

5. **Open Firefox, type:** `about:config`

6. **Accept warning**

7. **Search for:** `network.dns.blockDotOnion`

8. **Double-click to set:** `false`

### Step 3: Test .onion Access

**In Firefox, visit:**
```
http://3g2upl4pq6kufc4m.onion
```

**Should load DuckDuckGo onion service!** 🧅

**✅ Phase 7 Complete!** Workstation configured!

---

## ✅ **DEPLOYMENT COMPLETE!**

### What You Now Have:

```
┌─────────────────────────────────────────────┐
│  Alpine-Tor-Gateway (150MB, 512MB RAM)     │
│  ✅ Tor routing all traffic                │
│  ✅ .onion support for Firefox             │
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

### Test Everything Works:

**From Workstation:**

1. **Check public IP:**
   ```bash
   curl https://api.ipify.org
   # Should show Tor exit IP
   ```

2. **Check DNS:**
   ```bash
   nslookup google.com
   # Server should be 10.152.152.10
   ```

3. **Test .onion in Firefox:**
   ```
   http://3g2upl4pq6kufc4m.onion
   # DuckDuckGo should load
   ```

4. **Test regular site in Firefox:**
   ```
   https://check.torproject.org
   # Should say "Using Tor"
   ```

### Resource Usage:

| Component | RAM | Disk | Status |
|-----------|-----|------|--------|
| Alpine Gateway | 100MB used | 150MB | ✅ Running |
| Debian Workstation | ~600MB | 2-3GB | ✅ Running |
| **Total** | **~700MB** | **~3GB** | ✅ Complete |

**Compare to old plan:** 4GB RAM + 128GB disk → **Savings: 82% RAM, 97% disk**

---

## 🔧 **Useful Commands**

### On Gateway:

```bash
# Check Tor status
rc-service tor status

# View Tor log
tail -f /var/log/tor/notices.log

# Restart Tor
rc-service tor restart

# Check firewall rules
iptables -L -n -v

# Check network interfaces
ip addr show

# Test Tor is working
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```

### On Workstation:

```bash
# Check IP (should show Tor exit)
curl https://api.ipify.org

# Check DNS
nslookup google.com

# Test SOCKS proxy
curl --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip

# Check routing
ip route
# Should show: default via 10.152.152.10
```

---

## 🎯 **Next Steps (Optional)**

### 1. Install Tor Browser on Workstation
```bash
sudo apt install torbrowser-launcher
torbrowser-launcher
```

### 2. Add Password Manager
```bash
sudo apt install keepassxc
```

### 3. Enable Auto-start on Both VMs
```
Parallels → VM → Configure → Options → Startup and Shutdown
☑ Start automatically when user logs in
```

### 4. Create Additional Snapshots
- Before major changes
- Before updates
- Weekly backups

---

## 🛡️ **Security Notes**

### What You're Protected Against:
✅ ISP monitoring  
✅ Network surveillance  
✅ IP address correlation  
✅ DNS leaks  
✅ Accidental clearnet connections  

### What You're NOT Protected Against:
⚠️ Browser fingerprinting (use Tor Browser for max anonymity)  
⚠️ Malware on Workstation  
⚠️ Physical access to Mac  
⚠️ State-level adversaries  

### Best Practices:
- Use Tor Browser for sensitive activities
- Use regular Firefox for normal browsing
- Both go through Tor gateway
- Update both VMs regularly
- Create snapshots before updates

---

**🎉 CONGRATULATIONS! Your ARM64 Tor Gateway is Complete!**

**Total deployment time:** ~20 minutes  
**Total complexity:** Minimal  
**Total bloat:** Zero  

*Deployment completed: December 7, 2025*
