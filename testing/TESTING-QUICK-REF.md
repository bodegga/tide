# 🌊 Tide Gateway Testing - Quick Reference

## Your VMs (Ready to Go)

### Gateways (3 available):
- **Tide-Gateway**
- **Tide-Gateway-Auto**  
- **Tide-Gateway-TEMPLATE**

### Test Clients (2 deployed):
- **Tide-Test-Client-1** (512MB RAM, 2GB disk, Alpine Linux)
- **Tide-Test-Client-2** (512MB RAM, 2GB disk, Alpine Linux)

---

## 🚀 Quick Start (30 seconds)

```bash
# 1. Start a gateway
prlctl start Tide-Gateway

# 2. Start a test client
prlctl start Tide-Test-Client-1

# 3. Configure client network
prlctl enter Tide-Test-Client-1
# (Inside client VM after boot - login as root, no password)
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF
rc-service networking start
apk add curl lynx

# 4. Test dashboard
curl http://tide.bodegga.net
```

---

## 🔧 Change Gateway Mode (No Redeploy!)

### Quick Switch (from your Mac):
```bash
# SSH into running gateway
ssh root@10.101.101.10

# Quick mode switch
tide mode killa-whale

# Quick security switch
tide security hardened
```

### Interactive Menu:
```bash
ssh root@10.101.101.10
tide config
```

### Modes Available:
- `proxy` - SOCKS5 only
- `router` - DHCP + transparent proxy
- `killa-whale` - Router + fail-closed (RECOMMENDED)
- `takeover` - Killa Whale + ARP hijacking

### Security Profiles:
- `standard` - Default Tor (fastest)
- `hardened` - Exclude 14-eyes
- `paranoid` - Maximum isolation
- `bridges` - Censorship bypass

---

## 📊 Management Commands

### Gateway Management:
```bash
# Interactive menu
./MANAGE-GATEWAYS.sh

# Quick commands
./MANAGE-GATEWAYS.sh list                           # List all
./MANAGE-GATEWAYS.sh start Tide-Gateway             # Start
./MANAGE-GATEWAYS.sh ssh Tide-Gateway               # SSH in
./MANAGE-GATEWAYS.sh config Tide-Gateway killa-whale hardened
```

### VM Control (prlctl):
```bash
# List all VMs
prlctl list -a

# Start VM
prlctl start <vm-name>

# Stop VM
prlctl stop <vm-name>

# Enter console
prlctl enter <vm-name>

# Get VM info
prlctl list -i <vm-name>
```

---

## 🧪 Test Scenarios

### 1. Basic Dashboard Test
```bash
# In test client (after network setup):
curl http://tide.bodegga.net/api/status
```

### 2. DNS Hijacking Test
```bash
# In test client:
nslookup tide.bodegga.net 10.101.101.10
# Should return: 10.101.101.10

# Try to bypass with Google DNS (Killa Whale blocks this):
nslookup tide.bodegga.net 8.8.8.8
# Should STILL return: 10.101.101.10 (iptables intercepts)
```

### 3. Mode Switch Test
```bash
# SSH into gateway
ssh root@10.101.101.10

# Check current mode
tide status

# Switch mode
tide mode killa-whale

# Verify change
tide status
```

### 4. Multi-Client Test
```bash
# Start both clients
prlctl start Tide-Test-Client-1
prlctl start Tide-Test-Client-2

# Configure both (same network setup)

# Check connected clients from gateway
ssh root@10.101.101.10 'tide clients'
```

---

## 🔍 Troubleshooting

### Client can't get DHCP:
```bash
# Check gateway mode (must be router or killa-whale, not proxy)
ssh root@10.101.101.10 'tide status'

# If mode is proxy, switch:
ssh root@10.101.101.10 'tide mode router'
```

### Dashboard not loading:
```bash
# Check web server running
ssh root@10.101.101.10 'ps aux | grep tide-web-dashboard'

# Restart services
ssh root@10.101.101.10 'tide config'
# Choose restart option
```

### Can't SSH into gateway:
```bash
# Check if running
prlctl list | grep Tide-Gateway

# Use console instead
prlctl enter Tide-Gateway
```

---

## 💡 One-Liners

```bash
# Start everything
prlctl start Tide-Gateway && sleep 10 && prlctl start Tide-Test-Client-1

# Stop everything  
prlctl list | grep running | awk '{print $NF}' | xargs -I {} prlctl stop {}

# Check gateway status remotely
ssh root@10.101.101.10 'tide status'

# Watch status live
watch -n 2 'ssh root@10.101.101.10 "tide status"'

# Quick dashboard check
ssh root@10.101.101.10 'curl -s http://localhost/api/status | head -20'
```

---

## 📚 Documentation

- **VM-MANAGEMENT-GUIDE.md** - Complete VM management guide
- **WEB-DASHBOARD-README.md** - Dashboard features and API
- **QUICK-START.md** - 5-minute setup guide
- **README.md** - Main documentation

---

## 🎯 Your Mission

1. Pick a gateway → `prlctl start Tide-Gateway`
2. Configure it → `./MANAGE-GATEWAYS.sh config Tide-Gateway killa-whale hardened`
3. Start a client → `prlctl start Tide-Test-Client-1`
4. Test dashboard → Access http://tide.bodegga.net from client
5. Switch modes → Try `tide mode router`, then `tide mode killa-whale`
6. Verify no redeploy needed!

---

**Tide Gateway - freedom within the shell** 🌊
