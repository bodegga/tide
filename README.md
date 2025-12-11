<div align="center">

<img src="docs/logos/tide-readme-rounded.png" alt="Tide Gateway" width="200"/>

# Tide Gateway

**Transparent Internet Defense Engine**

> A zero-log Tor gateway appliance for transparent network-wide privacy.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.1.3-green)](https://github.com/bodegga/tide/releases)
[![Platform](https://img.shields.io/badge/platform-VM%20Appliance-lightgrey)](#supported-platforms)

---

## What is Tide Gateway?

Tide Gateway is a **privacy appliance** that routes all network traffic through Tor automatically. Deploy it as a VM on any hypervisor and point your devices at it for transparent anonymity.

### Key Features

- 🔐 **Zero-Log Policy** - No client tracking, no request logging, ever
- 🌐 **Web Dashboard** - Monitor status in real-time
- 🔧 **Multiple Modes** - Proxy, Router, or aggressive Killa Whale
- 🛡️ **Fail-Closed Security** - Traffic blocked if Tor fails
- 📱 **CLI Management** - Full control via command line
- 🔄 **Mode Switching** - Change deployment without rebuild

### Core Philosophy

**"Privacy is not a feature. It's the entire point."**

- Zero logs = zero evidence
- If you don't collect it, you can't leak it
- Open source = provable privacy
- No telemetry, no tracking, no exceptions

---

## Quick Start

### Prerequisites

- Any hypervisor (VMware, Proxmox, Hyper-V, VirtualBox, etc.)
- 512MB RAM minimum, 1GB recommended
- 2GB disk space

### Download

**Latest Release:** [v1.1.3](https://github.com/bodegga/tide/releases/latest)

Choose your platform:
- **VMware ESXi/Fusion/Workstation** - Download `.ova`
- **Proxmox VE** - Download `.qcow2`
- **Hyper-V** - Download `.vhdx`
- **VirtualBox** - Download `.ova`
- **QEMU/KVM** - Download `.qcow2`

### Deploy

1. **Import VM template** to your hypervisor
2. **Configure network** - 2 interfaces required:
   - Interface 1: Internet access (bridged/NAT)
   - Interface 2: Client network (host-only/isolated)
3. **Start VM** - Services auto-start
4. **Connect clients** - Point devices to gateway IP (default: 10.101.101.10)
5. **Access dashboard** - http://10.101.101.10 or http://tide.gateway

### CLI Usage

```bash
tide status        # Show gateway status
tide check         # Test Tor connectivity
tide mode router   # Switch deployment mode
tide security      # Configure security profile
```

---

## Deployment Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **proxy** | SOCKS5 only | Testing, single device |
| **router** | DHCP + transparent routing | Home lab, isolated network |
| **killa-whale** | Router + fail-closed firewall | High security |

---

## Security Profiles

| Profile | Description | Tor Configuration |
|---------|-------------|-------------------|
| **standard** | Default Tor settings | Fastest, general use |
| **hardened** | Excludes 14-eyes countries | Moderate speed |
| **paranoid** | Maximum isolation | Slowest, highest security |
| **bridges** | Uses obfs4 bridges | Anti-censorship |

---

## Supported Platforms

### Hypervisors

- ✅ VMware ESXi / Fusion / Workstation
- ✅ Proxmox VE
- ✅ Microsoft Hyper-V
- ✅ Oracle VirtualBox
- ✅ QEMU / KVM
- ✅ Parallels Desktop (macOS)

### Architectures

- ✅ ARM64 (aarch64)
- ✅ x86_64 (Intel/AMD)

---

## Zero-Log Policy

Tide Gateway enforces a **strict zero-log policy**:

- ❌ No client IP logging
- ❌ No request logging
- ❌ No DNS query logging
- ❌ No traffic analysis
- ❌ No user activity timestamps
- ❌ No systemd journal entries for user actions

All logs → `/dev/null`

**Full policy:** [docs/ZERO-LOG-POLICY.md](docs/ZERO-LOG-POLICY.md)

---

## Documentation

### Getting Started

- **[Installation Guide](docs/guides/QUICK-START.md)** - 5-minute setup
- **[Network Configuration](docs/guides/NETWORK-SETUP.md)** - Configure interfaces
- **[Deployment Guides](release/)** - Platform-specific instructions

### Reference

- **[Changelog](docs/CHANGELOG.md)** - Version history
- **[Zero-Log Policy](docs/ZERO-LOG-POLICY.md)** - Privacy guarantees
- **[Hardware Compatibility](docs/HARDWARE-COMPATIBILITY.md)** - Tested platforms
- **[Building VMs](docs/building/MULTI-PLATFORM-BUILD.md)** - Build from source

### Advanced

- **[Testing Infrastructure](testing/README.md)** - Automated testing
- **[API Reference](docs/guides/API-REFERENCE.md)** - HTTP API endpoints
- **[Security Model](docs/SECURITY.md)** - Threat model and guarantees

---

## Web Dashboard

Access the web dashboard from any connected client:

- **URL:** http://10.101.101.10 or http://tide.gateway
- **Port:** 80 (HTTP)

**Features:**
- Real-time Tor connection status
- Current exit IP and country
- Mode and security profile display
- System uptime
- Zero client tracking

---

## API Endpoints

**Base URL:** http://10.101.101.10:9051

| Endpoint | Description |
|----------|-------------|
| `GET /status` | Gateway status and configuration |
| `GET /circuit` | Current Tor exit IP information |
| `GET /check` | Health check endpoint |

**Example:**
```bash
curl http://10.101.101.10:9051/status
```

---

## Architecture

```
Client Devices → Tide Gateway (10.101.101.10)
                       ↓
                  ┌─────────────┐
                  │ Web Dashboard│ (port 80)
                  │ API Server   │ (port 9051)
                  │ SOCKS Proxy  │ (port 9050)
                  └─────────────┘
                       ↓
                  Tor Network
                       ↓
                  Internet
```

All client traffic routes through Tor automatically. No per-device configuration needed.

---

## Building from Source

### Requirements

- Linux or macOS
- `qemu-img` (for format conversion)
- 5GB free disk space
- Internet connection

### Build All Platforms

```bash
cd scripts/build
./build-multi-platform.sh --all
```

Output: `release/v1.1.3/` with OVA, QCOW2, VHDX, etc.

### Build Single Platform

```bash
./build-multi-platform.sh --platform esxi
```

**Documentation:** [docs/building/MULTI-PLATFORM-BUILD.md](docs/building/MULTI-PLATFORM-BUILD.md)

---

## Testing

Tide Gateway includes comprehensive testing infrastructure:

### Automated Testing

```bash
cd testing
./orchestrate-tests.sh
```

Runs tests in parallel:
- Docker (containerized)
- Hetzner Cloud (real ARM hardware)
- QEMU (local VM)
- VirtualBox (local VM)

### Matrix Testing

Test all hardware/OS combinations:

```bash
./orchestrate-tests.sh matrix --quick
```

**Cost:** ~$0.03 per run (~$3/year for comprehensive testing)

**Documentation:** [testing/README.md](testing/README.md)

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md).

### Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make changes
5. Test on real hardware (see testing/README.md)
6. Submit pull request

### Code of Conduct

- Maintain zero-log policy (no exceptions)
- Test changes on real hardware before PR
- Document all features in CHANGELOG.md
- Follow semantic versioning

---

## Roadmap

### Current (v1.1.3)

- ✅ Zero-log policy enforced
- ✅ Web dashboard and API
- ✅ Multi-platform VM builds
- ✅ Comprehensive testing

### Next (v1.2.0)

- [ ] WireGuard VPN for mobile devices
- [ ] Bandwidth monitoring (aggregate only)
- [ ] WebSocket live updates
- [ ] Interactive setup wizard

### Future

- [ ] Native mobile apps (iOS/Android)
- [ ] Bridge relay support
- [ ] Advanced traffic obfuscation
- [ ] Multi-gateway clustering

**Full roadmap:** [docs/ROADMAP.md](docs/ROADMAP.md)

---

## Support

### Issues

Report bugs or request features: [GitHub Issues](https://github.com/bodegga/tide/issues)

### Documentation

Full documentation: [docs/](docs/)

### Community

- **GitHub Discussions:** Coming soon
- **Documentation:** [docs/](docs/)
- **Releases:** [GitHub Releases](https://github.com/bodegga/tide/releases)

---

## Security

### Responsible Disclosure

Security vulnerabilities can be reported to: [GitHub Security](https://github.com/bodegga/tide/security)

### Threat Model

See [docs/SECURITY.md](docs/SECURITY.md) for:
- What Tide Gateway protects against
- Known limitations
- Security guarantees
- Zero-log policy enforcement

---

## License

MIT License - See [LICENSE](LICENSE)

Tide Gateway is free and open source software. You are free to use, modify, and distribute it.

---

## Acknowledgments

Built with:
- **Alpine Linux** - Lightweight base OS
- **Tor** - Anonymity network
- **Python** - Web dashboard and API
- **systemd** - Service management

Tested on:
- **Hetzner Cloud** - Primary testing platform
- **Multiple hypervisors** - VMware, Proxmox, Hyper-V, etc.

---

## Links

- **GitHub:** https://github.com/bodegga/tide
- **Releases:** https://github.com/bodegga/tide/releases
- **Issues:** https://github.com/bodegga/tide/issues
- **Documentation:** [docs/](docs/)

---

**Tide Gateway - freedom within the shell** 🌊

*Zero logs. Provable privacy. Open source.*

**Current Version:** v1.1.3  
**Last Updated:** December 2025
