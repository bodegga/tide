# Tide Gateway - Quick Build Guide

**Version:** 1.1.3  
**Phase 1 Status:** ✅ COMPLETE

---

## Prerequisites

### Install Tools (macOS)

```bash
brew install qemu cdrtools
```

### Install Tools (Linux)

```bash
sudo apt update
sudo apt install qemu-utils genisoimage
```

---

## Quick Build Commands

### Build Everything

```bash
cd scripts/build
./build-multi-platform.sh --all
```

**Output:** `release/v1.1.3/` with all platform images

**Build Time:** ~2-5 minutes  
**Disk Space Required:** ~5GB

---

## Build Specific Platforms

```bash
# VMware ESXi/Fusion/Workstation (OVA)
./build-multi-platform.sh --platform esxi

# Proxmox VE (QCOW2)
./build-multi-platform.sh --platform proxmox

# Microsoft Hyper-V (VHDX)
./build-multi-platform.sh --platform hyperv

# Oracle VirtualBox (OVA + VDI)
./build-multi-platform.sh --platform virtualbox

# QEMU/KVM (QCOW2)
./build-multi-platform.sh --platform qemu

# Parallels Desktop (macOS only)
cd ../../deployment/parallels
./PACKAGE-RELEASE.sh
```

---

## Build for x86_64

```bash
./build-multi-platform.sh --all --arch x86_64
```

---

## Verify Build

### Check Output Files

```bash
ls -lh ../../release/v1.1.3/vmware/
ls -lh ../../release/v1.1.3/proxmox/
ls -lh ../../release/v1.1.3/hyperv/
ls -lh ../../release/v1.1.3/virtualbox/
ls -lh ../../release/v1.1.3/qemu/
```

### Verify Checksums

```bash
cd ../../release/v1.1.3/vmware/
shasum -a 256 -c *.sha256
```

Expected: `OK` for each file

---

## Output Files by Platform

### VMware ESXi/Fusion/Workstation

```
release/v1.1.3/vmware/
├── Tide-Gateway-v1.1.3-ESXi-aarch64.ova      (~200MB)
├── Tide-Gateway-v1.1.3-ESXi-aarch64.vmdk     (~200MB)
├── *.sha256                                   (checksums)
└── README.md                                  (deployment guide)
```

### Proxmox VE

```
release/v1.1.3/proxmox/
├── Tide-Gateway-v1.1.3-Proxmox-aarch64.qcow2 (~150MB)
├── *.sha256
└── README.md
```

### Microsoft Hyper-V

```
release/v1.1.3/hyperv/
├── Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx   (~180MB)
├── *.sha256
└── README.md
```

### Oracle VirtualBox

```
release/v1.1.3/virtualbox/
├── Tide-Gateway-v1.1.3-VirtualBox-aarch64.ova (~200MB)
├── Tide-Gateway-v1.1.3-VirtualBox-aarch64.vdi (~160MB)
├── *.sha256
└── README.md
```

### QEMU/KVM

```
release/v1.1.3/qemu/
├── Tide-Gateway-v1.1.3-QEMU-aarch64.qcow2    (~150MB)
├── *.sha256
└── README.md
```

---

## VM Default Settings

```yaml
OS: Alpine Linux 3.21
Disk: 2GB (thin provisioned)
RAM: 512MB (configurable)
CPU: 1 vCPU (configurable)
Network: 2 adapters required
  - eth0 (WAN): Internet access
  - eth1 (LAN): Attack network

Default Credentials:
  Username: root
  Password: tide
  ⚠️ CHANGE AFTER FIRST BOOT!

Gateway IP: 10.101.101.10
Tor SOCKS: 10.101.101.10:9050
Tor DNS: 10.101.101.10:5353
Web UI: http://10.101.101.10:8080 (coming soon)
```

---

## Common Issues

### Missing qemu-img

**Error:** `qemu-img: command not found`

**Fix:**
```bash
brew install qemu              # macOS
sudo apt install qemu-utils    # Linux
```

### Missing mkisofs

**Error:** `mkisofs: command not found`

**Fix:**
```bash
brew install cdrtools          # macOS
sudo apt install genisoimage   # Linux
```

### Insufficient Disk Space

**Error:** `No space left on device`

**Fix:**
```bash
# Clean old builds
rm -rf scripts/build/tide-base-*.qcow2
rm -rf release/v1.1.2/  # Old versions

# Minimum required: 5GB free
df -h .
```

---

## Release Process

1. **Update VERSION file**
   ```bash
   echo "1.2.0" > VERSION
   ```

2. **Build all platforms**
   ```bash
   cd scripts/build
   ./build-multi-platform.sh --all
   ```

3. **Verify checksums**
   ```bash
   cd ../../release/v1.2.0
   for dir in */; do
     (cd "$dir" && shasum -a 256 -c *.sha256 2>/dev/null)
   done
   ```

4. **Create GitHub release**
   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   
   gh release create v1.2.0 \
     --title "Tide Gateway v1.2.0" \
     --notes-file release/v1.2.0/RELEASE-NOTES.md \
     release/v1.2.0/**/*.{qcow2,vhdx,vmdk,vdi,ova,sha256}
   ```

---

## Getting Help

### Documentation

- **Full Build Guide:** `docs/building/MULTI-PLATFORM-BUILD.md`
- **Platform Guides:** `release/v1.1.3/{platform}/README.md`
- **Phase 1 Summary:** `PHASE-1-SUMMARY.md`

### Command Help

```bash
# Main builder
./build-multi-platform.sh --help

# Base image creator
./create-base-image.sh --help

# Format converter
./convert-formats.sh --help
```

### Support

- **GitHub:** https://github.com/bodegga/tide
- **Issues:** https://github.com/bodegga/tide/issues
- **Website:** https://bodegga.net

---

## Next Steps

1. **Import VM** to your hypervisor (see platform README)
2. **Configure networks** (2 adapters required)
3. **Start VM**
4. **Change default password:** `passwd`
5. **Verify Tor:** `curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip`

---

**Quick Build Guide** | Tide Gateway v1.1.3  
**Bodegga Company** | Network Security | Petaluma, CA  
**Last Updated:** 2025-12-10
