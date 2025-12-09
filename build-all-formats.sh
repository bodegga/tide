#!/bin/bash
set -euo pipefail

# ============================================================
# Tide Gateway - Multi-Format Image Builder
# ============================================================
# Builds a pre-configured Tide Gateway image and converts to
# all major hypervisor formats.
#
# Output:
#   release/tide-gateway.qcow2  - UTM, QEMU, Proxmox
#   release/tide-gateway.vmdk   - VMware Fusion/Workstation
#   release/tide-gateway.vdi    - VirtualBox
#   release/tide-gateway.raw    - Parallels (import as raw)
#   release/cloud-init.iso      - Config seed (for qcow2)
#
# Usage: ./build-all-formats.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
ALPINE_CLOUD_IMG="nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
ALPINE_CLOUD_URL="https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
RELEASE_DIR="release"
WORK_DIR="$(mktemp -d)"
trap "rm -rf $WORK_DIR" EXIT

echo ""
echo "=========================================="
echo "   🌊 Tide Gateway - Image Builder"
echo "=========================================="
echo ""

# Check dependencies
for cmd in qemu-img qemu-system-aarch64 mkisofs; do
    if ! command -v $cmd &>/dev/null; then
        echo "ERROR: $cmd not found. Install with: brew install qemu cdrtools"
        exit 1
    fi
done

# Download Alpine cloud image if needed
if [ ! -f "$ALPINE_CLOUD_IMG" ]; then
    echo ">>> Downloading Alpine cloud image..."
    curl -# -L -o "$ALPINE_CLOUD_IMG" "$ALPINE_CLOUD_URL"
fi

mkdir -p "$RELEASE_DIR"

# ============================================================
# Step 1: Build cloud-init ISO
# ============================================================
echo ""
echo ">>> Step 1/4: Building cloud-init.iso..."

cat > "$WORK_DIR/meta-data" <<EOF
instance-id: tide-gateway-001
local-hostname: tide-gateway
EOF

cat > "$WORK_DIR/user-data" <<'EOF'
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
      echo "Tide Gateway started at $(date)" >> /var/log/tide.log
    permissions: '0755'

  - path: /etc/motd
    content: |
      
        🌊 TIDE GATEWAY
        ═══════════════════════════════════════
        Gateway IP:  10.101.101.10
        Tor SOCKS:   10.101.101.10:9050
        Tor DNS:     10.101.101.10:5353
      
        Verify:  curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
        Status:  rc-service tor status
        ═══════════════════════════════════════
      
    permissions: '0644'

packages:
  - tor
  - iptables
  - ip6tables
  - openssh

runcmd:
  - echo "root:tide" | chpasswd
  - sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - rc-update add sshd default
  - rc-update add tor default
  - rc-update add iptables default
  - rc-update add local default
  - sysctl -p /etc/sysctl.d/tide.conf
  - iptables-restore < /etc/iptables/rules-save
  - /etc/init.d/iptables save || true
  - rc-service tor start
  - echo "Tide Gateway configured $(date)" > /root/SETUP_COMPLETE

final_message: "Tide Gateway ready! Login: root/tide | Gateway: 10.101.101.10"
EOF

mkisofs -quiet -output "$RELEASE_DIR/cloud-init.iso" -volid cidata -joliet -rock \
    "$WORK_DIR/meta-data" "$WORK_DIR/user-data"
echo "    Created: $RELEASE_DIR/cloud-init.iso"

# ============================================================
# Step 2: Create base qcow2 image
# ============================================================
echo ""
echo ">>> Step 2/4: Creating qcow2 image..."

cp "$ALPINE_CLOUD_IMG" "$RELEASE_DIR/tide-gateway.qcow2"
qemu-img resize "$RELEASE_DIR/tide-gateway.qcow2" 1G 2>/dev/null || true
echo "    Created: $RELEASE_DIR/tide-gateway.qcow2"

# ============================================================
# Step 3: Convert to other formats
# ============================================================
echo ""
echo ">>> Step 3/4: Converting to other formats..."

# Raw (for Parallels)
echo "    Converting to raw..."
qemu-img convert -f qcow2 -O raw "$RELEASE_DIR/tide-gateway.qcow2" "$RELEASE_DIR/tide-gateway.raw"
echo "    Created: $RELEASE_DIR/tide-gateway.raw"

# VMDK (for VMware)
echo "    Converting to vmdk..."
qemu-img convert -f qcow2 -O vmdk "$RELEASE_DIR/tide-gateway.qcow2" "$RELEASE_DIR/tide-gateway.vmdk"
echo "    Created: $RELEASE_DIR/tide-gateway.vmdk"

# VDI (for VirtualBox)  
echo "    Converting to vdi..."
qemu-img convert -f qcow2 -O vdi "$RELEASE_DIR/tide-gateway.qcow2" "$RELEASE_DIR/tide-gateway.vdi"
echo "    Created: $RELEASE_DIR/tide-gateway.vdi"

# ============================================================
# Step 4: Summary
# ============================================================
echo ""
echo ">>> Step 4/4: Build complete!"
echo ""
echo "=========================================="
echo "   📦 Release Artifacts"
echo "=========================================="
echo ""
ls -lh "$RELEASE_DIR/"
echo ""
echo "Usage by hypervisor:"
echo ""
echo "  UTM/QEMU:"
echo "    - Import tide-gateway.qcow2 as boot disk"
echo "    - Attach cloud-init.iso as CD"
echo "    - Add 2 NICs (Shared + Host-Only)"
echo "    - Boot and wait 2 min"
echo ""
echo "  Parallels:"
echo "    - File → New → Install from image"
echo "    - Select tide-gateway.raw"
echo "    - Add second NIC (Host-Only)"
echo "    - Attach cloud-init.iso as CD"
echo "    - Boot and wait 2 min"
echo ""
echo "  VMware Fusion:"
echo "    - File → Import → tide-gateway.vmdk"
echo "    - Add second NIC (Host-Only)"
echo "    - Attach cloud-init.iso as CD"
echo ""
echo "  VirtualBox:"
echo "    - New VM → Use existing disk → tide-gateway.vdi"
echo "    - Add second NIC (Host-Only)"
echo "    - Attach cloud-init.iso as CD"
echo ""
echo "All formats: Login root/tide, Gateway 10.101.101.10"
echo ""
