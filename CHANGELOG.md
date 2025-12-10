# Changelog

All notable changes to Tide Gateway will be documented in this file.

## [v1.1.1] - 2025-12-09

### Added
- **Working Parallels VM template** (192MB compressed, 379MB extracted)
- **ONE-COMMAND deployment** - `curl -sSL ... | bash`
- **Automated VM creation** using prlctl
- **Killa Whale mode fully operational**
  - ARP poisoning working
  - Tor transparent proxy
  - DHCP server (10.101.101.100-200)
  - DNS over Tor
  - Fail-closed firewall
- Deployment scripts:
  - `ONE-COMMAND-DEPLOY.sh` - Download and deploy in one command
  - `DEPLOY-TEMPLATE.sh` - Clone template and start
  - `PACKAGE-RELEASE.sh` - Package template for release
  - `FINAL-INSTALL.sh` - Install Tide in fresh Alpine VM
  - `CLEAN-DEPLOY.sh` - Fresh Alpine to Tide Gateway
- Documentation:
  - `DEPLOYMENT-README.md` - Complete deployment guide
  - `FRESH-INSTALL-GUIDE.md` - Manual install instructions

### Changed
- Switched from Docker (can't access kernel) to VM-based deployment
- Improved installer scripts to handle Alpine package availability
- Fixed DNS configuration issues
- Fixed Tor permissions (`/var/lib/tor` ownership)

### Technical Details
- Built on Alpine Linux 3.21 (ARM64)
- Services: Tor, dnsmasq, iptables, arping, nmap
- Network: eth0=shared (internet), eth1=host-only (attack network)
- Gateway IP: 10.101.101.10
- Auto-starts on boot via OpenRC

### Session Notes
- 6 hours of development
- Multiple deployment approaches tested (Docker, QEMU, Parallels)
- Final solution: Parallels template with automated deployment
- Template creation automated via prlctl CLI

---

## [v1.1.0] - 2025-12-08

### Added
- Universal Tor Appliance release
- Cloud-init build system
- Multi-architecture support

---

## Development History (v1.0.0 - v1.2.0)

*Note: These releases were removed during versioning cleanup, but all commits are preserved in git history.*

### Dec 9, 2025 - Killa Whale Development
- Renamed "forced" mode to "Killa Whale" (Andre Nickatina tribute)
- Implemented ARP poisoning and aggressive network takeover
- Discovered Docker limitation (needs kernel access for Killa Whale)
- Created multiple installer scripts:
  - `ALPINE-POST-SETUP.sh`
  - `FINISH-INSTALL.sh`
  - `QUICK-SETUP.sh`
  - `SIMPLE-START.sh` / `SIMPLE-START-V2.sh`
  - `DIAGNOSE.sh`
  - `FIX-PERMISSIONS.sh`
- Built QEMU automation scripts
- Created Parallels deployment automation
- Fixed DNS, Tor permissions, network configuration issues
- **Final achievement**: Working VM template with one-command deployment

### Earlier Development
- Mode selection system (proxy, router, killa-whale, takeover)
- Fail-closed firewall implementation
- Tide wave icon and brand assets
- Native client apps (macOS, Linux, Windows)
- API token authentication
- Standard repository files

---

## Git History Preserved

All development work is preserved in git commits. Use:
```bash
git log --oneline --all
```

To see full development history.

---

**Versioning Philosophy**: 
- Major (X.0.0): Breaking changes
- Minor (1.X.0): New features
- Patch (1.1.X): Bug fixes, improvements

