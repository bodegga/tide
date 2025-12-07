# OPSEC VM Setup - Session Recovery

**Date:** 2025-12-07  
**Status:** 🟡 IN PROGRESS - Session crashed during configuration  
**Location:** M4 MacBook Air

---

## What Was Built Before Crash

### VM Infrastructure Created

Two Parallels VMs following Whonix-style Gateway/Workstation architecture:

| VM Name | Location | Created | Size | Purpose |
|---------|----------|---------|------|---------|
| **Tor-Gateway.pvm** | `~/Parallels/` | 14:36 today | 64GB allocated | Routes all traffic through Tor |
| **SecuredWorkstation.pvm** | `~/Parallels/` | 14:54 today | 64GB allocated | Isolated workstation (all traffic forced through Gateway) |

### Downloaded ISOs

Location: `~/Downloads/`

- ✅ `debian-12-arm64.iso` (551MB) - Full installer
- ✅ `debian-12.8.0-arm64-netinst.iso` (158MB) - Net installer
- ✅ `debian-12.9.0-arm64-netinst.iso` (2KB - metadata file)
- ✅ `debian-13.2.0-arm64-netinst.iso` (772MB) - Testing release
- ✅ `tor-browser-macos-15.0.2.dmg` (176MB)
- ✅ `Whonix-Xfce-17.4.4.6.Intel_AMD64.ova` (12MB - x86, reference only)
- 📁 `~/Downloads/Whonix/` directory created

### Network Configuration (From config.pvs)

**Tor-Gateway VM:**
- **Adapter 0 (eth0):** Shared Network (internet access)
  - EmulatedType: 1 (virtio)
  - Connected: Yes
- **Adapter 1:** Host-Only Network (internal LAN to Workstation)
  - EmulatedType: 0 (e1000)
  - Connected: Yes

**SecuredWorkstation VM:**
- Single adapter configuration (needs to be Host-Only to Gateway)

### Architecture Reference

From `/Users/abiasi/Downloads/compass_artifact_wf-56d85f30-4eb1-4e22-8139-35d05d727838_text_markdown.md`:

**Gateway Configuration (Target State):**
- Two network adapters: Shared Network (internet) + Host Only (internal LAN at 10.152.152.10)
- Tor configured with TransPort (9040), DnsPort (5353), multiple SOCKS ports
- nftables rules allowing only Tor user to reach external network
- All other traffic blocked (fail-closed design)

