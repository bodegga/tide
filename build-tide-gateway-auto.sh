#!/bin/bash
# Fully automated Tide Gateway build using QEMU monitor
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_IMG="$SCRIPT_DIR/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
OUTPUT_IMG="$SCRIPT_DIR/release/tide-gateway.qcow2"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

echo "🌊 Building Tide Gateway Image (Automated)"
echo "==========================================="

mkdir -p "$(dirname "$OUTPUT_IMG")"
cp "$BASE_IMG" "$OUTPUT_IMG"
qemu-img resize "$OUTPUT_IMG" 512M 2>/dev/null

# Create setup script to inject
SETUP_SCRIPT=$(cat << 'SETUPEOF'
#!/bin/sh
set -e

# Wait for network
sleep 5

# Install packages
apk update
apk add tor iptables curl

# Configure Tor
cat > /etc/tor/torrc << 'EOF'
User tor
DataDirectory /var/lib/tor
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 0.0.0.0:9040
DNSPort 0.0.0.0:5353
SocksPort 0.0.0.0:9050
Log notice file /var/log/tor/notices.log
EOF

mkdir -p /var/log/tor
chown tor:tor /var/log/tor

# Network config
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1  
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOF

# Iptables
cat > /etc/local.d/tor-gateway.start << 'EOF'
#!/bin/sh
iptables -F
iptables -t nat -F
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i eth1 -j ACCEPT
iptables -t nat -A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040
iptables -t nat -A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -A FORWARD -i eth1 -j ACCEPT
EOF
chmod +x /etc/local.d/tor-gateway.start

rc-update add tor default
rc-update add local default

echo "tide-gateway" > /etc/hostname
echo "root:tide" | chpasswd
rm -rf /var/cache/apk/*

echo "TIDE_BUILD_COMPLETE"
SETUPEOF
)

# Create a small ISO with the setup script
SETUP_DIR=$(mktemp -d)
echo "$SETUP_SCRIPT" > "$SETUP_DIR/setup.sh"
chmod +x "$SETUP_DIR/setup.sh"

# Use hdiutil to create ISO on macOS
hdiutil makehybrid -o "$SCRIPT_DIR/setup-inject.iso" "$SETUP_DIR" -iso -joliet 2>/dev/null || {
    # Fallback: just run interactively
    echo "Cannot create inject ISO, running interactive mode..."
    rm -rf "$SETUP_DIR"
    exec "$SCRIPT_DIR/build-tide-gateway.sh"
}

rm -rf "$SETUP_DIR"

echo "Starting automated build..."
echo "(This will take ~2 minutes)"
echo ""

# Run QEMU with the setup script
# Use expect-style interaction via stdin/stdout
(
    # Wait for login prompt
    sleep 30
    echo "root"
    sleep 2
    
    # Mount the inject ISO and run setup
    echo "mkdir -p /mnt/setup"
    sleep 1
    echo "mount -t iso9660 /dev/sr0 /mnt/setup 2>/dev/null || mount -t iso9660 /dev/cdrom /mnt/setup"
    sleep 1
    echo "sh /mnt/setup/setup.sh"
    sleep 60
    echo "poweroff"
) | qemu-system-aarch64 \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file="$OUTPUT_IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -cdrom "$SCRIPT_DIR/setup-inject.iso" \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0 \
  2>&1 | tee /tmp/tide-build.log | grep -E "(TIDE_BUILD|apk|error|Error)" || true

rm -f "$SCRIPT_DIR/setup-inject.iso"

echo ""
echo "Verifying build..."
if grep -q "TIDE_BUILD_COMPLETE" /tmp/tide-build.log; then
    echo "✅ Build successful!"
    echo "Image: $OUTPUT_IMG"
    ls -lh "$OUTPUT_IMG"
else
    echo "⚠️  Build may have issues. Check /tmp/tide-build.log"
fi
