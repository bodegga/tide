# Changelog

All notable changes to Tide Gateway will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Client GUI applications (native desktop apps)
- Advanced ARP takeover mode refinements
- Bridge relay support for censored regions
- Interactive circuit control (select exit country)
- Bandwidth usage graphs
- WebSocket live updates

---

## [1.2.0] - 2025-12-10

### Added
- **Web Dashboard** - Full-featured status interface at http://tide.bodegga.net
  - Real-time Tor connection status with visual indicators
  - Mode, security profile, and uptime display
  - Current Tor exit IP and country information
  - Connected DHCP clients counter
  - ARP poisoning status (Killa Whale mode)
  - Network health monitoring
  - Auto-refresh every 30 seconds
  - Mobile-responsive dark theme UI
- **Aggressive DNS Hijacking** - tide.bodegga.net ALWAYS resolves to 10.101.101.10
  - dnsmasq configuration with address hijacking
  - iptables enforcement in Killa Whale mode (no escape)
  - Works like commercial routers (Ubiquiti, Netgear approach)
- **Enhanced CLI Tool** - Comprehensive `tide` command
  - `tide status` - Full gateway status with colored output
  - `tide check` - Verify Tor connectivity
  - `tide circuit` - Show current exit IP and country
  - `tide newcircuit` - Request new Tor circuit
  - `tide clients` - List connected DHCP clients
  - `tide arp` - Show ARP poisoning status
  - `tide logs` - View Tor logs
  - `tide web` - Show dashboard URL
  - `tide help` - Command reference
- **Network Health Monitoring**
  - Connected client tracking
  - ARP poisoning process monitoring
  - Network scanner status
  - Real-time statistics
- **JSON API Enhancements**
  - `/api/status` - Full gateway status endpoint
  - `/health` - Simple health check
  - Enhanced circuit information
  - Network statistics included

### Changed
- **gateway-start.sh** - Now starts web dashboard server on port 80
- **dnsmasq configuration** - Added DNS hijacking for tide.bodegga.net
- **README.md** - Added Web Dashboard section with usage examples
- Service startup order optimized for dashboard availability

### Technical Details
- **Web Server**: Python3 http.server (lightweight, no dependencies)
- **Dashboard Port**: 80 (HTTP)
- **API Port**: 9051 (JSON endpoints)
- **DNS Hijacking**: dnsmasq `address=/tide.bodegga.net/10.101.101.10`
- **Killa Whale Enforcement**: iptables redirects all DNS to gateway
- **CLI Tool**: Shell script with ANSI color support
- **Auto-refresh**: JavaScript 30-second interval

### Documentation
- New file: `WEB-DASHBOARD-README.md` - Complete dashboard guide
- New file: `UPDATE-TO-V1.2.sh` - Upgrade script for existing deployments
- Updated: `README.md` with web dashboard section

### Upgrade Path
For existing v1.1.x deployments:
```bash
wget -O- https://raw.githubusercontent.com/bodegga/tide/main/UPDATE-TO-V1.2.sh | sh
```

---

## [1.1.1] - 2025-12-09

### Added
- **ONE-COMMAND deployment** - `curl -sSL https://tide.bodegga.net/deploy | bash`
- Working Parallels VM template (192MB compressed, 379MB extracted)
- Automated VM creation and provisioning via `prlctl`
- Killa Whale mode fully operational with:
  - ARP poisoning for network takeover
  - Tor transparent proxy (port 9040)
  - DHCP server (10.101.101.100-200 range)
  - DNS over Tor (port 5353)
  - Fail-closed firewall (blocks all non-Tor traffic)
- Comprehensive deployment scripts:
  - `ONE-COMMAND-DEPLOY.sh` - Download and deploy instantly
  - `DEPLOY-TEMPLATE.sh` - Clone pre-built template and start
  - `PACKAGE-RELEASE.sh` - Package template for GitHub releases
  - `FINAL-INSTALL.sh` - Install Tide in fresh Alpine VM
  - `CLEAN-DEPLOY.sh` - Convert fresh Alpine to Tide Gateway
- Documentation suite:
  - `DEPLOYMENT-README.md` - Complete deployment guide
  - `FRESH-INSTALL-GUIDE.md` - Manual installation walkthrough
  - `KILLA-WHALE-MODE-WARNING.md` - Security and legal warnings

