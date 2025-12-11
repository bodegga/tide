#!/bin/bash
# Reorganize Tide Gateway repository for clarity

set -e

echo "🌊 Reorganizing Tide Gateway Repository..."
echo ""

# Create new directory structure
mkdir -p docs/{guides,development,archived}
mkdir -p deployment/{parallels,qemu,hetzner,digitalocean}
mkdir -p testing
mkdir -p archive/old-scripts

echo "✓ Created directory structure"
echo ""

# Move documentation
echo "📚 Moving documentation..."
mv CHANGELOG.md docs/
mv ROADMAP.md docs/
mv HISTORY.md docs/
mv SECURITY.md docs/
mv CONTRIBUTING.md docs/

# User guides
mv QUICK-START.md docs/guides/
mv WEB-DASHBOARD-README.md docs/guides/
mv FRESH-INSTALL-GUIDE.md docs/guides/
mv KILLA-WHALE-UTM-DEPLOY.md docs/guides/
mv VM-MANAGEMENT-GUIDE.md docs/guides/

# Development docs
mv CLIENT-BUILD-SUMMARY.md docs/development/
mv SESSION-SUMMARY-2025-12-10.md docs/development/
mv DOCUMENTATION_SUMMARY.md docs/development/
mv HETZNER-TEST-RESULTS.md docs/development/

# Archived/obsolete docs
mv README-DEFAULT.md docs/archived/
mv README-MODES.md docs/archived/
mv README-SIMPLE.md docs/archived/
mv REORGANIZATION_PROPOSAL.md docs/archived/
mv REPO_REVIEW.md docs/archived/
mv DEPLOYMENT-GUIDE.md docs/archived/
mv DEPLOYMENT-README.md docs/archived/

echo "✓ Documentation organized"
echo ""

# Move deployment scripts
echo "🚀 Moving deployment scripts..."

# Hetzner
mv test-on-hetzner.sh deployment/hetzner/
mv UPDATE-TO-V1.2.sh deployment/hetzner/

# Parallels
mv DEPLOY-TEST-CLIENTS.sh deployment/parallels/
mv MANAGE-GATEWAYS.sh deployment/parallels/
mv auto-deploy-parallels.sh deployment/parallels/
mv auto-deploy-parallels-fixed.sh deployment/parallels/
mv KILLA-WHALE-PARALLELS-DEPLOY.sh deployment/parallels/
mv ONE-COMMAND-DEPLOY.sh deployment/parallels/
mv DEPLOY-TEMPLATE.sh deployment/parallels/
mv PACKAGE-RELEASE.sh deployment/parallels/

# QEMU
mv build-qemu-image.sh deployment/qemu/ 2>/dev/null || true
mv build-working-vm.sh deployment/qemu/
mv run-qemu.sh deployment/qemu/
mv run-tide-qemu.sh deployment/qemu/
mv run-killa-whale-qemu.sh deployment/qemu/

echo "✓ Deployment scripts organized"
echo ""

# Move testing scripts
echo "🧪 Moving testing scripts..."
mv MANUAL-TESTING-STEPS.md testing/
mv SIMPLE-TEST.md testing/
mv TEST-WITH-QEMU.sh testing/
mv TESTING-QUICK-REF.md testing/ 2>/dev/null || true

echo "✓ Testing scripts organized"
echo ""

# Move old/experimental scripts to archive
echo "📦 Archiving old scripts..."
mv deploy-killa-whale-auto.sh archive/old-scripts/
mv deploy-killa-whale-v2.sh archive/old-scripts/
mv deploy-killa-whale-v3.sh archive/old-scripts/
mv deploy-vm.sh archive/old-scripts/ 2>/dev/null || true
mv killa-whale-post-install.sh archive/old-scripts/
mv ALPINE-POST-SETUP.sh archive/old-scripts/
mv auto-install.sh archive/old-scripts/ 2>/dev/null || true
mv BUILD-AND-TEST.sh archive/old-scripts/
mv CLEAN-DEPLOY.sh archive/old-scripts/
mv DIAGNOSE.sh archive/old-scripts/
mv FINAL-INSTALL.sh archive/old-scripts/ 2>/dev/null || true
mv FINISH-INSTALL.sh archive/old-scripts/ 2>/dev/null || true
mv FIX-PERMISSIONS.sh archive/old-scripts/
mv INSTALL-IN-VM.sh archive/old-scripts/
mv KILLA-WHALE-ONE-COMMAND-INSTALL.sh archive/old-scripts/ 2>/dev/null || true
mv QUICK-SETUP.sh archive/old-scripts/ 2>/dev/null || true
mv SIMPLE-START.sh archive/old-scripts/ 2>/dev/null || true
mv SIMPLE-START-V2.sh archive/old-scripts/ 2>/dev/null || true
mv TINY-INSTALL.sh archive/old-scripts/ 2>/dev/null || true
mv setup-tide.sh archive/old-scripts/ 2>/dev/null || true
mv setup-tide-native.sh archive/old-scripts/ 2>/dev/null || true
mv reorganize-repo.sh archive/old-scripts/ 2>/dev/null || true

