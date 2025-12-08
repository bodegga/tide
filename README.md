# Tide 🌊

**Privacy gateway for ARM64**

Routes all traffic through Tor. Works on any ARM64 hypervisor.

Built by [Bodegga](https://bodegga.net). Made in Petaluma, CA.

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

## What You Get

- ✅ Tor transparent proxy (all traffic protected)
- ✅ DNS leak prevention
- ✅ .onion support built-in
- ✅ Fail-closed firewall
- ✅ ~1GB download, ~500MB RAM usage

---

## Workstation Setup

Point your VM to the gateway:

```bash
# /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
```

Test:
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

All ARM64 hypervisors supported.

---

## Build Your Own

Want Alpine instead of Debian? Smaller footprint?

See [docs/BUILD.md](docs/BUILD.md)

---

## Support

- [Issues](https://github.com/bodegga/tide/issues)
- [Discussions](https://github.com/bodegga/tide/discussions)

---

**Website:** [tide.bodegga.net](https://tide.bodegga.net)  
**License:** MIT

Privacy flows naturally. 🌊