### Changed
- **Major architecture shift**: Moved from Docker to VM-based deployment
  - Docker cannot access kernel for ARP poisoning (Killa Whale mode requirement)
  - VMs provide full kernel access for network manipulation
- Improved Alpine package handling in installer scripts
- Fixed DNS configuration issues (proper nameserver setup)
- Fixed Tor permissions (`/var/lib/tor` ownership corrected)
- Standardized gateway IP to 10.101.101.10 across all modes

### Fixed
- DNS resolution failures in fresh Alpine installations
- Tor service failing to start due to permission errors
- dnsmasq address conflicts with system DNS
- Network interface detection in automated scripts

### Technical Details
- **Base OS**: Alpine Linux 3.21 (ARM64)
- **Services**: Tor, dnsmasq, iptables, arping, nmap
- **Network**: 
  - eth0 = shared network (internet access)
  - eth1 = host-only network (attack/client network)
- **Gateway IP**: 10.101.101.10
- **Auto-start**: OpenRC services enabled for boot
- **Development time**: 6-hour evening session (Dec 9, 2025)

### Session Notes
Tonight's development session (6 hours) involved:
- Testing multiple deployment approaches: Docker → QEMU → Parallels
- Discovering Docker's kernel access limitation for ARP poisoning
- Building automated VM provisioning with `prlctl` CLI
- Creating compressed template for easy distribution
- Final solution: Pre-built Parallels template with one-command deployment

---

## [1.1.0] - 2025-12-07

### Added
- Universal Tor Appliance release
- Cloud-init build system for automated VM provisioning
- Multi-architecture support (x86_64 and ARM64)
- QEMU/KVM deployment support
- Consolidated `build-release.sh` script
- Test modes in `run-tide-qemu.sh`
- Proper `.gitignore` for binary artifacts

### Changed
- Fixed cloud-init configuration (proper file naming, working credentials)
- Reorganized development docs into `dev-docs/` directory
- Cleaned up README with clearer setup instructions
- Updated repository structure for professional presentation

### Fixed
- Cloud-init password configuration
- Build artifact organization

### Technical Details
- **Default credentials**: root/tide
- **LAN IP**: 10.101.101.10
- **Services**:
  - Tor transparent proxy (port 9040)
  - DNS server (port 5353)
  - SOCKS5 proxy (port 9050)
- **Release artifacts**:
  - `tide-gateway.qcow2` (Alpine cloud image)
  - `cloud-init.iso` (auto-configuration seed)
  - `tide-autoinstall-efi.iso` (fresh install option)

---

## [1.2.0] - 2025-12-09 (DELETED)

> **Note**: This release was deleted during version cleanup. Git history preserved at commit `c319ef6`.

This version introduced Docker Router Mode and was later superseded by v1.1.1's VM-based approach.

### What Was in This Release
- Docker Router Mode with DHCP + transparent routing
- Docker Proxy Mode (SOCKS5 only) as alternative
- Automated DHCP configuration for zero-config clients
- Complete end-to-end testing of transparent Tor routing
- Documentation: START-HERE.md, README-MODES.md, ROADMAP.md
- Braille egg logo branding (`🥚 freedom within the shell`)
- Security audit and persistence documentation

### Why It Was Removed
- Version number conflict during development
- Functionality preserved and improved in v1.1.1
- Docker mode discovered to be insufficient for Killa Whale mode

---

## [1.0.0] - 2025-12-07 (DELETED)

> **Note**: This release was deleted during version cleanup. Git history preserved at commit `abb234e`.

### What Was in This Release
- Initial public release as "Tide Gateway"
- Transition from private "opsec-vm" project
- Basic Tor transparent proxy functionality
- VM deployment for Parallels Desktop
- Manual configuration workflows

### The Origin Story
Tide Gateway started as "opsec-vm" - a personal privacy project for securing internet traffic through Tor. The Dec 7-9 development sprint transformed it into a polished, distributable privacy tool with multiple deployment modes and professional documentation.

### Early Commits (Historical Record)
- First working Tor Gateway configuration
- Parallels VM setup and clipboard support
- XFCE desktop environment
- nftables firewall rules
- Client-side routing configuration
- .onion domain resolution fixes
- Dark web access documentation

---

## Development History

### The 6-Hour Sprint (Dec 9, 2025 evening)