**Workstation Configuration (Target State):**
- Single Host Only adapter (same internal network as Gateway's second interface)
- Static IP: 10.152.152.11 with Gateway as default route (10.152.152.10)
- DNS pointing to Gateway's DnsPort
- No direct internet path - all traffic forced through Gateway's Tor instance

---

## Current Status

### ✅ Completed
- [x] Parallels Desktop installed on M4 MacBook Air
- [x] Downloaded multiple Debian ARM64 ISOs
- [x] Created Tor-Gateway VM
- [x] Created SecuredWorkstation VM
- [x] Configured dual network adapters on Tor-Gateway

### 🟡 In Progress / Unknown State
- [ ] Debian installation on Tor-Gateway (VM shows debian-12-arm64.iso mounted)
- [ ] Debian installation on SecuredWorkstation
- [ ] Kicksecure repository configuration
- [ ] Tor daemon configuration on Gateway
- [ ] nftables firewall rules on Gateway
- [ ] Host-Only network IP assignments (10.152.152.10/11)

### ⏸️ Not Started
- [ ] macOS host hardening (swap disable, FileVault, etc.)
- [ ] Workstation network isolation testing
- [ ] Tor Browser installation on Workstation
- [ ] Anti-forensic configurations (snapshot mode, RAM disk)
- [ ] Documentation of setup process

---

## Next Steps (Recovery Plan)

### 1. Check VM Installation State
```bash
# Open Parallels Control Center
open -a "Parallels Desktop"

# Check if Debian installer is running or completed
# Boot Tor-Gateway VM and check install status
```

### 2. Complete Debian Base Installation

**For Tor-Gateway:**
- Boot from debian-12-arm64.iso
- Install base system
- Set hostname: `tor-gateway`
- Configure network: eth0 (DHCP), eth1 (static 10.152.152.10/24)
- Install OpenSSH server for management

**For SecuredWorkstation:**
- Boot from debian-12-arm64.iso
- Install base system
- Set hostname: `secured-workstation`
- Configure network: static 10.152.152.11/24, gateway 10.152.152.10

### 3. Apply Kicksecure Hardening

```bash
# On both VMs, add Kicksecure repository
sudo apt-key --keyring /etc/apt/trusted.gpg.d/derivative.gpg adv \
  --keyserver keyserver.ubuntu.com \
  --recv-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA

echo "deb [signed-by=/etc/apt/trusted.gpg.d/derivative.gpg] \
  https://deb.kicksecure.com bookworm main contrib non-free" \
  | sudo tee /etc/apt/sources.list.d/derivative.list

sudo apt update
sudo apt install kicksecure-cli
```

### 4. Configure Tor Gateway

```bash
# Install Tor
sudo apt install tor tor-geoipdb

# Configure /etc/tor/torrc
# (See GATEWAY_TOR_CONFIG.md for full configuration)

# Install nftables
sudo apt install nftables

# Apply firewall rules
# (See GATEWAY_FIREWALL_RULES.md for configuration)
```

### 5. Test Isolation

```bash
# From Workstation, check public IP (should show Tor exit node)
curl ifconfig.me

# Check DNS leaks
nslookup google.com

# Verify no direct internet path
sudo route -n  # Should only show 10.152.152.10 as gateway
```

---

## Host Hardening TODO

**⚠️ CRITICAL: These must be completed for proper OPSEC**

### Disable macOS Swap (Prevent VM memory leaks to disk)
```bash
# Boot to Recovery Mode (hold Power during boot)
# In Recovery Terminal:
csrutil disable

# After reboot to normal mode:
sudo nvram boot-args="vm_compressor=2"
sudo pmset -a hibernatemode 0
sudo rm /private/var/vm/sleepimage

# Verify:
sysctl vm.compressor_mode  # Should show 2, not 4
```

### FileVault Encryption
```bash
# System Settings → Privacy & Security → FileVault
# Enable if not already active
```

### Disable Spotlight Indexing for VMs
```bash
sudo mdutil -i off ~/Parallels/
```

### Disable macOS Telemetry
- System Settings → Privacy & Security → Analytics & Improvements
- Disable all sharing options

### Little Snitch (Optional but Recommended)
- Install Little Snitch
- Block ocsp.apple.com
- Deny all Apple telemetry processes

---

## Architecture Decisions

### Why Parallels Instead of UTM?

**⚠️ WARNING: The guide recommends UTM for security reasons**

From the Kicksecure guide:
> UTM is the recommended hypervisor for security-focused use
> - Open source, auditable
> - Excellent anti-forensics (snapshot mode, no telemetry)
> - Uses Apple Hypervisor.framework
> - QEMU backend for better isolation control

**Parallels concerns:**
- Closed source
- Deep macOS integration (Coherence mode)
- Account required
- Poor anti-forensics rating

**Decision to be made:**
- [ ] Continue with Parallels (easier, better performance)
- [ ] Migrate to UTM (better security, open source)

### Current Threat Model

**What we're protecting against:**
- Network-level surveillance
- Forensic analysis of host system
- IP address correlation
- Browser fingerprinting

**What we're NOT defending against:**
- State-level adversaries with physical access
- macOS kernel exploits
- Hypervisor escapes
- Supply chain attacks on Parallels Desktop

---

## Files & Locations

### VMs
- `~/Parallels/Tor-Gateway.pvm/`
- `~/Parallels/SecuredWorkstation.pvm/`

### ISOs
- `~/Downloads/debian-12-arm64.iso` (mounted in Tor-Gateway)
- `~/Downloads/debian-12.8.0-arm64-netinst.iso`
- `~/Downloads/debian-13.2.0-arm64-netinst.iso`

### Documentation
- `~/Downloads/compass_artifact_wf-56d85f30-4eb1-4e22-8139-35d05d727838_text_markdown.md`
  - Complete Kicksecure/Whonix guide for Apple Silicon
- `/Users/abiasi/Documents/Personal-Projects/opsec-vm/` (this project)

---

## Questions to Answer

1. **What stage is Debian installation at?**
   - Need to boot VMs and check
   
2. **Has any Tor configuration been done?**
   - Check `/etc/tor/torrc` on Gateway VM
   
3. **Are IP addresses assigned?**
   - Check `ip addr` on both VMs
   
4. **Is Host-Only network created in Parallels?**
   - Check Parallels Network preferences
   
5. **Has any host hardening been done?**
   - Check `sysctl vm.compressor_mode`
   - Check FileVault status
   
---

## Reference: Expected Final State

### Tor-Gateway
- **OS:** Debian 12 ARM64 + Kicksecure hardening
- **Hostname:** tor-gateway
- **Network:**
  - eth0: DHCP (Shared Network to internet)
  - eth1: 10.152.152.10/24 (Host-Only to Workstation)
- **Services:**
  - Tor daemon (TransPort 9040, DnsPort 5353)
  - SSH server (for management)
- **Firewall:** Only `debian-tor` user can reach internet

### SecuredWorkstation
- **OS:** Debian 12 ARM64 + Kicksecure hardening
- **Hostname:** secured-workstation
- **Network:**
  - eth0: 10.152.152.11/24, gateway 10.152.152.10, DNS 10.152.152.10
- **Services:**
  - Tor Browser
  - Development tools (as needed)
- **Isolation:** No direct internet access, all traffic via Gateway

---

**Next Action:** Boot Tor-Gateway VM and determine installation state, then proceed with configuration checklist above.
