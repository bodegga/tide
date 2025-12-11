# Tide Gateway v1.1.3 - Proxmox VE

## Quick Start

### Upload Image to Proxmox

1. **Upload QCOW2 to Proxmox Host**
   ```bash
   # From your local machine
   scp Tide-Gateway-v1.1.3-Proxmox-aarch64.qcow2 root@proxmox:/var/lib/vz/images/
   ```

2. **Create VM via CLI**
   ```bash
   # SSH to Proxmox host
   ssh root@proxmox

   # Create VM
   qm create 100 \
     --name tide-gateway \
     --memory 512 \
     --cores 1 \
     --net0 virtio,bridge=vmbr0 \
     --net1 virtio,bridge=vmbr1 \
     --bootdisk scsi0
   
   # Import disk
   qm importdisk 100 /var/lib/vz/images/Tide-Gateway-v1.1.3-Proxmox-aarch64.qcow2 local-lvm
   
   # Attach disk to VM
   qm set 100 --scsi0 local-lvm:vm-100-disk-0
   
   # Set boot order
   qm set 100 --boot c --bootdisk scsi0
   
   # Start VM
   qm start 100
   ```

### Create VM via Web UI

1. **Upload Image**
   - Login to Proxmox web interface
   - Select storage (e.g., `local`)
   - **Upload** → Select QCOW2 file

2. **Create VM**
   - Click **Create VM**
   - **General:**
     - VM ID: `100` (or any available ID)
     - Name: `tide-gateway`
   - **OS:**
     - Do not use any media
     - Guest OS: Linux 5.x - 2.6 Kernel
   - **System:**
     - Leave defaults (QEMU/KVM)
   - **Disks:**
     - Delete default disk
     - **Add** → **Use existing disk**
     - Select uploaded QCOW2
   - **CPU:**
     - Cores: 1
   - **Memory:**
     - 512 MB
   - **Network:**
     - **Bridge 1**: vmbr0 (internet)
     - **Add** → **Bridge 2**: vmbr1 (attack network)
   - Click **Finish**

3. **Start VM**
   - Select VM in sidebar
   - Click **Start**
   - Open **Console**

## Network Configuration

### Bridge Setup

Tide Gateway requires 2 network bridges:

| Bridge | Purpose | Configuration |
|--------|---------|---------------|
| **vmbr0** | WAN (Internet) | Physical NIC, DHCP | 
| **vmbr1** | LAN (Attack Network) | Virtual only, no physical NIC |

### Create Attack Network Bridge

**Via Web UI:**
1. **Datacenter** → **Node** → **Network**
2. **Create** → **Linux Bridge**
3. Name: `vmbr1`
4. IP/CIDR: `10.101.101.1/24` (optional, for host access)
5. Autostart: ✓
6. Bridge ports: (leave empty)
7. Click **Create**
8. Click **Apply Configuration**

**Via CLI:**
```bash
# Edit network config
nano /etc/network/interfaces

# Add bridge
auto vmbr1
iface vmbr1 inet static
    address 10.101.101.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0

# Reload networking
ifreload -a
```

### Assign VM to Bridges

```bash
# Add WAN interface (vmbr0)
qm set 100 --net0 virtio,bridge=vmbr0

# Add LAN interface (vmbr1)
qm set 100 --net1 virtio,bridge=vmbr1
```

## Default Credentials

```
Username: root
Password: tide
```

**⚠️ CHANGE DEFAULT PASSWORD!**

```bash
# SSH to gateway
ssh root@10.101.101.10  # Password: tide
passwd  # Set new password
```

## Connecting Devices

### Attach VM to Attack Network

1. Create new VM or container
2. **Network:** Add interface on `vmbr1`
3. **IP Config:**
   - IP: `10.101.101.100` (or any in range)
   - Gateway: `10.101.101.10`
   - DNS: `10.101.101.10`

### From Proxmox Host

