# Changelog

All notable changes to Tide Gateway will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned Features (v1.2.0)
- **Web Dashboard** - Full-featured status interface at http://tide.bodegga.net
  - Real-time Tor connection status with visual indicators
  - Mode, security profile, and uptime display
  - Current Tor exit IP and country information
  - Connected DHCP clients counter
  - ARP poisoning status (Killa Whale mode)
  - Network health monitoring
  - Auto-refresh every 30 seconds
  - Mobile-responsive dark theme UI
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
- **JSON API Enhancements**
  - `/api/status` - Full gateway status endpoint
  - `/health` - Simple health check
  - Enhanced circuit information
  - Network statistics included

**Note:** Features above are in git but not yet in VM template. Will be released as v1.2.0 when template is rebuilt.

### Developer Tools
- Client GUI applications (native desktop apps)
- Advanced ARP takeover mode refinements
- Bridge relay support for censored regions
- Interactive circuit control (select exit country)
- Bandwidth usage graphs
- WebSocket live updates

---

## [1.1.5] - 2025-12-11

### Fixed - CRITICAL BUG FIX
- **Port 80 Binding Issue** - Resolved Python HTTP server failure with zero-log policy
  - **Problem:** Python's `socketserver.TCPServer` could not bind port 80 when `StandardError=null`
  - **Impact:** Web dashboard was completely non-functional on port 80
  - **Root Cause:** Python HTTP server requires stderr for port binding errors
  - **Solution:** Implemented nginx reverse proxy (production-grade)
    - nginx serves port 80 (external)
    - Python dashboard runs on port 8080 (internal)
    - nginx configured with `access_log off; error_log /dev/null;`
    - Zero-log policy fully maintained
  - **Testing:** Validated on Hetzner CPX11 ARM server
    - First test: Port 80 FAILED with StandardError=null
    - Second test: Port 80 WORKS with nginx reverse proxy
    - Cost: $0.02 (2 tests × $0.01 each)

###Changed
- **Web Dashboard** - Now runs on port 8080 internally (nginx proxies to port 80)
- **Service Dependencies** - tide-web.service now requires nginx.service
- **Installation** - install-services.sh now installs and configures nginx-light
- **Version Display** - Dashboard and API now read version dynamically from VERSION file
  - Fixed hardcoded "1.2.0" references
  - Both HTML footer and JSON API show correct version

### Added
- **nginx Configuration** - `config/nginx/tide-dashboard.conf`
  - Zero-log compliant (no access logs, error logs to /dev/null)
  - Reverse proxy 80 → 8080
  - Security headers (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection)
  - Health check endpoint for monitoring

### Security
- ✅ **Zero-Log Policy Maintained** - No user data logged
- ✅ **StandardError=null** - No stderr logging for both services
- ✅ **No Client IP Tracking** - nginx configured without X-Forwarded-For headers
- ✅ **Production-Grade HTTP Server** - nginx more robust than Python HTTP server

### Testing
- ✅ **All 7 tests passing** on Hetzner CPX11 (ARM, Ubuntu 22.04)
- ✅ Port 80 dashboard accessible and functional
- ✅ API on port 9051 working
- ✅ Tor connectivity confirmed
- ✅ Mode switching operational
- ✅ CLI commands functional
- ✅ Version displays correctly (1.1.5)

### Technical Details
- nginx-light package (~1MB) added as dependency
- CAP_NET_BIND_SERVICE capability removed (no longer needed)
- Port 8080 requires no special privileges
- nginx handles TLS termination capability for future HTTPS support

### Migration from v1.1.4
Users on v1.1.4 can update by pulling latest from GitHub and running:
```bash
cd /opt/tide
git pull
bash scripts/setup/install-services.sh
```

This release is **production-ready** and **fully tested** on real ARM hardware.

---

## [1.1.4] - 2025-12-11

### Fixed
- **Web Dashboard Port 80** - Now fully functional and accessible
  - Changed `StandardError` from `null` to `journal` in systemd service
  - Allows error logging while maintaining zero-log policy for user data
  - Port 80 now responds correctly with CAP_NET_BIND_SERVICE capability
- **Test Expectations** - Removed dnsmasq check (not installed by default)
  - dnsmasq only needed for router/killa-whale DHCP modes
  - Updated test suite to check API server instead

