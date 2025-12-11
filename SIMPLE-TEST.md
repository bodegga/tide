# Simple Testing Approach for Tide v1.2.0

## The Problem

- Existing Parallels VMs don't have v1.2.0 code
- QEMU automation is complex for full OS install
- We need to test the new features (web dashboard, mode switching, CLI)

## Simple Solution

**Just update one of your existing gateways with the new scripts!**

---

## Option 1: Update Existing Gateway (Easiest)

### Step 1: Start a gateway

```bash
prlctl start Tide-Gateway
```

### Step 2: Wait for boot, then enter console

```bash
# Wait 30 seconds for boot
sleep 30

# Enter console
prlctl enter Tide-Gateway
```

### Step 3: Get internet access working

```bash
# In the VM console
ping 8.8.8.8

# If no internet, fix DNS:
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### Step 4: Download and run update script

```bash
# In the VM
wget -O /tmp/update.sh https://raw.githubusercontent.com/bodegga/tide/main/UPDATE-TO-V1.2.sh

sh /tmp/update.sh
```

### Step 5: Reboot

```bash
reboot
```

### Step 6: Test new features

```bash
# After reboot, enter console again
prlctl enter Tide-Gateway

# Test CLI
tide status
tide config

# Test web dashboard server
ps aux | grep tide-web-dashboard
netstat -tulpn | grep :80

# Test mode switching
tide mode killa-whale
tide status
```

---

## Option 2: Manual File Copy (If No Internet)

### Step 1: Start HTTP server on your Mac

```bash
cd /Users/abiasi/Documents/Personal-Projects/tide

# Start simple web server
python3 -m http.server 8000
```

### Step 2: Get your Mac's IP

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Step 3: In VM, download files

```bash
# Example if your Mac IP is 192.168.1.100
cd /tmp

wget http://192.168.1.100:8000/scripts/runtime/tide-web-dashboard.py
wget http://192.168.1.100:8000/scripts/runtime/tide-cli.sh
wget http://192.168.1.100:8000/scripts/runtime/tide-config.sh
wget http://192.168.1.100:8000/scripts/runtime/gateway-start.sh

# Install
chmod +x *.py *.sh
mv tide-web-dashboard.py /usr/local/bin/
mv tide-cli.sh /usr/local/bin/
mv tide-config.sh /usr/local/bin/
mv gateway-start.sh /usr/local/bin/

ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide

# Create config
mkdir -p /etc/tide
echo "killa-whale" > /etc/tide/mode
echo "standard" > /etc/tide/security

# Restart services
killall tor dnsmasq python3 2>/dev/null || true
/usr/local/bin/gateway-start.sh &
```

---

## Option 3: Build Fresh VM (Clean Slate)

Use the `auto-install.sh` but modify it to include v1.2.0 features.

**This is what you should do for production**, but for testing, Option 1 or 2 is faster.

---

## What to Test

Once you have an updated gateway:

### ✅ CLI Commands
```bash
tide status          # Should show mode, security, tor status
tide config          # Should show interactive menu
tide mode router     # Should switch modes
tide security hardened  # Should switch security
tide clients         # Should list connected devices
```

### ✅ Web Dashboard
```bash
# Check if running
ps aux | grep tide-web-dashboard

# Check if port 80 is listening
netstat -tulpn | grep :80

# From another machine on same network:
curl http://10.101.101.10
# Should return HTML dashboard
```

### ✅ DNS Hijacking
```bash
# Check dnsmasq config
cat /etc/dnsmasq.conf | grep tide.bodegga.net

# Should see:
# address=/tide.bodegga.net/10.101.101.10
```

### ✅ Mode Switching
```bash
# Switch mode without reboot
tide mode proxy
tide status  # Should show proxy

tide mode killa-whale
tide status  # Should show killa-whale

# Services should restart automatically
```

---

## Recommended: Option 1

**Easiest path:**

1. Boot a gateway VM
2. Download UPDATE-TO-V1.2.sh from GitHub
3. Run it
4. Reboot
5. Test the new features

Takes 5 minutes total.

---

## If Testing Fails

Common issues:

**"tide command not found"**
- Symlink not created
- Fix: `ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide`

**"Web dashboard not running"**
- Script not installed or not executable
- Fix: `chmod +x /usr/local/bin/tide-web-dashboard.py`
- Start: `python3 /usr/local/bin/tide-web-dashboard.py &`

**"Mode switching doesn't work"**
- Config files don't exist
- Fix: `mkdir -p /etc/tide && echo "killa-whale" > /etc/tide/mode`

**"Can't download from GitHub"**
- No internet in VM
- Use Option 2 (HTTP server on Mac)

---

## Bottom Line

You don't need to rebuild VMs or mess with QEMU.

**Just update an existing gateway with the new scripts and test.**

The UPDATE-TO-V1.2.sh script does everything automatically if you have internet access.

If no internet, use the HTTP server method to transfer files.

---

**Time to test:** 5-10 minutes  
**Complexity:** Low  
**Success rate:** High
