# Tide Gateway v1.1.3 - QEMU/KVM

## Quick Start

### Run with QEMU (ARM64)

```bash
# Basic run (aarch64)
qemu-system-aarch64 \
  -M virt -cpu cortex-a72 -m 512 \
  -drive if=none,file=Tide-Gateway-v1.1.3-QEMU-aarch64.qcow2,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -device virtio-net-device,netdev=net0 \
  -device virtio-net-device,netdev=net1 \
  -netdev user,id=net0 \
  -netdev user,id=net1,hostfwd=tcp::2222-:22 \
  -nographic
```

### Run with QEMU (x86_64)

```bash
# Basic run (x86_64)
qemu-system-x86_64 \
  -enable-kvm \
  -m 512 \
  -drive file=Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2,format=qcow2 \
  -device virtio-net,netdev=net0 \
  -device virtio-net,netdev=net1 \
  -netdev user,id=net0 \
  -netdev user,id=net1 \
  -nographic
```

### Run with KVM (Linux)

```bash
# With KVM acceleration (Linux only)
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m 512 \
  -drive file=Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2,if=virtio,format=qcow2 \
  -netdev bridge,id=net0,br=br0 \
  -device virtio-net-pci,netdev=net0 \
  -netdev tap,id=net1,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=net1 \
  -nographic
```

## Default Credentials

```
Username: root
Password: tide
```

**⚠️ CHANGE DEFAULT PASSWORD!**

## Network Setup (Linux KVM Host)

### Create Bridge for WAN

```bash
# Install bridge utilities
sudo apt install bridge-utils

# Create bridge
sudo brctl addbr br0
sudo brctl addif br0 eth0  # Your physical NIC
sudo ip link set br0 up
sudo dhclient br0
```

### Create TAP Interface for LAN

```bash
# Create TAP interface
sudo ip tuntap add dev tap0 mode tap
sudo ip addr add 10.101.101.1/24 dev tap0
sudo ip link set tap0 up
```

### Persistent Configuration

**Debian/Ubuntu** (`/etc/network/interfaces`):
```
# WAN bridge
auto br0
iface br0 inet dhcp
    bridge_ports eth0
    bridge_stp off
    bridge_fd 0

# LAN tap
auto tap0
iface tap0 inet static
    address 10.101.101.1
    netmask 255.255.255.0
    pre-up ip tuntap add dev tap0 mode tap
    post-down ip tuntap del dev tap0 mode tap
```

## Verification

### Access Console

QEMU console uses serial output with `-nographic` flag.

**To exit:** Press `Ctrl-A` then `X`

### Test Tor

From gateway:
```bash
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```

Expected:
```json
{"IsTor":true,"IP":"<tor-exit-ip>"}
```

### SSH Access

With port forwarding:
```bash
ssh -p 2222 root@localhost
```

Or directly if using bridge/tap:
```bash
ssh root@10.101.101.10
```

## Advanced Usage

### Run in Background

```bash
# Start as daemon
qemu-system-x86_64 \
  -enable-kvm -m 512 \
  -drive file=Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2,if=virtio,format=qcow2 \
  -netdev user,id=net0 \
  -netdev user,id=net1,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -device virtio-net-pci,netdev=net1 \
  -daemonize \
  -pidfile /var/run/tide-gateway.pid \
  -display none
```

### VNC Access

```bash
# Enable VNC
qemu-system-x86_64 \
  -enable-kvm -m 512 \
  -drive file=Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2,if=virtio \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -vnc :0
```

Connect with VNC client to `localhost:5900`

### Snapshot Support

```bash
# Create snapshot
qemu-img snapshot -c initial Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2

# List snapshots
qemu-img snapshot -l Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2

# Restore snapshot
qemu-img snapshot -a initial Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2

# Delete snapshot
qemu-img snapshot -d initial Tide-Gateway-v1.1.3-QEMU-x86_64.qcow2
```

## File Information

**Filename:** `Tide-Gateway-v1.1.3-QEMU-{arch}.qcow2`  
**Format:** QCOW2  
**Size:** ~150MB  
**Checksum:** See `.sha256` file

**VM Specifications:**
- OS: Alpine Linux 3.21
- Disk: 2GB (thin provisioned)
- RAM: 512MB
- CPU: 1 vCPU
- Network: 2 interfaces

## Support

- **Documentation:** https://github.com/bodegga/tide
- **QEMU Manual:** https://www.qemu.org/docs/master/

---

**Tide Gateway v1.1.3** | Transparent Internet Defense Engine  
**Bodegga Company** | Network Security | Petaluma, CA
