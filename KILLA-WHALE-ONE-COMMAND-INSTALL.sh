#!/bin/sh
# ONE COMMAND KILLA WHALE INSTALL - Actually fucking works
# Run this AFTER setup-alpine completes. Nothing else needed.

set -e

echo "🐋 KILLA WHALE - One Command Install"
echo "====================================="
echo ""

# Fix network and DNS FIRST
echo "[STEP 1/7] Fixing network and DNS..."
cat > /etc/network/interfaces << 'NETCONF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
NETCONF

# Restart networking
rc-service networking restart 2>/dev/null || ifup eth0

# Set DNS
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Test internet
if ! ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
    echo "❌ No internet - check VM network settings"
    echo "   Need: net0=shared (for internet)"
    exit 1
fi

echo "   ✅ Internet working"

# Fix repositories - use EDGE for everything
echo "[STEP 2/7] Configuring Alpine repositories..."
cat > /etc/apk/repositories << 'REPOS'
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
REPOS

apk update

# Install EVERYTHING
echo "[STEP 3/7] Installing ALL packages..."
apk add tor iptables python3 dnsmasq nmap iputils net-tools git bash curl

# Clone/update Tide
echo "[STEP 4/7] Getting Tide code..."
cd /root
if [ -d "tide" ]; then
    cd tide && git pull
else
    git clone https://github.com/bodegga/tide.git
    cd tide
fi

# Install Tide
echo "[STEP 5/7] Installing Tide Gateway..."
mkdir -p /usr/local/bin /etc/tide /var/log/tide

cp scripts/runtime/gateway-start.sh /usr/local/bin/
cp scripts/runtime/tide-api.py /usr/local/bin/
cp torrc-gateway /etc/tor/torrc
cp config/torrc-* /etc/tor/ 2>/dev/null || true
chmod +x /usr/local/bin/gateway-start.sh /usr/local/bin/tide-api.py

# Configure KILLA-WHALE mode
echo "[STEP 6/7] Configuring KILLA-WHALE mode..."
echo "killa-whale" > /etc/tide/mode
echo "standard" > /etc/tide/security

cat > /etc/tide/env << 'ENVFILE'
export TIDE_MODE=killa-whale
export TIDE_SECURITY=standard
export TIDE_GATEWAY_IP=10.101.101.10
export TIDE_SUBNET=10.101.101.0/24
export TIDE_DHCP_START=10.101.101.100
export TIDE_DHCP_END=10.101.101.200
ENVFILE

# Create service
cat > /etc/init.d/tide-gateway << 'SERVICE'
#!/sbin/openrc-run

depend() {
    need net
}

start() {
    . /etc/tide/env
    ebegin "Starting Tide Gateway (KILLA-WHALE mode)"
    start-stop-daemon --start --background \
        --make-pidfile --pidfile /run/tide-gateway.pid \
        --stdout /var/log/tide/gateway.log \
        --stderr /var/log/tide/gateway.log \
        --exec /usr/local/bin/gateway-start.sh
    eend $?
}

stop() {
    ebegin "Stopping Tide Gateway"
    start-stop-daemon --stop --pidfile /run/tide-gateway.pid
    killall tor gateway-start.sh 2>/dev/null || true
    eend $?
}
SERVICE

chmod +x /etc/init.d/tide-gateway
rc-update add tide-gateway default

# Start it NOW
echo "[STEP 7/7] Starting KILLA-WHALE..."
rc-service tide-gateway start

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ KILLA WHALE DEPLOYED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Installed packages:"
apk info | grep -E 'tor|iptables|dnsmasq|nmap|iputils'
echo ""
echo "Service status:"
rc-service tide-gateway status
echo ""
echo "View logs:"
echo "  tail -f /var/log/tide/gateway.log"
echo ""
echo "🐋 KILLA WHALE - All features enabled"
echo "   - ARP poisoning: YES"
echo "   - DHCP server: YES"
echo "   - Fail-closed firewall: YES"
echo ""
