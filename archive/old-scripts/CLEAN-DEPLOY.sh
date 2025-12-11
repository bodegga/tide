#!/bin/sh
# Tide Gateway - CLEAN DEPLOYMENT (Fresh Alpine Install)
# Run this ONCE after fresh Alpine setup-alpine completes

set -e

echo "🌊 TIDE GATEWAY - CLEAN DEPLOYMENT"
echo "==================================="
echo ""
echo "This script assumes:"
echo "  - Fresh Alpine Linux (post setup-alpine)"
echo "  - Internet working (eth0)"
echo "  - Ready to configure as gateway"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "[1/7] Fixing DNS..."
cat > /etc/resolv.conf << 'EOFDNS'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOFDNS
echo "  ✅ DNS configured"

echo ""
echo "[2/7] Updating system..."
apk update
apk upgrade
echo "  ✅ System updated"

echo ""
echo "[3/7] Installing packages..."
apk add git tor iptables dnsmasq nmap iputils tcpdump curl bash openrc
echo "  ✅ Packages installed"

echo ""
echo "[4/7] Setting up Tor..."
adduser -D -H -s /sbin/nologin tor 2>/dev/null || true
mkdir -p /var/lib/tor
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor

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
echo "  ✅ Tor configured"

echo ""
echo "[5/7] Configuring eth1 interface..."
cat >> /etc/network/interfaces << 'EOFINT'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOFINT
ifup eth1 2>/dev/null || echo "  (will activate on reboot)"
echo "  ✅ eth1 configured"

echo ""
echo "[6/7] Installing Tide Gateway..."
cat > /usr/local/bin/tide-gateway << 'EOFGATEWAY'
#!/bin/sh
echo "🌊 Tide Gateway - Killa Whale Mode Starting..."

INTERFACE=eth1
GATEWAY_IP=10.101.101.10

# Kill existing
killall dnsmasq 2>/dev/null || true
killall tor 2>/dev/null || true
sleep 1

# Network setup
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
ip link set $INTERFACE promisc on 2>/dev/null || true

# Firewall
iptables -t nat -F 2>/dev/null || true
iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -j REDIRECT --to-ports 9040
iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 5353

echo "✅ Firewall ready"

# DHCP/DNS
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

# Tor
echo "🔐 Starting Tor..."
exec tor -f /etc/tor/torrc
EOFGATEWAY

chmod +x /usr/local/bin/tide-gateway

# Service
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
    need net networking
    after firewall
}

start_pre() {
    checkpath --directory --mode 0755 /var/log/tide
}
EOFSVC

chmod +x /etc/init.d/tide-gateway
rc-update add tide-gateway default
echo "  ✅ Tide Gateway installed"

echo ""
echo "[7/7] Testing installation..."
/usr/local/bin/tide-gateway &
GATEWAY_PID=$!
sleep 5

if ps | grep -q $GATEWAY_PID; then
    echo "  ✅ Gateway is running!"
    kill $GATEWAY_PID 2>/dev/null || true
    killall tor dnsmasq 2>/dev/null || true
else
    echo "  ❌ Gateway failed to start"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ INSTALLATION COMPLETE!"
echo "========================================="
echo ""
echo "Gateway will start automatically on boot."
echo ""
echo "Configuration:"
echo "  - Gateway IP: 10.101.101.10"
echo "  - DHCP Range: 10.101.101.100-200"
echo "  - Attack Interface: eth1"
echo "  - Internet: eth0"
echo ""
echo "To start now: rc-service tide-gateway start"
echo "Check status: rc-service tide-gateway status"
echo "View logs: tail -f /var/log/tide/gateway.log"
echo ""
echo "Ready to export this VM as a template!"
echo ""

