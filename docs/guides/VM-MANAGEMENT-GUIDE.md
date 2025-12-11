# Tide Gateway VM Management Guide

## Overview

You have **3 Tide Gateway VMs** and **2 Test Client VMs** ready for testing.

---

## 🌊 Your Tide Gateways

### Existing VMs:
1. **Tide-Gateway** - First gateway (status: stopped)
2. **Tide-Gateway-Auto** - Auto-deployed version (status: stopped)
3. **Tide-Gateway-TEMPLATE** - Template for cloning (status: stopped)

### Test Clients:
1. **Tide-Test-Client-1** - Lightweight Alpine client (512MB RAM, 2GB disk)
2. **Tide-Test-Client-2** - Lightweight Alpine client (512MB RAM, 2GB disk)

---

## 🚀 Quick Start Testing

### 1. Start a Gateway

```bash
# Start any gateway
prlctl start Tide-Gateway

# Or use the management script
./MANAGE-GATEWAYS.sh start Tide-Gateway
```

### 2. Start Test Clients

```bash
# Start both test clients
prlctl start Tide-Test-Client-1
prlctl start Tide-Test-Client-2
```

### 3. Configure Test Client Network

Access the client console:
```bash
prlctl enter Tide-Test-Client-1
```

Inside the client VM (after Alpine boots):
```bash
# Login as root (no password)

# Quick network setup
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Start networking
rc-service networking start

# Install test tools
apk add curl lynx

# Test Tide connection
curl http://tide.bodegga.net/api/status
```

### 4. Test Web Dashboard

From inside test client:
```bash
# Text-based browser
lynx http://tide.bodegga.net

# Or just curl to verify
curl http://tide.bodegga.net | head -50
```

---

## 🔧 Change Gateway Mode (On-The-Fly)

### Method 1: Direct SSH

SSH into running gateway:
```bash
# Get gateway IP first
prlctl list -i Tide-Gateway | grep "IP address"

# SSH in (default password: tide)
ssh root@10.101.101.10

# Quick mode switch
tide mode killa-whale

# Quick security switch
tide security hardened

# Or interactive menu
tide config
```

### Method 2: Remote Configuration

From your Mac (gateway must be running):
```bash
# Use the management script
./MANAGE-GATEWAYS.sh config Tide-Gateway killa-whale hardened
```

### Available Modes:
- **proxy** - SOCKS5 only (manual client config)
- **router** - DHCP + transparent proxy
- **killa-whale** - Router + fail-closed firewall (RECOMMENDED)
- **takeover** - Killa Whale + active ARP hijacking

### Available Security Profiles:
- **standard** - Default Tor (fastest)
- **hardened** - Exclude 14-eyes countries
- **paranoid** - Maximum isolation (slowest)
- **bridges** - Use obfs4 bridges (censorship bypass)

---

## 📊 Management Scripts

### MANAGE-GATEWAYS.sh

Interactive gateway management:

```bash
# Interactive menu
./MANAGE-GATEWAYS.sh

# Quick commands
./MANAGE-GATEWAYS.sh list                  # List all gateways
./MANAGE-GATEWAYS.sh info Tide-Gateway     # Get gateway info
./MANAGE-GATEWAYS.sh start Tide-Gateway    # Start gateway
./MANAGE-GATEWAYS.sh stop Tide-Gateway     # Stop gateway
./MANAGE-GATEWAYS.sh ssh Tide-Gateway      # SSH into gateway

# Configure remotely
./MANAGE-GATEWAYS.sh config Tide-Gateway killa-whale hardened

# Rename gateway
./MANAGE-GATEWAYS.sh label Tide-Gateway Tide-Production
```

### DEPLOY-TEST-CLIENTS.sh

Deploy more test clients:

```bash
# Edit NUM_VMS=2 to create more
./DEPLOY-TEST-CLIENTS.sh
```

---

## 🎯 Testing Scenarios

### Scenario 1: Web Dashboard Test

**Goal**: Verify tide.bodegga.net loads from client

1. Start gateway: `prlctl start Tide-Gateway`
2. Start client: `prlctl start Tide-Test-Client-1`
3. Enter client: `prlctl enter Tide-Test-Client-1`
4. Setup network (see Quick Start above)
5. Test: `curl http://tide.bodegga.net`
6. Expected: HTML dashboard loads

### Scenario 2: Mode Switching Test

**Goal**: Switch modes without redeploying

1. Start gateway with router mode
2. SSH in: `ssh root@10.101.101.10`
3. Switch mode: `tide mode killa-whale`
4. Verify: `tide status`
5. Expected: Mode changes, services restart

### Scenario 3: Multi-Client Test

**Goal**: Multiple clients connecting simultaneously

1. Start gateway
2. Start both test clients
3. Configure network on both
4. Both access: `curl http://tide.bodegga.net/api/status`
5. Check clients list: `ssh root@10.101.101.10 'tide clients'`
6. Expected: See 2 clients listed

### Scenario 4: Killa Whale DNS Hijacking Test

**Goal**: Verify aggressive DNS enforcement

1. Start gateway with killa-whale mode
2. Start client
3. In client, try to use external DNS:
   ```bash
   # Try to bypass with Google DNS
   nslookup tide.bodegga.net 8.8.8.8
   # Should still resolve to 10.101.101.10 (iptables intercepts)
   ```
4. Expected: DNS hijacking works regardless of DNS server

---

## 🔍 Identifying Your Gateways

Since you have 3 gateways and aren't sure which is which:

### Option 1: Start Each and Check

