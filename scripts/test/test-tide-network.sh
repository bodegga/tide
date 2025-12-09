#!/bin/bash
# Test Tide Gateway with two QEMU VMs sharing a virtual network
# This proves the universal gateway image works

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GATEWAY_IMG="$SCRIPT_DIR/tide-gateway.qcow2"
CLIENT_IMG="$SCRIPT_DIR/tide-client.qcow2"
CLOUD_INIT="$SCRIPT_DIR/cloud-init.iso"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
SOCKET="/tmp/tide-lan.sock"

# Clean up any existing socket
rm -f "$SOCKET"

echo "🌊 Tide Gateway Test Environment"
echo "================================"
echo ""

# Check if client image exists, if not create from base Alpine
if [ ! -f "$CLIENT_IMG" ]; then
    echo "Creating client image from Alpine base..."
    cp "$SCRIPT_DIR/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2" "$CLIENT_IMG"
fi

echo "Starting Gateway (10.101.101.10)..."
echo "  - WAN: User-mode NAT (internet access)"
echo "  - LAN: Unix socket (internal network)"
echo ""

# Start Gateway in background
qemu-system-aarch64 \
  -name "Tide-Gateway" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file="$GATEWAY_IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -netdev user,id=wan0 \
  -device virtio-net-device,netdev=wan0,mac=52:54:00:12:34:01 \
  -netdev socket,id=lan0,listen=:8010 \
  -device virtio-net-device,netdev=lan0,mac=52:54:00:12:34:02 \
  &

GATEWAY_PID=$!
echo "Gateway PID: $GATEWAY_PID"

# Wait for gateway to boot
echo "Waiting for gateway to boot (15 seconds)..."
sleep 15

echo ""
echo "Starting Client (will get IP via gateway)..."
echo "  - Connected to Gateway LAN via Unix socket"
echo ""

# Start Client (foreground - interactive)
qemu-system-aarch64 \
  -name "Tide-Client" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file="$CLIENT_IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -cdrom "$CLOUD_INIT" \
  -netdev socket,id=lan0,connect=127.0.0.1:8010 \
  -device virtio-net-device,netdev=lan0,mac=52:54:00:12:34:03

# Cleanup
echo "Shutting down gateway..."
kill $GATEWAY_PID 2>/dev/null
rm -f "$SOCKET"
echo "Done."
