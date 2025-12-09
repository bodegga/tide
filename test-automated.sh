#!/bin/bash
# Automated Tide Transparent Routing Test
# Boots gateway + client, waits for boot, then SSHes in to test

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

GATEWAY_IMG="tide-gateway.qcow2"
CLIENT_IMG="tide-client.qcow2"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

echo "🌊 Tide Automated Transparent Routing Test"
echo "============================================"
echo ""

# Create fresh client image
rm -f "$CLIENT_IMG"
cp "nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2" "$CLIENT_IMG"

echo "[1/4] Starting Gateway VM..."
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
echo "  Gateway PID: $GATEWAY_PID"

sleep 5

echo "[2/4] Starting Client VM with static IP..."
qemu-system-aarch64 \
  -name "Tide-Client" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file="$CLIENT_IMG",id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios "$BIOS" \
  -cdrom tide-client-static.iso \
  -netdev socket,id=lan,connect=127.0.0.1:8010 \
  -device virtio-net-device,netdev=lan,mac=52:54:00:12:34:03 \
  -netdev user,id=ssh,hostfwd=tcp::2223-:22 \
  -device virtio-net-device,netdev=ssh,mac=52:54:00:12:34:04 \
  > /tmp/tide-client.log 2>&1 &

CLIENT_PID=$!
echo "  Client PID: $CLIENT_PID"

echo "[3/4] Waiting for VMs to boot (60 seconds)..."
sleep 60

echo "[4/4] Testing transparent routing..."
echo ""
echo "Attempting to SSH into client (root/alpine on localhost:2223)..."
echo "If this works, we'll test if traffic routes through Tor..."
echo ""

# Try to SSH and run test
sshpass -p alpine ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2223 root@localhost << 'SSHCMD'
echo "=== Connected to client VM ==="
echo ""
echo "Testing network config..."
ip addr show eth0 | grep "inet "
echo ""
echo "Testing gateway connectivity..."
ping -c 2 10.101.101.10
echo ""
echo "Testing Tor transparent routing..."
wget -qO- https://check.torproject.org/api/ip
echo ""
echo "=== Test complete ==="
SSHCMD

TEST_EXIT=$?

echo ""
echo "Cleaning up..."
kill $CLIENT_PID $GATEWAY_PID 2>/dev/null
wait $CLIENT_PID $GATEWAY_PID 2>/dev/null

echo ""
if [ $TEST_EXIT -eq 0 ]; then
    echo "✅ TEST PASSED - Check output above for Tor status"
else
    echo "❌ TEST FAILED - Could not connect or test failed"
    echo ""
    echo "Gateway logs: /tmp/tide-gateway.log"
    echo "Client logs: /tmp/tide-client.log"
fi
