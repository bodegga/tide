# Tide Gateway - Agent Context

**Project:** Tide Gateway - Transparent Internet Defense Engine  
**Type:** Privacy Appliance / Tor Gateway  
**Status:** Active Development  
**Current Version:** v1.1.3  
**Repository:** https://github.com/bodegga/tide

---

## 🚨 MANDATORY STARTUP

**Before doing ANYTHING, execute these in parallel:**

1. Read this file (AGENTS.md)
2. Run `pwd` to confirm you're in `/Users/abiasi/Documents/Personal-Projects/tide`
3. Run `git status` to check current branch and changes
4. Run `git pull` to sync with GitHub
5. Check `cat VERSION` to see current version

**Then proceed with the user's request.**

---

## 🎯 Project Overview

### What is Tide Gateway?

**Tide Gateway** is a **privacy appliance** that:
- Routes ALL network traffic through Tor anonymously
- Works as a VM/appliance on any hypervisor
- Provides web dashboard for monitoring
- Supports multiple deployment modes (proxy, router, killa-whale)
- **Zero-log policy** - no client tracking, no request logging

**Target Users:**
- Privacy-conscious individuals
- Journalists/activists in hostile environments
- Researchers needing anonymity
- Anyone wanting transparent Tor routing for all devices

### Core Philosophy

**"Privacy is not a feature. It's the entire point."**

- Zero logs = zero evidence
- If you don't collect it, you can't leak it
- Open source = provable privacy
- No telemetry, no tracking, no exceptions

---

## 📁 Project Structure

```
tide/
├── VERSION                          # Current version (1.1.3)
├── README.md                        # Main documentation
├── AGENTS.md                        # This file
├── config/                          # Configuration files
│   ├── systemd/                     # Service definitions
│   │   ├── tide-web.service         # Web dashboard service
│   │   └── tide-api.service         # API server service
│   ├── torrc-*                      # Tor security profiles
│   └── iptables-*.rules             # Firewall rules
├── scripts/
│   ├── build/                       # VM building scripts
│   │   ├── build-multi-platform.sh  # Build for all hypervisors ✨ NEW
│   │   ├── create-base-image.sh     # Create base Alpine image
│   │   └── convert-formats.sh       # Convert to OVA/VHDX/etc
│   ├── runtime/                     # Runtime scripts (run on VM)
│   │   ├── tide-web-dashboard.py    # Web dashboard (port 80)
│   │   ├── tide-api.py              # API server (port 9051)
│   │   ├── tide-cli.sh              # CLI commands (tide status, etc)
│   │   └── tide-config.sh           # Interactive config
│   └── setup/                       # Installation scripts
│       └── install-services.sh      # Install systemd services
├── deployment/                      # Deployment scripts
│   ├── hetzner/                     # Hetzner Cloud deployments
│   ├── parallels/                   # Parallels Desktop (macOS)
│   └── qemu/                        # QEMU/KVM
├── testing/                         # Testing infrastructure ⭐
│   ├── orchestrate-tests.sh         # Run all tests in parallel
│   ├── cloud/test-hetzner.sh        # Hetzner cloud testing ($0.01)
│   ├── cloud/test-matrix.sh         # Matrix testing (all configs)
│   ├── containers/test-docker.sh    # Docker testing (free)
│   └── results/                     # Test results archive
├── docs/                            # Comprehensive documentation
│   ├── CHANGELOG.md                 # Version history
│   ├── ZERO-LOG-POLICY.md           # Privacy policy (CRITICAL)
│   ├── HETZNER-PLATFORM.md          # Hetzner as primary platform
│   ├── HARDWARE-COMPATIBILITY.md    # What works on what hardware
│   ├── building/                    # Build documentation
│   │   └── MULTI-PLATFORM-BUILD.md  # How to build VMs
│   ├── deployment/                  # Deployment guides
│   └── guides/                      # User guides
├── release/                         # Release artifacts
│   └── v1.1.3/                      # Current release files
│       ├── vmware/                  # VMware ESXi OVA
│       ├── proxmox/                 # Proxmox QCOW2
│       ├── hyperv/                  # Hyper-V VHDX
│       └── virtualbox/              # VirtualBox OVA
└── client/                          # Client applications (future)
```

---

## 🚀 Current State (v1.1.3)

### What Works ✅

**Core Functionality:**
- ✅ Tor routing (SOCKS5 on port 9050)
- ✅ Web dashboard (port 80) with zero-log policy
- ✅ API server (port 9051) with dynamic versioning
- ✅ CLI commands (`tide status`, `tide config`, etc.)
- ✅ Multiple modes (proxy, router, killa-whale)
- ✅ Security profiles (standard, hardened, paranoid)
- ✅ Systemd services (auto-start on boot)

