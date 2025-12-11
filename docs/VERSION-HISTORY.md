# Tide Gateway - Complete Version History

**Purpose:** Document the full development timeline including deleted/superseded releases.

---

## Timeline

### December 7, 2025 - Project Start

**v1.0.0** (commit `abb234e`) - **DELETED**
- Initial commit
- Basic Tor gateway functionality
- **Why deleted:** Version numbering confusion during rapid development
- **Status:** DELETED from releases, git tag removed
- **History preserved:** See CHANGELOG.md

**v1.1.0** (commit `c319ef6`) - **RELEASED** ✅
- Cloud-init build system
- Multi-architecture support (x86_64, ARM64)
- QEMU/KVM deployment
- **GitHub Release:** https://github.com/bodegga/tide/releases/tag/v1.1.0
- **Status:** Active release, still available

---

### December 9, 2025 - Major Development Session (6 hours)

**v1.2.0 (First attempt)** (commit `c319ef6`) - **DELETED**
- Docker Router Mode with DHCP
- Docker Proxy Mode (SOCKS5)
- Braille egg logo
- **Why deleted:** Docker couldn't support ARP poisoning (Killa Whale mode)
- **Status:** DELETED from releases, git tag removed
- **History preserved:** See CHANGELOG.md section "[1.2.0] - 2025-12-09 (DELETED)"
- **Functionality:** Migrated to VM-based approach in v1.1.1

**v1.1.1** (commit `9d51daa`) - **RELEASED** ✅
- ONE-COMMAND deployment
- Parallels VM template
- Killa Whale mode (ARP poisoning)
- VM-based architecture (replaced Docker)
- **GitHub Release:** https://github.com/bodegga/tide/releases/tag/v1.1.1
- **Status:** CURRENT RELEASE (as of Dec 10, 2025)

**v2.0.0** (commit `9d51daa` - same as v1.1.1) - **MISTAKE**
- Accidentally tagged same commit as v1.1.1
- No separate release
- **Status:** Tag removed (orphaned)

---

### December 10, 2025 - Testing Infrastructure & Web Dashboard Development

**Unreleased v1.2.0 features** (commits `6020463` onwards)
- Web Dashboard on port 80
- Enhanced CLI (`tide` command)
- DNS hijacking (tide.bodegga.net)
- JSON API endpoints
- Test orchestration system
- Multi-platform testing (Docker, Hetzner, QEMU)
- **VERSION file:** Still at 1.1.1
- **Status:** IN DEVELOPMENT, not tagged or released yet
- **Future:** Will be released as v1.2.0 when ready

**Testing infrastructure commits:**
- Test orchestration
- Hetzner Cloud testing
- Platform testing matrix
- Test validation system
- Repository reorganization
- **Status:** All committed, not versioned separately

---

## Current State (December 10, 2025)

### Released Versions

| Version | Date | Status | GitHub Release |
|---------|------|--------|----------------|
| v1.1.0 | Dec 7 | Active | ✅ Available |
| v1.1.1 | Dec 9 | **CURRENT** | ✅ Available (Latest) |

### Deleted Versions (History Preserved)

| Version | Date | Reason | Git History |
|---------|------|--------|-------------|
| v1.0.0 | Dec 7 | Version numbering confusion | Commit `abb234e` |
| v1.2.0 (Docker) | Dec 9 | Replaced by VM approach in v1.1.1 | Commit `c319ef6` |
| v2.0.0 | Dec 9 | Accidental duplicate of v1.1.1 | Commit `9d51daa` |

### In Development

| Version | Features | Status |
|---------|----------|--------|
| v1.2.0 | Web dashboard, enhanced CLI, testing | Unreleased (ready when you are) |

---

## Git Tags Status

### Before Cleanup

```
v1.0.0 → abb234e (deleted release)
v1.1.0 → c319ef6 ✅ (active release)
v1.1.1 → 9d51daa ✅ (current release)
v1.2.0 → c319ef6 (deleted release)
v2.0.0 → 9d51daa (mistake)
```

