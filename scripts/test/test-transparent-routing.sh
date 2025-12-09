#!/bin/bash
# Test Tide Transparent Routing
# This boots a gateway + client VM and lets you test transparent Tor routing

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

GATEWAY_IMG="tide-gateway.qcow2"
CLIENT_IMG="tide-client.qcow2"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

echo "🌊 Tide Transparent Routing Test"
echo "=================================="
echo ""

# Create fresh client image if needed
if [ ! -f "$CLIENT_IMG" ]; then
    echo "Creating fresh client image..."
    cp "nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2" "$CLIENT_IMG"
fi

echo "Starting Gateway VM in background..."
echo "  - WAN: NAT (internet access)"
echo "  - LAN: TCP socket port 8010"
echo "  - SSH: localhost:2222 (root/alpine)"
echo ""

# Start gateway with SSH access
qemu-system-aarch64 \
  -name "Tide-Gateway" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file="$GATEWAY_IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -netdev user,id=wan,hostfwd=tcp::2222-:22 \
  -device virtio-net-device,netdev=wan,mac=52:54:00:12:34:01 \
  -netdev socket,id=lan,listen=:8010 \
  -device virtio-net-device,netdev=lan,mac=52:54:00:12:34:02 \
  > /tmp/tide-gateway.log 2>&1 &

GATEWAY_PID=$!
echo "Gateway PID: $GATEWAY_PID"
echo "Gateway logs: tail -f /tmp/tide-gateway.log"
echo ""

# Wait for gateway to boot and socket to be ready
echo "Waiting for gateway to boot (20 seconds)..."
sleep 20

echo ""
echo "Gateway should be ready. Now starting CLIENT VM..."
echo ""
echo "CLIENT INSTRUCTIONS:"
echo "  1. Wait 30 seconds for cloud-init to configure network"
echo "  2. Login: root / alpine"
echo "  3. Check IP: ip addr show eth0 (should be 10.101.101.20)"
echo "  4. Test gateway: ping -c 2 10.101.101.10"
echo "  5. Test Tor: wget -qO- https://check.torproject.org/api/ip"
echo "  6. You should see: {\"IsTor\":true,\"IP\":\"<some-tor-exit-ip>\"}"
echo ""
echo "Press Ctrl-A X to exit QEMU when done"
echo "=================================="
echo ""

# Start client in foreground (interactive)
qemu-system-aarch64 \
  -name "Tide-Client" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file="$CLIENT_IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -cdrom tide-client-static.iso \
  -netdev socket,id=lan,connect=127.0.0.1:8010 \
  -device virtio-net-device,netdev=lan,mac=52:54:00:12:34:03

# Cleanup when client exits
echo ""
echo "Shutting down gateway..."
kill $GATEWAY_PID 2>/dev/null
wait $GATEWAY_PID 2>/dev/null
echo "Test complete."
