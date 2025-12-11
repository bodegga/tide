#!/bin/bash
# Run Killa Whale with QEMU - simpler than Parallels

cd "$(dirname "$0")"

echo "🐋 Creating Killa Whale VM with QEMU..."

# Create disk
qemu-img create -f qcow2 killa-whale.qcow2 4G

# Boot from ISO
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -m 1024 \
  -nographic \
  -drive if=virtio,file=killa-whale.qcow2,format=qcow2 \
  -cdrom alpine-standard-3.21.0-aarch64.iso \
  -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -netdev user,id=net0,dns=8.8.8.8 \
  -device virtio-net-pci,netdev=net0

echo "
To escape QEMU: Ctrl-A then X
"
