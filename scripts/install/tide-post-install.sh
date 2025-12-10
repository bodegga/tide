#!/bin/sh
# Tide Post-Install - Run AFTER Alpine is already installed
# Usage: ./tide-post-install.sh

set -e

echo "🐋 Tide Gateway - Post-Install"
echo "================================"
echo ""

# Check we're in Alpine
[ -f /etc/alpine-release ] || { echo "❌ Run from Alpine Linux"; exit 1; }

# Check if Alpine is installed to disk
if [ ! -f /etc/apk/world ]; then
    echo "❌ Alpine not installed to disk yet"
    echo "   Run 'setup-alpine' first!"
    exit 1
fi

# Mode selection
echo "Select deployment mode:"
echo "  [1] PROXY       - SOCKS5 only"
echo "  [2] ROUTER      - DHCP + transparent proxy"
echo "  [3] KILLA-WHALE - Router + leak-proof firewall + ARP poisoning"
echo "  [4] TAKEOVER    - Killa-Whale + ARP hijack"
printf "Select [1-4]: "
read MODE_NUM

case "$MODE_NUM" in
    1) TIDE_MODE="proxy" ;;
    2) TIDE_MODE="router" ;;
    3) TIDE_MODE="killa-whale" ;;
    4) TIDE_MODE="takeover" ;;
    *) echo "Invalid"; exit 1 ;;
esac

# Security profile
echo ""
echo "Select security profile:"
echo "  [1] STANDARD - Default Tor"
echo "  [2] HARDENED - Avoid 14-eyes"
echo "  [3] PARANOID - Maximum anonymity"
echo "  [4] BRIDGES  - Anti-censorship"
printf "Select [1-4]: "
read SEC_NUM

case "$SEC_NUM" in
    1) SECURITY="standard" ;;
    2) SECURITY="hardened" ;;
    3) SECURITY="paranoid" ;;
    4) SECURITY="bridges" ;;
    *) SECURITY="standard" ;;
esac

echo ""
echo "► Mode: $TIDE_MODE | Security: $SECURITY"
echo ""

# Install packages
echo "[1/5] Installing packages..."
apk update
apk add tor iptables dnsmasq python3

# Killa-whale needs extra tools
if [ "$TIDE_MODE" = "killa-whale" ] || [ "$TIDE_MODE" = "takeover" ]; then
    apk add nmap iputils net-tools
fi

# Install Tide files
echo "[2/5] Installing Tide Gateway..."
SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$SCRIPT_DIR"

mkdir -p /usr/local/bin /etc/tide /etc/tor /var/log/tide

cp scripts/runtime/gateway-start.sh /usr/local/bin/
cp scripts/runtime/tide-api.py /usr/local/bin/
cp torrc-gateway /etc/tor/torrc
cp config/torrc-hardened /etc/tor/ 2>/dev/null || true
cp config/torrc-paranoid /etc/tor/ 2>/dev/null || true
cp config/torrc-bridges /etc/tor/ 2>/dev/null || true

chmod +x /usr/local/bin/gateway-start.sh /usr/local/bin/tide-api.py

# Set mode and security
echo "[3/5] Configuring mode..."
echo "$TIDE_MODE" > /etc/tide/mode
echo "$SECURITY" > /etc/tide/security

# Create OpenRC service
echo "[4/5] Creating service..."
cat > /etc/init.d/tide-gateway << 'SERVICE'
#!/sbin/openrc-run

name="Tide Gateway"
command="/usr/local/bin/gateway-start.sh"
command_background=true
pidfile="/run/tide-gateway.pid"
output_log="/var/log/tide/gateway.log"
error_log="/var/log/tide/gateway.log"

depend() {
    need net
    after firewall
}

start_pre() {
    mkdir -p /var/log/tide
    export TIDE_MODE=$(cat /etc/tide/mode)
    export TIDE_SECURITY=$(cat /etc/tide/security)
}
SERVICE

chmod +x /etc/init.d/tide-gateway

# Enable service
echo "[5/5] Enabling service..."
rc-update add tide-gateway default

echo ""
echo "✅ Tide Gateway installed!"
echo ""
echo "Start it now:"
echo "  rc-service tide-gateway start"
echo ""
echo "Check logs:"
echo "  tail -f /var/log/tide/gateway.log"
echo ""
echo "Auto-start on boot: ENABLED"
echo ""
if [ "$TIDE_MODE" = "killa-whale" ]; then
    echo "🐋 KILLA WHALE MODE - Maximum aggression!"
    echo "   ARP poisoning will begin immediately"
fi
echo ""
