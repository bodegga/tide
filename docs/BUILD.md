# Building Tide from Source

## Goal

Lightweight, universal Tor gateway for ARM64 systems.

## Recommended: Alpine Linux

**Why:** 150MB footprint vs 3GB (Debian). Minimal attack surface.

### Requirements
- ARM64 system (Apple Silicon, ARM server, etc.)
- Hypervisor (Parallels, UTM, VMware, VirtualBox, KVM)
- Alpine Linux ARM64 ISO

### Build Steps

1. **Create VM**
   - 512MB RAM
   - 2GB disk
   - 2 network adapters (Shared + Host-Only)

2. **Install Alpine**
   ```bash
   setup-alpine
   ```

3. **Configure Tor**
   ```bash
   apk add tor iptables
   # Configure /etc/tor/torrc
   # Configure firewall rules
   ```

4. **Export**
   - Export as OVA for universal compatibility
   - Test on multiple hypervisors

## Current Release

v1.0.0 uses Debian (tested, stable, working).

Alpine version in development.

---

**Contributions welcome!**
