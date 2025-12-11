# Tide Gateway v1.1.3 - Microsoft Hyper-V

## Quick Start (Windows 10/11 Pro/Enterprise)

### Enable Hyper-V

1. **Enable Hyper-V Feature**
   ```powershell
   # Run PowerShell as Administrator
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   # Reboot when prompted
   ```

2. **Verify Installation**
   ```powershell
   Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
   # Should show "Enabled"
   ```

### Import VHDX

1. **Copy VHDX File**
   - Place `Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx` in a folder
   - Example: `C:\Hyper-V\Tide-Gateway\`

2. **Create VM via Hyper-V Manager**
   - Open **Hyper-V Manager**
   - **Action** → **New** → **Virtual Machine**
   - **Name:** Tide Gateway
   - **Generation:** Generation 2
   - **Memory:** 512 MB
   - **Networking:**
     - Connection 1: **Default Switch** (or external switch)
   - **Virtual Hard Disk:**
     - Select **Use an existing virtual hard disk**
     - Browse to downloaded VHDX file
   - Click **Finish**

3. **Add Second Network Adapter**
   - Right-click VM → **Settings**
   - **Add Hardware** → **Network Adapter** → **Add**
   - Set to **Internal** or **Private** virtual switch
   - Click **OK**

4. **Disable Secure Boot** (Important!)
   - VM Settings → **Security**
   - Uncheck **Enable Secure Boot**
   - Click **OK**

5. **Start VM**
   - Right-click VM → **Connect**
   - Click **Start**

### Create VM via PowerShell

```powershell
# Run as Administrator

# Create VM
New-VM -Name "Tide Gateway" -MemoryStartupBytes 512MB -Generation 2 `
  -VHDPath "C:\Hyper-V\Tide-Gateway\Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx"

# Add network adapters
Add-VMNetworkAdapter -VMName "Tide Gateway" -SwitchName "Default Switch"  # WAN
Add-VMNetworkAdapter -VMName "Tide Gateway" -SwitchName "Internal"        # LAN

# Disable Secure Boot
Set-VMFirmware -VMName "Tide Gateway" -EnableSecureBoot Off

# Set CPU count
Set-VM -Name "Tide Gateway" -ProcessorCount 1

# Start VM
Start-VM -Name "Tide Gateway"
```

## Network Configuration

### Virtual Switch Setup

Tide requires 2 virtual switches:

| Switch | Type | Purpose |
|--------|------|---------|
| **Default Switch** or **External** | External/NAT | Internet access |
| **Internal** | Internal | Attack network (isolated) |

### Create Internal Switch

**Hyper-V Manager:**
1. **Virtual Switch Manager**
2. **New virtual network switch**
3. Type: **Internal**
4. Name: `Internal` or `Attack Network`
5. Click **Create Virtual Switch**
6. Click **OK**

**PowerShell:**
```powershell
New-VMSwitch -Name "Internal" -SwitchType Internal
```

### Configure Host IP on Internal Switch

**PowerShell:**
```powershell
# Find the Internal switch adapter
Get-NetAdapter | Where-Object {$_.Name -like "*Internal*"}

# Set IP address (optional, for host access to gateway)
New-NetIPAddress -InterfaceAlias "vEthernet (Internal)" `
  -IPAddress 10.101.101.1 -PrefixLength 24
```

## Default Credentials

```
Username: root
Password: tide
```

**⚠️ CHANGE DEFAULT PASSWORD!**

```bash
# From VM console
passwd  # Set new password
```

## Connecting Devices

### Connect Windows Host to Tide

**PowerShell (as Administrator):**
```powershell
# Set IP on Internal adapter
New-NetIPAddress -InterfaceAlias "vEthernet (Internal)" `
  -IPAddress 10.101.101.100 -PrefixLength 24

# Set DNS to gateway
Set-DnsClientServerAddress -InterfaceAlias "vEthernet (Internal)" `
  -ServerAddresses 10.101.101.10

# Add route through gateway
New-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop 10.101.101.10 `
  -InterfaceAlias "vEthernet (Internal)" -RouteMetric 1
```

### Connect Another VM

1. Create new VM
2. **Network Adapter:** Attach to **Internal** switch
3. **Inside VM:** Configure static IP
   - IP: `10.101.101.101`
   - Gateway: `10.101.101.10`
   - DNS: `10.101.101.10`

## Verification

### Check VM Status

**PowerShell:**
```powershell
Get-VM -Name "Tide Gateway" | Select Name, State, Uptime
```

### Connect to Console

**Hyper-V Manager:**
- Right-click VM → **Connect**

**PowerShell:**
```powershell
vmconnect.exe localhost "Tide Gateway"
```

### Test Tor Connection

From VM console:
```bash
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```

Expected:
```json
{"IsTor":true,"IP":"<tor-exit-ip>"}
```

## Troubleshooting

### VM Won't Boot

**Issue:** "Boot failure" or hangs at logo

