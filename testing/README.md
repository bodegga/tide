# Tide Gateway - Automated Testing Infrastructure

Complete automated testing suite for Tide Gateway across multiple platforms.

## Overview

This directory contains automated test scripts for validating Tide Gateway functionality across different deployment platforms.

```
testing/
├── cloud/               # Cloud provider tests
│   └── test-hetzner.sh      ✅ Fully automated (working)
├── containers/          # Container platform tests
│   ├── test-docker.sh       ✅ Fully automated
│   └── docker-compose-test.yml  ✅ Multi-mode testing
├── hypervisors/         # Hypervisor tests
│   ├── test-qemu.sh         ⚠️  Semi-automated (requires manual Alpine setup)
│   └── test-virtualbox.sh   ⚠️  Semi-automated (requires VirtualBox + manual setup)
└── README.md            # This file
```

---

## Quick Start

### 1. Docker Testing (Recommended - Fastest)

**Best for:** Quick validation, CI/CD, development

```bash
cd testing/containers
./test-docker.sh
```

**What it tests:**
- ✅ Docker image builds
- ✅ Proxy mode (SOCKS5)
- ✅ Router mode basics
- ✅ Configuration files
- ✅ Tor connectivity
- ✅ API endpoints
- ⚠️ Killa Whale mode NOT supported (no kernel ARP access)

**Runtime:** ~2-3 minutes

---

### 2. Hetzner Cloud Testing (Proven)

**Best for:** Production validation, real ARM hardware

```bash
cd testing/cloud
./test-hetzner.sh
```

**Prerequisites:**
- Hetzner Cloud account
- API token in `~/.config/tide/hetzner.env`
- hcloud CLI installed: `brew install hcloud`

**What it tests:**
- ✅ Full Tide Gateway v1.2.0 installation
- ✅ All modes (proxy, router, killa-whale)
- ✅ Tor connectivity and exit IP validation
- ✅ Mode switching
- ✅ Service management
- ✅ Web dashboard

**Cost:** ~€0.008/hr (~$0.01/hr)  
**Runtime:** ~5 minutes  
**Cleanup:** Automatic (destroys server after tests)

---

### 3. QEMU Testing (Manual Setup Required)

**Best for:** Local ARM testing without cloud costs

```bash
cd testing/hypervisors
./test-qemu.sh
```

**Prerequisites:**
- QEMU installed: `brew install qemu`
- Alpine ISO in project root: `alpine-virt-3.21.0-aarch64.iso`

**What it does:**
- Creates VM disk image
- Generates installation scripts
- Provides manual setup instructions
- Creates test scripts

**Note:** Requires manual Alpine installation (not fully automated)

**For fully automated QEMU testing:**
```bash
# Use existing cloud-init deployment
cd deployment/qemu
./build-qemu-image.sh
```

---

### 4. VirtualBox Testing (When Available)

**Best for:** Cross-platform testing, GUI access

```bash
cd testing/hypervisors
./test-virtualbox.sh
```

**Prerequisites:**
- VirtualBox installed: `brew install --cask virtualbox`
- Alpine ISO in project root

**Status:** VBoxManage not detected on your system

**What it does:**
- Creates VM with proper settings
- Attaches Alpine ISO
- Configures port forwarding (SSH, HTTP, SOCKS, API)
- Provides manual setup guide

---

## Test Matrix

| Platform | Mode | Status | Automation | Runtime | Cost |
|----------|------|--------|------------|---------|------|
| **Docker** | Proxy | ✅ Working | Full | 2-3 min | Free |
| **Docker** | Router | ✅ Working | Full | 2-3 min | Free |
| **Docker** | Killa Whale | ❌ Not supported | N/A | N/A | Free |
| **Hetzner** | All modes | ✅ Working | Full | 5 min | €0.04 |
| **QEMU** | All modes | ⚠️ Manual | Partial | 10-15 min | Free |
| **VirtualBox** | All modes | ⚠️ Manual | Partial | 10-15 min | Free |

---

## Test Suite Details

All tests validate the following:

### 1. Installation Tests
- ✅ Tide CLI command available (`tide status`)
- ✅ Configuration files created (`/etc/tide/mode`, `/etc/tide/security`)
- ✅ Scripts installed in `/usr/local/bin`

### 2. Service Tests
- ✅ Tor daemon running
- ✅ SOCKS5 port listening (9050)
- ✅ API server running (9051)
- ✅ dnsmasq (router mode only)

### 3. Tor Connectivity Tests
- ✅ Tor circuit established
- ✅ Exit IP validation via check.torproject.org
- ✅ SOCKS5 proxy functional

### 4. Mode Switching Tests
- ✅ Switch between modes (proxy, router, killa-whale)
- ✅ Configuration persists
- ✅ Services restart properly