**Testing Infrastructure:**
- ✅ Hetzner Cloud testing (PRIMARY platform, $0.01/test)
- ✅ Docker testing (quick dev validation)
- ✅ Test orchestration (parallel execution)
- ✅ Matrix testing (multiple hardware/OS combos)
- ✅ Automated validation

**Build System:**
- ✅ Multi-platform VM builder (Phase 1 COMPLETE)
- ✅ Supports: VMware, Proxmox, Hyper-V, VirtualBox, QEMU, Parallels
- ✅ ARM64 and x86_64 architectures
- ✅ Automated format conversion

**Documentation:**
- ✅ Comprehensive CHANGELOG
- ✅ Zero-log policy documented
- ✅ Hetzner platform guide
- ✅ Hardware compatibility matrix
- ✅ Build system documentation

### What's In Progress 🔨

**Phase 2: Deployment Testing Suite**
- ⏳ ESXi deployment end-to-end testing
- ⏳ Proxmox deployment testing
- ⏳ Hyper-V deployment testing
- ⏳ Automated deployment tester

**Phase 3: Deployment Guides**
- ⏳ Screenshot-based guides
- ⏳ Video tutorials
- ⏳ Common pitfalls database

**Phase 4: Enhanced Features**
- ⏳ WireGuard VPN for mobile devices
- ⏳ Bandwidth monitoring
- ⏳ WebSocket live updates
- ⏳ Interactive setup wizard (`tide setup`)

### Known Issues ⚠️

- dnsmasq not running (determining if needed for killa-whale mode)
- README.md outdated (still shows v1.2.0, old logo)
- No VM templates built yet (build system ready, not executed)

---

## 🔧 Development Workflow

### Making Changes

1. **Check current version:**
   ```bash
   cat VERSION  # Should be 1.1.3
   ```

2. **Make changes to code**

3. **Test on Hetzner** (ALWAYS test on real hardware):
   ```bash
   cd testing/cloud
   ./test-hetzner.sh
   ```

4. **If tests pass, commit:**
   ```bash
   git add -A
   git commit -m "Description of changes"
   git push
   ```

5. **When ready to release:**
   ```bash
   # Bump version
   echo "1.1.4" > VERSION
   
   # Update CHANGELOG.md
   # Add [1.1.4] - 2025-12-XX section
   
   # Commit, tag, push
   git add VERSION docs/CHANGELOG.md
   git commit -m "Release v1.1.4 - Description"
   git tag -a v1.1.4 -m "Tide Gateway v1.1.4"
   git push origin main v1.1.4
   
   # Create GitHub release
   gh release create v1.1.4 --title "..." --notes "..."
   ```

### Testing Strategy

**Priority 1: Hetzner Cloud (ALWAYS)**
- Real ARM hardware
- Production-realistic environment
- Cost: $0.01 per test (~$3/year)
- Command: `cd testing/cloud && ./test-hetzner.sh`

**Priority 2: Docker (Quick validation)**
- Containerized testing
- Fast (2-3 min)
- Free
- Command: `cd testing/containers && ./test-docker.sh`

**Weekly: Matrix testing**
- Test multiple hardware configs
- Command: `cd testing && ./orchestrate-tests.sh matrix --quick`
- Cost: $0.03, 15 minutes

**Before releases: Full matrix**
- Command: `./orchestrate-tests.sh matrix --medium`
- Cost: $0.15, 40 minutes

### Versioning Strategy

**Semantic Versioning: MAJOR.MINOR.PATCH**

- **PATCH (1.1.X)** - Bug fixes, no new features
- **MINOR (1.X.0)** - New features, backwards compatible
- **MAJOR (X.0.0)** - Breaking changes

**Current: v1.1.3** (bug fixes and service improvements)

**Next: v1.2.0** - When web dashboard is in VM template (not just code)

**Git commits between releases** = "development builds" (tracked but not versioned)

---

## 🔐 Zero-Log Policy (CRITICAL)

**This is NON-NEGOTIABLE.**

### What We NEVER Log

❌ Client IP addresses  
❌ DNS queries  
❌ HTTP/HTTPS requests  
❌ Tor circuit information  
❌ Timestamps of user activity  
❌ API token usage  
❌ Web dashboard access  
❌ Traffic volumes per user  
❌ Mode switches  
❌ Configuration changes

### How It's Enforced

**Code level:**
```python
def log_message(self, format, *args):
    """ZERO-LOG POLICY: No request logging for privacy"""
    pass  # Literally do nothing
```

