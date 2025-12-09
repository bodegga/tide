# 🌊 TIDE - Transparent Internet Defense Engine

**Route through Tor or nothing.** A hardened, leak-proof Tor gateway with multiple deployment modes.

## Features

- **Fail-Closed Security** - If Tor dies, traffic is blocked (not leaked)
- **Immutable Config** - Critical files locked with `chattr +i`
- **Multiple Modes** - From simple proxy to full subnet takeover
- **Zero Config Clients** - DHCP + DNS handles everything

## Deployment Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Proxy** | SOCKS5 + DNS only | Single VM, testing |
| **Router** | DHCP + DNS + transparent proxy | VM lab, isolated network |
| **Forced** | Router + fail-closed firewall | High security |
| **Takeover** | Forced + ARP hijacking | Full subnet control |

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

**For Router/Forced/Takeover modes:** Clients just connect - DHCP handles everything.

**For Proxy mode:** Configure apps manually:
- SOCKS5: `10.101.101.1:9050`
- DNS: `10.101.101.1:5353`

**Verify:** `curl --socks5 10.101.101.1:9050 https://check.torproject.org/api/ip`

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
tide status    # Show mode, Tor status, IP
tide check     # Test Tor connectivity
tide takeover  # Activate ARP hijacking (takeover mode)
tide release   # Stop ARP hijacking
```

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
│  │   │ 10.101.101.1│         ▲                   ▲        │  │
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

**[bodegga/tide](https://github.com/bodegga/tide)** | Route through Tor or nothing. 🌊
