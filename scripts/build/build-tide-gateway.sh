#!/bin/bash
# Build the Tide Gateway image with Tor pre-configured
# Output: tide-gateway.qcow2 (universal, works in any QEMU/KVM environment)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_IMG="$SCRIPT_DIR/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
OUTPUT_IMG="$SCRIPT_DIR/release/tide-gateway.qcow2"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

echo "🌊 Building Tide Gateway Image"
echo "==============================="

# Check base image exists
if [ ! -f "$BASE_IMG" ]; then
    echo "ERROR: Base image not found: $BASE_IMG"
    echo "Download from: https://github.com/alpinelinux/cloud-images/releases"
    exit 1
fi

# Create output directory
mkdir -p "$(dirname "$OUTPUT_IMG")"

# Copy base image
echo "Copying base image..."
cp "$BASE_IMG" "$OUTPUT_IMG"

# Resize to 512MB (plenty for gateway)
echo "Resizing image to 512MB..."
qemu-img resize "$OUTPUT_IMG" 512M

echo ""
echo "Starting VM for configuration..."
echo "============================================"
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "1. Login as: root / alpine (or just root with no password)"
echo "2. Run these commands:"
echo ""
cat << 'COMMANDS'
# ===== COPY/PASTE THIS ENTIRE BLOCK =====

# Install packages
apk update
apk add tor iptables ip6tables curl

# Configure Tor for transparent proxy
cat > /etc/tor/torrc << 'EOF'
# Tide Gateway Tor Configuration
User tor
DataDirectory /var/lib/tor

# Transparent proxy settings
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 0.0.0.0:9040
DNSPort 0.0.0.0:5353

# SOCKS proxy (optional, for testing)
SocksPort 0.0.0.0:9050

# Logging
Log notice file /var/log/tor/notices.log
EOF

# Create log directory
mkdir -p /var/log/tor
chown tor:tor /var/log/tor

# Configure network interfaces
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

# WAN - gets IP via DHCP
auto eth0
iface eth0 inet dhcp

# LAN - static IP for gateway
auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOF

# Create iptables rules for transparent Tor proxy
cat > /etc/local.d/tor-gateway.start << 'EOF'
#!/bin/sh
# Tide Gateway - Transparent Tor Routing

# Flush existing rules
iptables -F
iptables -t nat -F

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Allow SSH (optional, for management)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow traffic from LAN (eth1)
iptables -A INPUT -i eth1 -j ACCEPT

# NAT: Redirect TCP from LAN to Tor TransPort
iptables -t nat -A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040

# NAT: Redirect DNS from LAN to Tor DNSPort
iptables -t nat -A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353

# Allow forwarding
iptables -A FORWARD -i eth1 -j ACCEPT
iptables -A FORWARD -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "Tor gateway iptables rules loaded"
EOF

chmod +x /etc/local.d/tor-gateway.start

# Enable services at boot
rc-update add tor default
rc-update add local default

# Set hostname
echo "tide-gateway" > /etc/hostname
hostname tide-gateway

# Set root password
echo "root:tide" | chpasswd

# Clean up
rm -rf /var/cache/apk/*

echo ""
echo "✅ Configuration complete!"
echo "Run 'poweroff' to save the image"
# ===== END OF BLOCK =====
COMMANDS

echo ""
echo "3. After running commands, type: poweroff"
echo "4. The image will be saved to: $OUTPUT_IMG"
echo "============================================"
echo ""
read -p "Press Enter to start the VM..."

# Start QEMU for configuration
qemu-system-aarch64 \
  -name "tide-gateway-build" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file="$OUTPUT_IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0

echo ""
echo "🌊 Build complete!"
echo "Image saved to: $OUTPUT_IMG"
echo ""
echo "To test: ./test-tide-network.sh"