**System level:**
```ini
[Service]
StandardOutput=null  # No stdout logging
StandardError=null   # No stderr logging
```

**Documentation:**
- `docs/ZERO-LOG-POLICY.md` - 600+ lines of security policy
- Referenced in all service files
- Enforced in code reviews

### Testing Zero-Log Compliance

```bash
# Make requests
curl http://localhost/

# Check for leaks (should be empty)
journalctl -u tide-web -u tide-api --since "1 min ago"
```

---

## 🌊 Hetzner Cloud (Primary Platform)

**Why Hetzner?**
- 28-52% cheaper than DigitalOcean
- Native ARM hardware (CPX series)
- Real production environment testing
- Hillsboro, OR location (closest to Petaluma)

**Annual cost:** ~$3/year for comprehensive testing

**Server types:**
- CPX11 (ARM, 2GB) - Testing (currently tested ✅)
- CX22 (x86, 4GB) - x86 validation
- CAX11 (ARM dedicated) - Performance testing

**Documentation:** `docs/HETZNER-PLATFORM.md`

---

## 📦 Supported Platforms

**Hypervisors (VM deployment):**
1. VMware ESXi/Fusion/Workstation (.ova)
2. Proxmox VE (.qcow2)
3. Microsoft Hyper-V (.vhdx)
4. Oracle VirtualBox (.ova + .vdi)
5. QEMU/KVM (.qcow2)
6. Parallels Desktop (.pvm)

**Architectures:**
- ARM64 (aarch64) ✅
- x86_64 (Intel/AMD) ✅

**Build system:** `scripts/build/build-multi-platform.sh --all`

---

## 🎨 Design & Branding

**Logo:** `docs/logos/tide-ai-v3_modern_badge.png` (latest)

