#!/bin/bash
# Build working Tide Gateway VM in QEMU, export for Parallels

set -e

echo "🌊 Building Tide Gateway VM (QEMU → Parallels)"
echo "=============================================="
echo ""

# Check if Alpine ISO exists
if [ ! -f alpine-virt-3.21.0-aarch64.iso ]; then
    echo "Alpine ISO not found. Download it? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        curl -L -O https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-virt-3.21.0-aarch64.iso
    else
        echo "Download Alpine from: https://alpinelinux.org/downloads/"
        exit 1
    fi
fi

# Create disk image
if [ ! -f tide-gateway-clean.qcow2 ]; then
    echo "Creating 4GB disk image..."
    qemu-img create -f qcow2 tide-gateway-clean.qcow2 4G
fi

echo ""
echo "MANUAL STEPS REQUIRED:"
echo "======================"
echo ""
echo "I'm going to start the VM. You need to:"
echo ""
echo "1. Login as 'root' (no password)"
echo "2. Type: setup-alpine"
echo "3. Follow prompts (see FRESH-INSTALL-GUIDE.md)"
echo "4. After install completes, type: reboot"
echo "5. After reboot, login and type:"
echo "     apk add curl git"
echo "     git clone https://github.com/bodegga/tide.git"
echo "     cd tide"
echo "     sh CLEAN-DEPLOY.sh"
echo ""
echo "Press ENTER to start VM..."
read

echo "Starting QEMU VM..."
echo "To exit QEMU: Press Ctrl-A then X"
echo ""

qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -smp 2 \
    -m 2048 \
    -nographic \
    -drive file=tide-gateway-clean.qcow2,if=virtio,format=qcow2 \
    -cdrom alpine-virt-3.21.0-aarch64.iso \
    -boot d \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net1 \
    -device virtio-net-pci,netdev=net1

echo ""
echo "VM exited."
echo ""
echo "If installation succeeded, convert to Parallels:"
echo "  qemu-img convert -f qcow2 -O parallels tide-gateway-clean.qcow2 tide-gateway.hdd"
echo ""

