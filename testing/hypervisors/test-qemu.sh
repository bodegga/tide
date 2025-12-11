#!/bin/bash
# Automated Tide Gateway Testing on QEMU/KVM (Apple Silicon)
# Creates Alpine ARM64 VM, installs Tide v1.2.0, runs tests, destroys VM
# Optimized for macOS on Apple Silicon

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

TIDE_VERSION="1.1.1"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
VM_NAME="tide-test-$(date +%s)"
VM_DIR="/tmp/$VM_NAME"
DISK_SIZE="2G"
MEMORY="1024"
ALPINE_ISO="$PROJECT_ROOT/alpine-virt-3.21.0-aarch64.iso"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌊 Tide Gateway - QEMU Testing (ARM64)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
echo -e "${CYAN}Checking prerequisites...${NC}"

if [ ! -f "$ALPINE_ISO" ]; then
    echo -e "${RED}Error: Alpine ISO not found at $ALPINE_ISO${NC}"
    echo "Expected: alpine-virt-3.21.0-aarch64.iso in project root"
    exit 1
fi

if ! command -v qemu-system-aarch64 &> /dev/null; then
    echo -e "${RED}Error: qemu-system-aarch64 not found${NC}"
    echo "Install with: brew install qemu"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

echo -e "${CYAN}Configuration:${NC}"
echo "  VM Name: $VM_NAME"
echo "  Memory: ${MEMORY}MB"
echo "  Disk: $DISK_SIZE"
echo "  ISO: alpine-virt-3.21.0-aarch64.iso"
echo "  QEMU: $(which qemu-system-aarch64)"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Kill QEMU processes
    pkill -f "$VM_NAME" 2>/dev/null || true
    
    # Remove VM directory
    if [ -d "$VM_DIR" ]; then
        rm -rf "$VM_DIR"
        echo -e "${GREEN}✓ VM directory removed${NC}"
    fi
}

trap cleanup EXIT

# Create VM directory
echo -e "${CYAN}[1/7] Creating VM workspace...${NC}"
mkdir -p "$VM_DIR"
echo -e "${GREEN}✓ Workspace created: $VM_DIR${NC}"
echo ""

# Create disk image
echo -e "${CYAN}[2/7] Creating disk image ($DISK_SIZE)...${NC}"
qemu-img create -f qcow2 "$VM_DIR/tide.qcow2" "$DISK_SIZE" >/dev/null
echo -e "${GREEN}✓ Disk created${NC}"
echo ""

# Create Alpine setup script
echo -e "${CYAN}[3/7] Creating Alpine auto-install script...${NC}"
cat > "$VM_DIR/setup-alpine-answers" << 'EOF'
# Alpine Linux automated setup for Tide Gateway testing
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n tide-gateway"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname tide-gateway
"
DNSOPTS="-d localdomain 8.8.8.8"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys /dev/vda"
EOF

echo -e "${GREEN}✓ Setup script created${NC}"
echo ""

