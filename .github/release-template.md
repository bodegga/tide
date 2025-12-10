# Tide Gateway v{VERSION} - {RELEASE_NAME}

> **Release Date:** {DATE}  
> **Type:** {MAJOR/MINOR/PATCH}  
> **Status:** {ALPHA/BETA/STABLE}

---

## 🎯 Overview

{Brief 1-2 sentence description of what this release delivers}

---

## ✨ Highlights

{3-5 bullet points of the most exciting features/fixes}

- 🚀 **Feature Name** - What it does and why it matters
- 🔧 **Improvement** - What got better
- 🐛 **Critical Fix** - What bug was squashed

---

## 📦 What's New

### Added
- New feature 1
- New feature 2
- New capability 3

### Changed
- Improvement 1
- Updated behavior 2
- Enhanced functionality 3

### Fixed
- Bug fix 1
- Issue resolution 2
- Problem solved 3

### Deprecated
{Only if applicable - features being phased out}

### Removed
{Only if applicable - features that were removed}

### Security
{Only if applicable - security-related changes}

---

## 🚀 Quick Start

### New Users

```bash
# One-command deployment (Parallels on macOS)
curl -sSL https://tide.bodegga.net/deploy | bash

# Or download template manually
wget https://github.com/bodegga/tide/releases/download/v{VERSION}/tide-gateway-template.zip
```

### Existing Users - Upgrade Path

{Provide upgrade instructions for users on previous versions}

**From v{PREVIOUS}:**
```bash
# Backup your current configuration
{backup commands}

# Download and apply update
{update commands}

# Verify upgrade
{verification commands}
```

---

## 📋 Installation Methods

### Method 1: Pre-Built Template (Recommended)

**Parallels Desktop (macOS)**
```bash
curl -sSL https://tide.bodegga.net/deploy | bash
```

**Pros:** Fastest, easiest, just works  
**Requirements:** Parallels Desktop, macOS (Intel or Apple Silicon)

### Method 2: Cloud-Init Image

**QEMU/KVM/UTM**
```bash
# Download cloud image and cloud-init ISO
wget {cloud-image-url}
wget {cloud-init-url}

# Boot with both attached
qemu-system-aarch64 \
  -drive file=tide-gateway.qcow2 \
  -cdrom cloud-init.iso \
  {additional qemu flags}
```

**Pros:** Universal VM support  
**Requirements:** Any hypervisor that supports cloud-init

### Method 3: Fresh Alpine Install

**Bare Metal or Any VM**
```bash
# After installing Alpine Linux 3.21+
wget https://tide.bodegga.net/install.sh
chmod +x install.sh
./install.sh
```

**Pros:** Maximum control, any platform  
**Requirements:** Alpine Linux 3.21+ (x86_64 or ARM64)

---

## 🔧 Configuration

### Default Settings

| Setting | Value | Description |
|---------|-------|-------------|
| Gateway IP | 10.101.101.10 | Host-only network address |
| DHCP Range | 10.101.101.100-200 | Client IP pool |
| DNS Port | 5353 | DNS over Tor |
| Tor Transparent Proxy | 9040 | Automatic routing |
| Tor SOCKS5 | 9050 | Manual proxy |

### Deployment Modes

{Link to mode documentation and explain when to use each}

| Mode | Use Case | Security Level |
|------|----------|----------------|
| Proxy | Testing, single VM | Medium |
| Router | Lab network | High |
| Killa Whale | Production, high security | Very High |
| Takeover | Full subnet control | Maximum |

---

## 🔒 Security Notes

### What's Protected
- ✅ All TCP traffic routed through Tor
- ✅ DNS queries encrypted
- ✅ Fail-closed firewall (no leaks)
- ✅ {Additional protections in this release}

### Known Limitations
- ⚠️ UDP traffic is blocked (not routed through Tor)
- ⚠️ {Any other limitations specific to this release}

### Security Advisories
{Include any CVEs fixed or security issues addressed}

---

## 📊 Performance

### Benchmarks
{If applicable, include performance metrics}

- **Throughput:** {network speed}
- **Latency:** {connection delay}
- **Memory:** {RAM usage}
- **CPU:** {processor usage}

### Compared to Previous Version
{Show improvements from last release}

---

## 🐛 Known Issues

### Issues Fixed in This Release
- [#{ISSUE_NUM}] {Issue description}
- [#{ISSUE_NUM}] {Issue description}

### Still Open
{List any known bugs that aren't fixed yet}

- [#{ISSUE_NUM}] {Description and workaround if any}

---

## 📚 Documentation

### New Documentation
- {Link to new guide}
- {Link to new tutorial}

### Updated Documentation
- {Link to updated doc}

### Full Documentation
- [README](../README.md) - Project overview
- [CHANGELOG](../CHANGELOG.md) - Complete version history
- [HISTORY](../HISTORY.md) - Development narrative
- [START-HERE](../START-HERE.md) - Quick start guide

---

## 🧪 Testing

### How This Release Was Tested
{Describe testing methodology}

- ✅ Clean install on {platform}
- ✅ Upgrade from v{previous}
- ✅ Killa Whale mode validation
- ✅ {Additional testing}

### Test It Yourself
```bash
# Verify Tor routing
curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip

# Check DNS over Tor  
dig @10.101.101.10 -p 5353 duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion

# Validate fail-closed firewall
{test commands}
```

---

## 💾 Download

### Release Assets

| File | Size | SHA256 | Description |
|------|------|--------|-------------|
| `tide-gateway-template.zip` | {SIZE} | `{HASH}` | Pre-built Parallels VM |
| `tide-gateway.qcow2` | {SIZE} | `{HASH}` | QEMU cloud image |
| `cloud-init.iso` | {SIZE} | `{HASH}` | Cloud-init seed |
| `install.sh` | {SIZE} | `{HASH}` | Fresh Alpine installer |

### Verification

```bash
# Verify checksum
sha256sum tide-gateway-template.zip
# Should match: {EXPECTED_HASH}

# Verify GPG signature (if implemented)
gpg --verify tide-gateway-template.zip.sig
```

---

## 🤝 Contributing

Found a bug? Have a feature request? Want to contribute?

- **Report Issues:** https://github.com/bodegga/tide/issues
- **Submit PRs:** https://github.com/bodegga/tide/pulls
- **Discussions:** https://github.com/bodegga/tide/discussions
- **Contributing Guide:** [CONTRIBUTING.md](../CONTRIBUTING.md)

---

## 📜 License

Tide Gateway is open source under the [MIT License](../LICENSE).

---

## 🙏 Acknowledgments

{Thank contributors, bug reporters, or anyone who helped with this release}

- Thanks to @{username} for reporting issue #{num}
- Thanks to @{username} for PR #{num}
- Thanks to the Tor Project for the incredible network

---

## 🔮 What's Next

### Roadmap for v{NEXT_VERSION}
{Tease upcoming features}

- [ ] Planned feature 1
- [ ] Planned feature 2
- [ ] Planned improvement 3

See the full [ROADMAP.md](../ROADMAP.md) for details.

---

## 📞 Support

- **GitHub Issues:** https://github.com/bodegga/tide/issues
- **Email:** {support email if applicable}
- **Documentation:** https://github.com/bodegga/tide

---

**Tide Gateway** - *freedom within the shell* 🌊🥚

Built with privacy in mind • Powered by Tor • Made in Petaluma, CA
