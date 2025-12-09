# Changelog

All notable changes to Tide will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### In Development
- v1.3: Forced mode (fail-closed firewall enforcement)
- v1.4: Security profiles (Standard, Hardened, Paranoid, Bridges)
- Client GUI improvements

## [1.2.0] - 2025-12-08

### Added
- Docker Router Mode (default)
- Gateway IP standardization (10.101.101.10)
- Platform support clarification (Docker, VM, bare-metal)
- Professional repository structure (CONTRIBUTING, SECURITY, CHANGELOG)
- Badges in README

### Changed
- Updated all documentation for 10.101.101.10 gateway IP
- Removed "Apple Silicon only" references
- Improved .gitignore

## [1.1.0] - 2025-12-08

### Added
- Cloud-init configuration
- Pre-built VM images (qcow2, ISO)
- Consolidated build system
- Better QEMU test runner

### Fixed
- Cloud-init file names and password configuration

## [1.0.0] - 2025-12-08

### Added
- ✅ **Proxy Mode** - SOCKS5 (port 9050) + DNS (port 5353)
- ✅ **Router Mode** - DHCP + transparent Tor routing (default)
- ✅ Docker deployment with `docker-compose`
- ✅ VM installer script (`tide-install.sh`)
- ✅ Platform support: Docker, VMs, bare-metal
- ✅ Security profiles: Standard, Hardened, Paranoid, Bridges
- ✅ Client discovery scripts (Python, Shell, Swift)
- ✅ Comprehensive documentation
- ✅ MIT License

### Security
- Fail-closed firewall (traffic blocked if Tor fails)
- IPv6 completely disabled (prevents leaks)
- Immutable config files (`chattr +i`)
- Transparent proxy via iptables
- DNS routed through Tor DNSPort

### Documentation
- README with Quick Start guide
- Platform compatibility matrix
- Security model documentation
- Deployment modes comparison
- ROADMAP for future features

## Project History

- **Dec 9, 2025**: v1.0 stable release
- **Dec 7, 2025**: Initial repository structure
- **Dec 2025**: Active development and testing

---

## Version Numbering

- **Major (1.x.x)**: Breaking changes, major features
- **Minor (x.1.x)**: New features, backward compatible
- **Patch (x.x.1)**: Bug fixes, security patches

[unreleased]: https://github.com/bodegga/tide/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/bodegga/tide/releases/tag/v1.2.0
[1.1.0]: https://github.com/bodegga/tide/releases/tag/v1.1.0
[1.0.0]: https://github.com/bodegga/tide/releases/tag/v1.0.0
