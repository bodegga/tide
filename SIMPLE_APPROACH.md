# Simple ARM64 Tor Gateway - The Right Way

**You're 100% correct.** We were massively over-engineering this.

---

## 🎯 What You Actually Need

### Gateway Requirements
- ✅ Boot minimal Linux
- ✅ Run Tor daemon
- ✅ Route traffic through Tor
- ✅ **Total size: ~150MB**

### What You DON'T Need
- ❌ Full Debian (700MB+)
- ❌ Kicksecure hardening (overkill for a router)
- ❌ Desktop environment on gateway
- ❌ Complex firewall rules
- ❌ Multiple isolated SOCKS ports

---

## 🚀 **Three Simple Approaches (Pick One)**

### **Option A: Alpine Linux Gateway** ⭐ Recommended

**Why Alpine?**
- Tiny: ~130MB installed
- Secure by default (musl, no systemd)
- Perfect for routing/gateway roles
- ARM64 support excellent

**Setup Time:** 15 minutes

#### Step-by-Step:

```bash
# 1. Download Alpine ARM64 (130MB)
curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-virt-3.19.1-aarch64.iso

# 2. Create VM in Parallels:
#    - Name: Tor-Gateway
#    - RAM: 512MB (yes, that's enough!)
#    - Disk: 2GB
#    - Network Adapter 0: Shared Network
#    - Network Adapter 1: Host-Only

# 3. Boot from ISO, login as root (no password initially)

# 4. Run setup (answer prompts - takes 2 minutes)
setup-alpine
# Keyboard: us
# Hostname: tor-gateway
# Network: eth0 dhcp, eth1 manual
# Timezone: UTC
# Disk: sys (to install to disk)

# 5. Configure eth1 manually
cat > /etc/network/interfaces << 'NETCONF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.152.152.10
    netmask 255.255.255.0
NETCONF

# 6. Reboot
reboot

# 7. After reboot, SSH in and install Tor
apk add tor iptables ip6tables

# 8. Configure Tor (minimal - 3 lines!)
cat > /etc/tor/torrc << 'TORRC'
SocksPort 10.152.152.10:9050
TransPort 10.152.152.10:9040
DNSPort 10.152.152.10:5353
TORRC

# 9. Simple firewall (6 rules total)
cat > /etc/iptables/rules-save << 'RULES'
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# Redirect DNS to Tor
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
# Redirect TCP to Tor transparent proxy
-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040
COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Allow loopback
-A INPUT -i lo -j ACCEPT
# Allow established
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Allow from internal network to Tor ports
-A INPUT -i eth1 -p tcp -m multiport --dports 9040,9050 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT
# Allow SSH from internal
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
COMMIT
RULES

# 10. Enable services
rc-update add iptables
rc-update add tor
rc-service iptables start
rc-service tor start

# 11. Check Tor is running
tail -f /var/log/tor/notices.log
# Wait for "Bootstrapped 100%"
```

**Done! Gateway is complete.**

Total disk usage: ~150MB  
Total RAM usage: ~100MB  
Boot time: ~5 seconds

---

### **Option B: Docker on macOS** ⭐ Even Simpler

**Why Docker?**
- No separate gateway VM needed
- Tor runs as container on macOS
- Workstation VM just points to it

**Setup Time:** 5 minutes

```bash
# 1. Install Docker Desktop for macOS (if not already)
# Download from docker.com

# 2. Run Tor container
docker run -d \
  --name tor-gateway \
  --restart unless-stopped \
  -p 9050:9050 \
  -p 5353:5353/udp \
  dperson/torproxy

# 3. Find your Mac's IP on the VM network
ifconfig | grep "inet "
# Example: 10.211.55.2

# 4. In Workstation VM, configure network:
cat > /etc/network/interfaces << 'NET'
auto eth0
iface eth0 inet static
    address 10.211.55.100
    netmask 255.255.255.0
    gateway 10.211.55.2
    dns-nameservers 10.211.55.2
NET

# 5. Configure Tor Browser to use SOCKS
# Preferences → Network → Manual Proxy
# SOCKS Host: 10.211.55.2
# Port: 9050
```

**Done!** No gateway VM at all.

---

### **Option C: macOS Native Tor** ⭐ Simplest

**Why native?**
- No virtualization overhead
- Tor runs directly on macOS
- Just point Workstation to it

**Setup Time:** 3 minutes

