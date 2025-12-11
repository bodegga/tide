#!/bin/bash
set -e

VM_NAME="Tide-Killa-Whale"
ISO_PATH="/Users/abiasi/Documents/Personal-Projects/tide/alpine-virt-3.21.0-aarch64.iso"

echo "🐋 Killa Whale - Parallels Deployment v2"
echo "========================================="

# Cleanup
prlctl stop "$VM_NAME" --kill 2>/dev/null || true
prlctl delete "$VM_NAME" 2>/dev/null || true
sleep 2

# Create VM with proper settings for Alpine ARM64
echo "📦 Creating VM..."
prlctl create "$VM_NAME" \
    --distribution other \
    --dst "$HOME/Parallels" \
    --no-hdd

# Configure
echo "⚙️  Configuring..."
prlctl set "$VM_NAME" --memsize 1024
prlctl set "$VM_NAME" --cpus 2
prlctl set "$VM_NAME" --videosize 32
prlctl set "$VM_NAME" --on-shutdown close

# Add disk
prlctl set "$VM_NAME" --device-add hdd --type expand --size 8192 --iface virtio

# Network
prlctl set "$VM_NAME" --device-set net0 --type shared --iface virtio
prlctl set "$VM_NAME" --device-add net --type host --iface virtio

# Boot from CD
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ISO_PATH" --connect

# EFI boot (required for ARM64)
prlctl set "$VM_NAME" --efi-boot on

echo "🚀 Starting VM..."
prlctl start "$VM_NAME"

echo ""
echo "✅ VM Created!"
echo ""
echo "Wait 30 seconds for boot, then:"
echo "  Login: root (no password)"
echo "  Run: setup-alpine"
echo ""
