#!/bin/bash
# Automated Tide Gateway Testing on VirtualBox
# Creates Alpine ARM64 VM, installs Tide v1.2.0, runs tests, destroys VM
# Cross-platform: macOS, Windows, Linux

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

TIDE_VERSION="1.2.0"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
VM_NAME="tide-test-$(date +%s)"
DISK_SIZE="2048"  # MB
MEMORY="1024"     # MB
ALPINE_ISO="$PROJECT_ROOT/alpine-virt-3.21.0-aarch64.iso"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌊 Tide Gateway - VirtualBox Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
echo -e "${CYAN}Checking prerequisites...${NC}"

if ! command -v VBoxManage &> /dev/null; then
    echo -e "${RED}Error: VBoxManage not found${NC}"
    echo ""
    echo "Install VirtualBox from:"
    echo "  https://www.virtualbox.org/wiki/Downloads"
    echo ""
    echo "Or via Homebrew:"
    echo "  brew install --cask virtualbox"
    echo ""
    exit 1
fi

if [ ! -f "$ALPINE_ISO" ]; then
    echo -e "${RED}Error: Alpine ISO not found at $ALPINE_ISO${NC}"
    echo "Expected: alpine-virt-3.21.0-aarch64.iso in project root"
    exit 1
fi

echo -e "${GREEN}✓ VirtualBox found: $(VBoxManage --version)${NC}"
echo -e "${GREEN}✓ Alpine ISO found${NC}"
echo ""

echo -e "${CYAN}Configuration:${NC}"
echo "  VM Name: $VM_NAME"
echo "  Memory: ${MEMORY}MB"
echo "  Disk: ${DISK_SIZE}MB"
echo "  ISO: alpine-virt-3.21.0-aarch64.iso"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Power off VM if running
    if VBoxManage list runningvms | grep -q "$VM_NAME"; then
        echo "  Powering off VM..."
        VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
        sleep 3
    fi
    
    # Unregister and delete VM
    if VBoxManage list vms | grep -q "$VM_NAME"; then
        echo "  Deleting VM..."
        VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Ask user if they want auto-cleanup
echo -e "${YELLOW}Auto-cleanup on exit?${NC}"
echo "  y) Yes - destroy VM after tests (default)"
echo "  n) No - keep VM for manual inspection"
echo ""
read -p "Choice [y/n]: " -n 1 -r CLEANUP_CHOICE
echo ""

if [[ ! $CLEANUP_CHOICE =~ ^[Nn]$ ]]; then
    trap cleanup EXIT
    echo -e "${CYAN}Auto-cleanup enabled${NC}"
else
    echo -e "${CYAN}Manual cleanup mode - VM will persist${NC}"
fi
echo ""

# Test 1: Create VM
echo -e "${CYAN}[1/8] Creating virtual machine...${NC}"

# Note: VirtualBox doesn't officially support ARM64 on all platforms
# This script creates a Linux 64-bit VM (x86_64) for broader compatibility
# For ARM testing, use QEMU instead

VBoxManage createvm --name "$VM_NAME" --ostype "Linux_64" --register

echo -e "${GREEN}✓ VM created${NC}"
echo ""

# Test 2: Configure VM
echo -e "${CYAN}[2/8] Configuring VM settings...${NC}"

VBoxManage modifyvm "$VM_NAME" \
    --memory "$MEMORY" \
    --cpus 2 \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --audio none \
    --usb off \
    --graphicscontroller vmsvga \
    --nic1 nat

# Port forwarding: SSH (2222->22), HTTP (8080->80), SOCKS (9050->9050), API (9051->9051)
VBoxManage modifyvm "$VM_NAME" \
    --natpf1 "ssh,tcp,,2222,,22" \
    --natpf1 "http,tcp,,8080,,80" \
    --natpf1 "socks,tcp,,9050,,9050" \
    --natpf1 "api,tcp,,9051,,9051"

echo -e "${GREEN}✓ VM configured${NC}"
echo ""

# Test 3: Create and attach disk
echo -e "${CYAN}[3/8] Creating virtual disk...${NC}"

DISK_PATH="$HOME/VirtualBox VMs/$VM_NAME/${VM_NAME}.vdi"
VBoxManage createhd --filename "$DISK_PATH" --size "$DISK_SIZE" --format VDI

VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

echo -e "${GREEN}✓ Disk created and attached${NC}"
echo ""

# Test 4: Attach ISO
echo -e "${CYAN}[4/8] Attaching Alpine ISO...${NC}"

VBoxManage storagectl "$VM_NAME" --name "IDE" --add ide
VBoxManage storageattach "$VM_NAME" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$ALPINE_ISO"

echo -e "${GREEN}✓ ISO attached${NC}"
echo ""

