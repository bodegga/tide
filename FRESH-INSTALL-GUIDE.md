# Tide Gateway - Fresh Install Guide

## Create Clean Parallels VM

### Step 1: Delete the fucked VM
1. Open Parallels
2. Delete "Tide-Gateway" VM
3. Empty trash

### Step 2: Create fresh Alpine VM
1. **New VM** → Install from ISO
2. **ISO**: `alpine-standard-3.21.2-aarch64.iso`
3. **Name**: `Tide-Gateway-Clean`
4. **Networks**:
   - Adapter 0: **Shared Network** (internet)
   - Adapter 1: **Host-Only Network** (attack network)
5. **Start VM**

### Step 3: Run setup-alpine
Boot the VM and login as `root` (no password), then:

```bash
setup-alpine
```

Answer prompts:
- Keyboard: `us` / `us`
- Hostname: `tide`
- Interface: `eth0`
- IP: `dhcp`
- Manual config: `n`
- Root password: `tide`
- Timezone: `UTC` (or your preference)
- Proxy: `none`
- Mirror: `1` (auto-detect)
- SSH: `openssh`
- Disk: `sda`
- Use: `sys`
- Erase: `y`

Wait for install, then:
```bash
reboot
```

### Step 4: Install Tide Gateway

After reboot, login as `root` / `tide`:

```bash
apk add wget
wget -O install.sh https://raw.githubusercontent.com/bodegga/tide/main/CLEAN-DEPLOY.sh
sh install.sh
```

**OR** if you can type it:

```bash
apk add curl git
git clone https://github.com/bodegga/tide.git
cd tide
sh CLEAN-DEPLOY.sh
```

### Step 5: Verify it works

```bash
rc-service tide-gateway start
tail -f /var/log/tide/gateway.log
```

You should see:
- ✅ Firewall configured
- ✅ dnsmasq starting
- ✅ ARP poisoning active
- ✅ Tor starting

### Step 6: Export VM as template

1. Shutdown VM: `poweroff`
2. In Parallels: Right-click VM → **Export**
3. Save as: `Tide-Gateway-Template.pvm`
4. Upload to cloud storage or keep locally

## Redeployment (Clean Shot)

Next time you need Killa Whale:

1. Import `Tide-Gateway-Template.pvm`
2. Start VM
3. Done. It's running.

**OR** clone the VM in Parallels (instant).

## Troubleshooting

If something fails:

```bash
# Check what's wrong
dmesg | tail
/usr/local/bin/tide-gateway

# Check network
ip addr
ip link set eth1 up

# Check Tor
ls -la /var/lib/tor
chown -R tor:tor /var/lib/tor

# Restart
rc-service tide-gateway restart
```

## One-Command Deploy (for future)

After we have the template working, create this:

```bash
#!/bin/bash
# deploy-tide.sh - One command Killa Whale deployment

curl -L https://github.com/bodegga/tide/releases/download/v1.0/tide-gateway.pvm.zip -o tide.zip
unzip tide.zip
open tide-gateway.pvm  # Imports to Parallels
# Done!
```

---

**Tonight's goal**: Get one clean working VM, export it, never fuck with Alpine setup again.

