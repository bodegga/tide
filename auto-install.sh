#!/bin/sh
# Tide Gateway - FULLY AUTOMATIC (no prompts)

set -e

echo "🌊 TIDE GATEWAY - AUTO INSTALL"
echo "==============================="

echo "[1/7] Fixing DNS..."
cat > /etc/resolv.conf << 'EOFDNS'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOFDNS

echo "[2/7] Updating system..."
apk update
apk upgrade

echo "[3/7] Installing packages..."
apk add git tor iptables dnsmasq nmap iputils tcpdump curl bash openrc

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

echo "[5/7] Configuring eth1..."
cat >> /etc/network/interfaces << 'EOFINT'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOFINT
ifup eth1 2>/dev/null || true

echo "[6/7] Installing gateway..."
cat > /usr/local/bin/tide-gateway << 'EOFGATEWAY'
#!/bin/sh
echo "🌊 Tide Gateway - Killa Whale Mode"
INTERFACE=eth1
GATEWAY_IP=10.101.101.10
killall dnsmasq tor 2>/dev/null || true
sleep 1
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
ip link set $INTERFACE promisc on 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -j REDIRECT --to-ports 9040
iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 5353
echo "✅ Firewall ready"
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
echo "💉 Starting ARP poisoning..."
(while true; do arping -U -c 1 -I $INTERFACE -s 10.101.101.1 10.101.101.255 2>/dev/null || true; sleep 3; done) &
echo "🔐 Starting Tor..."
exec tor -f /etc/tor/torrc
EOFGATEWAY

chmod +x /usr/local/bin/tide-gateway

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

echo "[7/7] Testing..."
/usr/local/bin/tide-gateway &
GATEWAY_PID=$!
sleep 5
if ps | grep -q $GATEWAY_PID; then
    echo "✅ Gateway running!"
    kill $GATEWAY_PID 2>/dev/null || true
    killall tor dnsmasq 2>/dev/null || true
else
    echo "❌ Failed"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ INSTALLATION COMPLETE!"
echo "========================================="
echo ""
echo "Start now: rc-service tide-gateway start"
echo "Check status: rc-service tide-gateway status"
echo "View logs: tail -f /var/log/tide/gateway.log"
echo ""