A focused development session that evolved through multiple approaches:

**Phase 1: Docker Discovery (8pm-10pm)**
- Initial attempt: Docker-based Killa Whale mode
- Problem discovered: Docker containers can't manipulate host ARP tables
- Lesson learned: Network takeover requires kernel access

**Phase 2: QEMU Exploration (10pm-11pm)**
- Built QEMU automation scripts
- Created Alpine VM templates
- Tested various installer approaches
- Multiple scripts created: ALPINE-POST-SETUP.sh, FINISH-INSTALL.sh, QUICK-SETUP.sh

**Phase 3: Parallels Automation (11pm-2am)**
- Discovered `prlctl` CLI for VM automation
- Created automated deployment scripts
- Built compressed VM template (192MB)
- Achieved one-command deployment goal
- Final success: Working Killa Whale mode with ARP poisoning

### Technical Evolution
| Iteration | Approach | Status | Reason |
|-----------|----------|--------|--------|
| Docker | Container-based | ❌ Failed | No kernel/ARP access |
| QEMU | Manual VM setup | ⚠️ Works but clunky | Requires manual setup |
| Parallels | Automated template | ✅ **Final solution** | One command, just works |

### Key Breakthroughs
1. **Killa Whale naming** - Andre Nickatina tribute for aggressive mode
2. **ARP poisoning realization** - Need VMs, not containers
3. **Template strategy** - Pre-build everything, compress, distribute
4. **prlctl automation** - No GUI needed, fully scriptable

### Deployment Method Progression
```
v1.0.0: Manual VM setup (old opsec-vm approach)
    ↓
v1.1.0: Cloud-init automation (better, still manual)
    ↓
v1.2.0: Docker attempt (blocked by kernel requirements)
    ↓
v1.1.1: VM template + one-command deploy (FINAL)
```

---

## Version History Overview

| Version | Date | Type | Status | Key Feature |
|---------|------|------|--------|-------------|
| 1.1.1 | 2025-12-09 | Current | ✅ Active | ONE-COMMAND deployment + Killa Whale |
| 1.1.0 | 2025-12-07 | Previous | ✅ Stable | Cloud-init + Universal support |
| 1.2.0 | 2025-12-09 | Deleted | 🗑️ Removed | Docker Router Mode (superseded) |
| 1.0.0 | 2025-12-07 | Deleted | 🗑️ Removed | Initial public release |

---

## Roadmap

### v1.2.0 (Next Release)
- [ ] Refine Killa Whale mode stability
- [ ] Add network health monitoring
- [ ] Improve VM template compression
- [ ] Support more hypervisors (UTM, VirtualBox)
- [ ] Add bandwidth statistics

### v1.3.0 (Client Apps)
- [ ] Native macOS client GUI
- [ ] Native Linux client GUI  
- [ ] Native Windows client GUI
- [ ] Unified configuration management
- [ ] Connection status monitoring

### v1.4.0 (Advanced Features)
- [ ] Web-based admin interface
- [ ] Tor bridge relay support
- [ ] Multi-gateway load balancing
- [ ] Traffic analysis tools
- [ ] Enhanced logging and alerts

### Future Considerations
- Mobile client support (iOS/Android)
- Hardware appliance version
- Commercial support options
- Enterprise deployment guides

---

## Versioning Policy

Tide Gateway follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes, architectural shifts
- **MINOR** (1.X.0): New features, backward compatible
- **PATCH** (1.1.X): Bug fixes, security patches, improvements

### What Constitutes a Breaking Change
- Changes to network configuration (IPs, ports)
- Removal of deployment modes
- Changes to client authentication
- Incompatible VM template formats

---

## How to View Full History

All development work is preserved in git:

```bash
# See all commits
git log --all --oneline --graph

# See commits for specific version
git log v1.1.0..v1.1.1

# See detailed commit
git show <commit-hash>

# See what was in deleted releases
git show v1.0.0  # or v1.2.0
```

---

## Links

- **GitHub**: https://github.com/bodegga/tide
- **Website**: https://tide.bodegga.net
- **Releases**: https://github.com/bodegga/tide/releases
- **Issues**: https://github.com/bodegga/tide/issues

---

*This changelog follows the [Keep a Changelog](https://keepachangelog.com/) format.*  
*Tide Gateway - freedom within the shell 🌊*
