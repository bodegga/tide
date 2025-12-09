# 🌊 Tide Gateway

**Dead-simple Tor gateway for your VMs.** Route all VM traffic through Tor with zero client configuration.

## Quick Start (Pick Your Hypervisor)

### Parallels Desktop

```bash
# 1. Download Alpine ISO (one-time)
curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-standard-3.21.2-aarch64.iso

# 2. Create VM: File → New → Install from DVD/image → select the ISO
#    - 512MB RAM, 2GB disk
#    - Add second network adapter: Host-Only

# 3. Boot, login as root (no password), run ONE command:
wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh

# 4. Type 'yes', wait 2-3 min, eject ISO, reboot. Done!
```

### UTM (Mac)

Download from [Releases](https://github.com/bodegga/tide/releases):
- `tide-gateway.qcow2` + `cloud-init.iso`

1. Create VM → Virtualize → Linux
2. Import `tide-gateway.qcow2` as boot disk  
3. Attach `cloud-init.iso` as CD
4. Add 2 NICs: Shared Network + Host-Only
5. Boot and wait 2 minutes - auto-configures!

### VMware / VirtualBox / Any Other

```bash
# Boot any Alpine Linux 3.20+ ISO, login as root, run:
wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
```

---

## After Installation

**Login:** `root` / `tide`  
**Gateway IP:** `10.101.101.10`

### Connect Client VMs

1. Put client VM on same Host-Only network as Tide's eth1
2. Configure client networking:

| Setting | Value |
|---------|-------|
| IP | `10.101.101.20` (or any .11-.99) |
| Subnet | `255.255.255.0` |
| Gateway | `10.101.101.10` |
| DNS | `10.101.101.10` |
| IPv6 | **Disabled** |

3. Test: Open browser → https://check.torproject.org

---

## Gateway Services

| Port | Service | Description |
|------|---------|-------------|
| 9040 | TransPort | Transparent TCP proxy (automatic) |
| 5353 | DNSPort | DNS over Tor |
| 9050 | SOCKS5 | Manual proxy (optional) |
| 22 | SSH | Administration |

### Useful Commands

```bash
rc-service tor status          # Check Tor
rc-service tor restart         # New circuit
tail -f /var/log/messages      # View logs
iptables -L -n -v -t nat       # Check firewall
```

---

## How It Works

```
┌─────────────┐     ┌─────────────────┐     ┌─────────┐
│  Client VM  │────▶│  Tide Gateway   │────▶│   Tor   │────▶ Internet
│ (Kali, etc) │     │  10.101.101.10  │     │ Network │
└─────────────┘     └─────────────────┘     └─────────┘
    eth0               eth1      eth0
 Host-Only           LAN       WAN (NAT)
```

All TCP traffic from clients is transparently routed through Tor. DNS queries go through Tor's DNS resolver. No client configuration needed beyond pointing gateway/DNS to Tide.

---

## Building from Source

```bash
# For UTM/QEMU releases (qcow2 + cloud-init)
./build-release.sh

# For Parallels (creates VM, you run installer)
./build-parallels.sh

# Test with QEMU
./run-tide-qemu.sh fresh
```

---

## Security Notes

- ⚠️ Default password is `tide` - change it!
- Root SSH enabled for convenience - disable in production
- IPv6 disabled to prevent leaks
- All LAN traffic forced through Tor

---

## License

MIT - See [LICENSE](LICENSE)

---

**Built with Alpine Linux + Tor | [bodegga/tide](https://github.com/bodegga/tide)**
