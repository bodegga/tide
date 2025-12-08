#!/bin/bash
# Fix Workstation network - remove DHCP, force static 10.152.152.11 only
# This ensures ALL traffic goes through Tor Gateway

set -e

echo "=========================================="
echo "Fixing Workstation Network Isolation"
echo "=========================================="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root or with sudo"
    exit 1
fi

# Detect interface name
IFACE=$(ip link show | grep -E "^[0-9]+: enp" | head -1 | awk -F': ' '{print $2}')

if [ -z "$IFACE" ]; then
    echo "ERROR: Could not detect network interface"
    ip link show
    exit 1
fi

echo "Detected interface: $IFACE"
echo ""

# Backup existing config
if [ -f /etc/network/interfaces ]; then
    cp /etc/network/interfaces /etc/network/interfaces.backup.$(date +%Y%m%d-%H%M%S)
fi

# Create static network configuration
echo "Creating static network configuration..."
cat > /etc/network/interfaces << NETEOF
# Loopback
auto lo
iface lo inet loopback

# Static configuration - isolated to Tor Gateway only
auto $IFACE
iface $IFACE inet static
    address 10.152.152.11/24
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
NETEOF

# Stop NetworkManager if running (conflicts with static config)
systemctl stop NetworkManager 2>/dev/null || true
systemctl disable NetworkManager 2>/dev/null || true

# Restart networking
echo ""
echo "Restarting network with static configuration..."
systemctl restart networking

# Remove the DHCP-assigned IP
ip addr flush dev $IFACE
ip addr add 10.152.152.11/24 dev $IFACE
ip link set $IFACE up
ip route add default via 10.152.152.10

# Set DNS
echo "nameserver 10.152.152.10" > /etc/resolv.conf

echo ""
echo "=========================================="
echo "Network Fixed!"
echo "=========================================="
echo ""
echo "Current configuration:"
ip addr show $IFACE
echo ""
ip route
echo ""
echo "DNS:"
cat /etc/resolv.conf
echo ""
echo "Testing Tor routing..."
timeout 5 curl https://check.torproject.org/api/ip 2>/dev/null || echo "Test connection (may need a moment for Tor)"
echo ""
echo "Workstation is now isolated - all traffic through Tor Gateway"
echo ""
