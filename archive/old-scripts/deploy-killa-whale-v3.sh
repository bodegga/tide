#!/bin/bash
set -e

VM_NAME="Tide-Killa-Whale"
ISO_PATH="/path/to/tide/alpine-virt-3.21.0-aarch64.iso"

echo "🐋 Killa Whale - Parallels Deployment v3"

prlctl stop "$VM_NAME" --kill 2>/dev/null || true
prlctl delete "$VM_NAME" 2>/dev/null || true
sleep 2

echo "📦 Creating VM..."
prlctl create "$VM_NAME" --distribution other --dst "$HOME/Parallels"

echo "⚙️  Configuring..."
prlctl set "$VM_NAME" --memsize 1024 --cpus 2
prlctl set "$VM_NAME" --efi-boot on
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ISO_PATH" --connect

echo "🚀 Starting..."
prlctl start "$VM_NAME"

echo "✅ Done! Wait 30s then login as root"
