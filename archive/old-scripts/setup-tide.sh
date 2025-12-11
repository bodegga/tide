#!/bin/sh
set -e

echo "🌊 Tide Gateway Setup"

# Fix DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Update repos
apk update
apk upgrade

# Install packages
apk add git tor iptables dnsmasq nmap iputils tcpdump curl bash openrc

# Clone tide repo
cd /root
git clone https://github.com/bodegga/tide.git

# Create tor user and fix permissions
adduser -D -H -s /sbin/nologin tor 2>/dev/null || true
mkdir -p /var/lib/tor
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor

# Install torrc
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

# Install gateway script
cat > /usr/local/bin/tide-gateway << 'EOFGATEWAY'
#!/bin/sh
set -e

echo "🌊 Tide Gateway - Killa Whale Mode"

INTERFACE=eth1
GATEWAY_IP=10.101.101.10

# Kill existing services
killall dnsmasq 2>/dev/null || true

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true

# Enable promiscuous mode
ip link set $INTERFACE promisc on 2>/dev/null || true

# Flush and setup iptables
iptables -t nat -F 2>/dev/null || true
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

# Create OpenRC service
cat > /etc/init.d/tide-gateway << 'EOFSVC'
#!/sbin/openrc-run
name="Tide Gateway"
description="Tide Tor Gateway (Killa Whale Mode)"
command="/usr/local/bin/tide-gateway"
command_background="yes"
pidfile="/run/tide-gateway.pid"
depend() {
    need net
    after firewall
}
start_pre() {
    checkpath --directory --mode 0755 /var/log/tide
}
EOFSVC

chmod +x /etc/init.d/tide-gateway

# Enable services
rc-update add tide-gateway default
rc-update add networking boot

echo "✅ Tide Gateway installed!"
echo "Reboot and it will start automatically"

# Power off to finish
poweroff
