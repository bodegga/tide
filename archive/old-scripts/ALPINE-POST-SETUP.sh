#!/bin/sh
# Tide Gateway - Post Alpine Setup Script
# Run this AFTER setup-alpine completes and system reboots

set -e

echo "========================================="
echo "Tide Gateway - Killa Whale Setup"
echo "========================================="
echo ""

# Fix DNS
echo "[1/6] Configuring DNS..."
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# Switch to edge repos
echo "[2/6] Switching to Alpine edge repositories..."
cat > /etc/apk/repositories << 'EOF'
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
EOF

# Update and upgrade
echo "[3/6] Updating system..."
apk update
apk upgrade

# Install required packages
echo "[4/6] Installing packages (tor, iptables, dnsmasq, etc)..."
apk add git tor iptables dnsmasq nmap iputils tcpdump curl bash openrc

# Clone tide repo
echo "[5/6] Cloning Tide repository..."
cd /root
if [ -d "tide" ]; then
    echo "Tide directory exists, pulling latest..."
    cd tide
    git pull
else
    git clone https://github.com/anthonybiasi/tide.git
    cd tide
fi

# Install tide gateway
echo "[6/6] Installing Tide Gateway..."
chmod +x scripts/gateway-start.sh
cp scripts/gateway-start.sh /usr/local/bin/tide-gateway

# Create config directory
mkdir -p /etc/tide

# Create default killa-whale config
cat > /etc/tide/gateway.conf << 'EOFCONFIG'
# Tide Gateway Configuration
MODE=killa-whale
INTERFACE=eth1
NETWORK=10.101.101.0/24
GATEWAY_IP=10.101.101.10
DNS_SERVER=8.8.8.8
TOR_TRANS_PORT=9040
TOR_DNS_PORT=5353
EOFCONFIG

# Create OpenRC service
cat > /etc/init.d/tide-gateway << 'EOFSERVICE'
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
EOFSERVICE

chmod +x /etc/init.d/tide-gateway

# Enable and start service
echo ""
echo "Enabling Tide Gateway service..."
rc-update add tide-gateway default
rc-service tide-gateway start

echo ""
echo "========================================="
echo "✓ Tide Gateway Installation Complete!"
echo "========================================="
echo ""
echo "Mode: Killa Whale"
echo "Attack Interface: eth1"
echo "Gateway IP: 10.101.101.10/24"
echo ""
echo "Check status: rc-service tide-gateway status"
echo "View logs: tail -f /var/log/tide/gateway.log"
echo ""
