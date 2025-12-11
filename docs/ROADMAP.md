# Tide Gateway - Roadmap

## ✅ Completed

### v1.0 - Core Functionality
- [x] Proxy Mode (SOCKS5 + DNS)
- [x] Router Mode (DHCP + Transparent Routing)
- [x] Docker containers (Alpine-based)
- [x] macOS compatibility
- [x] Tor integration with TransPort
- [x] iptables transparent proxy
- [x] dnsmasq DHCP server
- [x] Mode selection (Proxy vs Router)
- [x] Configuration via .env
- [x] Comprehensive documentation

**Status:** Both Proxy and Router modes fully tested and working.

---

## 🚧 In Development

### v1.1 - Client GUI Application
**Goal:** Easy-to-use desktop app for managing Tide connection

**Features:**
- [ ] System tray icon (Windows, macOS, Linux)
- [ ] One-click connect/disconnect
- [ ] Network status indicator
- [ ] Tor circuit information
- [ ] Exit IP display
- [ ] Connection logs
- [ ] Auto-connect on startup
- [ ] Notification alerts

**Tech Stack:**
- Python + pystray for system tray
- Cross-platform (Windows, macOS, Linux)
- Minimal dependencies

**Location:** `/client/tide-client.py` (exists, needs completion)

---

### v1.2 - Takeover Mode
**Goal:** ARP hijacking for full subnet control

**Features:**
- [ ] ARP spoofing implementation
- [ ] Network device discovery
- [ ] Selective device targeting
- [ ] Safety mechanisms (restoration scripts)
- [ ] Network state monitoring
- [ ] Conflict detection
- [ ] Automatic fallback on error

**Security Considerations:**
- Only use on networks you own
- Require explicit user confirmation
- Implement kill switch for restoration
- Log all hijacked devices
- Detect and handle network conflicts

**Dependencies:**
- scapy (ARP manipulation)
- Enhanced iptables rules
- Network monitoring tools

---

## 📋 Planned Features

### v1.3 - Forced Mode (Fail-Closed)
- [ ] Strict OUTPUT firewall rules
- [ ] Tor health monitoring
- [ ] Automatic circuit refresh
- [ ] Leak detection
- [ ] Emergency lockdown mode

### v1.4 - Security Profiles
- [ ] Standard (current default)
- [ ] Hardened (exclude 14-eyes)
- [ ] Paranoid (maximum isolation)
- [ ] Bridges (obfs4 support)

### v1.5 - VM Images
- [ ] Pre-built qcow2 images
- [ ] OVA for universal import
- [ ] Cloud-init integration
- [ ] UTM/QEMU templates
- [ ] Parallels support

### v2.0 - Advanced Features
- [ ] Multi-hop Tor circuits
- [ ] Custom exit node selection
- [ ] Bandwidth monitoring
- [ ] Traffic statistics
- [ ] Web UI dashboard
- [ ] Mobile app support

---

## Current Focus

**Priority 1:** Client GUI Application
- Make Tide accessible to non-technical users
- One-click connection experience
- Visual feedback on Tor status

**Priority 2:** Takeover Mode Development & Testing
- Complete ARP hijacking implementation
- Extensive testing in isolated environments
- Safety mechanisms and rollback procedures
- Documentation for responsible use

---

## Contributing

Interested in helping? Check out:
- `/client/tide-client.py` - GUI application needs completion
- `gateway-start.sh` - Add Takeover mode logic here
- Documentation improvements always welcome

---

**Last Updated:** Dec 9, 2025  
**Current Version:** 1.0 (Router Mode stable)  
**Next Release:** 1.1 (Client GUI)
