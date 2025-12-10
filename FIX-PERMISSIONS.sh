#!/bin/sh
echo "🔧 Fixing Tor permissions..."

# Create tor user if doesn't exist
adduser -D -H -s /sbin/nologin tor 2>/dev/null || echo "tor user already exists"

# Create and fix /var/lib/tor
mkdir -p /var/lib/tor
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor

# Fix torrc permissions
chmod 644 /etc/tor/torrc

echo "✅ Permissions fixed"
echo ""
echo "Now run: rc-service tide-gateway start"