# Archive old config files
mv alpine-answers.txt archive/old-scripts/ 2>/dev/null || true
mv cloud-init-killa-whale.yaml archive/old-scripts/ 2>/dev/null || true
mv torrc archive/old-scripts/ 2>/dev/null || true
mv torrc-fixed archive/old-scripts/ 2>/dev/null || true
mv torrc-gateway archive/old-scripts/ 2>/dev/null || true

echo "✓ Old scripts archived"
echo ""

# Create new README structure
cat > README.md << 'EOFREADME'
# 🌊 Tide Gateway

**Transparent Internet Defense Engine**

> A hardened, leak-proof Tor gateway with web-based management and multiple deployment modes.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.0-green)](docs/CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Docker%20%7C%20VM%20%7C%20Bare--metal-lightgrey)](docs/ROADMAP.md)

---

## Quick Start

### Web Dashboard (NEW in v1.2.0!)
```bash
# Access from any client device:
http://tide.bodegga.net
```

### One-Command Deployment
```bash
# Hetzner Cloud (automated testing):
./deployment/hetzner/test-on-hetzner.sh

# Parallels Desktop (macOS):
./deployment/parallels/ONE-COMMAND-DEPLOY.sh
```

### Features
- 🌐 **Web Dashboard** - Monitor status at http://tide.bodegga.net
- 🔧 **Mode Switching** - Change modes without redeploy (`tide mode killa-whale`)
- 🔒 **Fail-Closed Security** - If Tor dies, traffic is blocked
- 🐋 **Killa Whale Mode** - Aggressive network takeover with ARP poisoning
- 📱 **CLI Management** - `tide status`, `tide config`, `tide clients`

---

## Documentation

### Getting Started
- **[Quick Start Guide](docs/guides/QUICK-START.md)** - 5-minute setup
- **[Web Dashboard](docs/guides/WEB-DASHBOARD-README.md)** - Dashboard features and API
- **[Fresh Installation](docs/guides/FRESH-INSTALL-GUIDE.md)** - Manual installation walkthrough

### Deployment Guides
- **[Hetzner Cloud](deployment/hetzner/)** - Automated cloud testing (~$0.003/test)
- **[Parallels Desktop](deployment/parallels/)** - macOS VM deployment
- **[QEMU/KVM](deployment/qemu/)** - Linux VM deployment

### Reference
- **[Changelog](docs/CHANGELOG.md)** - Version history
- **[Roadmap](docs/ROADMAP.md)** - Planned features
- **[Security](docs/SECURITY.md)** - Security model and guarantees
- **[Contributing](docs/CONTRIBUTING.md)** - How to contribute

---

## Deployment Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Proxy** | SOCKS5 only | Single VM, testing |
| **Router** | DHCP + transparent proxy | VM lab, isolated network |
| **Killa Whale** | Router + fail-closed firewall | High security |
| **Takeover** | Killa Whale + ARP hijacking | Full subnet control |

## Security Profiles

| Profile | Description | Speed |
|---------|-------------|-------|
| **Standard** | Default Tor settings | Fastest |
| **Hardened** | Excludes 14-eyes countries | Moderate |
| **Paranoid** | Maximum isolation | Slowest |
| **Bridges** | Uses obfs4 bridges | Anti-censorship |

---

## CLI Commands

```bash
tide status        # Show gateway status
tide config        # Interactive configuration
tide mode <mode>   # Switch deployment mode
tide security <p>  # Switch security profile
tide clients       # List connected clients
tide check         # Test Tor connectivity
tide web           # Show dashboard URL
```

---

## Architecture

```
Client Devices
    ↓
    └─ http://tide.bodegga.net (DNS hijacked)
        ↓
    Tide Gateway (10.101.101.10)
        ├─ Web Dashboard (port 80)
        ├─ API Endpoint (port 9051)
        ├─ DHCP Server (dnsmasq)
        ├─ DNS Hijacking
        └─ Tor Transparent Proxy
            ↓
        Tor Network
            ↓
        Internet
```

---

## Project Structure