### 5. API Tests
- ✅ API endpoint responds
- ✅ JSON status data valid
- ✅ Mode and security level reported

---

## Platform Recommendations

### For Development/CI
**Use:** Docker (`test-docker.sh`)
- Fastest execution
- No cleanup needed
- Works on any Docker-capable system
- Perfect for pre-commit checks

### For Production Validation
**Use:** Hetzner Cloud (`test-hetzner.sh`)
- Real ARM hardware
- Tests all modes including Killa Whale
- Full network stack
- Minimal cost (~$0.01 per run)

### For Local Testing Without Cloud
**Use:** QEMU (`test-qemu.sh`)
- Free
- Runs locally
- ARM64 emulation
- Requires manual Alpine setup

### For GUI Access
**Use:** VirtualBox (`test-virtualbox.sh`)
- Visual console access
- Easy troubleshooting
- Cross-platform
- Requires manual setup

---

## Docker Multi-Mode Testing

Test all modes simultaneously:

```bash
cd testing/containers
docker-compose -f docker-compose-test.yml up -d

# Test each mode
curl --socks5 localhost:9050 https://check.torproject.org/api/ip  # Proxy
curl --socks5 localhost:9052 https://check.torproject.org/api/ip  # Hardened
curl --socks5 localhost:9054 https://check.torproject.org/api/ip  # Paranoid

# Check status
docker-compose -f docker-compose-test.yml ps

# View logs
docker-compose -f docker-compose-test.yml logs tide-proxy

# Cleanup
docker-compose -f docker-compose-test.yml down
```

---

## Limitations by Platform

### Docker Limitations
- ❌ Killa Whale mode (ARP poisoning requires kernel access)
- ⚠️ Router mode works but limited (no physical network bridging)
- ✅ Perfect for proxy mode and API testing

### QEMU Limitations
- ⚠️ Slower than native (emulation overhead)
- ⚠️ Requires manual Alpine installation
- ✅ Full feature support once installed

### VirtualBox Limitations
- ⚠️ Requires GUI or complex serial automation
- ⚠️ ARM64 support varies by host platform
- ✅ Best for visual debugging

### Hetzner Cloud Limitations
- 💰 Costs money (minimal, but not free)
- 🌍 Requires internet connection
- ✅ Most realistic production environment

---

## Adding New Test Platforms

To add a new platform:

1. Create test script in appropriate directory:
   - `cloud/` - Cloud providers (AWS, DigitalOcean, etc.)
   - `containers/` - Container platforms (Podman, LXC, etc.)
   - `hypervisors/` - Hypervisors (VMware, Hyper-V, etc.)

2. Follow the pattern from `test-hetzner.sh`:
   ```bash
   #!/bin/bash
   # [1/N] Create environment
   # [2/N] Install Tide Gateway v1.2.0
   # [3/N] Run test suite
   # [4/N] Cleanup
   ```

3. Include standard test suite:
   - CLI command test
   - Configuration files test
   - Services running test
   - Tor connectivity test
   - Mode switching test

4. Update this README with platform details

---

## Troubleshooting

### Docker Tests Fail

```bash
# Check Docker daemon
docker info

# Check for port conflicts
lsof -i :9050

# View container logs
docker logs tide-test-<container-id>

# Clean up stuck containers
docker ps -a | grep tide-test | awk '{print $1}' | xargs docker rm -f
```

### Hetzner Tests Fail

```bash
# Verify token
cat ~/.config/tide/hetzner.env

# Check hcloud CLI
hcloud server list

# Manual cleanup
hcloud server list | grep tide-test
hcloud server delete <server-name>
```

### QEMU Won't Boot

```bash
# Verify QEMU installation
qemu-system-aarch64 --version

# Check ISO
ls -lh alpine-virt-3.21.0-aarch64.iso

# Try with graphics (slower but easier to debug)
qemu-system-aarch64 -M virt -m 1024 -cdrom alpine-virt-3.21.0-aarch64.iso
```

---

## Future Enhancements

- [ ] AWS EC2 testing script
- [ ] DigitalOcean testing script
- [ ] GitHub Actions integration
- [ ] Fully automated QEMU with expect
- [ ] Performance benchmarking suite
- [ ] Security audit tests
- [ ] Multi-client load testing
- [ ] Network performance tests

---

## Contributing

When adding tests:
1. Keep tests self-contained
2. Clean up resources automatically
3. Provide clear success/failure output
4. Document prerequisites
5. Include cost estimates (if applicable)

---

**Last Updated:** 2024-12-10  
**Tide Version:** 1.2.0  
**Tested Platforms:** Docker ✅, Hetzner ✅, QEMU ⚠️, VirtualBox ⚠️
