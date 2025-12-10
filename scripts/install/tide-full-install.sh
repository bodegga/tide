#!/bin/sh
# Tide FULL Install - Get ALL packages working on ARM64

set -e

echo "🐋 Tide Gateway - FULL Install (ARM64 Fixed)"
echo "=============================================="
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

# Fix repositories PROPERLY
echo "[1/6] Configuring Alpine repositories..."
cat > /etc/apk/repositories << 'REPOS'
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
REPOS

apk update

# Install ALL packages
echo "[2/6] Installing ALL packages (including edge)..."
apk add tor iptables python3

# Try to install optional packages from edge if needed
apk add dnsmasq || apk add dnsmasq --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main
apk add nmap || apk add nmap --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
apk add iputils || true
apk add net-tools || apk add net-tools --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main

echo "[3/6] Installing Tide..."
SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p /usr/local/bin /etc/tide /var/log/tide

cp "$SCRIPT_DIR/scripts/runtime/gateway-start.sh" /usr/local/bin/
cp "$SCRIPT_DIR/scripts/runtime/tide-api.py" /usr/local/bin/
cp "$SCRIPT_DIR/torrc-gateway" /etc/tor/torrc
cp "$SCRIPT_DIR/config"/torrc-* /etc/tor/ 2>/dev/null || true
chmod +x /usr/local/bin/gateway-start.sh /usr/local/bin/tide-api.py

echo "[4/6] Configuring..."
echo "$TIDE_MODE" > /etc/tide/mode
echo "standard" > /etc/tide/security

cat > /etc/tide/env << 'ENVFILE'
export TIDE_MODE=killa-whale
export TIDE_SECURITY=standard
export TIDE_GATEWAY_IP=10.101.101.10
export TIDE_SUBNET=10.101.101.0/24
export TIDE_DHCP_START=10.101.101.100
export TIDE_DHCP_END=10.101.101.200
ENVFILE

echo "[5/6] Creating service..."
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

echo "[6/6] Enabling service..."
rc-update add tide-gateway default

echo ""
echo "✅ Tide Gateway FULLY installed!"
echo ""
echo "Installed packages:"
apk info | grep -E "tor|iptables|dnsmasq|nmap|iputils"
echo ""
echo "Start it:"
echo "  rc-service tide-gateway restart"
echo ""
echo "Check logs:"
echo "  tail -f /var/log/tide/gateway.log"
echo ""
if [ "$TIDE_MODE" = "killa-whale" ]; then
    echo "🐋 KILLA WHALE - FULL AGGRESSION MODE"
    echo "   ALL features enabled"
fi
