#!/bin/bash
set -euo pipefail

# ========================================
# Tide Gateway - Release Builder
# ========================================
# Creates production-ready release artifacts:
#   - cloud-init.iso (nocloud seed for Alpine cloud image)
#   - tide-gateway.qcow2 (ready-to-use gateway disk)
#   - tide-autoinstall-efi.iso (for fresh installs)
# ========================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
BASE_IMG="nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
RELEASE_DIR="release"
CLOUD_INIT_ISO="cloud-init.iso"

echo "=========================================="
echo "   Tide Gateway Release Builder"
echo "=========================================="

# Ensure release directory exists
mkdir -p "$RELEASE_DIR"

# ==========================================
# Step 1: Build cloud-init ISO
# ==========================================
echo ""
echo ">>> Step 1: Building cloud-init.iso..."

# Create temp directory for cloud-init files
CIDATA=$(mktemp -d)
trap "rm -rf $CIDATA" EXIT

# meta-data
cat > "$CIDATA/meta-data" <<EOF
instance-id: tide-gateway-001
local-hostname: tide-gateway
EOF

# user-data (full Tor gateway config)
cat > "$CIDATA/user-data" <<'EOF'
#cloud-config

# Tide Gateway - Alpine Tor Gateway Cloud-Init Config
# This configures a fresh Alpine cloud image as a Tor transparent proxy

hostname: tide-gateway

# Configure root user for simplicity
users:
  - name: root
    lock_passwd: false
    shell: /bin/ash

# Network configuration
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
  
  - path: /etc/sysctl.d/tor-gateway.conf
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.disable_ipv6 = 1
    permissions: '0644'
  
  - path: /etc/tor/torrc
    content: |
      # Tide Gateway - Tor Configuration
      User tor
      DataDirectory /var/lib/tor
      SocksPort 0.0.0.0:9050
      DNSPort 0.0.0.0:5353
      TransPort 0.0.0.0:9040
      VirtualAddrNetworkIPv4 10.192.0.0/10
      AutomapHostsOnResolve 1
      AutomapHostsSuffixes .onion
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

# Install packages
packages:
  - tor
  - iptables
  - ip6tables
  - openssh

# Run commands after packages are installed
runcmd:
  # Set root password to "tide"
  - echo "root:tide" | chpasswd
  
  # Enable root SSH login (for testing only)
  - sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - rc-update add sshd default
  - rc-service sshd start
  
  # Apply sysctl settings
  - sysctl -p /etc/sysctl.d/tor-gateway.conf
  
  # Bring up eth1 (LAN interface)
  - ifup eth1 || true
  
  # Apply iptables rules
  - iptables-restore < /etc/iptables/rules-save
  
  # Enable services to start on boot
  - rc-update add tor default
  - rc-update add iptables default
  
  # Start Tor
  - rc-service tor start
  
  # Save iptables rules
  - /etc/init.d/iptables save || true
  
  # Mark setup complete
  - echo "Tide Gateway configured successfully on $(date)" > /root/SETUP_COMPLETE
  - echo "Login: root / tide" >> /root/SETUP_COMPLETE
  - echo "Gateway IP: 10.101.101.10" >> /root/SETUP_COMPLETE

final_message: "Tide Gateway is ready! Login: root/tide | Gateway: 10.101.101.10"
EOF

# Build ISO
mkisofs -quiet -output "$CLOUD_INIT_ISO" -volid cidata -joliet -rock "$CIDATA"
echo "    Created: $CLOUD_INIT_ISO"

# ==========================================
# Step 2: Copy base image to release
# ==========================================
echo ""
echo ">>> Step 2: Preparing release qcow2..."

if [ ! -f "$BASE_IMG" ]; then
    echo "ERROR: Base image not found: $BASE_IMG"
    echo "Download Alpine cloud image first."
    exit 1
fi

# Copy base image to release
cp "$BASE_IMG" "$RELEASE_DIR/tide-gateway.qcow2"

# Resize to 512MB for some headroom
qemu-img resize "$RELEASE_DIR/tide-gateway.qcow2" 512M 2>/dev/null || true

echo "    Created: $RELEASE_DIR/tide-gateway.qcow2"

# ==========================================
# Step 3: Copy cloud-init ISO to release
# ==========================================
cp "$CLOUD_INIT_ISO" "$RELEASE_DIR/"
echo "    Copied:  $RELEASE_DIR/$CLOUD_INIT_ISO"

# ==========================================
# Step 4: Build autoinstall ISO (optional)
# ==========================================
echo ""
echo ">>> Step 3: Building autoinstall ISO..."

if [ -f "alpine-virt-3.19.6-aarch64.iso" ]; then
    ./build-autoinstall-iso.sh 2>/dev/null || echo "    (Autoinstall ISO build skipped - check dependencies)"
    if [ -f "tide-autoinstall-efi.iso" ]; then
        mv tide-autoinstall-efi.iso "$RELEASE_DIR/"
        echo "    Created: $RELEASE_DIR/tide-autoinstall-efi.iso"
    fi
else
    echo "    Skipping autoinstall ISO (base Alpine ISO not found)"
fi

# ==========================================
# Summary
# ==========================================
echo ""
echo "=========================================="
echo "   Build Complete!"
echo "=========================================="
echo ""
echo "Release artifacts in $RELEASE_DIR/:"
ls -lh "$RELEASE_DIR/"
echo ""
echo "For UTM/QEMU users:"
echo "  1. Import tide-gateway.qcow2 as boot disk"
echo "  2. Attach cloud-init.iso as CD/DVD"
echo "  3. Configure 2 network adapters (Shared + Host-Only)"
echo "  4. Boot and wait ~2 minutes for setup"
echo ""
echo "Login: root / tide"
echo "Gateway IP: 10.101.101.10"
echo ""
