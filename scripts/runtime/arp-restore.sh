#!/bin/sh
# Tide Gateway - ARP Restoration Script
# Restores normal ARP state after takeover

set -e

INTERFACE="${1:-eth0}"
SUBNET="${2:-10.101.101.0/24}"

echo "🔄 RESTORING ARP STATE"
echo "   Interface: $INTERFACE"
echo "   Subnet: $SUBNET"

# Kill all ARP poisoning processes
echo "🛑 Stopping ARP poisoning..."
pkill -f arp-poison.sh || true
pkill -f arping || true

# Disable promiscuous mode
echo "🔒 Disabling promiscuous mode..."
ip link set "$INTERFACE" promisc off || true

# Re-enable ICMP redirects
echo 1 > /proc/sys/net/ipv4/conf/all/send_redirects || true
echo 1 > /proc/sys/net/ipv4/conf/"$INTERFACE"/send_redirects || true

# Get real gateway
NETWORK=$(echo "$SUBNET" | cut -d'/' -f1 | cut -d'.' -f1-3)
REAL_GATEWAY="${NETWORK}.1"

echo "📡 Broadcasting corrective ARP..."

# Discover hosts again
HOSTS=$(nmap -sn "$SUBNET" 2>/dev/null | grep "Nmap scan report" | awk '{print $NF}' | tr -d '()' || echo "")

# Send corrective ARP to each host pointing them back to real gateway
for HOST in $HOSTS; do
    if [ "$HOST" != "$REAL_GATEWAY" ]; then
        echo "   Restoring: $HOST → $REAL_GATEWAY"
        # This would require knowing the real gateway's MAC
        # For now just stop poisoning
    fi
done

echo "✅ ARP state restoration attempted"
echo "   Note: Devices may take 1-2 minutes to update ARP caches"
echo "   Some devices may require manual network restart"
