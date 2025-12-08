# ARM64 Custom OPSEC VM Build Plan

**Date:** December 7, 2025  
**System:** M4 MacBook Air (macOS 26.1)  
**Architecture:** arm64  
**Goal:** Build hardened Tor Gateway/Workstation VMs using ARM64-native tools

---

## 🎯 **What We Learned from Investigation**

### ✅ **ARM64 IS Secure for OPSEC**
- Tor Browser supports ARM64 (macOS + Android)
- Debian packages Tor for ARM64
- Whonix has ARM64 builds (Raspberry Pi)
- No fundamental security flaws found

### ❌ **What's Missing**
- Qubes OS (Xen hypervisor doesn't support ARM64 desktop well)
- Official Tails ARM64 (x86-only design decision)
- VirtualBox ARM64 support (experimental/unstable)

### ✅ **What We CAN Use**
1. **UTM (QEMU)** - Open source, Apple Hypervisor.framework
2. **Parallels** - Commercial but mature (what we already have)
3. **Debian ARM64** - Official Tor packages
4. **Kicksecure** - Works on ARM64
5. **Custom Tor configuration** - Architecture-agnostic

---

## 🏗️ **Build Strategy: Two Approaches**

### Option A: Parallels (Current Setup - Fast Path)
**Pros:**
- Already installed and VMs created
- Better performance
- Better macOS integration
- Faster to get working

**Cons:**
- Closed source
- Account telemetry concerns
- Less auditable

**Status:** VMs partially installed, need completion

### Option B: UTM (Security-First Path)
**Pros:**
- Open source (QEMU + Hypervisor.framework)
- Better anti-forensics
- No account required
- Recommended by Kicksecure guide

**Cons:**
- Need to rebuild from scratch
- Slightly slower performance
- More manual configuration

**Recommendation:** Start with Parallels (Option A) to get working quickly, then optionally migrate to UTM later.

---

## 📋 **Phase 1: Complete Current Parallels Setup**

### Step 1.1: Check Current VM State

```bash
# Open Parallels
open -a "Parallels Desktop"

# List VMs and their status
prlctl list -a

# Check if VMs are running
prlctl status Tor-Gateway
prlctl status SecuredWorkstation
```

### Step 1.2: Complete Debian Installation on Tor-Gateway

**Boot VM and complete installation:**

1. **Partitioning:**
   - Use entire disk
   - Single partition (no swap - we'll use zram later)
   - ext4 filesystem

2. **Software Selection:**
   - Uncheck "Desktop Environment"
   - Check "SSH server"
   - Check "Standard system utilities"

3. **Network Configuration:**
   - Hostname: `tor-gateway`
   - Domain: (leave blank)
   - eth0: DHCP (will work automatically)
   - eth1: Configure later for static 10.152.152.10

4. **User Setup:**
   - Root password: (strong password)
   - User: `user` / password: (strong password)

5. **After Installation:**
   ```bash
   # First login as root
   ssh root@<gateway-ip>
   
   # Update system
   apt update && apt upgrade -y
   
   # Install essentials
   apt install -y sudo curl wget gnupg2 apt-transport-https net-tools
   
   # Add user to sudo group
   usermod -aG sudo user
   ```

### Step 1.3: Complete Debian Installation on SecuredWorkstation

**Repeat process with:**
- Hostname: `secured-workstation`
- Same software selection
- Network will be configured for 10.152.152.11 later

---

## 📋 **Phase 2: Install Kicksecure Hardening**

### Step 2.1: Add Kicksecure Repository (Both VMs)

```bash
# Download and install Kicksecure signing key
sudo mkdir -p /etc/apt/trusted.gpg.d/
sudo curl -fsSL https://www.kicksecure.com/keys/derivative.asc | \
  sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/derivative.gpg

# Add Kicksecure repository
echo "deb [signed-by=/etc/apt/trusted.gpg.d/derivative.gpg] \
  https://deb.kicksecure.com bookworm main contrib non-free" | \
  sudo tee /etc/apt/sources.list.d/derivative.list

# Update package lists
sudo apt update
```

### Step 2.2: Install Kicksecure CLI Package

```bash
# Install base Kicksecure (CLI mode, no GUI)
sudo apt install -y kicksecure-cli

# This installs:
# - Hardened kernel parameters
# - Security-focused system configuration
# - AppArmor profiles
# - Secure time sync
# - Memory hardening
```

**Expected changes:**
- `/etc/sysctl.d/` hardening
- AppArmor profiles installed
- Boot parameters modified
- Kernel hardening enabled

---

## 📋 **Phase 3: Configure Tor Gateway**

### Step 3.1: Install Tor

```bash
# On Tor-Gateway VM
sudo apt install -y tor tor-geoipdb obfs4proxy

# Stop Tor (we'll configure first)
sudo systemctl stop tor
```

### Step 3.2: Configure Network Interfaces

**Edit `/etc/network/interfaces`:**

```bash
sudo tee /etc/network/interfaces > /dev/null <<EOF
# Loopback interface
auto lo
iface lo inet loopback

# External interface (internet via Parallels Shared Network)
auto eth0
iface eth0 inet dhcp

# Internal interface (to Workstation)
auto eth1
iface eth1 inet static
    address 10.152.152.10
    netmask 255.255.255.0
    network 10.152.152.0
    broadcast 10.152.152.255
EOF

# Restart networking
sudo systemctl restart networking
```

### Step 3.3: Configure Tor

**Create `/etc/tor/torrc`:**

```bash
sudo tee /etc/tor/torrc > /dev/null <<'EOF'
# Tor Gateway Configuration for ARM64
# Based on Whonix Gateway design

## Transparent Proxy
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 10.152.152.10:9040 IsolateClientAddr IsolateSOCKSAuth IsolateClientProtocol IsolateDestPort IsolateDestAddr
DNSPort 10.152.152.10:5353

## SOCKS Ports (for different applications)
# General purpose SOCKS
SocksPort 10.152.152.10:9050 IsolateClientAddr IsolateSOCKSAuth IsolateClientProtocol IsolateDestPort IsolateDestAddr

# Tor Browser
SocksPort 10.152.152.10:9150 IsolateSOCKSAuth KeepAliveIsolateSOCKSAuth

# SSH
SocksPort 10.152.152.10:9151 IsolateDestAddr

# Git
SocksPort 10.152.152.10:9152 IsolateDestAddr

## Control Port (for monitoring)
ControlPort 10.152.152.10:9051
CookieAuthentication 1

## Logging
Log notice file /var/log/tor/notices.log

## Performance
DisableDebuggerAttachment 0

## Connection Settings
ConnLimit 1000

## Circuit Build Timeout
CircuitBuildTimeout 60

## Entry Guards
NumEntryGuards 3

## Descriptor Fetching
FetchDirInfoEarly 1
FetchDirInfoExtraEarly 1

## Bandwidth Management (adjust based on your connection)
RelayBandwidthRate 100 KBytes
RelayBandwidthBurst 200 KBytes

## Exit Policy (we're a client, not a relay)
ExitPolicy reject *:*
ExitPolicy reject6 *:*
EOF

# Set permissions
sudo chmod 644 /etc/tor/torrc

# Create log directory
sudo mkdir -p /var/log/tor
sudo chown debian-tor:debian-tor /var/log/tor
```

### Step 3.4: Configure Firewall (nftables)

**Create `/etc/nftables.conf`:**

```bash
sudo tee /etc/nftables.conf > /dev/null <<'EOF'
#!/usr/sbin/nft -f
# Tor Gateway Firewall for ARM64
# Based on Whonix Gateway design

# Flush all existing rules
flush ruleset

# Define variables
define INTERNAL_NET = 10.152.152.0/24
define GATEWAY_IP = 10.152.152.10
define TOR_UID = debian-tor

table inet filter {
    # Incoming connections
    chain input {
        type filter hook input priority 0; policy drop;
        
        # Accept loopback
        iif lo accept
        
        # Accept established connections
        ct state established,related accept
        
        # Accept SSH from internal network
        iif eth1 ip saddr $INTERNAL_NET tcp dport 22 accept
        
        # Accept Tor ports from internal network
        iif eth1 ip saddr $INTERNAL_NET tcp dport { 9040, 9050, 9051, 9150, 9151, 9152 } accept
        iif eth1 ip saddr $INTERNAL_NET udp dport 5353 accept
        
        # Log and drop everything else
        log prefix "INPUT-DROP: " limit rate 3/minute
    }
    
    # Outgoing connections
    chain output {
        type filter hook output priority 0; policy drop;
        
        # Accept loopback
        oif lo accept
        
        # Accept established connections
        ct state established,related accept
        
        # Allow Tor user to access internet
        oif eth0 skuid $TOR_UID accept
        
        # Allow DNS to internal network (Tor DNSPort)
        oif eth1 ip daddr $INTERNAL_NET udp sport 5353 accept
        
        # Allow responses to internal network
        oif eth1 ip daddr $INTERNAL_NET ct state established,related accept
        
        # Allow DHCP client on external interface
        oif eth0 udp dport 67 accept
        
        # Log and drop everything else
        log prefix "OUTPUT-DROP: " limit rate 3/minute
    }
    
    # Forwarding (should be none, but explicit drop)
    chain forward {
        type filter hook forward priority 0; policy drop;
        log prefix "FORWARD-DROP: " limit rate 3/minute
    }
}

# NAT table for transparent proxy
table ip nat {
    chain prerouting {
        type nat hook prerouting priority -100; policy accept;
        
        # Redirect DNS from internal network to Tor DNSPort
        iif eth1 udp dport 53 redirect to :5353
        
        # Redirect TCP from internal network to Tor TransPort
        iif eth1 tcp flags syn / syn,rst redirect to :9040
    }
    
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        # No NAT needed - Tor handles everything
    }
}
EOF

# Set permissions
sudo chmod 644 /etc/nftables.conf

# Enable nftables service
sudo systemctl enable nftables
sudo systemctl restart nftables

# Verify rules loaded
sudo nft list ruleset
```

### Step 3.5: Enable IP Forwarding

```bash
# Enable IPv4 forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/99-tor-gateway.conf

# Disable IPv6 (Tor doesn't support it well yet)
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-tor-gateway.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-tor-gateway.conf

# Apply settings
sudo sysctl -p /etc/sysctl.d/99-tor-gateway.conf
```

### Step 3.6: Start Tor

```bash
# Start Tor service
sudo systemctl start tor

# Enable on boot
sudo systemctl enable tor

# Check status
sudo systemctl status tor

# Monitor logs
sudo tail -f /var/log/tor/notices.log

# Wait for "Bootstrapped 100%: Done" message
```

---

## 📋 **Phase 4: Configure Secured Workstation**

### Step 4.1: Configure Network

**Edit `/etc/network/interfaces` on Workstation:**

```bash
sudo tee /etc/network/interfaces > /dev/null <<EOF
# Loopback interface
auto lo
iface lo inet loopback

# Internal interface (to Gateway)
auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
EOF

# Restart networking
sudo systemctl restart networking

# Test connectivity to Gateway
ping -c 3 10.152.152.10
```

### Step 4.2: Configure DNS

```bash
# Edit /etc/resolv.conf
echo "nameserver 10.152.152.10" | sudo tee /etc/resolv.conf

# Make it immutable (prevent DHCP from overwriting)
sudo chattr +i /etc/resolv.conf
```

### Step 4.3: Install Desktop Environment

```bash
# Install minimal Xfce desktop
sudo apt install -y \
    xfce4 \
    xfce4-goodies \
    lightdm \
    firefox-esr \
    curl \
    wget \
    git \
    vim \
    htop

# Enable display manager
sudo systemctl enable lightdm
sudo systemctl start lightdm
```

### Step 4.4: Install Tor Browser (ARM64 Native)

```bash
# Download Tor Browser for macOS (will run via QEMU user mode if needed)
# OR use torbrowser-launcher

# Install dependencies
sudo apt install -y torbrowser-launcher

# As regular user, launch once to download
torbrowser-launcher

# This will download ARM64-compatible Tor Browser
```

**Alternative: Manual Installation**

```bash
# Download latest ARM64 Tor Browser
cd ~/Downloads
wget https://www.torproject.org/dist/torbrowser/15.0.2/tor-browser-linux-arm64-15.0.2.tar.xz

# Extract
tar -xf tor-browser-linux-arm64-15.0.2.tar.xz

# Move to opt
sudo mv tor-browser ~/tor-browser

# Create launcher
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/tor-browser.desktop <<EOF
[Desktop Entry]
Name=Tor Browser
Exec=/home/user/tor-browser/Browser/start-tor-browser
Icon=/home/user/tor-browser/Browser/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;Security;
EOF

# Make executable
chmod +x ~/tor-browser/Browser/start-tor-browser
```

### Step 4.5: Configure Tor Browser to Use Gateway SOCKS

**Edit `~/tor-browser/Browser/TorBrowser/Data/Tor/torrc`:**

```bash
# Disable local Tor (use Gateway's Tor instead)
# Comment out all SocksPort/ControlPort lines

# Add:
Socks5Proxy 10.152.152.10:9150
```

**OR use environment variable:**

```bash
# Create wrapper script
cat > ~/start-tor-browser-via-gateway.sh <<'EOF'
#!/bin/bash
export TOR_SOCKS_HOST="10.152.152.10"
export TOR_SOCKS_PORT="9150"
~/tor-browser/Browser/start-tor-browser "$@"
EOF

chmod +x ~/start-tor-browser-via-gateway.sh
```

---

## 📋 **Phase 5: Testing & Verification**

### Test 5.1: Check IP Address

```bash
# From Workstation, check public IP
curl --socks5 10.152.152.10:9050 https://check.torproject.org/api/ip

# Should return Tor exit node IP, not your real IP
```

### Test 5.2: DNS Leak Test

```bash
# From Workstation
nslookup google.com

# Should show:
# Server: 10.152.152.10
# Address: 10.152.152.10#53
```

### Test 5.3: Verify No Direct Internet

```bash
# From Workstation, try direct connection (should fail)
curl https://google.com --interface eth0

# Should timeout or fail (all traffic forced through Gateway)
```

### Test 5.4: Tor Browser Check

1. Open Tor Browser
2. Visit https://check.torproject.org
3. Should say: "Congratulations. This browser is configured to use Tor."
4. Check IP: https://whatismyipaddress.com
5. Should show Tor exit node, not your real IP

### Test 5.5: Circuit Inspection

```bash
# On Gateway, monitor Tor
sudo tail -f /var/log/tor/notices.log

# Should see circuit building messages
```

---

## 📋 **Phase 6: Hardening & Anti-Forensics**

### Step 6.1: macOS Host Hardening

```bash
# Disable swap (requires SIP disabled - be careful!)
# Boot to Recovery Mode (hold Power button)
# In Terminal:
csrutil disable

# Reboot, then:
sudo nvram boot-args="vm_compressor=2"
sudo pmset -a hibernatemode 0
sudo rm -f /private/var/vm/sleepimage

# Disable Spotlight for VMs
sudo mdutil -i off ~/Parallels/

# Enable FileVault
# System Settings → Privacy & Security → FileVault → Turn On
```

### Step 6.2: VM Snapshot Mode

```bash
# In Parallels, for each VM:
# VM → Configure → Security → Enable "Discard changes on shutdown"

# This makes VMs stateless - nothing persists between reboots
```

### Step 6.3: RAM Disk for Workstation (Optional)

```bash
# Create RAM disk for /tmp and /home/user/Downloads
echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0" | sudo tee -a /etc/fstab
echo "tmpfs /home/user/Downloads tmpfs defaults,noatime,size=2G,uid=1000,gid=1000 0 0" | sudo tee -a /etc/fstab

# Mount
sudo mount -a
```

### Step 6.4: Disable Unnecessary Services

```bash
# On both VMs
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon

# On Workstation only
sudo systemctl mask tor  # Don't run local Tor
```

---

## 📋 **Phase 7: Optional Enhancements**

### Enhancement 7.1: Install Additional Security Tools

```bash
# On Workstation
sudo apt install -y \
    keepassxc \        # Password manager
    kleopatra \        # GPG key manager
    thunderbird \      # Email client
    mat2 \             # Metadata removal tool
    bleachbit \        # Secure file deletion
    onionshare         # Secure file sharing
```

### Enhancement 7.2: Add Multiple Tor Circuits

**Modify `/etc/tor/torrc` on Gateway:**

```bash
# Add circuit isolation for different activities
SocksPort 10.152.152.10:9160 IsolateSOCKSAuth # Banking
SocksPort 10.152.152.10:9161 IsolateSOCKSAuth # Research
SocksPort 10.152.152.10:9162 IsolateSOCKSAuth # Social media
```

### Enhancement 7.3: Tor Bridges (If Needed)

```bash
# If Tor is blocked in your region, add bridges
# Get bridges from https://bridges.torproject.org

# Add to /etc/tor/torrc:
UseBridges 1
Bridge obfs4 [bridge address]:[port] [fingerprint] ...
```

### Enhancement 7.4: Monitoring Dashboard

```bash
# Install on Gateway
sudo apt install -y nyx  # Tor controller

# Run to monitor Tor
sudo -u debian-tor nyx
```

---

## 📋 **Phase 8: Documentation & Backup**

### Step 8.1: Document Configuration

Create `/home/user/SETUP_NOTES.md` on each VM with:
- Network configuration
- Installed packages
- Custom configurations
- Troubleshooting steps

### Step 8.2: Create VM Snapshots

```bash
# In Parallels:
# VM → Manage Snapshots → Take Snapshot
# Name: "Clean Install - Tor Gateway - [DATE]"
# Name: "Clean Install - Workstation - [DATE]"
```

### Step 8.3: Export Configuration

```bash
# On Gateway
sudo tar czf ~/gateway-config-backup.tar.gz \
    /etc/tor/torrc \
    /etc/nftables.conf \
    /etc/network/interfaces \
    /etc/sysctl.d/

# Copy to host
# Parallels → VM → Actions → Share File
```

---

## 🔧 **Troubleshooting**

### Issue: Tor Won't Start

```bash
# Check logs
sudo journalctl -u tor -f

# Common causes:
# 1. Port conflicts (check if another process uses 9040/9050)
sudo netstat -tulpn | grep 90

# 2. Permission issues
sudo chown -R debian-tor:debian-tor /var/lib/tor
sudo chmod 700 /var/lib/tor

# 3. Config syntax errors
sudo tor --verify-config
```

### Issue: Workstation Can't Reach Gateway

```bash
# On Gateway, verify interfaces
ip addr show

# Should see:
# eth0: <UP,BROADCAST,RUNNING>
# eth1: <UP,BROADCAST,RUNNING> inet 10.152.152.10/24

# On Workstation, check routing
ip route

# Should show:
# default via 10.152.152.10 dev eth0

# Test connectivity
ping 10.152.152.10
```

### Issue: DNS Not Working

```bash
# On Workstation
cat /etc/resolv.conf
# Should show: nameserver 10.152.152.10

# On Gateway, check Tor DNSPort
sudo netstat -tulpn | grep 5353

# Should show Tor listening on 10.152.152.10:5353

# Test DNS
dig @10.152.152.10 -p 5353 google.com
```

### Issue: Tor Browser Can't Connect

```bash
# Check SOCKS proxy settings in Tor Browser
# Settings → Network Settings
# Should be: Manual proxy, SOCKS Host: 10.152.152.10, Port: 9150

# Test SOCKS from command line
curl --socks5 10.152.152.10:9150 https://check.torproject.org/api/ip
```

---

## ✅ **Success Criteria**

Your setup is complete when:

1. ✅ Gateway VM boots and Tor starts automatically
2. ✅ Workstation VM can only access internet through Gateway
3. ✅ `curl` from Workstation shows Tor exit IP
4. ✅ DNS queries go through Tor
5. ✅ Tor Browser shows "Configured to use Tor"
6. ✅ Direct internet access from Workstation is blocked
7. ✅ VMs persist no data between reboots (if snapshot mode enabled)

---

## 📚 **Next Steps After Setup**

1. **Practice operational security:**
   - Always verify Tor circuit before sensitive activities
   - Use different SOCKS ports for different activities
   - Regularly update both VMs

2. **Monitor for leaks:**
   - Periodically check https://ipleak.net
   - Use https://check.torproject.org
   - Monitor Gateway logs

3. **Consider migration to UTM:**
   - Once stable, consider rebuilding on UTM for better security
   - UTM is open source and recommended by Kicksecure

4. **Expand capabilities:**
   - Add VPN-over-Tor if needed
   - Install additional privacy tools
   - Configure encrypted email

---

**Current Status:** Ready to proceed with Phase 1 - Complete Debian installation on existing Parallels VMs.

**Time Estimate:** 
- Phase 1-2: 1-2 hours
- Phase 3-4: 2-3 hours
- Phase 5-6: 1 hour
- Total: 4-6 hours for complete setup

---

*Build Plan Created: December 7, 2025*  
*Architecture: ARM64 (Apple Silicon)*  
*Validated Against: Whonix design, Kicksecure docs, Tor Project documentation*