# Test 5: Start VM
echo -e "${CYAN}[5/8] Starting VM...${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}VIRTUALBOX MANUAL SETUP REQUIRED${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "VirtualBox will now start the VM in headless mode."
echo ""
echo "To complete setup:"
echo ""
echo "1. Open VirtualBox Manager GUI:"
echo "   - Find VM: $VM_NAME"
echo "   - Double-click to open console"
echo ""
echo "2. In VM console:"
echo "   - Login as root (no password)"
echo "   - Run: setup-alpine"
echo "   - Follow prompts (accept defaults)"
echo "   - Use disk: sda"
echo "   - Reboot when done"
echo ""
echo "3. After reboot, install Tide:"
echo ""
cat << 'EOFINSTALL'
   # SSH into VM (password: root password from setup)
   ssh -p 2222 root@localhost

   # Install dependencies
   apk add --no-cache curl git python3 py3-pip tor iptables dnsmasq nmap iputils

   # Create Tide config
   mkdir -p /etc/tide
   echo "router" > /etc/tide/mode
   echo "standard" > /etc/tide/security

   # Download and install Tide
   cd /tmp
   git clone https://github.com/bodegga/tide.git
   cd tide
   cp scripts/runtime/tide-cli.sh /usr/local/bin/
   cp scripts/runtime/tide-config.sh /usr/local/bin/
   cp scripts/runtime/tide-api.py /usr/local/bin/
   cp scripts/runtime/gateway-start.sh /usr/local/bin/
   
   chmod +x /usr/local/bin/tide-*.py /usr/local/bin/tide-*.sh /usr/local/bin/gateway-start.sh
   ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide

   # Enable Tor
   rc-update add tor default
   rc-service tor start
EOFINSTALL
echo ""
echo "4. Run tests:"
echo "   tide status"
echo "   tide mode router"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Starting VM in headless mode...${NC}"

VBoxManage startvm "$VM_NAME" --type headless

echo -e "${GREEN}✓ VM started${NC}"
echo ""

# Test 6: Wait for boot
echo -e "${CYAN}[6/8] Waiting for VM to boot (30 seconds)...${NC}"
sleep 30
echo -e "${GREEN}✓ Boot wait complete${NC}"
echo ""

# Test 7: Connection info
echo -e "${CYAN}[7/8] Connection Information${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VM ACCESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "VirtualBox Console:"
echo "  1. Open VirtualBox Manager"
echo "  2. Find VM: $VM_NAME"
echo "  3. Double-click to open console"
echo ""
echo "SSH Access (after setup):"
echo "  ssh -p 2222 root@localhost"
echo ""
echo "Port Forwards (host -> VM):"
echo "  2222 -> 22   (SSH)"
echo "  8080 -> 80   (Web Dashboard)"
echo "  9050 -> 9050 (SOCKS5)"
echo "  9051 -> 9051 (API)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 8: Test Suite Script
echo -e "${CYAN}[8/8] Creating test script...${NC}"

TEST_SCRIPT="/tmp/tide-vbox-tests-${VM_NAME}.sh"
cat > "$TEST_SCRIPT" << 'EOFTESTS'
#!/bin/sh
# Run this inside the VM after Tide installation

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TIDE GATEWAY TEST SUITE - VirtualBox"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: CLI
echo "✓ TEST 1: CLI Command"
tide status 2>/dev/null || echo "  ✗ tide command not found"
echo ""

# Test 2: Config Files
echo "✓ TEST 2: Configuration Files"
[ -f /etc/tide/mode ] && echo "  ✓ Mode: $(cat /etc/tide/mode)" || echo "  ✗ Mode file missing"
[ -f /etc/tide/security ] && echo "  ✓ Security: $(cat /etc/tide/security)" || echo "  ✗ Security file missing"
echo ""

# Test 3: Services
echo "✓ TEST 3: Services Running"
pgrep -x tor >/dev/null && echo "  ✓ Tor running" || echo "  ✗ Tor not running"
pgrep -f tide-api >/dev/null && echo "  ✓ API running" || echo "  ✗ API not running"
echo ""

# Test 4: Tor Connectivity
echo "✓ TEST 4: Tor Connectivity"
if nc -z 127.0.0.1 9050; then
    echo "  ✓ SOCKS port open"
    if curl -s --socks5 127.0.0.1:9050 --max-time 10 https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
        echo "  ✓ Tor is working"
    fi
fi
echo ""

# Test 5: Mode Switching
echo "✓ TEST 5: Mode Switching"
tide mode router && echo "  ✓ Switched to router" || echo "  ✗ Switch failed"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TESTS COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOFTESTS

chmod +x "$TEST_SCRIPT"
echo -e "${GREEN}✓ Test script created: $TEST_SCRIPT${NC}"
echo ""
echo "Copy to VM with:"
echo "  scp -P 2222 $TEST_SCRIPT root@localhost:/tmp/tests.sh"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VIRTUALBOX TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ VM created: $VM_NAME${NC}"
echo -e "${GREEN}✓ Alpine ISO attached${NC}"
echo -e "${GREEN}✓ VM running in headless mode${NC}"
echo -e "${YELLOW}⚠ Manual setup required (see instructions above)${NC}"
echo ""

if [[ ! $CLEANUP_CHOICE =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Auto-cleanup enabled - press Ctrl+C to keep VM${NC}"
    echo ""
    echo "Waiting for manual intervention..."
    echo "Press Enter when done testing to cleanup..."
    read -r
else
    echo -e "${CYAN}VM will persist for manual testing${NC}"
    echo ""
    echo "To cleanup later:"
    echo "  VBoxManage controlvm \"$VM_NAME\" poweroff"
    echo "  VBoxManage unregistervm \"$VM_NAME\" --delete"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