### Testing
- ✅ **100% tests passing** on Hetzner CPX11 (ARM)
- All 21 tests pass successfully
- Web dashboard, API, Tor, CLI all fully functional
- Tested on real ARM hardware (Ubuntu 22.04)

### Technical Details
- Zero-log policy maintained (errors logged, not user data)
- SystemError logging enables proper debugging without privacy violations
- All services auto-start correctly via systemd

---

## [1.1.3] - 2025-12-10

### Added - CRITICAL SECURITY UPDATE
- **Zero-Log Privacy Policy** - Comprehensive privacy implementation
  - No client IP logging (ever)
  - No request logging in web dashboard
  - No API call logging
  - Systemd services output to /dev/null
  - Created ZERO-LOG-POLICY.md (600+ lines of security documentation)
  - Philosophy: "If you don't collect it, you can't leak it"
- **Systemd Service Management**
  - tide-web.service - Web dashboard on port 80
  - tide-api.service - API server on port 9051
  - Auto-start on boot
  - Proper service dependencies (Tor must start first)
- **Hetzner Cloud Platform Documentation**
  - HETZNER-PLATFORM.md - Comprehensive platform guide
  - Cost analysis: 28-52% cheaper than DigitalOcean
  - Migration planning for production workloads
  - Annual testing cost: ~$3/year
- **Installation Scripts**
  - install-services.sh - Systemd service installer
  - Automated service deployment in test environments

### Fixed
- **Web Dashboard Port 80** - Added CAP_NET_BIND_SERVICE capability
- **API Version** - Now reads from VERSION file dynamically (was hardcoded)
- **Zero-Log Violations** - Removed all startup/shutdown logging messages
- **Service Auto-Start** - Services now properly start via systemd
- **VERSION File Distribution** - Copied to /opt/tide for runtime version detection

### Changed
- **Testing Priority** - Hetzner Cloud is now PRIMARY testing platform
  - Real ARM hardware (not containerized)
  - Production-realistic environment
  - Updated GETTING-STARTED.md to reflect priority
- **Privacy First** - All code reviewed for logging violations
- **Service Architecture** - Moved from manual startup to systemd management

### Security
- **ZERO-LOG POLICY ENFORCED**
  - Web dashboard: No client tracking
  - API server: No call logging
  - Systemd: All output to /dev/null
  - Privacy is not a feature - it's the entire point

### Technical Details
- **Services verified on:** Hetzner Cloud ARM (Ubuntu 22.04)
- **Test results:** All core functionality working
- **Version format:** Semantic versioning (MAJOR.MINOR.PATCH)
- **Git commits as builds:** Development between releases tracked via git

### Breaking Changes
None - Fully backwards compatible with v1.1.2

---

## [1.1.2] - 2025-12-10

### Added
- **Test Orchestration System** - Parallel testing across platforms
  - Docker testing (2-3 min, free)
  - Hetzner Cloud testing (5 min, ~$0.01 per test)
  - QEMU and VirtualBox support
  - Automated result aggregation
  - Visual HTML dashboards
- **Test Validation Framework** - Ensures tests match features
  - TEST-SPEC.yml specification system
  - Automated version consistency checking
  - Feature coverage validation
  - CHANGELOG alignment verification
- **Comprehensive Testing Documentation**
  - Multi-platform testing guides
  - Test maintenance workflow
  - Platform comparison matrix
  - Quick start guides

### Changed
- **Repository Organization** - Enforced file structure
  - Moved scripts to proper directories
  - GitHub Actions workflow for organization checks
  - Cleaned up root directory
- **Privacy & Security** - Removed personal info from public repo
  - IDEAS.md now local-only (gitignored)
  - Sanitized personal paths from archive scripts
  - Updated workflow to prevent future leaks

### Documentation
- Complete version history (VERSION-HISTORY.md)
- Test maintenance guide (TEST-MAINTENANCE.md)
- Testing quick start (GETTING-STARTED.md)
- Test orchestration documentation
- Platform testing comparison

### Technical Details
- **Testing cost:** ~$3/year for comprehensive cloud testing
- **Parallel execution:** Saves 2-3 minutes vs sequential
- **Bash 3.2 compatible:** Works on macOS default shell
- **CI/CD ready:** JSON output and exit codes

**Note:** This release focuses on developer/testing infrastructure. User-facing features (web dashboard, CLI) are in development for v1.2.0.

---
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
