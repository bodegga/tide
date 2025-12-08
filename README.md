# Tide Gateway - Universal Tor Appliance (ARM64)

**Dead-simple, transparent Tor gateway for your VMs.**

Route all traffic from any VM through Tor with zero configuration inside the client. Just point your VM's gateway to Tide.

## 🌊 Quick Start

### Download

Get the latest release from [GitHub Releases](https://github.com/anthonybiasi/opsec-vm/releases):
- `tide-gateway.qcow2` - Pre-configured Alpine Linux disk image
- `cloud-init.iso` - Auto-configuration seed (required for first boot)

### Setup in UTM (Mac)

1. **Create VM:** UTM → Create → Virtualize → Linux
2. **Boot Disk:** Import `tide-gateway.qcow2`
3. **CD/DVD:** Add `cloud-init.iso`
4. **Network Adapter 1:** Shared Network (WAN - internet)
5. **Network Adapter 2:** Host-Only (LAN - for your workstation)
6. **Boot** and wait ~2 minutes for auto-configuration

**Login:** `root` / `tide`

### Setup in Parallels (Mac)

Parallels requires a fresh Alpine install (the qcow2 format isn't directly compatible):

```bash
# Run the automated builder (downloads Alpine ISO, creates VM)
./build-parallels.sh
```

Then in the Parallels console:
1. Login as `root` (no password)
2. Run the one-liner:
   ```bash
   wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
   ```
3. Press Enter to confirm disk wipe
4. After install completes, eject ISO and reboot

**Note:** Alpine 3.21+ standard ISO is required (the virt ISO doesn't boot in Parallels).

---

## 🔌 Client Configuration

Connect any VM (Kali, Ubuntu, Windows) to the **same Host-Only network** as Tide's LAN adapter.

**Inside the client OS:**

| Setting | Value |
|---------|-------|
| IP Address | `10.101.101.20` (or .11-.99) |
| Subnet Mask | `255.255.255.0` |
| Gateway | `10.101.101.10` |
| DNS Server | `10.101.101.10` |
| IPv6 | **Disabled** |

### Verify Tor Connection

Open a browser in the client and go to: https://check.torproject.org

You should see: **"Congratulations. This browser is configured to use Tor."**

---

## 📡 Gateway Services

| Service | Port | Purpose |
|---------|------|---------|
| **Transparent Proxy** | 9040 | Auto-routes all TCP traffic |
| **DNS** | 5353 | Resolves through Tor |
| **SOCKS5** | 9050 | Manual proxy option |
| **SSH** | 22 | Administration |

---

## 🔧 Administration

- **Gateway IP:** `10.101.101.10`
- **Login:** `root` / `tide`
- **SSH:** `ssh root@10.101.101.10` (from LAN)
- **Tor Config:** `/etc/tor/torrc`
- **Firewall:** `iptables -L -n -v`
- **Tor Status:** `rc-service tor status`

### Useful Commands

```bash
# Check Tor status
rc-service tor status

# View Tor logs
tail -f /var/log/messages | grep -i tor

# Restart Tor (get new circuit)
rc-service tor restart

# Check iptables rules
iptables -L -n -v -t nat
```

---

## 🏗️ Building from Source

### Prerequisites

```bash
# macOS
brew install qemu cdrtools
```

### Build Release Artifacts

```bash
git clone https://github.com/anthonybiasi/opsec-vm.git
cd opsec-vm

# Download Alpine cloud image (one-time)
wget https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2

# Build release
./build-release.sh
```

Output in `release/`:
- `tide-gateway.qcow2` - Gateway disk image
- `cloud-init.iso` - Configuration seed
- `tide-autoinstall-efi.iso` - Fresh install ISO (optional)

### Test with QEMU

```bash
./run-tide-qemu.sh fresh
```

---

## 📁 Project Structure

```
opsec-vm/
├── release/                    # Release artifacts
│   ├── tide-gateway.qcow2      # Gateway disk
│   ├── cloud-init.iso          # Auto-config seed
│   └── tide-autoinstall-efi.iso
├── build-release.sh            # Main build script
├── run-tide-qemu.sh            # QEMU test runner
├── setup-tide.sh               # Manual setup script
├── cloud-init-userdata.yaml    # Cloud-init config source
└── docs/                       # Additional documentation
```

---

## ⚠️ Security Notes

- **Default password is `tide`** - Change in production!
- Root SSH login is enabled for convenience - disable if not needed
- All traffic from the LAN is transparently routed through Tor
- IPv6 is disabled to prevent leaks
- The gateway itself uses DHCP on eth0 for internet access

---

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

## 🤝 Contributing

Issues and PRs welcome! See the build documentation in `docs/BUILD.md`.

---

**Petaluma Pride 🌊 | Built with Alpine Linux + Tor**
