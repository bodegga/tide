# Tide 🌊

**Privacy gateway for ARM64**

Transparent Tor proxy for Apple Silicon and ARM64 systems.

---

## Quick Start

**Download:**
```bash
curl -LO https://github.com/bodegga/tide/releases/download/v1.0.0/tide-gateway-v1.0-arm64.tar.gz
```

**Extract & Import:**
```bash
tar -xzf tide-gateway-v1.0-arm64.tar.gz -C ~/Parallels/
prlctl register ~/Parallels/Tor-Gateway.pvm
prlctl start Tor-Gateway
```

**Gateway IP:** `10.152.152.10`

---

## Features

- ✅ Tor transparent proxy (all traffic protected)
- ✅ DNS leak prevention
- ✅ .onion support built-in
- ✅ Fail-closed firewall
- ✅ ~1GB download, ~500MB RAM usage

---

## Workstation Setup

Configure your VM to route through the gateway:

```bash
# /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
```

Verify:
```bash
curl https://check.torproject.org/api/ip
# Should return: {"IsTor":true}
```

---

## Supported Platforms

- Parallels Desktop
- UTM (free, open source)
- VMware Fusion
- VirtualBox
- QEMU/KVM

Works on any ARM64 hypervisor.

---

## Build Your Own

See [docs/BUILD.md](docs/BUILD.md) for building from source.

---

## Support

- [Issues](https://github.com/bodegga/tide/issues)
- [Discussions](https://github.com/bodegga/tide/discussions)

---

**License:** MIT

Open source. Free forever.