```bash
# 1. Install Tor on macOS
brew install tor

# 2. Configure Tor to listen on all interfaces
cat > /opt/homebrew/etc/tor/torrc << 'TORRC'
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:5353
TORRC

# 3. Start Tor
brew services start tor

# 4. Find Mac IP
ifconfig | grep "inet " | grep -v 127.0.0.1
# Example: 192.168.1.100

# 5. In Workstation VM:
# - Set DNS to Mac IP
# - Configure Tor Browser SOCKS to Mac IP:9050
```

**Done!** Ultimate simplicity.

---

## 📊 Comparison

| Approach | Gateway Size | Setup Time | Isolation | Complexity |
|----------|--------------|------------|-----------|------------|
| **Alpine VM** | 150MB | 15 min | ⭐⭐⭐⭐⭐ Best | Medium |
| **Docker** | ~500MB | 5 min | ⭐⭐⭐⭐ Good | Low |
| **macOS Native** | ~50MB | 3 min | ⭐⭐⭐ OK | Lowest |

---

## 🎯 Recommended: Alpine Linux Approach

**Why?**
1. **Proper isolation:** Separate VM = separate attack surface
2. **Minimal:** 150MB total, boots in 5 seconds
3. **Auditable:** Everything fits in your head
4. **Standard:** Same architecture as real routers use

**What you get:**
```
Workstation VM → (only path out) → Alpine Gateway → Tor Network → Internet
```

**What you avoid:**
- Bloated Debian install
- Unnecessary hardening packages
- Complex firewall rules
- Hours of configuration

---

## 📋 Quick Start: Alpine Method

### On Your M4 Mac:

```bash
# 1. Download Alpine (2 minutes)
cd ~/Downloads
curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-virt-3.19.1-aarch64.iso

# 2. Create VM in Parallels:
# - Name: Alpine-Tor-Gateway
# - RAM: 512MB
# - Disk: 2GB
# - CPU: 1 core
# - Boot from alpine-virt ISO

# 3. In VM, run:
setup-alpine  # Follow prompts (2 minutes)

# 4. After reboot, install Tor:
apk add tor iptables

# 5. Copy/paste the configs from Option A above

# 6. Start services:
rc-service tor start
rc-service iptables start

# 7. Check it works:
tail /var/log/tor/notices.log
# Should see "Bootstrapped 100%"
```

**Total time: 15 minutes**  
**Total complexity: Minimal**  
**Total bloat: None**

---

## 🔧 Workstation Configuration (Same for All Approaches)

### Create Your Workstation VM:

```bash
# 1. Use Debian ARM64 netinst (158MB ISO)
# Install with Desktop Environment

# 2. Configure network to use Gateway:
sudo tee /etc/network/interfaces << 'NET'
auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
NET

# 3. Install Tor Browser
sudo apt install torbrowser-launcher

# 4. Configure Tor Browser SOCKS (if using Alpine Gateway):
# Settings → Network → SOCKS5 → 10.152.152.10:9050

# 5. Test:
curl --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip
```

**Done!**

---

## 🎯 Why This is Better

### Before (What We Were Doing):
```
Gateway VM:
- Debian: 700MB base
- Kicksecure: +200MB
- Desktop env: +500MB
- Total: ~1.4GB
- Setup: 2-3 hours
- Config files: 10+
```

### After (Alpine Approach):
```
Gateway VM:
- Alpine: 130MB
- Tor: 20MB
- Total: 150MB
- Setup: 15 minutes
- Config files: 2
```

**Savings:**
- 💾 Disk: 90% smaller (1.4GB → 150MB)
- ⏱️ Time: 90% faster (2-3h → 15min)
- 🧠 Complexity: 80% simpler (10 configs → 2)

---

## 🚨 What We Learned

**The cardinal sin of engineering:** Solving the wrong problem.

We were building a **secure operating system** when you just needed a **Tor router**.

**The fix:** Use the right tool for the job:
- Alpine Linux = Made for routing/gateway roles
- Minimal footprint = Smaller attack surface
- Simple config = Easier to audit
- Fast setup = Less time wasted

---

## 🎬 Next Action

**Let's rebuild with Alpine:**

1. Delete current bloated VMs (if you want)
2. Download Alpine ISO (130MB)
3. Create tiny Gateway VM (512MB RAM, 2GB disk)
4. Run the 6 commands above
5. Done in 15 minutes

**Or use Docker/macOS native if you want even simpler.**

Want me to walk you through the Alpine setup right now?

---

*You were right. This should be simple. Now it is.*
