#!/bin/sh
# Tide Gateway Startup - Sets up transparent routing

echo "🌊 Starting Tide Gateway (Transparent Mode)"

# Enable IP forwarding (should already be enabled via sysctl)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Wait a moment for network to be ready
sleep 2

# Setup iptables for transparent proxy
# Redirect all TCP traffic from clients to Tor TransPort
iptables -t nat -A PREROUTING -i eth0 -p tcp -j REDIRECT --to-ports 9040

# Redirect DNS queries to Tor DNSPort  
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j REDIRECT --to-ports 5353

# Allow Tor process to connect out
iptables -t nat -A OUTPUT -m owner --uid-owner tor -j RETURN

# Redirect gateway's own traffic through Tor (optional, for testing)
# iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-ports 9040

echo "✅ iptables configured for transparent proxy"
iptables -t nat -L -n -v

# Start Tor
echo "🔐 Starting Tor..."
exec tor -f /etc/tor/torrc
