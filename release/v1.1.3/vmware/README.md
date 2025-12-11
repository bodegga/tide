# Tide Gateway v1.1.3 - VMware ESXi / Fusion / Workstation

## Quick Start

### VMware ESXi

1. **Upload OVA to ESXi**
   - Login to ESXi web interface
   - Navigate to **Virtual Machines**
   - Click **Create/Register VM** → **Deploy a virtual machine from an OVF or OVA file**
   - Select `Tide-Gateway-v1.1.3-ESXi-aarch64.ova`
   - Choose datastore and deployment options
   - Click **Finish**

2. **Configure Network Adapters**
   - After import, select the VM
   - Click **Edit** → **Network Adapter 1**
     - Set to **VM Network** or **Internet** port group
   - Click **Add network adapter**
     - Set to **Host-Only** or **Internal** network
   - Save settings

3. **Power On**
   - Click **Power On**
   - Open console
   - Wait ~30 seconds for boot

4. **Verify**
   - Login: `root` / `tide`
   - Check Tor status: `rc-service tor status`
   - Test: `curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip`

### VMware Fusion (macOS)

1. **Import OVA**
   - **File** → **Import**
   - Select `Tide-Gateway-v1.1.3-ESXi-aarch64.ova`
   - Choose import location
   - Click **Import**

2. **Configure Networks**
   - Open VM settings
   - **Network Adapter 1**: Set to **Bridged** or **NAT**
   - **Network Adapter 2**: Set to **Host-Only**
   - Save

3. **Start VM**
   - Click **Play**
   - Open console window

### VMware Workstation (Windows/Linux)

1. **Import OVA**
   - **File** → **Open** → Select `.ova` file
   - Review settings
   - Click **Import**

2. **Network Configuration**
   - Right-click VM → **Settings**
   - **Network Adapter 1**: **Bridged** or **NAT**
   - **Network Adapter 2**: **Host-Only**
   - Click **OK**

3. **Power On**
   - Click **Play virtual machine**

## Network Configuration

### Required Network Adapters

| Adapter | Type | Purpose | IP Assignment |
|---------|------|---------|---------------|
| **eth0** (WAN) | Bridged/NAT | Internet access | DHCP |
| **eth1** (LAN) | Host-Only | Attack network | Static: 10.101.101.10 |

### Host-Only Network Setup

**ESXi:**
- Create port group on vSwitch (no uplink)
- Assign to Network Adapter 2

**Fusion/Workstation:**
- **Virtual Network Editor**
- Create/use **vmnet1** (Host-Only)
- Subnet: `10.101.101.0/24`
- No NAT, no DHCP

## Default Credentials

```
Username: root
Password: tide
```

**⚠️ CHANGE DEFAULT PASSWORD AFTER FIRST BOOT!**

```bash
passwd  # Set new password
```

## Connecting Devices

### Option 1: Configure Static IP

On your attack machine:

```bash
# Linux/macOS
sudo ifconfig eth1 10.101.101.100 netmask 255.255.255.0
sudo route add default gw 10.101.101.10
echo "nameserver 10.101.101.10" | sudo tee /etc/resolv.conf

# Windows (PowerShell)
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 10.101.101.100 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses 10.101.101.10
New-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop 10.101.101.10
```

### Option 2: DHCP (Future Feature)

Coming in v1.2 - DHCP server on LAN interface

## Verification

### Check Tor Status

```bash
ssh root@10.101.101.10  # Password: tide
rc-service tor status
```

Expected output: `tor is running`

### Test Tor Connection

From gateway:
```bash
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```

From attack machine:
```bash
curl https://check.torproject.org/api/ip
```

Both should return:
```json
{"IsTor":true,"IP":"<tor-exit-ip>"}
```

## Troubleshooting

### VM Won't Boot

- **Check BIOS/UEFI settings**: Enable virtualization (VT-x/AMD-V)
- **ESXi**: Ensure ARM64 support (Apple Silicon or ARM servers)
- **Fusion**: Requires Apple Silicon Mac for ARM64 images

### No Network Connectivity

1. Check network adapters in VM settings
2. Verify host-only network exists
3. Check cable connected status

### Tor Not Starting

```bash
# Check logs
tail -f /var/log/messages | grep tor

# Restart Tor
rc-service tor restart

# Check firewall
iptables -L -n -v
```

### Can't SSH to Gateway

```bash
# From VM console
ifconfig eth1  # Should show 10.101.101.10

# Restart networking
rc-service networking restart
```

## Advanced Configuration

### Change Gateway IP

Edit `/etc/network/interfaces`:

```bash
auto eth1
iface eth1 inet static
    address 192.168.99.1  # New IP
    netmask 255.255.255.0
```

Update firewall and Tor configs to match.

### Add Tor Bridges

Edit `/etc/tor/torrc`:

```
UseBridges 1
Bridge obfs4 <bridge-address>
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
```

Restart Tor:
```bash
rc-service tor restart
```

### Enable Web Dashboard

Coming in v1.2 - Web UI at http://10.101.101.10:8080

## File Information

**Filename:** `Tide-Gateway-v1.1.3-ESXi-aarch64.ova`  
**Format:** OVA (Open Virtualization Archive)  
**Size:** ~200MB  
**Checksum:** See `.sha256` file

**VM Specifications:**
- OS: Alpine Linux 3.21
- Disk: 2GB (thin provisioned)
- RAM: 512MB (adjustable)
- CPU: 1 vCPU (adjustable)
- Network: 2 adapters required

## Support

- **Documentation:** https://github.com/bodegga/tide
- **Issues:** https://github.com/bodegga/tide/issues
- **Website:** https://bodegga.net

---

**Tide Gateway v1.1.3** | Transparent Internet Defense Engine  
**Bodegga Company** | Network Security | Petaluma, CA
