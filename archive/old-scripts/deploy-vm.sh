#!/bin/bash
set -e

VM_NAME="Tide-Gateway-Auto"
ISO_PATH="$(pwd)/alpine-standard-3.21.0-aarch64.iso"

echo "🌊 Creating Tide Gateway VM"

prlctl create "$VM_NAME" --ostype linux --distribution linux
prlctl set "$VM_NAME" --cpus 2 --memsize 2048
prlctl set "$VM_NAME" --device-set hdd0 --size 8192
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ISO_PATH" --enable --connect

echo "✅ VM created. Starting..."
prlctl start "$VM_NAME"

echo ""
echo "VM started! Open Parallels and run setup-alpine"
echo "Then tell me when you're done."

