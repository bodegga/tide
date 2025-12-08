# Tide Gateway - Build Instructions

## Automated Build Using Alpine Cloud Image

### Files Ready:
- `nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2` - Alpine cloud image (141MB)
- `cloud-init.iso` - Auto-configuration ISO
- `cloud-init-userdata.yaml` - Tor gateway setup script
- `cloud-init-metadata.yaml` - VM metadata

### Gateway Configuration:
- **IP Address**: `10.101.101.10`
- **Network**: `10.101.101.0/24` (supports multiple client VMs)
- **Services**:
  - SOCKS5 Proxy: `10.101.101.10:9050`
  - Transparent Proxy: `10.101.101.10:9040`
  - DNS: `10.101.101.10:5353`
  - Control Port: `10.101.101.10:9051`
  - SSH: `10.101.101.10:22`
- **Credentials**: `alpine / tide` (change in production)

### Manual Build Steps (UTM):

1. **Create New VM in UTM**:
   - Open UTM
   - Click "Create a New Virtual Machine"
   - Choose "Virtualize" (ARM64)
   - Select "Other"
   - Skip ISO

2. **Configure Hardware**:
   - CPU Cores: 1
   - Memory: 512 MB
   - Enable UEFI Boot

3. **Replace Boot Disk**:
   - Delete the default disk
   - Add existing disk: `nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2`
   - Set as boot disk

4. **Add Cloud-Init**:
   - Add CD/DVD Drive
   - Attach `cloud-init.iso`

5. **Configure Network**:
   - Network Adapter 1: Shared Network (for internet)
   - Network Adapter 2: Host-Only (`10.101.101.0/24`)

6. **First Boot**:
   - Start the VM
   - Cloud-init will auto-configure Tor (~2 minutes)
   - Watch for "Tide Gateway is ready!" message

7. **Verify**:
   - SSH: `ssh alpine@10.101.101.10` (password: `tide`)
   - Check Tor: `rc-service tor status`
   - Test: `curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip`

8. **Export**:
   - Shut down VM
   - Export as OVA or distribute the qcow2 + cloud-init.iso

### Automated Build (Parallels - NOT WORKING YET):
Parallels doesn't natively support qcow2 import. Need to:
1. Convert qcow2 → raw → Parallels HDD format
2. Or build in UTM and export to OVA

### Distribution:
- Package: `tide-gateway-v1.1-alpine-arm64.zip`
- Contains:
  - `tide-gateway.qcow2` (configured disk)
  - `cloud-init.iso` (optional - already applied)
  - `README.md` (import instructions)
  - `LICENSE`

### For End Users:
- Download ZIP
- Import `tide-gateway.qcow2` into UTM/Parallels/VMware
- Add Host-Only network adapter
- Boot and connect clients to `10.101.101.10`
