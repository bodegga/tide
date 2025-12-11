#!/bin/bash
# Automated QEMU testing for Tide Gateway v1.2.0
# Builds fresh gateway with latest code and tests web dashboard

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TIDE_DIR=$(pwd)
TEST_DIR="$TIDE_DIR/test-build"
ALPINE_ISO="alpine-virt-3.21.0-aarch64.iso"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌊 Tide Gateway QEMU Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean previous test
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

echo -e "${CYAN}[1/5] Creating install script with v1.2.0 code...${NC}"

# Create comprehensive installer with ALL new v1.2.0 features
cat > "$TEST_DIR/tide-full-install.sh" << 'EOFINSTALL'
#!/bin/sh
# Tide Gateway v1.2.0 - Full Installation with Web Dashboard

set -e

echo "🌊 Installing Tide Gateway v1.2.0..."

# Fix DNS
cat > /etc/resolv.conf << 'EOFDNS'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOFDNS

# Update and install packages
echo "[1/8] Installing packages..."
apk update
apk add tor iptables dnsmasq nmap iputils arping python3 curl bash openrc

# Setup Tor
echo "[2/8] Configuring Tor..."
adduser -D -H -s /sbin/nologin tor 2>/dev/null || true
mkdir -p /var/lib/tor
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor

cat > /etc/tor/torrc << 'EOFTORRC'
User tor
SocksPort 0.0.0.0:9050
TransPort 0.0.0.0:9040
DNSPort 0.0.0.0:5353
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice stdout
DataDirectory /var/lib/tor
EOFTORRC

# Configure network
echo "[3/8] Configuring network..."
cat >> /etc/network/interfaces << 'EOFINT'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOFINT

# Create config directory
mkdir -p /etc/tide
echo "killa-whale" > /etc/tide/mode
echo "standard" > /etc/tide/security

# Install gateway startup script
echo "[4/8] Installing gateway startup..."
EOFINSTALL

# Inject the actual gateway-start.sh content
cat "$TIDE_DIR/scripts/runtime/gateway-start.sh" >> "$TEST_DIR/tide-full-install.sh"

# Continue installation script
cat >> "$TEST_DIR/tide-full-install.sh" << 'EOFINSTALL2'

# Save gateway-start.sh
cat > /usr/local/bin/gateway-start.sh << 'EOFGATEWAYSTART'
EOFINSTALL2

# Inject gateway-start.sh again (for the heredoc)
cat "$TIDE_DIR/scripts/runtime/gateway-start.sh" >> "$TEST_DIR/tide-full-install.sh"

cat >> "$TEST_DIR/tide-full-install.sh" << 'EOFINSTALL3'
EOFGATEWAYSTART
chmod +x /usr/local/bin/gateway-start.sh

# Install web dashboard
echo "[5/8] Installing web dashboard..."
EOFINSTALL3

# Inject web dashboard
echo 'cat > /usr/local/bin/tide-web-dashboard.py << ' >> "$TEST_DIR/tide-full-install.sh"
echo "'EOFDASHBOARD'" >> "$TEST_DIR/tide-full-install.sh"
cat "$TIDE_DIR/scripts/runtime/tide-web-dashboard.py" >> "$TEST_DIR/tide-full-install.sh"
echo "EOFDASHBOARD" >> "$TEST_DIR/tide-full-install.sh"

cat >> "$TEST_DIR/tide-full-install.sh" << 'EOFINSTALL4'
chmod +x /usr/local/bin/tide-web-dashboard.py

# Install CLI tool
echo "[6/8] Installing CLI tool..."
EOFINSTALL4

# Inject CLI tool
echo 'cat > /usr/local/bin/tide-cli.sh << ' >> "$TEST_DIR/tide-full-install.sh"
echo "'EOFCLI'" >> "$TEST_DIR/tide-full-install.sh"
cat "$TIDE_DIR/scripts/runtime/tide-cli.sh" >> "$TEST_DIR/tide-full-install.sh"
echo "EOFCLI" >> "$TEST_DIR/tide-full-install.sh"

cat >> "$TEST_DIR/tide-full-install.sh" << 'EOFINSTALL5'
chmod +x /usr/local/bin/tide-cli.sh
ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide

# Install config tool
echo "[7/8] Installing config tool..."
EOFINSTALL5

# Inject config tool
echo 'cat > /usr/local/bin/tide-config.sh << ' >> "$TEST_DIR/tide-full-install.sh"
echo "'EOFCONFIG'" >> "$TEST_DIR/tide-full-install.sh"
cat "$TIDE_DIR/scripts/runtime/tide-config.sh" >> "$TEST_DIR/tide-full-install.sh"
echo "EOFCONFIG" >> "$TEST_DIR/tide-full-install.sh"

cat >> "$TEST_DIR/tide-full-install.sh" << 'EOFINSTALL6'
chmod +x /usr/local/bin/tide-config.sh

# Start services
echo "[8/8] Starting services..."
ifup eth1 2>/dev/null || true
/usr/local/bin/gateway-start.sh &

echo "✅ Tide Gateway v1.2.0 installed!"
echo ""
echo "Access web dashboard at: http://tide.bodegga.net"
echo "Or: http://10.101.101.10"
echo ""
echo "CLI commands:"
echo "  tide status"
echo "  tide config"
echo ""
EOFINSTALL6

chmod +x "$TEST_DIR/tide-full-install.sh"

echo -e "${GREEN}✓ Install script created${NC}"
echo ""

echo -e "${CYAN}[2/5] Creating test disk image...${NC}"
qemu-img create -f qcow2 "$TEST_DIR/tide-gateway-test.qcow2" 4G
echo -e "${GREEN}✓ Disk created (4GB)${NC}"
echo ""

echo -e "${CYAN}[3/5] Starting QEMU VM for installation...${NC}"
echo -e "${YELLOW}This will boot Alpine, you'll need to:${NC}"
echo "1. Login as root (no password)"
echo "2. Run: setup-alpine"
echo "3. Choose options:"
echo "   - Keyboard: us"
echo "   - Hostname: tide-gateway"
echo "   - Interface: eth0 (dhcp)"
echo "   - Root password: tide"
echo "   - Timezone: America/Los_Angeles"
echo "   - Proxy: none"
echo "   - Mirror: 1 (default)"
echo "   - SSH: openssh"
echo "   - Disk: vda (sys)"
echo "4. Reboot"
echo "5. Login again and run the install script"
echo ""
echo -e "${CYAN}Starting VM...${NC}"

# Boot Alpine for installation
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a72 \
    -m 1024 \
    -nographic \
    -drive if=virtio,file="$TEST_DIR/tide-gateway-test.qcow2",format=qcow2 \
    -cdrom "$ALPINE_ISO" \
    -boot d \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net1 \
    -netdev user,id=net1,net=10.101.101.0/24,host=10.101.101.1,dhcpstart=10.101.101.100

echo ""
echo -e "${YELLOW}Note: This is a manual step. Automate with expect if needed.${NC}"
echo ""
echo -e "${CYAN}Next steps after Alpine is installed:${NC}"
echo "1. SSH into VM: ssh -p 2222 root@localhost"
echo "2. Copy install script: scp -P 2222 $TEST_DIR/tide-full-install.sh root@localhost:/root/"
echo "3. Run: sh /root/tide-full-install.sh"
echo "4. Test: curl http://localhost:8080 (forwarded from VM's port 80)"
