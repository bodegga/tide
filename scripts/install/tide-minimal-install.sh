#!/bin/sh
# Tide Minimal Install - Works on any Alpine (even with limited packages)

set -e

echo "🐋 Tide Gateway - Minimal Install"
echo "==================================="
echo ""

# Mode selection
echo "Select mode:"
echo "  [1] PROXY"
echo "  [2] ROUTER" 
echo "  [3] KILLA-WHALE"
printf "Select [1-3]: "
read MODE_NUM

case "$MODE_NUM" in
    1) TIDE_MODE="proxy" ;;
    2) TIDE_MODE="router" ;;
    3) TIDE_MODE="killa-whale" ;;
    *) echo "Invalid"; exit 1 ;;
esac

echo ""
echo "► Mode: $TIDE_MODE"
echo ""

# Install ONLY what's guaranteed available
echo "[1/4] Installing core packages..."
apk update
apk add tor iptables

echo "[2/4] Installing Tide..."
SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p /usr/local/bin /etc/tide /var/log/tide

# Copy files
cp "$SCRIPT_DIR/scripts/runtime/gateway-start.sh" /usr/local/bin/
cp "$SCRIPT_DIR/scripts/runtime/tide-api.py" /usr/local/bin/
cp "$SCRIPT_DIR/torrc-gateway" /etc/tor/torrc
chmod +x /usr/local/bin/gateway-start.sh

# Config
echo "$TIDE_MODE" > /etc/tide/mode
echo "standard" > /etc/tide/security

# Environment
cat > /etc/tide/env << 'ENVFILE'
export TIDE_MODE=killa-whale
export TIDE_SECURITY=standard
export TIDE_GATEWAY_IP=10.101.101.10
export TIDE_SUBNET=10.101.101.0/24
ENVFILE

echo "[3/4] Creating service..."
cat > /etc/init.d/tide-gateway << 'SERVICE'
#!/sbin/openrc-run

depend() {
    need net
}

start() {
    . /etc/tide/env
    ebegin "Starting Tide Gateway ($TIDE_MODE mode)"
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

echo "[4/4] Enabling service..."
rc-update add tide-gateway default

echo ""
echo "✅ Tide Gateway installed!"
echo ""
echo "⚠️  NOTE: Some features disabled due to missing packages"
echo "   - No DHCP (dnsmasq unavailable)"
echo "   - No ARP poisoning (nmap/arping unavailable)"
echo "   - Tor transparent proxy will work"
echo ""
echo "Start it:"
echo "  rc-service tide-gateway start"
echo ""
echo "Check logs:"
echo "  tail -f /var/log/tide/gateway.log"
echo ""
