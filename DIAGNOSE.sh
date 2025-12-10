#!/bin/sh
echo "🔍 Tide Gateway Diagnostic"
echo ""

echo "Checking installed packages..."
which tor && echo "✅ tor installed" || echo "❌ tor MISSING"
which dnsmasq && echo "✅ dnsmasq installed" || echo "❌ dnsmasq MISSING"
which iptables && echo "✅ iptables installed" || echo "❌ iptables MISSING"
which arping && echo "✅ arping installed" || echo "❌ arping MISSING (install iputils)"
which nmap && echo "✅ nmap installed" || echo "❌ nmap MISSING"

echo ""
echo "Checking network interfaces..."
ip link show

echo ""
echo "Checking Tor config..."
if [ -f /etc/tor/torrc ]; then
    echo "✅ /etc/tor/torrc exists"
    head -5 /etc/tor/torrc
else
    echo "❌ /etc/tor/torrc MISSING"
fi

echo ""
echo "Checking /var/lib/tor directory..."
ls -la /var/lib/tor 2>/dev/null || echo "❌ /var/lib/tor doesn't exist - creating..."

echo ""
echo "Done!"
