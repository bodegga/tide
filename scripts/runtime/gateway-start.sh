#!/bin/sh
# Tide Gateway Startup - Multi-mode support
# Supports: proxy, router, forced, takeover

set -e

echo "🌊 Starting Tide Gateway"

# Load configuration from environment or defaults
TIDE_MODE="${TIDE_MODE:-router}"
TIDE_SECURITY="${TIDE_SECURITY:-standard}"
TIDE_GATEWAY_IP="${TIDE_GATEWAY_IP:-10.101.101.10}"
TIDE_SUBNET="${TIDE_SUBNET:-10.101.101.0/24}"

echo "📋 Configuration:"
echo "   Mode: $TIDE_MODE"
echo "   Security: $TIDE_SECURITY"
echo "   Gateway IP: $TIDE_GATEWAY_IP"

# Save mode and security to /etc/tide for API
mkdir -p /etc/tide
echo "$TIDE_MODE" > /etc/tide/mode
echo "$TIDE_SECURITY" > /etc/tide/security

# Enable IP forwarding if needed
if [ "$TIDE_MODE" != "proxy" ]; then
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "⚠️  IP forwarding already enabled"
fi

# Disable IPv6 completely
echo "🚫 Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1 || true
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true

# Wait for network
sleep 2

# ============================================
# MODE: PROXY
# ============================================
if [ "$TIDE_MODE" = "proxy" ]; then
    echo "🔧 Mode: Proxy (SOCKS5 only)"
    echo "   No DHCP, no transparent routing"
    echo "   Clients must manually configure SOCKS5: $TIDE_GATEWAY_IP:9050"
    
    # No firewall rules needed for proxy mode
    
# ============================================
# MODE: ROUTER
# ============================================
elif [ "$TIDE_MODE" = "router" ]; then
    echo "🔧 Mode: Router (Transparent + DHCP)"
    
    # NAT rules for transparent proxy
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 9051 -j ACCEPT
    iptables -t nat -A PREROUTING -i eth0 -p tcp -j REDIRECT --to-ports 9040
    iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5353
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j REDIRECT --to-ports 5353
    iptables -t nat -A OUTPUT -m owner --uid-owner tor -j RETURN
    
    echo "✅ Transparent routing enabled"
    
    # Configure DHCP
    cat > /etc/dnsmasq.conf << EOF
interface=eth0
dhcp-range=${TIDE_DHCP_START:-10.101.101.100},${TIDE_DHCP_END:-10.101.101.200},12h
dhcp-option=3,$TIDE_GATEWAY_IP
dhcp-option=6,$TIDE_GATEWAY_IP
server=127.0.0.1#5353
no-resolv
log-queries
log-dhcp
EOF
    
    echo "🌐 Starting dnsmasq (DHCP + DNS)..."
    dnsmasq --no-daemon --log-facility=- &

