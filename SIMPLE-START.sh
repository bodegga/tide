#!/bin/sh
# Simple Killa Whale starter (no API, no complicated stuff)

echo "🌊 Starting Tide Gateway - Killa Whale Mode"

# Config
INTERFACE=eth1
GATEWAY_IP=10.101.101.10
SUBNET=10.101.101.0/24
NETWORK=10.101.101

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Enable promiscuous mode
ip link set $INTERFACE promisc on

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true

# NAT rules for transparent proxy
iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -j REDIRECT --to-ports 9040
iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 5353

echo "✅ Firewall configured"

# Start dnsmasq
cat > /tmp/dnsmasq.conf << EOF
interface=$INTERFACE
dhcp-range=10.101.101.100,10.101.101.200,12h
dhcp-option=3,$GATEWAY_IP
dhcp-option=6,$GATEWAY_IP
server=127.0.0.1#5353
no-resolv
log-queries
log-dhcp
EOF

echo "🌐 Starting dnsmasq..."
dnsmasq -C /tmp/dnsmasq.conf --no-daemon --log-facility=- &

# Start ARP poisoning
echo "💉 Starting ARP poisoning..."
while true; do
    arping -U -c 1 -I $INTERFACE -s ${NETWORK}.1 ${NETWORK}.255 2>/dev/null
    sleep 2
done &

# Start Tor
echo "🔐 Starting Tor..."
exec tor -f /etc/tor/torrc
