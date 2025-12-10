# Tide Gateway - Killa Whale Deployment

## 🎯 What You Get

A **working Parallels VM** that routes ALL traffic through Tor using:
- ✅ ARP poisoning (intercepts network traffic)
- ✅ Transparent proxy (no client configuration)
- ✅ DHCP server (auto-assigns IPs)
- ✅ DNS over Tor
- ✅ Fail-closed firewall (nothing escapes)

**Template Size**: 192MB compressed, 379MB extracted

---

## 🚀 ONE COMMAND DEPLOYMENT

```bash
curl -sSL https://raw.githubusercontent.com/bodegga/tide/main/ONE-COMMAND-DEPLOY.sh | bash
```

**That's it.** VM downloads, deploys, and starts in ~2 minutes.

---

## 📋 Manual Deployment

### 1. Download Template

```bash
curl -L -o tide-template.tar.gz https://github.com/bodegga/tide/releases/download/v1.2.0/Tide-Gateway-Template-v1.2.0.tar.gz
```

### 2. Extract to Parallels

```bash
tar -xzf tide-template.tar.gz -C ~/Parallels/
```

### 3. Deploy

```bash
prlctl clone Tide-Gateway-TEMPLATE --name "Killa-Whale-$(date +%Y%m%d)"
prlctl start "Killa-Whale-$(date +%Y%m%d)"
```

**Done!**

---

## 🔧 What's Configured

- **OS**: Alpine Linux 3.21 (ARM64)
- **Gateway IP**: 10.101.101.10
- **DHCP Range**: 10.101.101.100-200
- **Services**: Tor, dnsmasq, iptables, arping
- **Mode**: Killa Whale (aggressive takeover)

### Network Setup

- **Adapter 0**: Shared Network (internet access)
- **Adapter 1**: Host-Only Network (attack network)

---

## 🎮 Usage

### Connect a Device

1. **Start the VM** (auto-starts Killa Whale)
2. **Connect device** to the host-only network
3. **Done** - all traffic routed through Tor

### Verify It's Working

On the connected device:
```bash
curl ifconfig.me  # Should show Tor exit node IP
```

### VM Management

```bash
# List VMs
prlctl list -a

# Start
prlctl start Killa-Whale-20251209

# Stop
prlctl stop Killa-Whale-20251209

# Delete
prlctl delete Killa-Whale-20251209
```

---

## 🏗️ Build Your Own Template

Don't trust the pre-built template? Build it yourself:

```bash
git clone https://github.com/bodegga/tide.git
cd tide
./deploy-vm.sh
```

Then in the VM:
```bash
git clone https://github.com/bodegga/tide.git
cd tide
sh FINAL-INSTALL.sh
```

Shutdown and clone as template:
```bash
prlctl stop Tide-Gateway-Auto
prlctl clone Tide-Gateway-Auto --name Tide-Gateway-TEMPLATE
```

---

## 📦 Package for Distribution

```bash
./PACKAGE-RELEASE.sh
```

Outputs: `releases/Tide-Gateway-Template-v1.2.0.tar.gz`

---

## 🔐 Security Notes

**This is a MITM attack tool.**

- Use only on networks you own
- Killa Whale mode is AGGRESSIVE (ARP poisoning)
- All traffic forced through Tor (even if device tries to bypass)
- Tor exit nodes can see unencrypted traffic
- Use HTTPS for sensitive data

---

## 🐛 Troubleshooting

### VM won't boot
```bash
prlctl set VM-NAME --device-set cdrom0 --disconnect
prlctl start VM-NAME
```

### Services not starting
```bash
# In VM
rc-service tide-gateway status
tail -f /var/log/tide/gateway.log
```

### No internet in VM
```bash
# In VM
ping 8.8.8.8
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

---

## 📊 Stats

- **Build time**: ~10 minutes (first time)
- **Deploy time**: ~30 seconds (from template)
- **Download size**: 192MB
- **Disk usage**: 379MB
- **RAM usage**: 512MB-1GB
- **CPU**: 2 cores recommended

---

## 🎯 Roadmap

- [ ] UTM/QEMU template (Mac/Linux/Windows)
- [ ] VirtualBox OVA export
- [ ] Docker version (Linux hosts only)
- [ ] Auto-update mechanism
- [ ] Web UI for status
- [ ] Multiple security profiles

---

**Built with rage and determination on Dec 9, 2025.**

*"It should have taken 15 minutes. It took 6 hours. But now it's ONE COMMAND."*