```
tide/
├── README.md                   # This file
├── LICENSE                     # MIT License
├── VERSION                     # Current version
│
├── docs/                       # Documentation
│   ├── guides/                 # User guides
│   ├── development/            # Development docs
│   ├── CHANGELOG.md            # Version history
│   ├── ROADMAP.md              # Future plans
│   └── SECURITY.md             # Security documentation
│
├── deployment/                 # Deployment scripts
│   ├── hetzner/                # Hetzner Cloud (recommended for testing)
│   ├── parallels/              # Parallels Desktop (macOS)
│   ├── qemu/                   # QEMU/KVM
│   └── digitalocean/           # DigitalOcean (future)
│
├── scripts/                    # Runtime scripts
│   ├── runtime/                # Gateway runtime scripts
│   ├── install/                # Installation scripts
│   └── build/                  # Build scripts
│
├── client/                     # Client applications
│   ├── macos/                  # Native macOS app
│   ├── linux/                  # Linux client
│   └── shared/                 # Shared Python client
│
├── config/                     # Configuration templates
│   ├── torrc-*                 # Tor configurations
│   └── answerfile              # Alpine auto-install
│
└── testing/                    # Testing tools
    └── MANUAL-TESTING-STEPS.md
```

---

## Quick Links

- **[Deployment: Hetzner Cloud](deployment/hetzner/test-on-hetzner.sh)** - Automated testing
- **[Deployment: Parallels](deployment/parallels/ONE-COMMAND-DEPLOY.sh)** - macOS VMs
- **[Web Dashboard Guide](docs/guides/WEB-DASHBOARD-README.md)** - Dashboard features
- **[VM Management](docs/guides/VM-MANAGEMENT-GUIDE.md)** - Managing gateway VMs
- **[Testing Results](docs/development/HETZNER-TEST-RESULTS.md)** - Latest test results

---

## License

MIT License - See [LICENSE](LICENSE) file

---

## Links

- **GitHub**: https://github.com/bodegga/tide
- **Issues**: https://github.com/bodegga/tide/issues
- **Documentation**: [docs/](docs/)

---

**Tide Gateway - freedom within the shell** 🌊

*v1.2.0 - Web Dashboard Edition*
EOFREADME

echo "✓ Created new README.md"
echo ""

# Create index file for docs
cat > docs/README.md << 'EOFDOCS'
# Tide Gateway Documentation

## Quick Links

### Getting Started
- [Quick Start Guide](guides/QUICK-START.md) - Get up and running in 5 minutes
- [Web Dashboard](guides/WEB-DASHBOARD-README.md) - Dashboard features and usage
- [Fresh Installation](guides/FRESH-INSTALL-GUIDE.md) - Manual installation steps

### Deployment
- [Hetzner Cloud](../deployment/hetzner/) - Automated cloud testing
- [Parallels Desktop](../deployment/parallels/) - macOS VM deployment
- [VM Management](guides/VM-MANAGEMENT-GUIDE.md) - Managing gateway VMs

### Reference
- [Changelog](CHANGELOG.md) - Version history
- [Roadmap](ROADMAP.md) - Future features
- [Security](SECURITY.md) - Security model
- [Contributing](CONTRIBUTING.md) - How to contribute

### Development
- [Test Results](development/HETZNER-TEST-RESULTS.md) - Latest test results
- [Session Summary](development/SESSION-SUMMARY-2025-12-10.md) - Development notes
- [Client Build](development/CLIENT-BUILD-SUMMARY.md) - Client application builds

---

**[← Back to Main README](../README.md)**
EOFDOCS

echo "✓ Created docs/README.md"
echo ""

# Create deployment README
cat > deployment/README.md << 'EOFDEPLOYMENT'
# Tide Gateway Deployment

## Recommended: Hetzner Cloud

**Cost:** ~$0.003 per test  
**Speed:** Server ready in 30 seconds  
**Perfect for:** Automated testing, CI/CD, production

```bash
cd hetzner/
./test-on-hetzner.sh
```

[→ Hetzner Deployment Guide](hetzner/)

---

## Parallels Desktop (macOS)

**Cost:** Free (runs on your Mac)  
**Speed:** 5 minutes to deploy  
**Perfect for:** Development, testing on macOS

```bash
cd parallels/
./ONE-COMMAND-DEPLOY.sh
```

[→ Parallels Deployment Guide](parallels/)

---

## QEMU/KVM (Linux)

**Cost:** Free (runs on your server)  
**Speed:** Manual setup required  
**Perfect for:** Linux servers, bare metal

```bash
cd qemu/
./build-qemu-image.sh
```

[→ QEMU Deployment Guide](qemu/)

---

**[← Back to Main README](../README.md)**
EOFDEPLOYMENT

echo "✓ Created deployment/README.md"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Repository reorganized!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "New structure:"
echo "  docs/          - All documentation"
echo "  deployment/    - Deployment scripts by platform"
echo "  testing/       - Testing tools"
echo "  archive/       - Old/experimental scripts"
echo ""
echo "Main files in root:"
ls -1 *.md *.txt 2>/dev/null | grep -v "^docs" | grep -v "^deployment"
echo ""
echo "Next steps:"
echo "  1. Review the changes"
echo "  2. Test a deployment script"
echo "  3. Commit: git add -A && git commit -m 'Reorganize repository structure'"
echo ""
