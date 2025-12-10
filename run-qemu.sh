#!/bin/bash
# Run Tide Gateway in QEMU

IMAGE="tide-gateway.qcow2"
ISO="alpine-virt-3.21.0-aarch64.iso"

if [ ! -f "$IMAGE" ]; then
    echo "❌ Image not found. Run ./build-qemu-image.sh first"
    exit 1
fi

echo "🌊 Starting Tide Gateway (QEMU)"
echo "================================"
echo ""
echo "Networks:"
echo "  - eth0: User network (internet via host)"
echo "  - eth1: Host-only 10.101.101.0/24 (attack network)"
echo ""
echo "SSH: ssh root@localhost -p 2222"
echo "Gateway IP: 10.101.101.10"
echo ""

qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -smp 2 \
    -m 1024 \
    -nographic \
    -drive file="$IMAGE",if=virtio,format=qcow2 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -netdev socket,id=net1,listen=:8010 \
    -device virtio-net-pci,netdev=net1 \
    ${ISO:+-cdrom "$ISO"}