**Solution:**
1. Disable Secure Boot:
   ```powershell
   Set-VMFirmware -VMName "Tide Gateway" -EnableSecureBoot Off
   ```
2. Ensure VHDX is not corrupted:
   ```powershell
   Test-VHD -Path "C:\...\Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx"
   ```

### No Network Connectivity

**Check virtual switch:**
```powershell
Get-VMSwitch
Get-VMNetworkAdapter -VMName "Tide Gateway"
```

**Fix:**
```powershell
# Re-add adapters
Remove-VMNetworkAdapter -VMName "Tide Gateway" -Name "Network Adapter"
Add-VMNetworkAdapter -VMName "Tide Gateway" -SwitchName "Default Switch"
Add-VMNetworkAdapter -VMName "Tide Gateway" -SwitchName "Internal"
```

### Tor Not Starting

**From VM console:**
```bash
# Check Tor status
rc-service tor status

# View logs
tail -f /var/log/messages | grep tor

# Restart Tor
rc-service tor restart
```

### Can't SSH to Gateway

**Enable SSH from host:**
1. Ensure Internal switch has IP: `10.101.101.1`
2. Test connectivity: `ping 10.101.101.10`
3. SSH: `ssh root@10.101.101.10`

**If using Windows SSH client:**
```powershell
# Install OpenSSH client
Add-WindowsCapability -Online -Name OpenSSH.Client*

# Connect
ssh root@10.101.101.10
```

## Advanced Configuration

### Increase Disk Size

**PowerShell:**
```powershell
# Stop VM
Stop-VM -Name "Tide Gateway"

# Resize VHDX (e.g., to 4GB)
Resize-VHD -Path "C:\...\Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx" `
  -SizeBytes 4GB

# Start VM
Start-VM -Name "Tide Gateway"

# Inside VM, resize filesystem
ssh root@10.101.101.10
resize2fs /dev/sda1  # Or appropriate partition
```

### Add More RAM/CPU

**PowerShell:**
```powershell
# Stop VM
Stop-VM -Name "Tide Gateway"

# Set 1GB RAM
Set-VM -Name "Tide Gateway" -MemoryStartupBytes 1GB

# Set 2 CPUs
Set-VM -Name "Tide Gateway" -ProcessorCount 2

# Start VM
Start-VM -Name "Tide Gateway"
```

### Enable Dynamic Memory

**PowerShell:**
```powershell
Set-VM -Name "Tide Gateway" -DynamicMemory `
  -MemoryMinimumBytes 512MB `
  -MemoryMaximumBytes 2GB `
  -MemoryStartupBytes 512MB
```

### Export VM

**PowerShell:**
```powershell
# Export VM (for backup or migration)
Export-VM -Name "Tide Gateway" -Path "C:\Hyper-V\Exports\"
```

### Clone VM

**PowerShell:**
```powershell
# Copy VHDX
Copy-Item "C:\...\Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx" `
  "C:\...\Tide-Gateway-Clone.vhdx"

# Create new VM
New-VM -Name "Tide Gateway 2" -MemoryStartupBytes 512MB -Generation 2 `
  -VHDPath "C:\...\Tide-Gateway-Clone.vhdx"
```

## Windows Server Hyper-V

### Install Hyper-V Role

**PowerShell:**
```powershell
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

### Create VM (same process as desktop)

All PowerShell commands above work on Windows Server.

## Performance Tips

1. **Use SSD storage** - Place VHDX on SSD for better Tor performance
2. **Dynamic Memory** - Allow Hyper-V to manage RAM allocation
3. **Disable antivirus scanning** on VHDX file (add exclusion)
4. **Use VirtIO drivers** - Already included in image

## Integration with Windows Features

### Use with WSL2

Connect WSL2 instance to Tide:

```bash
# In WSL2
sudo ip addr add 10.101.101.101/24 dev eth0
sudo ip route add default via 10.101.101.10
echo "nameserver 10.101.101.10" | sudo tee /etc/resolv.conf
```

### Use with Docker Desktop

Docker Desktop uses Hyper-V backend:
- Containers can access Internal switch
- Configure container networking to use 10.101.101.0/24

## File Information

**Filename:** `Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx`  
**Format:** VHDX (Hyper-V Virtual Hard Disk v2)  
**Size:** ~180MB  
**Checksum:** See `.sha256` file

**VM Specifications:**
- OS: Alpine Linux 3.21
- Disk: 2GB (dynamic, expandable)
- RAM: 512MB (configurable)
- CPU: 1 vCPU (configurable)
- Network: 2 adapters required
- Generation: 2 (UEFI)

## Support

- **Documentation:** https://github.com/bodegga/tide
- **Issues:** https://github.com/bodegga/tide/issues
- **Hyper-V Docs:** https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/

---

**Tide Gateway v1.1.3** | Transparent Internet Defense Engine  
**Bodegga Company** | Network Security | Petaluma, CA
