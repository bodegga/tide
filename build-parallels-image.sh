#!/bin/bash
set -euo pipefail

# ============================================================
# Tide Gateway - Parallels Image Builder (Fast Method)
# ============================================================
# Creates a Parallels-ready disk that auto-configures on first boot.
# No manual steps needed - just import, add Host-Only NIC, boot.
#
# How it works:
# 1. Downloads Alpine standard ISO
# 2. Creates a Parallels VM
# 3. Runs setup-alpine automatically
# 4. Injects first-boot script that configures Tide on first real boot
# 5. Exports the disk for distribution
#
# Usage: ./build-parallels-image.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

VM_NAME="Tide-Build"
ALPINE_VERSION="3.21"
ALPINE_MINOR="2"
ARCH=$(uname -m)
[ "$ARCH" = "arm64" ] && ARCH="aarch64"

ALPINE_ISO="alpine-standard-${ALPINE_VERSION}.${ALPINE_MINOR}-${ARCH}.iso"
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ARCH}/${ALPINE_ISO}"

echo ""
echo "=========================================="
echo "   🌊 Tide - Parallels Image Builder"
echo "=========================================="
echo ""

# Check Parallels
if ! command -v prlctl &>/dev/null; then
    echo "ERROR: Parallels CLI not found"
    exit 1
fi

# Download ISO if needed
if [ ! -f "$ALPINE_ISO" ]; then
    echo ">>> Downloading Alpine ISO..."
    curl -# -L -o "$ALPINE_ISO" "$ALPINE_URL"
fi

# Clean up any existing build VM
if prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
    echo ">>> Cleaning up old build VM..."
    prlctl stop "$VM_NAME" --kill 2>/dev/null || true
    prlctl delete "$VM_NAME" 2>/dev/null || true
    sleep 2
fi

echo ""
echo ">>> Creating build VM..."
echo "    This will open Parallels. Complete these steps:"
echo ""
echo "    1. In the console, login as 'root' (no password)"
echo "    2. Run: setup-alpine"
echo "    3. Answer the prompts (defaults are fine, use 'tide' as password)"
echo "    4. When asked about disk, choose 'sda' and 'sys'"
echo "    5. After install completes, DON'T reboot yet!"
echo "    6. Run this command to inject Tide config:"
echo ""
echo "       wget -qO /mnt/etc/local.d/tide-firstboot.start https://raw.githubusercontent.com/bodegga/tide/main/tide-firstboot.sh && chmod +x /mnt/etc/local.d/tide-firstboot.start"
echo ""
echo "    7. Then: reboot"
echo ""
echo "    After reboot, Tide will auto-configure on first boot (~1 min)."
echo ""
read -p "Press Enter to create the VM..."

# Create VM
rm -rf "$SCRIPT_DIR/tide-build.hdd" 2>/dev/null || true
prlctl create "$VM_NAME" --ostype linux --distribution linux-2.6 --no-hdd
prl_disk_tool create --hdd "$SCRIPT_DIR/tide-build.hdd" --size 2G --expanding
prlctl set "$VM_NAME" --memsize 512 --cpus 1
prlctl set "$VM_NAME" --device-add hdd --image "$SCRIPT_DIR/tide-build.hdd"
prlctl set "$VM_NAME" --device-set cdrom0 --image "$SCRIPT_DIR/$ALPINE_ISO" --connect
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host-only
prlctl set "$VM_NAME" --device-bootorder "cdrom0 hdd0"
prlctl start "$VM_NAME"

echo ""
echo ">>> VM started. Follow the steps above in the Parallels window."
echo ""
echo ">>> When done and the VM is configured, run:"
echo "    prlctl stop $VM_NAME"
echo "    cp tide-build.hdd release/tide-gateway-parallels.hdd"
echo ""