# ============================================
# MODE: FORCED (Router + Fail-Closed)
# ============================================
elif [ "$TIDE_MODE" = "forced" ]; then
    echo "🔧 Mode: Forced (Fail-Closed Firewall)"
    echo "   If Tor dies, traffic is BLOCKED"
    
    # Load leak-proof iptables rules
    if [ -f /etc/tide/iptables-leak-proof.rules ]; then
        echo "🔒 Loading fail-closed firewall rules..."
        iptables-restore < /etc/tide/iptables-leak-proof.rules
        echo "✅ Fail-closed firewall active"
    else
        echo "⚠️  Leak-proof rules not found, applying inline..."
        
        # NAT rules
        iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 9051 -j ACCEPT
        iptables -t nat -A PREROUTING -i eth0 -p tcp -j REDIRECT --to-ports 9040
        iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5353
        iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j REDIRECT --to-ports 5353
        iptables -t nat -A OUTPUT -m owner --uid-owner tor -j RETURN
        
        # FILTER rules - Fail-closed
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT DROP
        
        # Allow loopback
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A OUTPUT -o lo -j ACCEPT
        
        # Allow established connections
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        
        # Allow clients to reach gateway services
        iptables -A INPUT -i eth0 -s ${TIDE_SUBNET} -p tcp -m multiport --dports 9040,9050,9051,22 -j ACCEPT
        iptables -A INPUT -i eth0 -s ${TIDE_SUBNET} -p udp --dport 53 -j ACCEPT
        iptables -A INPUT -i eth0 -s ${TIDE_SUBNET} -p udp --dport 67 -j ACCEPT
        iptables -A INPUT -i eth0 -s ${TIDE_SUBNET} -p icmp -j ACCEPT
        
        # ONLY Tor can talk to internet
        iptables -A OUTPUT -m owner --uid-owner tor -p tcp -j ACCEPT
        
        # Allow gateway to respond to clients
        iptables -A OUTPUT -o eth0 -d ${TIDE_SUBNET} -j ACCEPT
        
        # Allow DHCP and NTP (Tor needs accurate time)
        iptables -A OUTPUT -p udp --dport 67 -j ACCEPT
        iptables -A OUTPUT -p udp --dport 123 -m owner --uid-owner root -j ACCEPT
        
        echo "✅ Fail-closed firewall active (inline rules)"
    fi
    
    # Configure DHCP
    cat > /etc/dnsmasq.conf << EOF
interface=eth0
dhcp-range=${TIDE_DHCP_START:-10.101.101.100},${TIDE_DHCP_END:-10.101.101.200},12h
dhcp-option=3,$TIDE_GATEWAY_IP
dhcp-option=6,$TIDE_GATEWAY_IP
server=127.0.0.1#5353
no-resolv
log-queries
log-dhcp
EOF
    
    echo "🌐 Starting dnsmasq (DHCP + DNS)..."
    dnsmasq --no-daemon --log-facility=- &

# ============================================
# MODE: TAKEOVER (Forced + ARP Hijack)
# ============================================
elif [ "$TIDE_MODE" = "takeover" ]; then
    echo "🔧 Mode: Takeover (ARP Hijacking)"
    echo "⚠️  WARNING: This mode is NOT YET IMPLEMENTED"
    echo "   Falling back to Forced mode..."
    
    # TODO: Implement ARP hijacking
    # For now, just use forced mode
    TIDE_MODE=forced
    exec "$0"  # Re-run with forced mode

else
    echo "❌ Unknown mode: $TIDE_MODE"
    echo "   Valid modes: proxy, router, forced, takeover"
    exit 1
fi

# ============================================
# SECURITY PROFILES (Torrc Selection)
# ============================================
TORRC="/etc/tor/torrc"

case "$TIDE_SECURITY" in
    standard)
        echo "🔐 Security: Standard (default Tor settings)"
        # Use default torrc-gateway
        ;;
    hardened)
        echo "🔐 Security: Hardened (excluding 14-eyes countries)"
        if [ -f /etc/tor/torrc-hardened ]; then
            TORRC="/etc/tor/torrc-hardened"
        else
            echo "⚠️  torrc-hardened not found, using standard"
        fi
        ;;
    paranoid)
        echo "🔐 Security: Paranoid (maximum isolation)"
        if [ -f /etc/tor/torrc-paranoid ]; then
            TORRC="/etc/tor/torrc-paranoid"
        else
            echo "⚠️  torrc-paranoid not found, using standard"
        fi
        ;;
    bridges)
        echo "🔐 Security: Bridges (obfs4 for censorship bypass)"
        if [ -f /etc/tor/torrc-bridges ]; then
            TORRC="/etc/tor/torrc-bridges"
        else
            echo "⚠️  torrc-bridges not found, using standard"
        fi
        ;;
    *)
        echo "⚠️  Unknown security profile: $TIDE_SECURITY (using standard)"
        ;;
esac

# ============================================
# START SERVICES
# ============================================

# Start API server (all modes)
echo "🌐 Starting Tide API server (port 9051)..."
python3 /usr/local/bin/tide-api.py &

# Start Tor
echo "🔐 Starting Tor with config: $TORRC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exec tor -f "$TORRC"
