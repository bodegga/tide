#!/bin/bash
# Run Tide Gateway with QEMU
# Usage: ./run-tide-qemu.sh [fresh|test]
#   fresh = use base image (cloud-init will configure)
#   test  = use existing test image

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-fresh}"
BASE_IMG="nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
TEST_IMG="test-gateway.qcow2"
CLOUD_INIT="cloud-init.iso"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

echo "🌊 Tide Gateway - QEMU Test Runner"
echo "==================================="

if [ "$MODE" = "fresh" ]; then
    echo "Mode: Fresh build (cloud-init will configure)"
    echo "Creating test copy of base image..."
    cp "$BASE_IMG" "$TEST_IMG"
    IMG="$TEST_IMG"
elif [ "$MODE" = "test" ]; then
    echo "Mode: Testing existing image"
    if [ ! -f "$TEST_IMG" ]; then
        echo "ERROR: $TEST_IMG not found. Run with 'fresh' first."
        exit 1
    fi
    IMG="$TEST_IMG"
else
    echo "Usage: $0 [fresh|test]"
    exit 1
fi

echo ""
echo "Image: $IMG"
echo "Cloud-Init: $CLOUD_INIT"
echo ""
echo "Login: root / tide"
echo "Gateway LAN IP: 10.101.101.10 (eth1)"
echo ""
echo "To test from client VM:"
echo "  curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip"
echo ""
echo "Press Ctrl-A X to exit QEMU"
echo "==================================="
echo ""

qemu-system-aarch64 \
  -name "Tide-Gateway" \
  -M virt \
  -cpu cortex-a72 \
  -m 512 \
  -nographic \
  -drive if=none,file="$IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -cdrom "$CLOUD_INIT" \
  -netdev user,id=wan,hostfwd=tcp::2222-:22 \
  -device virtio-net-device,netdev=wan,mac=52:54:00:12:34:01 \
  -netdev socket,id=lan,listen=:8010 \
  -device virtio-net-device,netdev=lan,mac=52:54:00:12:34:02
