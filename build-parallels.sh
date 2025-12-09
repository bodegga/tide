#!/bin/bash
set -euo pipefail

# ============================================================
# Tide Gateway - Parallels Desktop Builder
# ============================================================
# Creates a VM with proper configuration, boots Alpine ISO,
# then you run one command to install Tide Gateway.
#
# Usage: ./build-parallels.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

VM_NAME="Tide-Gateway"
ALPINE_VERSION="3.21"
ALPINE_MINOR="2"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ALPINE_ARCH="aarch64"
else
    ALPINE_ARCH="x86_64"
fi

ALPINE_ISO="alpine-standard-${ALPINE_VERSION}.${ALPINE_MINOR}-${ALPINE_ARCH}.iso"
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${ALPINE_ISO}"

echo ""
echo "=========================================="
echo "   🌊 Tide Gateway - Parallels Builder"
echo "=========================================="
echo ""
echo "Architecture: $ALPINE_ARCH"
echo ""

# Check for Parallels CLI
if ! command -v prlctl &>/dev/null; then
    echo "ERROR: Parallels Desktop CLI (prlctl) not found!"
    echo "       Install Parallels Desktop first."
    exit 1
fi

# Download Alpine ISO if needed
if [ ! -f "$ALPINE_ISO" ]; then
    echo ">>> Downloading Alpine Linux ${ALPINE_VERSION}.${ALPINE_MINOR} (${ALPINE_ARCH})..."
    curl -# -L -o "$ALPINE_ISO" "$ALPINE_URL"
    echo ""
fi

if [ ! -f "$ALPINE_ISO" ]; then
    echo "ERROR: Failed to download Alpine ISO!"
    exit 1
fi

echo ">>> Using ISO: $ALPINE_ISO"

# Clean up existing VM
if prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
    echo ">>> Removing existing $VM_NAME VM..."
    prlctl stop "$VM_NAME" --kill 2>/dev/null || true
    sleep 1
    prlctl delete "$VM_NAME" 2>/dev/null || true
    sleep 2
fi

# Clean up old disk files
rm -rf "$SCRIPT_DIR/tide-gateway.hdd" 2>/dev/null || true

# Create VM
echo ">>> Creating VM..."
prlctl create "$VM_NAME" --ostype linux --distribution linux-2.6 --no-hdd

# Configure VM resources
echo ">>> Configuring VM resources..."
prlctl set "$VM_NAME" --memsize 512 --cpus 1

# Create and attach disk (2GB expanding)
echo ">>> Creating 2GB disk..."
prl_disk_tool create --hdd "$SCRIPT_DIR/tide-gateway.hdd" --size 2G --expanding
prlctl set "$VM_NAME" --device-add hdd --image "$SCRIPT_DIR/tide-gateway.hdd"

# Attach Alpine ISO
echo ">>> Attaching Alpine ISO..."
prlctl set "$VM_NAME" --device-set cdrom0 --image "$SCRIPT_DIR/$ALPINE_ISO" --connect

# Configure networking:
#   net0 = Shared (NAT) - for internet access (WAN)
#   net1 = Host-Only - for client VMs (LAN)
echo ">>> Configuring network adapters..."
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host-only

# Set boot order: CD first for initial install
prlctl set "$VM_NAME" --device-bootorder "cdrom0 hdd0"

# Start the VM
echo ">>> Starting VM..."
prlctl start "$VM_NAME"

# Print instructions
echo ""
echo "=========================================="
echo "   ✅ VM STARTED - COMPLETE SETUP BELOW"
echo "=========================================="
echo ""
echo "In the Parallels console window:"
echo ""
echo "  Step 1: Login as 'root' (no password)"
echo ""
echo "  Step 2: Run this ONE command:"
echo ""
echo "     wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh"
echo ""
echo "  Step 3: Type 'yes' when prompted to confirm disk wipe"
echo ""
echo "  Step 4: Wait for installation (~2-3 minutes)"
echo ""
echo "  Step 5: When complete, eject ISO:"
echo "          - Click Devices menu → CD/DVD → Disconnect"
echo "          - Type 'reboot' in console"
echo ""
echo "=========================================="
echo ""
echo "After reboot:"
echo "  • Login:    root / tide"
echo "  • Gateway:  10.101.101.10"
echo ""
echo "To connect a client VM:"
echo "  • Add it to the same Host-Only network"
echo "  • Set client's gateway & DNS to 10.101.101.10"
echo "  • Visit https://check.torproject.org to verify"
echo ""
echo "=========================================="
echo ""
