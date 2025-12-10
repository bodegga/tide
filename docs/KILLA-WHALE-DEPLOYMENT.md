# 🐋 Killa Whale Mode - Deployment Guide

## ⚠️ CRITICAL: Not for Docker!

**Killa Whale mode CANNOT run in Docker.** It requires:

- **Full kernel access** (modify `/proc/sys/net/*`)
- **Raw network access** (ARP poisoning, promiscuous mode)
- **No containerization** (defeats the purpose of aggressive network control)

## Deployment Options

### ✅ Option 1: Physical VM (VirtualBox/VMware/Proxmox)
**Recommended for production**

1. Download Tide VM image (qcow2/OVA)
2. Import into hypervisor
3. Configure network adapter as "Bridged" or "Host-only"
4. Set `TIDE_MODE=killa-whale` in `/etc/tide.conf`
5. Start VM

### ✅ Option 2: QEMU/KVM Direct
**For advanced users**

```bash
./run-tide-qemu.sh killa-whale
```

### ✅ Option 3: Native Linux Install
**Maximum performance**

```bash
./tide-install.sh
# Select "Killa Whale" during setup
```

## Why Not Docker?

Docker isolates containers from the host kernel for security. Killa Whale **needs** to:

- Modify kernel network parameters (`/proc/sys/net/*`)
- Send raw ARP packets
- Enable promiscuous mode on network interface
- Control iptables with FAIL-CLOSED rules

Running in Docker would require `--privileged` mode, which defeats container isolation and still doesn't give full network control.

## What Works in Docker?

- ✅ **Proxy Mode** - SOCKS5 only
- ✅ **Router Mode** - Transparent proxy + DHCP (limited)

## Ready to Test Killa Whale?

See: **[VM Deployment Guide](DEPLOYMENT-VM.md)**

---

*Named after Andre Nickatina - maximum aggression, Bay Area style* 🎤🐋
