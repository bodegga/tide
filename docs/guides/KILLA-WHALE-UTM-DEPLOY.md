# 🐋 Deploy Killa Whale on macOS with UTM

## Quick Start (5 minutes)

### Step 1: Download Alpine Linux
```bash
cd ~/Documents/Personal-Projects/tide
curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-virt-3.21.0-aarch64.iso
```

### Step 2: Create VM in UTM

1. Open **UTM.app**
2. Click **"Create a New Virtual Machine"**
3. Select **"Virtualize"** (faster on Apple Silicon)
4. Choose **"Linux"**

**VM Settings:**
- **ISO Image**: Select the `alpine-virt-3.21.0-aarch64.iso` you downloaded
- **Memory**: 512 MB (minimum)
- **CPU**: 1 core
- **Storage**: 2 GB
- **Network**: Shared Network

Click **"Save"** and name it **"Tide-Killa-Whale"**

### Step 3: Install Alpine in VM

1. Start the VM
2. Login as `root` (no password at first)
3. Run the installer:

```bash
setup-alpine
```

**Answer the prompts:**
- Keyboard layout: `us`
- Hostname: `tide`
- Network: `eth0`, `dhcp` (press Enter for defaults)
- Root password: `tide` (or whatever you want)
- Timezone: `America/Los_Angeles`
- Mirror: `1` (use default)
- SSH: `openssh`
- Disk: `sda`, `sys` (use entire disk)
- Confirm: `y`

4. When done, type `poweroff`
5. In UTM, remove the CD/ISO from the VM settings
6. Start the VM again

### Step 4: Install Tide Gateway

SSH into the VM or use UTM console:

```bash
# Login as root with your password

# Install git and dependencies
apk add git bash curl

# Clone Tide
cd /root
git clone https://github.com/bodegga/tide.git
cd tide

# Run installer
./tide-install.sh
```

**During install, select:**
- Mode: **3) Killa Whale**
- Security: **1) Standard** (or your preference)
- Network: Accept defaults or customize

### Step 5: Configure Network

The VM needs **2 network interfaces**:
- **eth0** (WAN): Shared/NAT - connects to internet
- **eth1** (LAN): Host-only - your test network for Killa Whale

**In UTM:**
1. Stop the VM
2. Go to VM Settings → Network
3. Add second interface: **"Host Only"**
4. Start VM

### Step 6: Activate Killa Whale

```bash
# In the VM
systemctl start tide-gateway

# Check logs
journalctl -u tide-gateway -f
```

You should see:
```
🐋 Mode: KILLA WHALE - AGGRESSIVE NETWORK TAKEOVER
   ⚠️  MAXIMUM AGGRESSION: All subnet traffic WILL be intercepted
```

## Testing Killa Whale

Create a test client VM in UTM on the **same host-only network**.

The client will:
- Get ARP poisoned immediately
- ALL traffic forced through Tor
- NO escapes possible

---

**Ready to go nuclear?** 🐋🎤

*Named after Andre Nickatina - Bay Area legend*
