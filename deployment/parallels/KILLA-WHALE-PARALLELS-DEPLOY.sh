#!/bin/bash
# 🐋 Killa Whale - Parallels Automated Deployment
# Deploy Tide Gateway in Killa Whale mode using Parallels Desktop

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

VM_NAME="Tide-Killa-Whale"
ISO_PATH="$SCRIPT_DIR/alpine-virt-3.21.0-aarch64.iso"
VM_PATH="$HOME/Parallels/$VM_NAME.pvm"

echo "🐋 Killa Whale - Parallels Deployment"
echo "======================================"
echo ""

# Check Parallels
if ! command -v prlctl &> /dev/null; then
    echo "❌ Error: Parallels 'prlctl' not found"
    echo "   Install Parallels Desktop first"
    exit 1
fi

# Check ISO
if [ ! -f "$ISO_PATH" ]; then
    echo "❌ Error: Alpine ISO not found: $ISO_PATH"
    echo "   Downloading now..."
    curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-virt-3.21.0-aarch64.iso
fi

echo "✅ Parallels: $(prlctl --version)"
echo "✅ ISO: $ISO_PATH"
echo ""

# Cleanup existing VM
echo "🧹 Cleaning up any existing VM..."
prlctl stop "$VM_NAME" --kill 2>/dev/null || true
prlctl delete "$VM_NAME" 2>/dev/null || true
sleep 2

# Create VM
echo "📦 Creating VM: $VM_NAME"
prlctl create "$VM_NAME" \
    --distribution linux \
    --dst "$HOME/Parallels"

# Configure VM
echo "⚙️  Configuring VM..."
prlctl set "$VM_NAME" --memsize 512
prlctl set "$VM_NAME" --cpus 1
prlctl set "$VM_NAME" --videosize 16  # Minimal video RAM
prlctl set "$VM_NAME" --3d-accelerate off

# Network: 2 interfaces needed for Killa Whale
echo "🌐 Setting up network interfaces..."
prlctl set "$VM_NAME" --device-set net0 --type shared  # WAN (internet)
prlctl set "$VM_NAME" --device-add net --type host     # LAN (attack network)

# Attach ISO
echo "💿 Attaching Alpine ISO..."
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ISO_PATH" --connect

# Start VM
echo "🚀 Starting VM..."
prlctl start "$VM_NAME"

echo ""
echo "✅ VM Created and Started!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next Steps (Manual):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Parallels window should open automatically"
echo "   Login as: root (no password)"
echo ""
echo "2. Run Alpine installer:"
echo "   setup-alpine"
echo ""
echo "   Settings:"
echo "   - Keyboard: us"
echo "   - Hostname: tide"
echo "   - Network: eth0, dhcp (defaults)"
echo "   - Password: tide"
echo "   - Timezone: America/Los_Angeles"
echo "   - Disk: sda, sys"
echo ""
echo "3. After install completes:"
echo "   poweroff"
echo ""
echo "4. Remove ISO from VM settings, restart VM"
echo ""
echo "5. In the VM, install Tide:"
echo "   apk add git bash curl"
echo "   git clone https://github.com/bodegga/tide.git"
echo "   cd tide"
echo "   ./tide-install.sh"
echo "   (Select: 3 - Killa Whale mode)"
echo ""
echo "6. Start Killa Whale:"
echo "   rc-service tide start"
echo "   (or: systemctl start tide-gateway if using openrc)"
echo ""
echo "7. Check logs for the whale:"
echo "   tail -f /var/log/tide/gateway.log"
echo ""
echo "Expected output:"
echo "  🐋 Mode: KILLA WHALE - AGGRESSIVE NETWORK TAKEOVER"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎤 Named after Andre Nickatina - Bay Area legend"
echo "🐋 Maximum aggression, zero escapes"
echo ""