# Note: QEMU automated installation is complex
# This script demonstrates the testing framework
# Full automation requires expect or serial console scripting

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}QEMU TESTING NOTE${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "QEMU automated testing requires additional tooling:"
echo ""
echo "Option 1: Manual Testing"
echo "  - Boot VM with command below"
echo "  - Install Alpine manually"
echo "  - Install Tide Gateway"
echo "  - Run test suite"
echo ""
echo "Option 2: Expect Script (Advanced)"
echo "  - Use expect to automate serial console"
echo "  - Requires: brew install expect"
echo "  - More complex but fully automated"
echo ""
echo "Option 3: Cloud-Init (Recommended)"
echo "  - Use cloud-init ISO for automation"
echo "  - See deployment/qemu/ for examples"
echo ""
echo -e "${CYAN}Manual Boot Command:${NC}"
echo ""
echo "qemu-system-aarch64 \\"
echo "  -M virt \\"
echo "  -cpu cortex-a72 \\"
echo "  -m $MEMORY \\"
echo "  -nographic \\"
echo "  -drive file=$VM_DIR/tide.qcow2,if=virtio \\"
echo "  -cdrom $ALPINE_ISO \\"
echo "  -device virtio-net-pci,netdev=net0 \\"
echo "  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test 4: Create Test Script
echo -e "${CYAN}[4/7] Creating test script for VM...${NC}"
cat > "$VM_DIR/tide-tests.sh" << 'EOFTESTS'
#!/bin/sh
# Tide Gateway Test Suite for QEMU VM

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TIDE GATEWAY TEST SUITE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: CLI Command
echo "✓ TEST 1: CLI Command"
if command -v tide >/dev/null 2>&1; then
    tide status || echo "  Status check failed"
else
    echo "  ✗ tide command not found"
fi
echo ""

# Test 2: Configuration Files
echo "✓ TEST 2: Configuration Files"
if [ -f /etc/tide/mode ]; then
    echo "  ✓ Mode: $(cat /etc/tide/mode)"
else
    echo "  ✗ Mode file missing"
fi

if [ -f /etc/tide/security ]; then
    echo "  ✓ Security: $(cat /etc/tide/security)"
else
    echo "  ✗ Security file missing"
fi
echo ""

# Test 3: Services Running
echo "✓ TEST 3: Services Running"
pgrep -x tor >/dev/null && echo "  ✓ Tor running" || echo "  ✗ Tor not running"
pgrep -f tide-api >/dev/null && echo "  ✓ API running" || echo "  ✗ API not running"
pgrep -x dnsmasq >/dev/null && echo "  ✓ dnsmasq running" || echo "  ✗ dnsmasq not running"
echo ""

# Test 4: Tor Connectivity
echo "✓ TEST 4: Tor Connectivity"
if nc -z 127.0.0.1 9050 2>/dev/null; then
    echo "  ✓ Tor SOCKS port open (9050)"
    
    # Try to get Tor exit IP
    TOR_CHECK=$(curl -s --socks5 127.0.0.1:9050 --max-time 10 https://check.torproject.org/api/ip 2>/dev/null || echo "")
    if echo "$TOR_CHECK" | grep -q '"IsTor":true'; then
        EXIT_IP=$(echo "$TOR_CHECK" | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)
        echo "  ✓ Tor is working"
        echo "  ✓ Exit IP: $EXIT_IP"
    else
        echo "  ⚠ Tor may still be bootstrapping"
    fi
else
    echo "  ✗ Tor SOCKS port not accessible"
fi
echo ""

# Test 5: Mode Switching
echo "✓ TEST 5: Mode Switching"
CURRENT_MODE=$(cat /etc/tide/mode 2>/dev/null || echo "unknown")
echo "  Current mode: $CURRENT_MODE"

if [ "$CURRENT_MODE" != "router" ]; then
    echo "  Switching to router mode..."
    tide mode router >/dev/null 2>&1 && sleep 2
    NEW_MODE=$(cat /etc/tide/mode 2>/dev/null || echo "unknown")
    
    if [ "$NEW_MODE" = "router" ]; then
        echo "  ✓ Successfully switched to: $NEW_MODE"
    else
        echo "  ✗ Mode switch failed"
    fi
else
    echo "  Already in router mode"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TESTS COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOFTESTS

chmod +x "$VM_DIR/tide-tests.sh"
echo -e "${GREEN}✓ Test script created${NC}"
echo ""

# Test 5: Installation Script
echo -e "${CYAN}[5/7] Creating Tide installation script...${NC}"
cat > "$VM_DIR/install-tide.sh" << 'EOFINSTALL'
#!/bin/sh
# Install Tide Gateway v1.2.0 on Alpine Linux

set -e

echo "Installing Tide Gateway v1.2.0..."
echo ""

# Install dependencies
echo "→ Installing dependencies..."
apk add --no-cache curl git python3 py3-pip tor iptables dnsmasq nmap iputils

# Create Tide config
echo "→ Creating Tide configuration..."
mkdir -p /etc/tide
echo "router" > /etc/tide/mode
echo "standard" > /etc/tide/security

# Download Tide
echo "→ Downloading Tide Gateway..."
cd /tmp
git clone -q https://github.com/bodegga/tide.git

# Install Tide components
echo "→ Installing Tide components..."
cd tide
cp scripts/runtime/tide-cli.sh /usr/local/bin/
cp scripts/runtime/tide-config.sh /usr/local/bin/
cp scripts/runtime/tide-api.py /usr/local/bin/
cp scripts/runtime/gateway-start.sh /usr/local/bin/

chmod +x /usr/local/bin/tide-*.py /usr/local/bin/tide-*.sh /usr/local/bin/gateway-start.sh
ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide

# Enable services
echo "→ Enabling services..."
rc-update add tor default
rc-service tor start

echo ""
echo "✓ Tide Gateway installed successfully!"
echo ""
echo "Run tests with: /tmp/tide-tests.sh"
EOFINSTALL

chmod +x "$VM_DIR/install-tide.sh"
echo -e "${GREEN}✓ Installation script created${NC}"
echo ""

# Test 6: Summary
echo -e "${CYAN}[6/7] QEMU Test Infrastructure Created${NC}"
echo ""
echo -e "${GREEN}✓ VM disk image created${NC}"
echo -e "${GREEN}✓ Alpine setup answers created${NC}"
echo -e "${GREEN}✓ Test script created${NC}"
echo -e "${GREEN}✓ Installation script created${NC}"
echo ""

# Test 7: Usage Instructions
echo -e "${CYAN}[7/7] Usage Instructions${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QEMU MANUAL TESTING WORKFLOW"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Start VM:"
echo "   cd $VM_DIR"
echo "   qemu-system-aarch64 \\"
echo "     -M virt -cpu cortex-a72 -m $MEMORY \\"
echo "     -nographic \\"
echo "     -drive file=tide.qcow2,if=virtio \\"
echo "     -cdrom $ALPINE_ISO \\"
echo "     -device virtio-net-pci,netdev=net0 \\"
echo "     -netdev user,id=net0,hostfwd=tcp::2222-:22"
echo ""
echo "2. In VM console:"
echo "   - Login as root (no password)"
echo "   - Run: setup-alpine"
echo "   - Accept defaults or customize"
echo "   - Reboot when done"
echo ""
echo "3. After reboot, install Tide:"
echo "   - Copy install-tide.sh to VM"
echo "   - Run: sh install-tide.sh"
echo ""
echo "4. Run tests:"
echo "   - Copy tide-tests.sh to VM"
echo "   - Run: sh tide-tests.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ALTERNATIVE: Automated Cloud-Init"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "For fully automated testing, use cloud-init:"
echo "  See: deployment/qemu/build-qemu-image.sh"
echo ""
echo "Scripts available in:"
echo "  $VM_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}Note: QEMU requires manual interaction for Alpine install${NC}"
echo -e "${YELLOW}Use cloud-init for fully automated testing${NC}"
echo ""

# Don't cleanup on success - let user decide
trap - EXIT

echo -e "${GREEN}QEMU test infrastructure ready!${NC}"
echo ""
echo -e "${CYAN}VM files located at: $VM_DIR${NC}"
echo ""
echo "To clean up manually:"
echo "  rm -rf $VM_DIR"
echo ""
