#!/bin/sh
# Update existing Tide Gateway to v1.2.0 with Web Dashboard
# Run this script on the Tide Gateway VM

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌊 Tide Gateway Update to v1.2.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will add:"
echo "  - Web dashboard (http://tide.bodegga.net)"
echo "  - Enhanced CLI tool (tide status, tide clients, etc.)"
echo "  - DNS hijacking for tide.bodegga.net"
echo "  - Network health monitoring"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root"
    exit 1
fi

# Backup existing files
echo "📦 Backing up existing configuration..."
mkdir -p /root/tide-backup-$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/root/tide-backup-$(date +%Y%m%d-%H%M%S)"

if [ -f /usr/local/bin/gateway-start.sh ]; then
    cp /usr/local/bin/gateway-start.sh "$BACKUP_DIR/"
fi
if [ -f /etc/dnsmasq.conf ]; then
    cp /etc/dnsmasq.conf "$BACKUP_DIR/"
fi

echo "✅ Backup saved to: $BACKUP_DIR"
echo ""

# Download new files from GitHub
echo "⬇️  Downloading new files from GitHub..."

BASE_URL="https://raw.githubusercontent.com/bodegga/tide/main/scripts/runtime"

# Web dashboard
echo "   - tide-web-dashboard.py"
wget -q -O /usr/local/bin/tide-web-dashboard.py \
    "${BASE_URL}/tide-web-dashboard.py" || {
    echo "❌ Failed to download tide-web-dashboard.py"
    exit 1
}
chmod +x /usr/local/bin/tide-web-dashboard.py

# CLI tool
echo "   - tide-cli.sh"
wget -q -O /usr/local/bin/tide-cli.sh \
    "${BASE_URL}/tide-cli.sh" || {
    echo "❌ Failed to download tide-cli.sh"
    exit 1
}
chmod +x /usr/local/bin/tide-cli.sh

# Updated gateway startup script
echo "   - gateway-start.sh (updated)"
wget -q -O /usr/local/bin/gateway-start.sh \
    "${BASE_URL}/gateway-start.sh" || {
    echo "❌ Failed to download gateway-start.sh"
    exit 1
}
chmod +x /usr/local/bin/gateway-start.sh

echo "✅ Files downloaded successfully"
echo ""

# Create CLI symlink
echo "🔗 Creating CLI symlink..."
ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide
echo "✅ CLI tool available as 'tide' command"
echo ""

# Install dependencies (if not already present)
echo "📦 Checking dependencies..."
apk add --no-cache python3 curl netcat-openbsd 2>/dev/null || echo "   Already installed"
echo ""

# Update version file
echo "1.2.0" > /etc/tide/version 2>/dev/null || {
    mkdir -p /etc/tide
    echo "1.2.0" > /etc/tide/version
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Update complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Next steps:"
echo ""
echo "1. Reboot the gateway to apply changes:"
echo "   reboot"
echo ""
echo "2. After reboot, test the CLI:"
echo "   tide status"
echo ""
echo "3. Access web dashboard from client device:"
echo "   http://tide.bodegga.net"
echo ""
echo "📋 New CLI commands:"
echo "   tide status     - Full gateway status"
echo "   tide check      - Test Tor connectivity"
echo "   tide circuit    - Show exit IP"
echo "   tide clients    - List connected clients"
echo "   tide arp        - ARP poisoning status"
echo "   tide web        - Dashboard URL"
echo "   tide help       - Show help"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