**Colors:**
- Primary: Ocean blue (#0077BE)
- Accent: Wave teal (#00A9A5)
- Background: Dark navy (#001F3F)

**Tagline:** "Transparent Internet Defense Engine"  
**Motto:** "freedom within the shell"

**Icon:** Wave emoji 🌊

---

## 📝 Key Documentation Files

**Must-read for new developers:**
1. `AGENTS.md` - This file
2. `docs/ZERO-LOG-POLICY.md` - Privacy requirements
3. `docs/CHANGELOG.md` - Version history
4. `docs/HETZNER-PLATFORM.md` - Testing platform
5. `testing/GETTING-STARTED.md` - How to test

**For building:**
6. `docs/building/MULTI-PLATFORM-BUILD.md` - Build system
7. `QUICK-BUILD-GUIDE.md` - Quick reference

**For deploying:**
8. `release/v1.1.3/*/README.md` - Platform-specific guides

---

## 🚨 Common Tasks

### Update README with new logo

```bash
# README.md currently has old badge/logo
# Update with: docs/logos/tide-ai-v3_modern_badge.png
# Fix version badge (says 1.2.0, should be 1.1.3)
```

### Run tests before committing

```bash
cd testing/cloud
./test-hetzner.sh
# Verify all tests pass
```

### Build VM templates

```bash
cd scripts/build
./build-multi-platform.sh --all
# Outputs to: release/v1.1.3/
```

### Check zero-log compliance

```bash
# Search for print statements with user data
grep -r "print.*client" scripts/runtime/
# Should be empty

# Check systemd services
grep -r "StandardOutput" config/systemd/
# Should all be "null"
```

### Add new feature

1. Check if it requires logging user data → Don't build it
2. Implement feature
3. Update CHANGELOG.md under [Unreleased]
4. Test on Hetzner
5. Commit
6. When ready to release, move from [Unreleased] to [X.X.X]

---

## 💡 Design Decisions

### Why Alpine Linux?

- Tiny footprint (~150MB)
- Fast boot times
- Security-focused
- Perfect for appliances

### Why Python for web/API?

- Standard library HTTP server (no deps)
- Easy to read/maintain
- Works on Alpine without issues
- Anthony is comfortable with it

### Why systemd services?

- Auto-start on boot
- Proper service management
- Restart on failure
- Standard across Linux

### Why Hetzner over DigitalOcean?

- 28-52% cheaper
- Native ARM hardware (DO doesn't have ARM in US)
- Better for testing real production scenarios
- Annual cost: $3 vs DigitalOcean $5+

---

## 🎯 Project Goals

**Short-term (Next 2 weeks):**
- [ ] Update README.md with new logo and v1.1.3
- [ ] Build VM templates for all platforms
- [ ] Test ESXi deployment end-to-end
- [ ] Complete Phase 2 (deployment testing)

**Medium-term (Next month):**
- [ ] Complete Phase 3 (deployment guides with screenshots)
- [ ] Complete Phase 4 (automated deployment tester)
- [ ] Release v1.2.0 with VM templates
- [ ] WireGuard VPN implementation (v1.3.0)

**Long-term (3-6 months):**
- [ ] Mobile app (iOS/Android) for WireGuard
- [ ] Bandwidth monitoring
- [ ] WebSocket live updates
- [ ] Community adoption (GitHub stars, users)

---

## 🤝 Anthony's Preferences

**Communication:**
- Direct and practical (no fluff)
- Working solutions over theory
- Docker/VM-first (not bare metal unless needed)
- Clear documentation for future reference

**Petaluma Pride:**
- Hillsboro, OR Hetzner location (closest to Petaluma)
- Built in Petaluma, for privacy-conscious users everywhere
- "Bodegga" branding (Anthony's brand)

**Privacy First:**
- Zero-log policy is non-negotiable
- Open source = provable privacy
- No telemetry, no tracking, no exceptions
- Users trust us with their privacy - don't betray that

---

## 🔗 External Links

- **GitHub:** https://github.com/bodegga/tide
- **Releases:** https://github.com/bodegga/tide/releases
- **Latest Release:** v1.1.3
- **Issues:** https://github.com/bodegga/tide/issues

---

## 📞 Contact

**Developer:** Anthony Biasi  
**Location:** Petaluma, CA  
**Email:** a@biasi.co  
**Brand:** Bodegga

---

## 🎓 Learning Resources

**If you're new to the codebase:**
1. Read `README.md` (after we update it)
2. Read `docs/ZERO-LOG-POLICY.md` (understand privacy requirements)
3. Run `testing/cloud/test-hetzner.sh` (see it in action)
4. Read `docs/CHANGELOG.md` (understand evolution)
5. Try building: `scripts/build/build-multi-platform.sh --platform qemu`

**For testing:**
- Start with `testing/GETTING-STARTED.md`
- Always use Hetzner for real validation
- Docker is for quick dev checks only

**For building VMs:**
- Start with `docs/building/MULTI-PLATFORM-BUILD.md`
- Use `QUICK-BUILD-GUIDE.md` as reference

---

## ⚠️ Critical Warnings

### DON'T

❌ Add logging that tracks users  
❌ Skip testing on Hetzner before releases  
❌ Commit without updating CHANGELOG  
❌ Expose secrets in git (API tokens, keys)  
❌ Release without testing zero-log compliance  
❌ Use DigitalOcean when Hetzner works better  

### DO

✅ Test every change on real hardware (Hetzner)  
✅ Document everything in CHANGELOG  
✅ Follow semantic versioning (MAJOR.MINOR.PATCH)  
✅ Maintain zero-log policy (no exceptions)  
✅ Keep VM images small (<500MB)  
✅ Make deployment as easy as possible  

---

## 🎉 Recent Wins

**v1.1.3 (December 10, 2025):**
- ✅ Zero-log policy implemented and enforced
- ✅ Systemd services (web + API) working on port 80 and 9051
- ✅ Hetzner Cloud documented as primary platform
- ✅ Multi-platform build system created (Phase 1 complete)
- ✅ All tests passing on Hetzner ARM hardware

**Testing infrastructure:**
- ✅ Matrix testing system (test all configs)
- ✅ Cost: $3/year for comprehensive testing
- ✅ Automated orchestration (parallel execution)

**Build system:**
- ✅ 6 platforms supported (VMware, Proxmox, Hyper-V, etc.)
- ✅ 2 architectures (ARM64, x86_64)
- ✅ Automated format conversion

---

## 📊 Metrics

**Code:**
- ~15,000 lines of scripts and configs
- ~10,000 lines of documentation
- 3 Python services (web, API, CLI)
- 30+ shell scripts

**Testing:**
- 4 test platforms (Docker, Hetzner, QEMU, VirtualBox)
- 7 tests per platform
- ~$3/year testing cost
- 100% pass rate on v1.1.3

**Build system:**
- 6 hypervisor platforms supported
- 2 CPU architectures
- 12 possible build combinations
- ~1.5GB total release size

---

**Last Updated:** December 10, 2025  
**Current Version:** v1.1.3  
**Status:** Active Development  
**Build System:** Phase 1 Complete ✅  
**Testing:** Comprehensive ✅  
**Zero-Log Policy:** Enforced ✅  

🌊 **Tide Gateway: True Privacy. Provable. Verifiable. Zero Logs.**
