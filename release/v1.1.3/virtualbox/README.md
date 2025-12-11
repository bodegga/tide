# Tide Gateway v1.1.3 - Oracle VirtualBox

## Quick Start

### Import OVA

1. **Open VirtualBox**
   - Launch Oracle VM VirtualBox Manager

2. **Import Appliance**
   - **File** → **Import Appliance**
   - Click **Choose** and select `Tide-Gateway-v1.1.3-VirtualBox-aarch64.ova`
   - Click **Next**
   
3. **Review Settings**
   - Name: Tide Gateway
   - Guest OS: Linux 2.6 / 3.x / 4.x / 5.x (64-bit)
   - CPU: 1
   - RAM: 512 MB
   - Network Adapter 1: NAT or Bridged
   - Click **Import**

4. **Add Second Network Adapter**
   - Right-click VM → **Settings**
   - **Network** → **Adapter 2**
   - ✓ **Enable Network Adapter**
   - Attached to: **Host-only Adapter**
   - Name: `vboxnet0` (or create new)
   - Click **OK**

5. **Start VM**
   - Select VM → Click **Start**
   - Console window opens

## Network Configuration

### Host-Only Network Setup

VirtualBox requires a Host-only network adapter:

**Create Host-Only Adapter:**
1. **File** → **Host Network Manager** (or **Tools** → **Network**)
2. Click **Create**
3. Configure adapter:
   - **IPv4 Address:** `10.101.101.1`
   - **IPv4 Network Mask:** `255.255.255.0`
   - **DHCP Server:** Disable
4. Click **Apply**

**Via Command Line:**
```bash
# Create host-only network
VBoxManage hostonlyif create

# Configure IP
VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.101.101.1 --netmask 255.255.255.0
```

### Network Adapter Configuration

| Adapter | Type | Purpose | IP |
|---------|------|---------|-----|
| **Adapter 1** | NAT or Bridged | Internet (WAN) | DHCP |
| **Adapter 2** | Host-only (vboxnet0) | Attack Network (LAN) | 10.101.101.10 |

## Default Credentials

```
Username: root
Password: tide
```

**⚠️ CHANGE DEFAULT PASSWORD!**
```bash
passwd  # Set new password
```

## Connecting Devices

### Connect Host Machine

Your host already has access via the host-only adapter:

```bash
# Test connectivity
ping 10.101.101.10

# SSH to gateway
ssh root@10.101.101.10  # Password: tide

# Route traffic through Tide
# Linux/macOS:
sudo route add default gw 10.101.101.10 vboxnet0
echo "nameserver 10.101.101.10" | sudo tee /etc/resolv.conf

# Windows (PowerShell as Admin):
route add 0.0.0.0 mask 0.0.0.0 10.101.101.10 metric 10
```

### Connect Another VM

1. Create new VM in VirtualBox
2. **Network Adapter:** Set to **Host-only Adapter (vboxnet0)**
3. Inside VM:
   - IP: `10.101.101.100`
   - Gateway: `10.101.101.10`
   - DNS: `10.101.101.10`

## Verification

### Check VM Status

From VirtualBox Manager:
- VM should show **Running** status

### Access Console

- Double-click VM in sidebar
- Or: Right-click → **Show**

### Test Tor

From gateway console:
```bash
# Check Tor status
rc-service tor status

# Test Tor connection
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```

Expected output:
```json
{"IsTor":true,"IP":"<tor-exit-ip>"}
```

### Test from Host

```bash
# Set gateway as DNS
sudo sh -c 'echo "nameserver 10.101.101.10" > /etc/resolv.conf'

# Test Tor exit
curl https://check.torproject.org/api/ip
```

Should also return `"IsTor":true`

## Troubleshooting

### OVA Import Fails

**Error:** "Failed to import appliance"

**Solution:**
1. Verify file integrity:
   ```bash
   shasum -a 256 -c Tide-Gateway-v1.1.3-VirtualBox-aarch64.ova.sha256
   ```
2. Try importing VDI directly:
   - Extract OVA: `tar -xvf Tide-Gateway-v*.ova`
   - Create new VM manually
   - Attach extracted VDI file

### No Host-Only Network

**Error:** "Host-only network not found"

**Solution:**
```bash
# Create network
VBoxManage hostonlyif create

# List networks
VBoxManage list hostonlyifs

# Configure IP
VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.101.101.1
```

### VM Won't Boot

**Check:**
1. Virtualization enabled in BIOS (VT-x/AMD-V)
2. Secure Boot disabled
3. Sufficient RAM allocated

