

# Tide Gateway - Multi-Platform Build System

**Version:** 1.0  
**Last Updated:** 2025-12-10  
**Tide Version:** 1.1.3

## Overview

The Tide Gateway multi-platform build system creates VM images for all major hypervisors from a single source. This document describes the build process, tool requirements, and release procedures.

## Table of Contents

1. [Architecture](#architecture)
2. [Tool Requirements](#tool-requirements)
3. [Build Process](#build-process)
4. [Output Formats](#output-formats)
5. [Quick Start](#quick-start)
6. [Advanced Usage](#advanced-usage)
7. [Release Process](#release-process)
8. [Troubleshooting](#troubleshooting)

---

## Architecture

### Build Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    Source: Alpine Linux                      │
│               (Cloud-init enabled QCOW2)                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              create-base-image.sh                            │
│  • Downloads Alpine cloud image                             │
│  • Creates cloud-init configuration                          │
│  • Installs Tide Gateway                                     │
│  • Configures services                                       │
│                                                              │
│  Output: tide-base-{arch}.qcow2                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│           build-multi-platform.sh                            │
│  • Orchestrates entire build process                         │
│  • Calls create-base-image.sh                                │
│  • Converts to platform-specific formats                     │
│  • Generates checksums                                       │
│  • Creates release notes                                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              convert-formats.sh                              │
│  • Converts base image to all formats                        │
│  • Creates OVA packages                                      │
│  • Generates platform-specific metadata                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Release Artifacts                           │
│  release/v1.1.3/                                             │
│  ├── vmware/       (ESXi OVA)                                │
│  ├── proxmox/      (QCOW2)                                   │
│  ├── hyperv/       (VHDX)                                    │
│  ├── virtualbox/   (VDI/OVA)                                 │
│  ├── qemu/         (QCOW2)                                   │
│  └── parallels/    (PVM)                                     │
└─────────────────────────────────────────────────────────────┘
```

### Component Breakdown

| Script | Purpose | Input | Output |
|--------|---------|-------|--------|
| **create-base-image.sh** | Creates golden image with Tide installed | Alpine cloud image | tide-base-{arch}.qcow2 |
| **build-multi-platform.sh** | Main orchestrator | Version, platform selection | All platform images |
| **convert-formats.sh** | Format conversion utility | QCOW2 base image | VMDK, VHDX, VDI, RAW, OVA |

---

## Tool Requirements

### Core Requirements (All Platforms)

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **qemu-img** | 7.0+ | Image format conversion | `brew install qemu` (macOS)<br>`apt install qemu-utils` (Linux) |
| **bash** | 3.2+ | Build scripts | Pre-installed (macOS/Linux) |
| **curl** | Any | Download Alpine images | Pre-installed |

### Optional Tools (Platform-Specific)

| Tool | Purpose | Required For | Installation |
|------|---------|--------------|--------------|
| **mkisofs** or **genisoimage** | ISO creation | OVA packaging | `brew install cdrtools` (macOS)<br>`apt install genisoimage` (Linux) |
| **VBoxManage** | VirtualBox OVA | VirtualBox builds | VirtualBox installation |
| **ovftool** | VMware OVA | VMware builds | VMware Fusion/Workstation |
| **prl_convert** | Parallels conversion | Parallels builds | Parallels Desktop |

### Architecture Support

| Architecture | Status | Hypervisors | Notes |
|--------------|--------|-------------|-------|
| **aarch64** (ARM64) | ✅ Full support | UTM, QEMU, Parallels | Primary target |
| **x86_64** (Intel/AMD) | ✅ Full support | All platforms | Universal compatibility |

---

## Build Process

### Phase 1: Base Image Creation

**Script:** `create-base-image.sh`

**What it does:**
1. Downloads Alpine Linux cloud image (if not cached)
2. Creates cloud-init configuration with:
   - Network interfaces (eth0 = WAN, eth1 = LAN)
   - Tor configuration (transparent proxy mode)
   - Firewall rules (iptables)
   - System services (Tor, SSH, iptables)
   - MOTD and login banner
3. Packages cloud-init as ISO
4. Creates base QCOW2 image (2GB, thin provisioned)

**Output:**
- `tide-base-{arch}.qcow2` - Golden image
- `cloud-init-{arch}.iso` - Configuration ISO

**Duration:** ~30 seconds (download) + 5 seconds (build)

### Phase 2: Platform Conversion

**Script:** `build-multi-platform.sh`

**What it does:**
1. Validates dependencies
2. Calls `create-base-image.sh`
3. Converts base image to platform-specific formats:
   - **QCOW2** → Proxmox, QEMU (copy only)
   - **VMDK** → VMware ESXi (stream-optimized)
   - **VHDX** → Hyper-V (dynamic disk)
   - **VDI** → VirtualBox (native format)
   - **RAW** → Parallels import
4. Creates OVA packages (VMware, VirtualBox)
5. Generates SHA256 checksums for all files
6. Creates release notes
7. Sets up release directory structure

**Duration:** ~2-5 minutes (all platforms)

### Phase 3: OVA Packaging

**Script:** `convert-formats.sh --create-ova`

**What it does:**
1. Creates OVF descriptor with:
   - VM hardware specs (512MB RAM, 1 CPU, 2 NICs)
   - Network adapter configs
   - Boot order
   - Annotations (credentials, setup instructions)
2. Generates manifest file (SHA256 checksums)
3. Packages as TAR archive (.ova)

**Duration:** ~10 seconds per OVA

---

## Output Formats

### Supported Formats

| Format | Extension | Platform | Compression | Size (Approx) |
|--------|-----------|----------|-------------|---------------|
| **QCOW2** | .qcow2 | Proxmox, QEMU, KVM, UTM | Thin provisioned | ~150MB |
| **VMDK** | .vmdk | VMware ESXi, Fusion, Workstation | Stream-optimized | ~200MB |
| **VHDX** | .vhdx | Hyper-V, Azure Stack | Dynamic | ~180MB |
| **VDI** | .vdi | VirtualBox | Native | ~160MB |
| **OVA** | .ova | VMware, VirtualBox | TAR archive | ~200MB |
| **RAW** | .raw | Parallels, Universal | Uncompressed | ~2GB |
| **PVM** | .pvm.tar.gz | Parallels Desktop | Compressed archive | ~300MB |

### VM Specifications (All Platforms)

| Component | Default | Configurable | Notes |
|-----------|---------|--------------|-------|
| **OS** | Alpine Linux 3.21 | No | Hardened, minimal |
| **Disk** | 2GB | Yes (resize post-import) | Thin provisioned |
| **RAM** | 512MB | Yes (VM settings) | Sufficient for gateway |
| **CPU** | 1 vCPU | Yes (VM settings) | Single-threaded Tor |
| **Network 1** | eth0 (WAN) | Bridge/NAT | Internet access |
| **Network 2** | eth1 (LAN) | Host-Only | Attack network |

### Installed Software

| Package | Version | Purpose |
|---------|---------|---------|
| **Tor** | Latest (Alpine repo) | Transparent proxy |
| **iptables** | Latest | Firewall/NAT |
| **OpenSSH** | Latest | Remote management |
| **Python 3** | 3.x | Web dashboard |
| **Flask** | Latest | API server |
| **nginx** | Latest | Web server (dashboard) |
| **curl** | Latest | Testing/verification |

### Default Configuration

```yaml
Hostname: tide-gateway
Username: root
Password: tide  # ⚠️ Change after first boot!

Network:
  eth0 (WAN): DHCP
  eth1 (LAN): 10.101.101.10/24

Tor:
  SOCKS: 0.0.0.0:9050
  DNS: 0.0.0.0:5353
  TransPort: 0.0.0.0:9040

Services:
  - Tor (enabled, auto-start)
  - SSH (enabled, auto-start)
  - iptables (enabled, auto-start)
  - tide-web (planned)
  - tide-api (planned)

Mode: killa-whale (fail-closed)
Security: standard
```

---

## Quick Start

### Build All Platforms

```bash
cd scripts/build
./build-multi-platform.sh --all
```

**Output:** `release/v1.1.3/` with all platform directories

### Build Specific Platform

```bash
# VMware ESXi
./build-multi-platform.sh --platform esxi

# Proxmox VE
./build-multi-platform.sh --platform proxmox

# Hyper-V
./build-multi-platform.sh --platform hyperv

# VirtualBox
./build-multi-platform.sh --platform virtualbox

# QEMU/KVM
./build-multi-platform.sh --platform qemu
```

### Build for x86_64

```bash
./build-multi-platform.sh --all --arch x86_64
```

### Verify Build

```bash
# Check release directory
ls -lh ../../release/v1.1.3/

# Verify checksums
cd ../../release/v1.1.3/vmware/
shasum -a 256 -c *.sha256
```

---

## Advanced Usage

### Custom Base Image

```bash
# Create base image only
./create-base-image.sh --arch aarch64 --disk-size 4G

# Use custom base image
./build-multi-platform.sh --platform esxi
# (automatically uses tide-base-aarch64.qcow2)
```

### Batch Conversion

```bash
# Convert existing QCOW2 to all formats
./convert-formats.sh --input tide-base-aarch64.qcow2 --output-dir ./converted
```

### Manual OVA Creation

```bash
# Create OVA from VMDK
./convert-formats.sh --create-ova disk.vmdk output.ova --version 1.1.3
```

### Platform-Specific Builds

```bash
# Build only VMware + VirtualBox
./build-multi-platform.sh --platform esxi
./build-multi-platform.sh --platform virtualbox

# Build for both architectures
./build-multi-platform.sh --all --arch aarch64
./build-multi-platform.sh --all --arch x86_64
```

---

## Release Process

### Standard Release Workflow

1. **Update VERSION file**
   ```bash
   echo "1.1.4" > VERSION
   ```

2. **Build all platforms**
   ```bash
   cd scripts/build
   ./build-multi-platform.sh --all
   ```

3. **Verify builds**
   ```bash
   cd ../../release/v1.1.4
   
   # Check all platforms exist
   ls -lh */
   
   # Verify checksums
   for dir in */; do
     (cd "$dir" && shasum -a 256 -c *.sha256)
   done
   ```

4. **Test one platform**
   ```bash
   # Example: Test QEMU build
   cd qemu
   qemu-system-aarch64 \
     -M virt -cpu cortex-a72 -m 512 \
     -drive if=none,file=Tide-Gateway-v1.1.4-QEMU-aarch64.qcow2,id=hd0 \
     -device virtio-blk-device,drive=hd0 \
     -device virtio-net-device,netdev=net0 \
     -device virtio-net-device,netdev=net1 \
     -netdev user,id=net0 \
     -netdev user,id=net1 \
     -nographic
   ```

5. **Create GitHub release**
   ```bash
   # Tag release
   git tag v1.1.4
   git push origin v1.1.4
   
   # Upload artifacts
   gh release create v1.1.4 \
     --title "Tide Gateway v1.1.4" \
     --notes-file release/v1.1.4/RELEASE-NOTES.md \
     release/v1.1.4/**/*.{qcow2,vhdx,vmdk,vdi,ova,sha256}
   ```

### File Size Estimates

```
vmware/
  Tide-Gateway-v1.1.3-ESXi-aarch64.vmdk     (~200MB)
  Tide-Gateway-v1.1.3-ESXi-aarch64.ova      (~200MB)
  *.sha256                                   (~200 bytes each)

proxmox/
  Tide-Gateway-v1.1.3-Proxmox-aarch64.qcow2 (~150MB)

hyperv/
  Tide-Gateway-v1.1.3-HyperV-aarch64.vhdx   (~180MB)

virtualbox/
  Tide-Gateway-v1.1.3-VirtualBox-aarch64.vdi (~160MB)
  Tide-Gateway-v1.1.3-VirtualBox-aarch64.ova (~200MB)

qemu/
  Tide-Gateway-v1.1.3-QEMU-aarch64.qcow2    (~150MB)

Total size per architecture: ~1.5GB
```

### Compression (Optional)

```bash
# Compress large images
for file in release/v1.1.3/**/*.{vhdx,raw}; do
  gzip -9 "$file"
done

# Reduces VHDX from ~180MB to ~140MB
# Reduces RAW from ~2GB to ~150MB
```

---

## Troubleshooting

### Common Issues

#### 1. Missing Dependencies

**Error:**
```
ERROR: qemu-img not found
```

**Solution:**
```bash
# macOS
brew install qemu cdrtools

# Linux (Debian/Ubuntu)
sudo apt update
sudo apt install qemu-utils genisoimage

# Linux (RHEL/CentOS)
sudo yum install qemu-img genisoimage
```

#### 2. Alpine Download Fails

**Error:**
```
curl: (56) Recv failure: Connection reset by peer
```

**Solution:**
```bash
# Download manually
curl -L -o nocloud_alpine-3.21.2-aarch64-uefi-tiny-r0.qcow2 \
  https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/cloud/nocloud_alpine-3.21.2-aarch64-uefi-tiny-r0.qcow2

# Then run build
./build-multi-platform.sh --all
```

#### 3. Permission Denied

**Error:**
```
bash: ./build-multi-platform.sh: Permission denied
```

**Solution:**
```bash
chmod +x scripts/build/*.sh
```

#### 4. Insufficient Disk Space

**Error:**
```
qemu-img: Could not resize image: No space left on device
```

**Solution:**
```bash
# Check available space
df -h .

# Clean old builds
rm -rf scripts/build/tide-base-*.qcow2
rm -rf release/v1.1.2/  # Old versions

# Minimum required: ~5GB free for all platforms
```

#### 5. OVA Creation Fails

**Error:**
```
mkisofs: command not found
```

**Solution:**
```bash
# macOS
brew install cdrtools

# Linux
sudo apt install genisoimage

# Alternative: Skip OVA, use VMDK/VDI directly
./build-multi-platform.sh --platform esxi  # Creates VMDK only
```

#### 6. Parallels Build Not Working

**Issue:** Parallels builds require macOS + Parallels Desktop

**Solution:**
```bash
# On macOS with Parallels
cd deployment/parallels
./PACKAGE-RELEASE.sh

# On other platforms: Skip Parallels builds
./build-multi-platform.sh --all  # Skips Parallels automatically
```

### Debugging

#### Enable Verbose Mode

```bash
./build-multi-platform.sh --all --verbose
```

#### Check Base Image

```bash
qemu-img info scripts/build/tide-base-aarch64.qcow2
```

Expected output:
```
file format: qcow2
virtual size: 2 GiB (2147483648 bytes)
disk size: 150 MiB
```

#### Test Conversion

```bash
# Test VMDK conversion manually
cd scripts/build
qemu-img convert -f qcow2 -O vmdk tide-base-aarch64.qcow2 test.vmdk
qemu-img info test.vmdk
```

### Performance Tips

1. **Use SSD for builds** - 5-10x faster than HDD
2. **Cache Alpine images** - Don't delete downloaded .qcow2 files
3. **Build specific platforms** - Skip unused hypervisors
4. **Parallel builds** - Run multiple `build-multi-platform.sh` instances for different architectures

---

## Build System Maintenance

### Updating Alpine Version

Edit `create-base-image.sh`:

```bash
# Change these lines
ALPINE_VERSION="3.21"
ALPINE_RELEASE="3.21.2"
```

### Adding New Platform

1. Add build function to `build-multi-platform.sh`:
   ```bash
   build_newplatform() {
       print_header "Building NewPlatform Image"
       # Implementation
   }
   ```

2. Add to platform list in help text

3. Add case statement entry

4. Create platform-specific README

### Modifying VM Specs

Edit `convert-formats.sh` OVF template:

```xml
<!-- Change RAM -->
<rasd:VirtualQuantity>1024</rasd:VirtualQuantity>  <!-- 1GB -->

<!-- Change CPU -->
<rasd:VirtualQuantity>2</rasd:VirtualQuantity>  <!-- 2 vCPUs -->
```

### Customizing Cloud-Init

Edit `create-base-image.sh` user-data section:

```yaml
# Add packages
packages:
  - tor
  - iptables
  - your-package

# Add custom commands
runcmd:
  - your-custom-command
```

---

## Additional Resources

- **Alpine Linux Cloud Images:** https://alpinelinux.org/cloud/
- **QEMU Documentation:** https://www.qemu.org/documentation/
- **OVF Specification:** https://www.dmtf.org/standards/ovf
- **Tide Gateway Repo:** https://github.com/bodegga/tide

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-10  
**Maintained By:** Bodegga Company