### After Cleanup (Run ./FIX-VERSIONS.sh)

```
v1.1.0 → c319ef6 ✅ (active release)
v1.1.1 → 9d51daa ✅ (current release)
```

**Orphaned tags removed:** v1.0.0, v1.2.0, v2.0.0

---

## Development Sessions

### Session 1 - December 7, 2025
- Initial development
- Created v1.0.0 and v1.1.0
- Cloud-init automation

### Session 2 - December 9, 2025 (6 hours)
- Explored Docker approach (v1.2.0 - deleted)
- Discovered Docker limitations for ARP poisoning
- Switched to VM architecture
- Created Parallels template
- Released v1.1.1

### Session 3 - December 10, 2025 (Today)
- Built test orchestration system
- Added web dashboard features
- Created multi-platform testing
- Added validation systems
- Repository organization
- **NOT YET TAGGED OR RELEASED**

---

## Versioning Strategy

Following [Semantic Versioning 2.0.0](https://semver.org/):

**MAJOR.MINOR.PATCH**

- **MAJOR (2.0.0)** - Breaking changes
- **MINOR (1.X.0)** - New features (backward compatible)
- **PATCH (1.1.X)** - Bug fixes only

### Examples from Tide History

| Change | Version Jump | Reasoning |
|--------|--------------|-----------|
| Initial release | 1.0.0 | Starting point |
| Added cloud-init | 1.0.0 → 1.1.0 | New feature (minor) |
| Added VM template | 1.1.0 → 1.1.1 | Deployment improvement (patch) |
| Web dashboard (future) | 1.1.1 → 1.2.0 | New feature (minor) |

---

## Lessons Learned

### Version Numbering
- Don't tag same commit with multiple versions
- Delete orphaned tags promptly
- Keep VERSION file in sync with tags
- Use semantic versioning consistently

### Release Management
- Test before tagging
- Document deleted releases in CHANGELOG
- Keep git history (don't force-push)
- Use GitHub releases for distribution

### Development Workflow
- Commit often
- Tag releases when stable
- Document session progress
- Preserve history even for deleted releases

---

## Future Releases

### Planned v1.2.0 (When Ready)
- Web dashboard
- Enhanced CLI
- DNS hijacking
- JSON API
- **Trigger:** When you decide to tag it

### Potential v1.3.0 (Future)
- WireGuard VPN for mobile
- Bandwidth monitoring
- WebSocket live updates

### Potential v2.0.0 (Far Future)
- Breaking changes (TBD)
- Major architecture changes

---

## How to Release v1.2.0 (When You're Ready)

```bash
# 1. Update VERSION file
echo "1.2.0" > VERSION

# 2. Commit
git add VERSION
git commit -m "Release v1.2.0 - Web Dashboard & Enhanced CLI"

# 3. Tag
git tag -a v1.2.0 -m "Tide Gateway v1.2.0 - Web Dashboard & Enhanced CLI

Features:
- Web dashboard on port 80
- Enhanced tide CLI
- DNS hijacking for tide.bodegga.net
- JSON API endpoints
- Test orchestration system

See CHANGELOG.md for full details."

# 4. Push
git push origin main
git push origin v1.2.0

# 5. Create GitHub release
gh release create v1.2.0 \
  --title "Tide Gateway v1.2.0 - Web Dashboard & Enhanced CLI" \
  --notes "See CHANGELOG.md for details"
```

---

## References

- **CHANGELOG.md** - User-facing change log
- **VERSIONING.md** - Versioning guidelines
- **README.md** - Current project status
- **Git tags** - Release markers
- **GitHub Releases** - Public distribution

---

**Last Updated:** December 10, 2025  
**Current Version:** v1.1.1  
**Next Version:** v1.2.0 (unreleased, in development)  
**Maintained by:** Anthony Biasi

**All history preserved. Nothing lost.**
