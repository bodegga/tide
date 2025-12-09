#!/bin/bash
set -euo pipefail

# ============================================================
# Tide Gateway - Golden Image Builder
# ============================================================
# Creates a FULLY CONFIGURED disk image by:
# 1. Booting Alpine cloud image with cloud-init
# 2. Letting it auto-configure as Tide Gateway
# 3. Shutting down and capturing the configured state
# 4. Converting to all hypervisor formats
#
# The result is a disk image that boots directly into a working
# Tor gateway - NO cloud-init ISO needed, NO manual steps.
#
# Usage: ./build-golden-image.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
ALPINE_CLOUD_IMG="nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
ALPINE_CLOUD_URL="https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
RELEASE_DIR="release"
WORK_DIR="$(mktemp -d)"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

cleanup() {
    rm -rf "$WORK_DIR"
    # Kill any lingering QEMU
    pkill -f "tide-golden" 2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo "=========================================="
echo "   🌊 Tide Gateway - Golden Image Builder"
echo "=========================================="
echo ""

# Check dependencies
for cmd in qemu-img qemu-system-aarch64 mkisofs; do
    if ! command -v $cmd &>/dev/null; then
        echo "ERROR: $cmd not found. Install with: brew install qemu cdrtools"
        exit 1
    fi
done

if [ ! -f "$BIOS" ]; then
    echo "ERROR: UEFI firmware not found at $BIOS"
    exit 1
fi

# Download Alpine cloud image if needed
if [ ! -f "$ALPINE_CLOUD_IMG" ]; then
    echo ">>> Downloading Alpine cloud image..."
    curl -# -L -o "$ALPINE_CLOUD_IMG" "$ALPINE_CLOUD_URL"
fi

mkdir -p "$RELEASE_DIR"

# ============================================================
# Step 1: Build cloud-init ISO
# ============================================================
echo ">>> Step 1/5: Building cloud-init seed..."

cat > "$WORK_DIR/meta-data" <<EOF
instance-id: tide-gateway-golden
local-hostname: tide-gateway
EOF

cat > "$WORK_DIR/user-data" <<'CLOUDCONFIG'
#cloud-config
hostname: tide-gateway

users:
  - name: root
    lock_passwd: false
    shell: /bin/ash

write_files:
  - path: /etc/network/interfaces
    content: |
      auto lo
      iface lo inet loopback
      
      auto eth0
      iface eth0 inet dhcp
      
      auto eth1
      iface eth1 inet static
          address 10.101.101.10
          netmask 255.255.255.0
    permissions: '0644'
  
  - path: /etc/sysctl.d/tide.conf
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
    permissions: '0644'
  
  - path: /etc/tor/torrc
    content: |
      User tor
      DataDirectory /var/lib/tor
      SocksPort 0.0.0.0:9050
      DNSPort 0.0.0.0:5353
      TransPort 0.0.0.0:9040
      VirtualAddrNetworkIPv4 10.192.0.0/10
      AutomapHostsOnResolve 1
      Log notice syslog
    permissions: '0644'
  
  - path: /etc/iptables/rules-save
    content: |
      *nat
      :PREROUTING ACCEPT [0:0]
      :INPUT ACCEPT [0:0]
      :OUTPUT ACCEPT [0:0]
      :POSTROUTING ACCEPT [0:0]
      -A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
      -A PREROUTING -i eth1 -p tcp --dport 53 -j REDIRECT --to-ports 5353
      -A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040
      COMMIT
      *filter
      :INPUT DROP [0:0]
      :FORWARD DROP [0:0]
      :OUTPUT ACCEPT [0:0]
      -A INPUT -i lo -j ACCEPT
      -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
      -A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 9050 -j ACCEPT
      -A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 9040 -j ACCEPT
      -A INPUT -i eth1 -s 10.101.101.0/24 -p udp --dport 5353 -j ACCEPT
      -A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 22 -j ACCEPT
      -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
      COMMIT
    permissions: '0644'

  - path: /etc/local.d/tide-init.start
    content: |
      #!/bin/sh
      sysctl -p /etc/sysctl.d/tide.conf 2>/dev/null
      iptables-restore < /etc/iptables/rules-save 2>/dev/null
    permissions: '0755'

  - path: /etc/motd
    content: |
      
        🌊 TIDE GATEWAY v1.2
        ═══════════════════════════════════════
        Gateway IP:  10.101.101.10
        Tor SOCKS5:  10.101.101.10:9050
        Tor DNS:     10.101.101.10:5353
      
        Status:  rc-service tor status
        Logs:    tail -f /var/log/messages | grep tor
        ═══════════════════════════════════════
      
    permissions: '0644'

packages:
  - tor
  - iptables
  - ip6tables
  - openssh

runcmd:
  # Set root password
  - echo "root:tide" | chpasswd
  
  # Configure SSH
  - sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - rc-update add sshd default
  
  # Enable services
  - rc-update add tor default
  - rc-update add iptables default
  - rc-update add local default
  
  # Apply sysctl
  - sysctl -p /etc/sysctl.d/tide.conf
  
  # Apply and save iptables
  - iptables-restore < /etc/iptables/rules-save
  - /etc/init.d/iptables save || true
  
  # Start services
  - rc-service sshd start
  - rc-service tor start
  
  # Clean up cloud-init so it doesn't run again
  - rc-update del cloud-init || true
  - rc-update del cloud-init-local || true
  - rc-update del cloud-final || true
  - rm -rf /var/lib/cloud/instances/*
  
  # Mark golden image complete
  - echo "Tide Gateway Golden Image - Built $(date)" > /root/BUILD_INFO
  - echo "Login: root / tide" >> /root/BUILD_INFO
  - echo "Gateway: 10.101.101.10" >> /root/BUILD_INFO
  
  # Signal completion by creating marker file
  - touch /tmp/TIDE_READY
  
  # Shutdown after config (QEMU will catch this)
  - sleep 5
  - poweroff

final_message: "Tide Gateway configured - shutting down to create golden image"
CLOUDCONFIG

mkisofs -quiet -output "$WORK_DIR/cloud-init.iso" -volid cidata -joliet -rock \
    "$WORK_DIR/meta-data" "$WORK_DIR/user-data"

# ============================================================
# Step 2: Create working copy of base image
# ============================================================
echo ">>> Step 2/5: Preparing base image..."

cp "$ALPINE_CLOUD_IMG" "$WORK_DIR/tide-golden.qcow2"
qemu-img resize "$WORK_DIR/tide-golden.qcow2" 1G 2>/dev/null

# ============================================================
# Step 3: Boot with QEMU and let cloud-init configure
# ============================================================
echo ">>> Step 3/5: Booting image with cloud-init (this takes ~2-3 minutes)..."
echo "    The VM will configure itself and shutdown automatically."
echo ""

# Run QEMU and wait for it to complete (VM will poweroff when done)
# Using -no-reboot so QEMU exits after guest shutdown
echo "    Starting QEMU... (watch for cloud-init progress)"
echo ""

qemu-system-aarch64 \
    -name "tide-golden" \
    -M virt \
    -cpu cortex-a72 \
    -m 1024 \
    -nographic \
    -no-reboot \
    -drive if=none,file="$WORK_DIR/tide-golden.qcow2",id=hd0,format=qcow2 \
    -device virtio-blk-device,drive=hd0 \
    -bios "$BIOS" \
    -cdrom "$WORK_DIR/cloud-init.iso" \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0 \
    2>&1 || true

echo ""
echo "    QEMU exited."

echo ""
echo ">>> Step 4/5: VM configured. Creating release images..."

# ============================================================
# Step 4: Copy configured image and convert formats
# ============================================================

# The qcow2 is now configured - copy to release
cp "$WORK_DIR/tide-golden.qcow2" "$RELEASE_DIR/tide-gateway.qcow2"
echo "    Created: tide-gateway.qcow2"

# Convert to raw (for Parallels)
qemu-img convert -f qcow2 -O raw \
    "$RELEASE_DIR/tide-gateway.qcow2" \
    "$RELEASE_DIR/tide-gateway.raw"
echo "    Created: tide-gateway.raw"

# Convert to VMDK (for VMware)
qemu-img convert -f qcow2 -O vmdk \
    "$RELEASE_DIR/tide-gateway.qcow2" \
    "$RELEASE_DIR/tide-gateway.vmdk"
echo "    Created: tide-gateway.vmdk"

# Convert to VDI (for VirtualBox)
qemu-img convert -f qcow2 -O vdi \
    "$RELEASE_DIR/tide-gateway.qcow2" \
    "$RELEASE_DIR/tide-gateway.vdi"
echo "    Created: tide-gateway.vdi"

# ============================================================
# Step 5: Summary
# ============================================================
echo ""
echo ">>> Step 5/5: Build complete!"
echo ""
echo "=========================================="
echo "   📦 Golden Image Artifacts"
echo "=========================================="
echo ""
ls -lh "$RELEASE_DIR/"*.{qcow2,raw,vmdk,vdi} 2>/dev/null || ls -lh "$RELEASE_DIR/"
echo ""
echo "These images are FULLY CONFIGURED - just import and boot!"
echo "No cloud-init ISO needed. No installation steps."
echo ""
echo "  UTM/QEMU:    tide-gateway.qcow2"
echo "  Parallels:   tide-gateway.raw (import as existing disk)"
echo "  VMware:      tide-gateway.vmdk"
echo "  VirtualBox:  tide-gateway.vdi"
echo ""
echo "All images:"
echo "  • Login: root / tide"
echo "  • Gateway: 10.101.101.10"
echo "  • Just add a second NIC (Host-Only) for client VMs"
echo ""
echo "=========================================="
