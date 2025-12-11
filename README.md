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
