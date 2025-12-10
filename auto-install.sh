#!/bin/bash
# Fully automated Tide Gateway installation in QEMU

set -e

echo "🌊 AUTOMATED Tide Gateway Installation"
echo "======================================"

# Start QEMU in background with serial console
echo "Starting VM..."
qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -smp 2 \
    -m 1024 \
    -nographic \
    -drive file=tide-gateway.qcow2,if=virtio,format=qcow2 \
    -cdrom alpine-virt-3.21.0-aarch64.iso \
    -boot d \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -serial mon:stdio

echo "VM started. Follow prompts to install Alpine..."
echo "After install completes, run the setup-tide.sh script"

