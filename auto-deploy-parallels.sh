#!/bin/bash
# Fully automated Tide Gateway deployment in Parallels

set -e

VM_NAME="Tide-Gateway-Auto"
ISO_PATH="$(pwd)/alpine-standard-3.21.0-aarch64.iso"

echo "🌊 AUTOMATED TIDE GATEWAY DEPLOYMENT"
echo "====================================="
echo ""

# Delete old VM if exists
echo "Cleaning up old VMs..."
prlctl list -a | grep -q "$VM_NAME" && prlctl delete "$VM_NAME" --force 2>/dev/null || true
prlctl list -a | grep -q "Tide-Gateway" && prlctl stop Tide-Gateway --kill 2>/dev/null || true

echo "Creating new VM: $VM_NAME"
prlctl create "$VM_NAME" \
    --ostype linux \
    --distribution other-linux \
    --no-hdd

echo "Configuring VM..."
prlctl set "$VM_NAME" --cpus 2
prlctl set "$VM_NAME" --memsize 2048
prlctl set "$VM_NAME" --device-add hdd --size 8192 --iface virtio

echo "Setting up network adapters..."
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host --iface vnic1

echo "Attaching Alpine ISO..."
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ISO_PATH" --enable

echo "✅ VM created!"
echo ""
echo "Starting VM..."
prlctl start "$VM_NAME"

echo ""
echo "VM is booting. You need to:"
echo "1. Open Parallels and connect to: $VM_NAME"
echo "2. Login as root"
echo "3. Run: setup-alpine"
echo "4. After reboot, we'll install Tide automatically"
echo ""
echo "VM UUID: $(prlctl list -a | grep $VM_NAME | awk '{print $1}')"
echo ""