```bash
# Start one at a time
prlctl start Tide-Gateway

# Check its configuration
./MANAGE-GATEWAYS.sh info Tide-Gateway

# SSH in and check
ssh root@10.101.101.10
tide status

# Stop it
prlctl stop Tide-Gateway

# Repeat for others
```

### Option 2: Label Them

```bash
# Rename for clarity
./MANAGE-GATEWAYS.sh label Tide-Gateway Tide-Testing
./MANAGE-GATEWAYS.sh label Tide-Gateway-Auto Tide-Development  
./MANAGE-GATEWAYS.sh label Tide-Gateway-TEMPLATE Tide-Template
```

### Option 3: Check Description

```bash
# View full VM info
prlctl list -i Tide-Gateway

# Look for:
# - Description field
# - Date created
# - Configuration details
```

---

## 🛠 Common Operations

### Start Everything for Testing

```bash
# Start a gateway
prlctl start Tide-Gateway

# Start both test clients
prlctl start Tide-Test-Client-1
prlctl start Tide-Test-Client-2

# Wait a moment, then check status
prlctl list
```

### Stop Everything

```bash
# Stop all running VMs
prlctl list | grep running | awk '{print $NF}' | while read vm; do
    prlctl stop "$vm"
done
```

### Clean Up Test Clients

```bash
# Remove test clients (if needed)
prlctl stop Tide-Test-Client-1
prlctl delete Tide-Test-Client-1

prlctl stop Tide-Test-Client-2
prlctl delete Tide-Test-Client-2
```

### Clone a Gateway

```bash
# Clone from template
prlctl clone Tide-Gateway-TEMPLATE --name Tide-Testing-v2

# Or clone any gateway
prlctl clone Tide-Gateway --name Tide-Backup
```

---

## 📋 Test Checklist

### Basic Functionality
- [ ] Gateway starts successfully
- [ ] Client gets DHCP IP (10.101.101.xxx)
- [ ] Client can access http://tide.bodegga.net
- [ ] Dashboard shows correct status
- [ ] Tor connectivity works

### Mode Switching
- [ ] Can switch from router to killa-whale
- [ ] Can switch from killa-whale to proxy
- [ ] Services restart correctly
- [ ] Configuration persists after restart

### Web Dashboard
- [ ] Dashboard loads in text browser (lynx)
- [ ] Status shows correct mode
- [ ] Exit IP is visible
- [ ] Client count is accurate
- [ ] Auto-refresh works (check 30s later)

### DNS Hijacking
- [ ] tide.bodegga.net resolves to 10.101.101.10
- [ ] Works even with external DNS configured
- [ ] iptables enforcement active (killa-whale mode)

### Multi-Client
- [ ] Multiple clients can connect
- [ ] All show in 'tide clients' output
- [ ] All can access dashboard
- [ ] No IP conflicts

---

## 🐛 Troubleshooting

### Client Can't Get DHCP

**Check gateway dnsmasq:**
```bash
ssh root@10.101.101.10
ps aux | grep dnsmasq
```

**Check gateway mode:**
```bash
tide status
# If mode is "proxy", switch to router or killa-whale
tide mode router
```

### tide.bodegga.net Not Resolving

**Check DNS from client:**
```bash
# In client VM
nslookup tide.bodegga.net 10.101.101.10
# Should return: 10.101.101.10
```

**Check dnsmasq config:**
```bash
# In gateway
ssh root@10.101.101.10
cat /etc/dnsmasq.conf | grep tide.bodegga.net
# Should see: address=/tide.bodegga.net/10.101.101.10
```

### Dashboard Not Loading

**Check web server:**
```bash
ssh root@10.101.101.10
ps aux | grep tide-web-dashboard
netstat -tulpn | grep :80
```

**Restart services:**
```bash
tide config
# Choose restart option
```

### Can't SSH Into Gateway

**Check if VM is running:**
```bash
prlctl list | grep Tide-Gateway
```

**Check IP address:**
```bash
prlctl list -i Tide-Gateway | grep "IP address"
```

**Try console instead:**
```bash
prlctl enter Tide-Gateway
```

---

## 💡 Pro Tips

### Quick Test Loop

```bash
# One-liner to start everything
prlctl start Tide-Gateway && sleep 10 && prlctl start Tide-Test-Client-1

# Watch gateway status
watch -n 2 'ssh root@10.101.101.10 "tide status"'
```

### Save Configurations

After configuring a gateway perfectly:
```bash
# Clone it as a template
prlctl clone Tide-Gateway --name Tide-Perfect-Config

# Export as template
prlctl clone Tide-Gateway --name Tide-Template-v1 --template
```

### Automated Testing Script

```bash
#!/bin/bash
# test-dashboard.sh

echo "Starting gateway..."
prlctl start Tide-Gateway
sleep 15

echo "Starting client..."
prlctl start Tide-Test-Client-1
sleep 10

echo "Testing dashboard..."
ssh root@10.101.101.10 'tide status'

echo "Done!"
```

---

## 📚 Related Documentation

- **WEB-DASHBOARD-README.md** - Complete dashboard features
- **QUICK-START.md** - 5-minute deployment guide
- **README.md** - Main project documentation
- **CHANGELOG.md** - Version history

---

## 🎯 Next Steps

1. **Start a gateway**: `prlctl start Tide-Gateway`
2. **Configure your preferred mode**: `./MANAGE-GATEWAYS.sh config Tide-Gateway killa-whale hardened`
3. **Start test clients**: `prlctl start Tide-Test-Client-1`
4. **Test dashboard**: Access from client and verify functionality
5. **Label your gateways**: Give them meaningful names based on use case

---

**Tide Gateway - freedom within the shell** 🌊

*VM Management Guide v1.2.0*