**Fix:**
```bash
# Check VM config
VBoxManage showvminfo "Tide Gateway"

# Disable PAE/NX if issues
VBoxManage modifyvm "Tide Gateway" --pae off
```

### No Network Connectivity

**Check adapters:**
```bash
VBoxManage showvminfo "Tide Gateway" | grep NIC
```

**Re-attach adapters:**
```bash
# Adapter 1 (NAT)
VBoxManage modifyvm "Tide Gateway" --nic1 nat

# Adapter 2 (Host-only)
VBoxManage modifyvm "Tide Gateway" --nic2 hostonly --hostonlyadapter2 vboxnet0
```

### Can't SSH to Gateway

1. Verify host-only network has correct IP
2. Check firewall on host
3. Ensure SSH is running in VM:
   ```bash
   # From VM console
   rc-service sshd status
   rc-service sshd start
   ```

## Advanced Configuration

### Increase Disk Size

```bash
# Stop VM
VBoxManage controlvm "Tide Gateway" poweroff

# Resize VDI (e.g., to 4GB = 4096 MB)
VBoxManage modifyhd "Tide Gateway.vdi" --resize 4096

# Start VM
VBoxManage startvm "Tide Gateway"

# Inside VM, resize filesystem
ssh root@10.101.101.10
resize2fs /dev/sda1
```

### Add More RAM/CPU

```bash
# Set 1GB RAM
VBoxManage modifyvm "Tide Gateway" --memory 1024

# Set 2 CPUs
VBoxManage modifyvm "Tide Gateway" --cpus 2
```

### Clone VM

**Via GUI:**
- Right-click VM → **Clone**
- Choose **Full clone** or **Linked clone**
- Click **Clone**

**Via CLI:**
```bash
VBoxManage clonevm "Tide Gateway" --name "Tide Gateway 2" --register
```

### Enable Headless Mode

```bash
# Start without GUI
VBoxManage startvm "Tide Gateway" --type headless

# Connect via VNC
VBoxManage modifyvm "Tide Gateway" --vrde on --vrdeport 5900
```

### Export OVA

```bash
# Export VM to OVA
VBoxManage export "Tide Gateway" --output tide-gateway-export.ova
```

## VirtualBox Extension Pack

For USB 2.0/3.0 support (optional):

1. Download Extension Pack: https://www.virtualbox.org/wiki/Downloads
2. **File** → **Preferences** → **Extensions**
3. Click **+** and select downloaded pack
4. Click **Install**

## CLI Usage

### Start/Stop VM

```bash
# Start
VBoxManage startvm "Tide Gateway"

# Start headless
VBoxManage startvm "Tide Gateway" --type headless

# Pause
VBoxManage controlvm "Tide Gateway" pause

# Resume
VBoxManage controlvm "Tide Gateway" resume

# Stop (save state)
VBoxManage controlvm "Tide Gateway" savestate

# Power off
VBoxManage controlvm "Tide Gateway" poweroff
```

### View VM Info

```bash
# List all VMs
VBoxManage list vms

# Show VM details
VBoxManage showvminfo "Tide Gateway"

# Show running VMs
VBoxManage list runningvms
```

## Performance Tips

1. **Enable VT-x/AMD-V** in BIOS for hardware virtualization
2. **Allocate more RAM** if running intensive Tor circuits (1GB recommended)
3. **Use SSD storage** for VM disk files
4. **Disable unnecessary services** in guest OS
5. **Use paravirtualization** - Already configured (VirtIO)

## File Information

**Filename:** `Tide-Gateway-v1.1.3-VirtualBox-aarch64.ova`  
**Format:** OVA (Open Virtualization Archive)  
**Size:** ~200MB  
**Checksum:** See `.sha256` file

**Alternative:** `Tide-Gateway-v1.1.3-VirtualBox-aarch64.vdi` (VDI only, no OVA)

**VM Specifications:**
- OS: Alpine Linux 3.21
- Disk: 2GB (dynamically allocated)
- RAM: 512MB (adjustable)
- CPU: 1 vCPU (adjustable)
- Network: 2 adapters required
- Chipset: ICH9
- Graphics: VMSVGA

## Support

- **Documentation:** https://github.com/bodegga/tide
- **Issues:** https://github.com/bodegga/tide/issues
- **VirtualBox Manual:** https://www.virtualbox.org/manual/

---

**Tide Gateway v1.1.3** | Transparent Internet Defense Engine  
**Bodegga Company** | Network Security | Petaluma, CA
