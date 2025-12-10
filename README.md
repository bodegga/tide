<div align="center">

<img src="README-icon.png" width="200" alt="Tide Icon" />

# 🌊 TIDE

**Transparent Internet Defense Engine**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Docker%20%7C%20VM%20%7C%20Bare--metal-lightgrey)](https://github.com/bodegga/tide)
[![Version](https://img.shields.io/badge/version-1.2.0-green)](https://github.com/bodegga/tide/releases)
[![Tor](https://img.shields.io/badge/Tor-enabled-purple)](https://www.torproject.org/)

*freedom within the shell* • [bodegga.net](https://bodegga.net)

</div>

**Route through Tor or nothing.** A hardened, leak-proof Tor gateway with multiple deployment modes.

## Platform Support

Tide runs on **any platform** that supports Docker or VMs:
- ✅ **Docker** - Linux, macOS (Intel/Apple Silicon), Windows (WSL2)
- ✅ **VMs** - UTM, QEMU, VirtualBox, VMware, Parallels, Hyper-V
- ✅ **Bare-metal** - Any Alpine Linux compatible hardware (x86_64, ARM64)

Client devices can be **anything** with network access.

## Features

- **Fail-Closed Security** - If Tor dies, traffic is blocked (not leaked)
- **Immutable Config** - Critical files locked with `chattr +i`
- **Multiple Modes** - From simple proxy to full subnet takeover
- **Zero Config Clients** - DHCP + DNS handles everything
- **Platform Agnostic** - Runs anywhere Docker or VMs do

## Deployment Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Proxy** | SOCKS5 + DNS only | Single VM, testing |
| **Router** | DHCP + DNS + transparent proxy | VM lab, isolated network |
| **Killa Whale** | Router + fail-closed firewall | High security |
| **Takeover** | Killa Whale + ARP hijacking | Full subnet control |

## Security Profiles

| Profile | Description | Trade-off |
|---------|-------------|-----------|
| **Standard** | Default Tor settings | Fastest, most relays |
| **Hardened** | Excludes 14-eyes countries | Fewer exits, more privacy |
| **Paranoid** | Max isolation, hostile countries blocked | Slowest, maximum anonymity |
| **Bridges** | Uses obfs4 bridges | Anti-censorship, bypasses blocks |

## Quick Start

### Docker (Proxy Only)
```bash
docker run -d --name tide -p 9050:9050 -p 5353:5353/udp bodegga/tide
# Configure apps: SOCKS5=localhost:9050, DNS=localhost:5353
```

### VM Gateway (Full Features)
```bash
# Boot Alpine Linux ISO, login as root, run:
wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh

# Select your mode (1-4), follow prompts
```

### UTM / QEMU
Download from [Releases](https://github.com/bodegga/tide/releases):
1. Import `tide-gateway.qcow2` + attach `cloud-init.iso`
2. Add 2 NICs (Shared + Host-Only)
3. Boot → auto-configures

## Client Configuration

**For Router/Killa Whale/Takeover modes:** Clients just connect - DHCP handles everything.

**For Proxy mode:** Configure apps manually:
- SOCKS5: `10.101.101.10:9050`
- DNS: `10.101.101.10:5353`

**Verify:** `curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip`

## Security Model

```
                    ┌─────────────────┐
   Clients ────────▶│  TIDE GATEWAY   │────▶ Tor Network ────▶ Internet
   (auto DHCP)      │                 │
                    │ • iptables DROP │
                    │ • Only Tor out  │
                    │ • Fail-closed   │
                    └─────────────────┘
                           │
                    Clearnet blocked ❌
```

**Guarantees:**
- All TCP redirected through Tor TransPort
- All DNS through Tor DNSPort  
- No UDP except DNS (dropped)
- No ICMP to outside (dropped)
- No IPv6 (disabled)
- Gateway itself cannot reach clearnet (only Tor process can)

## Commands

```bash
tide status      # Show mode, Tor status, IP
tide check       # Test Tor connectivity
tide newcircuit  # Request new Tor circuit
tide onion       # Show SSH .onion address (if enabled)
tide takeover    # Activate ARP hijacking (takeover mode)
tide release     # Stop ARP hijacking
```

## Client Apps

Tide includes client apps for easy gateway discovery and connection.

### Discovery API (Port 9051)

The gateway runs an HTTP API for auto-discovery:

```bash
# Check gateway status
curl http://10.101.101.10:9051/status

# Response:
# {"gateway":"tide","version":"1.0","mode":"killa-whale","security":"hardened",
#  "tor":"connected","uptime":3600,"ip":"10.101.101.10",
#  "ports":{"socks":9050,"dns":5353,"api":9051}}

# Get current exit IP
curl http://10.101.101.10:9051/circuit

# Request new circuit
curl http://10.101.101.10:9051/newcircuit

# Verify Tor is working
curl http://10.101.101.10:9051/check
```

### Python Client (Cross-Platform)

```bash
# Install dependencies
pip install requests pystray pillow

# Run
python client/tide-client.py
```

Features:
- System tray icon with Tor status
- Auto-discovers gateway on local network
- One-click circuit refresh
- Shows current exit IP

### macOS Native Client

Build with Xcode or Swift:
```bash
swiftc client/macos/TideClient.swift -o TideClient
./TideClient
```

Features:
- Native menu bar app
- Auto-discovery via Bonjour
- Click to copy proxy settings
- Status indicator (🟢 connected / 🔴 offline)

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        HOST MACHINE                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Host-Only Network (vmnet)                 │  │
│  │                                                        │  │
│  │   ┌────────────┐     ┌────────────┐     ┌──────────┐  │  │
│  │   │   TIDE     │     │  Client 1  │     │ Client 2 │  │  │
│  │   │  Gateway   │     │  (Kali)    │     │ (Win11)  │  │  │
│  │   │            │     │            │     │          │  │  │
│  │   │ DHCP+DNS   │◀────│ Auto-DHCP  │     │Auto-DHCP │  │  │
│  │   │ Tor Proxy  │     │            │     │          │  │  │
│  │   │            │     └────────────┘     └──────────┘  │  │
│  │   │10.101.101.10│         ▲                   ▲        │  │
│  │   └──────┬─────┘         │                   │        │  │
│  │          │               └───────────────────┘        │  │
│  └──────────┼───────────────────────────────────────────┘  │
│             │ eth0 (NAT)                                    │
│             ▼                                               │
│        [ Tor Network ] ─────────▶ Internet                  │
└──────────────────────────────────────────────────────────────┘
```

## Building

```bash
# Docker image
docker build -t tide .

# VM images (requires QEMU)
./build-release.sh

# Custom Alpine ISO
./build-tide-iso.sh
```

## Files

| File | Purpose |
|------|---------|
| `tide-install.sh` | Interactive installer (run from Alpine ISO) |
| `Dockerfile` | Docker container build |
| `cloud-init-userdata.yaml` | Cloud-init for qcow2 images |
| `iptables-leak-proof.rules` | Hardened firewall rules |

## Security Notes

- Default password is `tide` - **change it!**
- Config files are immutable (`chattr +i`) - use `chattr -i` to modify
- Takeover mode uses ARP poisoning - **use responsibly**
- All modes disable IPv6 completely

## License

MIT

---

**[bodegga/tide](https://github.com/bodegga/tide)** | *Freedom within the shell.* 🌊
