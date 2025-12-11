#!/bin/bash
# Fully automated Tide Gateway deployment in Parallels

set -e

VM_NAME="Tide-Gateway-Auto"
ISO_PATH="$(pwd)/alpine-standard-3.21.0-aarch64.iso"

echo "🌊 AUTOMATED TIDE GATEWAY DEPLOYMENT"
echo "====================================="
echo ""

# Delete old VMs
echo "Cleaning up old VMs..."
prlctl list -a | grep -q "$VM_NAME" && prlctl delete "$VM_NAME" 2>/dev/null || true

echo "Creating new VM: $VM_NAME"
prlctl create "$VM_NAME" \
    --ostype linux \
    --distribution linux \
    --no-hdd

echo "Configuring VM..."
prlctl set "$VM_NAME" --cpus 2
prlctl set "$VM_NAME" --memsize 2048
prlctl set "$VM_NAME" --device-add hdd --size 8192 --iface virtio

echo "Setting up network adapters..."
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host

echo "Attaching Alpine ISO..."
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ISO_PATH" --enable --connect

echo "✅ VM created: $VM_NAME"
echo ""
echo "Starting VM..."
prlctl start "$VM_NAME"

sleep 5

echo ""
echo "========================================="
echo "VM is running!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Open Parallels and connect to: $VM_NAME"
echo "2. Or use: open 'parallels://vm/$VM_NAME'"
echo "3. Login as root (no password)"
echo "4. Type: setup-alpine"
echo ""
echo "After setup-alpine completes and reboots,"
echo "come back here and we'll finish automatically."
echo ""

