#!/bin/bash
# Simple test - Gateway boots with DHCP, client gets IP automatically

cd "$(dirname "$0")"

echo "🌊 Testing Tide Gateway with DHCP"
echo "=================================="
echo ""

# Clean up old client
rm -f tide-client.qcow2
cp nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2 tide-client.qcow2

echo "[1/3] Starting Gateway (with DHCP server)..."
qemu-system-aarch64 \
  -name "Tide-Gateway" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file=tide-gateway-complete.qcow2,id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -cdrom cloud-init.iso \
  -netdev user,id=wan \
  -device virtio-net-device,netdev=wan,mac=52:54:00:12:34:01 \
  -netdev socket,id=lan,listen=:8010 \
  -device virtio-net-device,netdev=lan,mac=52:54:00:12:34:02 \
  > /tmp/gateway.log 2>&1 &

GATEWAY_PID=$!
echo "  Gateway PID: $GATEWAY_PID"
echo "  Logs: tail -f /tmp/gateway.log"
echo ""

sleep 30

echo "[2/3] Starting Client (should get DHCP from gateway)..."
qemu-system-aarch64 \
  -name "Tide-Client" \
  -M virt -cpu cortex-a72 -m 512 \
  -nographic \
  -drive if=none,file=tide-client.qcow2,id=hd0,format=qcow2 \
  -device virtio-blk-device,drive=hd0 \
  -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -netdev socket,id=lan,connect=127.0.0.1:8010 \
  -device virtio-net-device,netdev=lan,mac=52:54:00:12:34:03 \
  > /tmp/client.log 2>&1 &

CLIENT_PID=$!
echo "  Client PID: $CLIENT_PID"
echo "  Logs: tail -f /tmp/client.log"
echo ""

echo "[3/3] Waiting 60 seconds for boot..."
sleep 60

echo ""
echo "Checking DHCP logs on gateway..."
grep -i "dhcp" /tmp/gateway.log | tail -10

echo ""
echo "Checking client network..."
grep -i "eth0\|dhcp" /tmp/client.log | tail -10

echo ""
echo "VMs still running. Press Ctrl-C to kill them."
echo "Or check logs manually:"
echo "  Gateway: tail -f /tmp/gateway.log"
echo "  Client:  tail -f /tmp/client.log"

wait
