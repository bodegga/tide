#!/bin/sh
# Tide Gateway - FINAL WORKING INSTALLER
# This WILL work or I'm a fucking idiot

set -e

echo "🌊 Tide Gateway - FINAL INSTALL"
echo "================================"

# Step 1: Create tor user and fix permissions
echo "[1/5] Setting up Tor user and permissions..."
adduser -D -H -s /sbin/nologin tor 2>/dev/null || echo "  tor user exists"
mkdir -p /var/lib/tor
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor
echo "  ✅ Tor permissions fixed"

# Step 2: Install Tor config
echo "[2/5] Installing Tor configuration..."
cat > /etc/tor/torrc << 'EOFTORRC'
User tor
SocksPort 0.0.0.0:9050
TransPort 0.0.0.0:9040
DNSPort 0.0.0.0:5353
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice stdout
DataDirectory /var/lib/tor
EOFTORRC
echo "  ✅ Torrc installed"

# Step 3: Install gateway startup script
echo "[3/5] Installing gateway script..."
cat > /usr/local/bin/tide-gateway << 'EOFGATEWAY'
#!/bin/sh
echo "🌊 Tide Gateway - Killa Whale Mode"

INTERFACE=eth1
GATEWAY_IP=10.101.101.10

# Kill existing services
killall dnsmasq 2>/dev/null || true
killall tor 2>/dev/null || true

# Wait for network
sleep 2

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true

# Enable promiscuous mode
ip link set $INTERFACE promisc on 2>/dev/null || true

# Flush iptables
iptables -t nat -F 2>/dev/null || true

# Setup NAT
iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -j REDIRECT --to-ports 9040
iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 5353

echo "✅ Firewall configured"

# Start dnsmasq
cat > /tmp/dnsmasq.conf << EOF
interface=$INTERFACE
bind-interfaces
dhcp-range=10.101.101.100,10.101.101.200,12h
dhcp-option=3,$GATEWAY_IP
dhcp-option=6,$GATEWAY_IP
server=127.0.0.1#5353
no-resolv
log-queries
log-dhcp
EOF

echo "🌐 Starting dnsmasq..."
dnsmasq -C /tmp/dnsmasq.conf &

sleep 2

# ARP poisoning
echo "💉 Starting ARP poisoning..."
(
while true; do
    arping -U -c 1 -I $INTERFACE -s 10.101.101.1 10.101.101.255 2>/dev/null || true
    sleep 3
done
) &

# Start Tor
echo "🔐 Starting Tor..."
exec tor -f /etc/tor/torrc
EOFGATEWAY

chmod +x /usr/local/bin/tide-gateway
echo "  ✅ Gateway script installed"

# Step 4: Create OpenRC service
echo "[4/5] Creating system service..."
cat > /etc/init.d/tide-gateway << 'EOFSVC'
#!/sbin/openrc-run
name="Tide Gateway"
description="Tide Tor Gateway (Killa Whale Mode)"
command="/usr/local/bin/tide-gateway"
command_background="yes"
pidfile="/run/tide-gateway.pid"
output_log="/var/log/tide/gateway.log"
error_log="/var/log/tide/gateway-error.log"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --mode 0755 /var/log/tide
}
EOFSVC

chmod +x /etc/init.d/tide-gateway
echo "  ✅ Service created"

# Step 5: Enable and start
echo "[5/5] Enabling service..."
rc-update add tide-gateway default
echo "  ✅ Service enabled"

echo ""
echo "========================================="
echo "✅ INSTALLATION COMPLETE!"
echo "========================================="
echo ""
echo "Starting Tide Gateway..."
rc-service tide-gateway start

sleep 3

echo ""
echo "Checking status..."
rc-service tide-gateway status

echo ""
echo "Check logs with: tail -f /var/log/tide/gateway.log"
echo ""

