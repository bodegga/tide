#!/bin/bash
set -e

# Tide Gateway - Build Universal Disk Image (Pre-Installed)
# ---------------------------------------------------------
# Instead of an ISO that installs, we build a DISK that is already installed.
# This works everywhere (UTM, Parallels, QEMU) without interactive scripts failing.

DISK_IMG="tide-gateway.img"
DISK_SIZE="2G"
MOUNT_DIR="/tmp/tide-build"

# 1. Create a blank disk image
echo ">>> Creating disk image ($DISK_SIZE)..."
qemu-img create -f qcow2 tide-builder.qcow2 $DISK_SIZE

# We use the brute-force ISO we just made to install to this disk image.
# Once it shuts down, tide-builder.qcow2 IS our Golden Master.
qemu-system-aarch64 \
  -M virt -cpu cortex-a72 -m 1024 -nographic \
  -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -drive if=virtio,file=tide-builder.qcow2,format=qcow2 \
  -device virtio-scsi-pci,id=scsi0 \
  -drive id=cdrom,if=none,format=raw,media=cdrom,file="release/tide-autoinstall-efi.iso" \
  -device scsi-cd,bus=scsi0.0,drive=cdrom \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
  -boot order=d

echo ">>> Build complete. Converting to distribution formats..."
mv tide-builder.qcow2 release/tide-gateway.qcow2
# Convert to raw for Parallels
qemu-img convert -O raw release/tide-gateway.qcow2 release/tide-gateway.raw

echo ">>> Artifacts ready in release/:"
ls -lh release/
