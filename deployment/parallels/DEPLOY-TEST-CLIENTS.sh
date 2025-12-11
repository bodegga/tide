#!/bin/bash
# Deploy lightweight Alpine Linux test VMs for Tide Gateway testing
# Uses prlctl for full automation (no GUI needed)

set -e

# Configuration
ALPINE_ISO="alpine-virt-3.21.0-aarch64.iso"
BASE_NAME="Tide-Test-Client"
NUM_VMS=2
NETWORK="Host-Only"  # Connect to Tide Gateway's host-only network
DISK_SIZE=2048       # 2GB disk (minimal)
RAM=512              # 512MB RAM (minimal)
CPU=1                # 1 CPU core

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌊 Tide Test Client Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Alpine ISO exists
if [ ! -f "$ALPINE_ISO" ]; then
    echo -e "${YELLOW}Alpine ISO not found, downloading...${NC}"
    curl -L -o "$ALPINE_ISO" \
        "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-virt-3.21.0-aarch64.iso"
fi

echo -e "${CYAN}Configuration:${NC}"
echo "  VMs to create: $NUM_VMS"
echo "  Base name:     $BASE_NAME"
echo "  Network:       $NETWORK"
echo "  RAM:           ${RAM}MB"
echo "  Disk:          ${DISK_SIZE}MB"
echo "  CPU:           $CPU core(s)"
echo ""

# Get existing Tide Gateways
echo -e "${CYAN}Existing Tide Gateways:${NC}"
prlctl list -a | grep -i "tide.*gateway" || echo "  None found"
echo ""

# Create VMs
for i in $(seq 1 $NUM_VMS); do
    VM_NAME="${BASE_NAME}-${i}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}Creating: $VM_NAME${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if VM already exists
    if prlctl list -a | grep -q "$VM_NAME"; then
        echo -e "${YELLOW}VM already exists, removing old version...${NC}"
        prlctl stop "$VM_NAME" --kill 2>/dev/null || true
        prlctl delete "$VM_NAME" 2>/dev/null || true
        sleep 2
    fi
    
    # Create new VM
    echo "1. Creating VM..."
    prlctl create "$VM_NAME" \
        --distribution linux \
        --no-hdd
    
    # Configure VM
    echo "2. Configuring VM..."
    prlctl set "$VM_NAME" \
        --memsize "$RAM" \
        --cpus "$CPU" \
        --device-add hdd --size "$DISK_SIZE" \
        --device-set cdrom0 --image "$ALPINE_ISO" --connect
    
    # Network configuration - Host-Only for Tide Gateway access
    echo "3. Configuring network ($NETWORK)..."
    prlctl set "$VM_NAME" \
        --device-set net0 --type host
    
    # Boot options
    echo "4. Setting boot options..."
    prlctl set "$VM_NAME" \
        --startup-view headless \
        --on-shutdown close
    
    echo -e "${GREEN}✓ VM created: $VM_NAME${NC}"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ Test VMs created successfully!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}Created VMs:${NC}"
for i in $(seq 1 $NUM_VMS); do
    echo "  - ${BASE_NAME}-${i}"
done
echo ""

echo -e "${CYAN}Next Steps:${NC}"
echo ""
echo "1. Start a Tide Gateway VM:"
echo "   prlctl start Tide-Gateway"
echo ""
echo "2. Start test clients:"
echo "   prlctl start ${BASE_NAME}-1"
echo "   prlctl start ${BASE_NAME}-2"
echo ""
echo "3. Access client console:"
echo "   prlctl enter ${BASE_NAME}-1"
echo ""
echo "4. In client VM (after Alpine boots):"
echo "   - Login as root (no password)"
echo "   - Run: setup-alpine (quick setup)"
echo "   - Or for minimal testing:"
echo "     setup-interfaces    # Configure eth0 for DHCP"
echo "     rc-service networking start"
echo "     apk add curl lynx"
echo "     curl http://tide.bodegga.net  # Test dashboard"
echo ""
echo "5. Test web dashboard:"
echo "   lynx http://tide.bodegga.net"
echo ""

echo -e "${YELLOW}Quick Test Commands:${NC}"
echo ""
echo "# Auto-configure network (in client VM):"
echo "cat > /etc/network/interfaces << EOF"
echo "auto lo"
echo "iface lo inet loopback"
echo ""
echo "auto eth0"
echo "iface eth0 inet dhcp"
echo "EOF"
echo ""
echo "rc-service networking restart"
echo "apk add curl lynx"
echo "curl http://tide.bodegga.net/api/status | head -20"
echo ""

echo -e "${CYAN}Management Commands:${NC}"
echo ""
echo "List all VMs:"
echo "  prlctl list -a"
echo ""
echo "Start VM:"
echo "  prlctl start <vm-name>"
echo ""
echo "Stop VM:"
echo "  prlctl stop <vm-name>"
echo ""
echo "Enter console:"
echo "  prlctl enter <vm-name>"
echo ""
echo "Delete VM:"
echo "  prlctl delete <vm-name>"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
