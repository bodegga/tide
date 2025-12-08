#!/bin/bash
set -euo pipefail

# Tide Gateway - Parallels Desktop Builder
# Creates VM and boots Alpine ISO, then you run one command to install.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

VM_NAME="Tide-Gateway"

# Find Alpine ISO (prefer 3.21 standard, fall back to 3.19 virt)
ALPINE_ISO=""
for iso in alpine-standard-3.21*.iso alpine-virt-3.19*.iso; do
    [ -f "$iso" ] && ALPINE_ISO="$SCRIPT_DIR/$iso" && break
done

echo "=========================================="
echo "   Tide Gateway - Parallels Builder"
echo "=========================================="

if [ -z "$ALPINE_ISO" ]; then
    echo ">>> Downloading Alpine Linux ISO..."
    curl -LO "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-standard-3.21.2-aarch64.iso"
    ALPINE_ISO="$SCRIPT_DIR/alpine-standard-3.21.2-aarch64.iso"
fi

echo ">>> Using ISO: $(basename "$ALPINE_ISO")"

# Clean up existing VM
if prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
    echo ">>> Removing existing $VM_NAME..."
    prlctl stop "$VM_NAME" --kill 2>/dev/null || true
    prlctl delete "$VM_NAME" 2>/dev/null || true
    sleep 2
fi

# Create fresh disk
echo ">>> Creating VM disk..."
rm -rf "$SCRIPT_DIR/tide-gateway.hdd"
prl_disk_tool create --hdd "$SCRIPT_DIR/tide-gateway.hdd" --size 2G --expanding

# Create VM
echo ">>> Creating VM..."
prlctl create "$VM_NAME" --ostype linux --distribution linux-2.6 --no-hdd
prlctl set "$VM_NAME" --memsize 512 --cpus 1
prlctl set "$VM_NAME" --device-add hdd --image "$SCRIPT_DIR/tide-gateway.hdd"
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ALPINE_ISO" --connect
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host-only
prlctl set "$VM_NAME" --device-bootorder "cdrom0 hdd0"

echo ">>> Starting VM..."
prlctl start "$VM_NAME"

echo ""
echo "=========================================="
echo "   VM STARTED - COMPLETE INSTALL IN CONSOLE"
echo "=========================================="
echo ""
echo "In the Parallels window:"
echo ""
echo "  1. Login as: root (no password)"
echo ""
echo "  2. Run this ONE command:"
echo ""
echo "     wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh"
echo ""
echo "  3. Follow prompts (press Enter to confirm disk wipe)"
echo ""
echo "  4. When done, eject ISO and reboot"
echo ""
echo "=========================================="
echo ""
echo "After reboot:"
echo "  Login:   root / tide"
echo "  Gateway: 10.101.101.10"
echo ""
