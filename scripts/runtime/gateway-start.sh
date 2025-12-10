#!/bin/sh
# Tide Gateway Startup - Sets up transparent routing

echo "🌊 Starting Tide Gateway (Transparent Mode)"

# Enable IP forwarding (already set via docker sysctl, but try anyway)
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "⚠️  IP forwarding already enabled via Docker"

# Wait a moment for network to be ready
sleep 2

# Setup iptables for transparent proxy
# Exclude API port from Tor redirection
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 9051 -j ACCEPT
# Redirect all other TCP traffic from clients to Tor TransPort
iptables -t nat -A PREROUTING -i eth0 -p tcp -j REDIRECT --to-ports 9040

# Redirect DNS queries to Tor DNSPort  
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j REDIRECT --to-ports 5353

# Allow Tor process to connect out
iptables -t nat -A OUTPUT -m owner --uid-owner tor -j RETURN

echo "✅ iptables configured for transparent proxy"
iptables -t nat -L -n -v

# Configure dnsmasq for DHCP
echo "📡 Configuring dnsmasq for DHCP..."
cat > /etc/dnsmasq.conf << 'DNSMASQ'
interface=eth0
dhcp-range=10.101.101.100,10.101.101.200,12h
dhcp-option=3,10.101.101.10
dhcp-option=6,10.101.101.10
server=127.0.0.1#5353
no-resolv
log-queries
log-dhcp
DNSMASQ

# Start dnsmasq (DHCP + DNS)
echo "🌐 Starting dnsmasq (DHCP + DNS)..."
dnsmasq --no-daemon --log-facility=- &

# Start API server (port 9051)
echo "🌐 Starting Tide API server (port 9051)..."
python3 /usr/local/bin/tide-api.py &

# Start Tor
echo "🔐 Starting Tor..."
exec tor -f /etc/tor/torrc
