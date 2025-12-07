#!/bin/bash
echo "=== All Network Interfaces ==="
ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | tr -d ':'
echo ""
echo "=== Interfaces with IPs ==="
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1"
