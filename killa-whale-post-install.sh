#!/bin/sh
# Killa Whale Post-Install (run AFTER Alpine is installed)

set -e

echo "🐋 Installing Killa Whale..."

# Install packages
echo "📦 Installing packages..."
apk update
apk add tor iptables dnsmasq nmap iputils git bash curl

# Create tide user
echo "👤 Creating tide user..."
adduser -D -s /bin/bash tide || true
echo "tide:tide" | chpasswd

# Copy tide scripts
echo "📁 Installing Tide Gateway..."
mkdir -p /usr/local/bin /etc/tide /var/log/tide

# Copy from current directory (we're in /root/tide)
cp scripts/runtime/gateway-start.sh /usr/local/bin/
cp scripts/runtime/tide-api.py /usr/local/bin/
cp torrc-gateway /etc/tor/torrc
cp config/torrc-* /etc/tor/ 2>/dev/null || true
chmod +x /usr/local/bin/gateway-start.sh /usr/local/bin/tide-api.py

# Configure mode
echo "killa-whale" > /etc/tide/mode
echo "standard" > /etc/tide/security

# Create service
cat > /etc/init.d/tide-gateway << 'SERVICE'
#!/sbin/openrc-run

depend() {
    need net
}

start() {
    ebegin "Starting Tide Gateway"
    start-stop-daemon --start --background \
        --stdout /var/log/tide/gateway.log \
        --stderr /var/log/tide/gateway.log \
        --exec /usr/local/bin/gateway-start.sh
    eend $?
}

stop() {
    ebegin "Stopping Tide Gateway"
    killall gateway-start.sh tor 2>/dev/null
    eend $?
}
SERVICE

chmod +x /etc/init.d/tide-gateway

# Enable service
rc-update add tide-gateway default

echo ""
echo "✅ Killa Whale installed!"
echo ""
echo "Start it:"
echo "  rc-service tide-gateway start"
echo ""
echo "Check logs:"
echo "  tail -f /var/log/tide/gateway.log"
echo ""
echo "🐋🎤 Let's go!"