If you gave vmbr1 an IP (`10.101.101.1`):

```bash
# Route traffic through Tide
ip route add default via 10.101.101.10 dev vmbr1 metric 100

# Use Tide DNS
echo "nameserver 10.101.101.10" > /etc/resolv.conf
```

## Verification

### Check VM Status

```bash
qm status 100  # Should show "running"
```

### Access Console

**Web UI:**
- Select VM → **Console** (noVNC)

**CLI:**
```bash
qm terminal 100
```

### Test Tor

From gateway console:
```bash
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```

Expected output:
```json
{"IsTor":true,"IP":"<tor-exit-ip>"}
```

## Troubleshooting

### VM Won't Start

```bash
# Check VM config
qm config 100

# View logs
tail -f /var/log/pve/tasks/active

# Check disk import
ls -lh /var/lib/vz/images/100/
```

### No Network Connectivity

```bash
# Check bridges
ip link show vmbr0
ip link show vmbr1

# Check VM network config
qm config 100 | grep net

# Restart networking in VM
qm console 100
# Then inside VM:
rc-service networking restart
```

### Tor Not Running

```bash
# SSH to gateway
ssh root@10.101.101.10

# Check Tor status
rc-service tor status

# View logs
tail -f /var/log/messages | grep tor

# Restart Tor
rc-service tor restart
```

### Can't Access Gateway from VMs

1. Verify vmbr1 bridge exists and is active
2. Check firewall rules on Proxmox host
3. Verify VM network interface is on vmbr1
4. Test connectivity: `ping 10.101.101.10`

## Advanced Configuration

### Increase Disk Size

```bash
# Resize disk (e.g., to 4GB)
qm resize 100 scsi0 +2G

# Inside VM, resize partition
ssh root@10.101.101.10
resize2fs /dev/sda1  # Or appropriate partition
```

### Add More RAM/CPU

```bash
# Set 1GB RAM
qm set 100 --memory 1024

# Set 2 CPUs
qm set 100 --cores 2

# Restart VM
qm stop 100
qm start 100
```

### Clone for Multiple Gateways

```bash
# Full clone
qm clone 100 101 --name tide-gateway-2

# Linked clone (uses less disk space)
qm clone 100 102 --name tide-gateway-3 --full 0
```

### Enable Auto-Start

```bash
# Start VM when Proxmox boots
qm set 100 --onboot 1
```

## Performance Tips

1. **Use local-lvm storage** - Faster than NFS/CIFS
2. **Enable VirtIO drivers** - Already configured in image
3. **Allocate sufficient RAM** - 512MB minimum, 1GB recommended for heavy use
4. **Use SSD storage** - Dramatically improves Tor performance

## Migration

### Move to Different Proxmox Node

```bash
# Offline migration
qm migrate 100 node2

# Live migration (requires shared storage)
qm migrate 100 node2 --online
```

### Backup VM

```bash
# Create backup
vzdump 100 --mode snapshot --compress gzip

# Restore from backup
qmrestore /var/lib/vz/dump/vzdump-qemu-100-*.vma.gz 100
```

## File Information

**Filename:** `Tide-Gateway-v1.1.3-Proxmox-aarch64.qcow2`  
**Format:** QCOW2 (QEMU Copy-On-Write v2)  
**Size:** ~150MB  
**Checksum:** See `.sha256` file

**VM Specifications:**
- OS: Alpine Linux 3.21
- Disk: 2GB (thin provisioned)
- RAM: 512MB (adjustable)
- CPU: 1 vCPU (adjustable)
- Network: 2 interfaces required

## Support

- **Documentation:** https://github.com/bodegga/tide
- **Issues:** https://github.com/bodegga/tide/issues
- **Proxmox Forums:** https://forum.proxmox.com

---

**Tide Gateway v1.1.3** | Transparent Internet Defense Engine  
**Bodegga Company** | Network Security | Petaluma, CA
