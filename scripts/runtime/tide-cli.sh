#!/bin/sh
# Tide Gateway CLI Tool
# Quick status and control commands

CMD="${1:-status}"

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

case "$CMD" in
    status)
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🌊 TIDE GATEWAY STATUS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Mode
        if [ -f /etc/tide/mode ]; then
            MODE=$(cat /etc/tide/mode)
            case "$MODE" in
                proxy) MODE_EMOJI="🔌" ;;
                router) MODE_EMOJI="🌐" ;;
                killa-whale) MODE_EMOJI="🐋" ;;
                takeover) MODE_EMOJI="☠️" ;;
                *) MODE_EMOJI="❓" ;;
            esac
            echo -e "${GREEN}Mode:${NC} $MODE_EMOJI $MODE"
        else
            echo -e "${RED}Mode:${NC} unknown"
        fi
        
        # Security Profile
        if [ -f /etc/tide/security ]; then
            SECURITY=$(cat /etc/tide/security)
            case "$SECURITY" in
                standard) SEC_EMOJI="🔐" ;;
                hardened) SEC_EMOJI="🛡️" ;;
                paranoid) SEC_EMOJI="🔒" ;;
                bridges) SEC_EMOJI="🌉" ;;
                *) SEC_EMOJI="🔐" ;;
            esac
            echo -e "${BLUE}Security:${NC} $SEC_EMOJI $SECURITY"
        fi
        
        # Tor Status
        if pgrep -x tor >/dev/null 2>&1; then
            if nc -z 127.0.0.1 9050 2>/dev/null; then
                echo -e "${GREEN}Tor:${NC} 🟢 connected"
            else
                echo -e "${YELLOW}Tor:${NC} 🟡 bootstrapping"
            fi
        else
            echo -e "${RED}Tor:${NC} 🔴 offline"
        fi
        
        # Uptime
        if [ -f /proc/uptime ]; then
            UPTIME_SEC=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
            UPTIME_HOURS=$((UPTIME_SEC / 3600))
            UPTIME_MINS=$(((UPTIME_SEC % 3600) / 60))
            echo -e "${CYAN}Uptime:${NC} ${UPTIME_HOURS}h ${UPTIME_MINS}m"
        fi
        
        # Gateway IP
        echo -e "${PURPLE}Gateway IP:${NC} 10.101.101.10"
        
        # Connected Clients
        if [ -f /var/lib/misc/dnsmasq.leases ]; then
            CLIENTS=$(wc -l < /var/lib/misc/dnsmasq.leases)
            echo -e "${GREEN}Clients:${NC} $CLIENTS connected"
        fi
        
        # ARP Poisoning (Killa Whale mode)
        if pgrep -f "arp-poison" >/dev/null 2>&1; then
            echo -e "${RED}ARP Poisoning:${NC} 🔥 ACTIVE"
        fi
        
        # Network Scanner
        if pgrep -f "network-scanner" >/dev/null 2>&1; then
            echo -e "${YELLOW}Network Scanner:${NC} 👁️  ACTIVE"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${CYAN}Dashboard:${NC} http://tide.bodegga.net"
        echo -e "${CYAN}API:${NC} http://10.101.101.10:9051/status"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ;;
    
    check)
        echo "🔍 Checking Tor connectivity..."
        RESULT=$(curl -s --socks5 127.0.0.1:9050 --max-time 10 https://check.torproject.org/api/ip)
        
        if echo "$RESULT" | grep -q '"IsTor":true'; then
            IP=$(echo "$RESULT" | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)
            COUNTRY=$(echo "$RESULT" | grep -o '"Country":"[^"]*"' | cut -d'"' -f4)
            echo -e "${GREEN}✅ Connected via Tor${NC}"
            echo -e "   Exit IP: $IP"
            echo -e "   Country: $COUNTRY"
        else
            echo -e "${RED}❌ Not connected via Tor${NC}"
            exit 1
        fi
        ;;
    
    circuit|ip)
        echo "🔍 Getting current Tor circuit info..."
        RESULT=$(curl -s --socks5 127.0.0.1:9050 --max-time 10 https://check.torproject.org/api/ip)
        
        if echo "$RESULT" | grep -q '"IsTor":true'; then
            IP=$(echo "$RESULT" | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)
            COUNTRY=$(echo "$RESULT" | grep -o '"Country":"[^"]*"' | cut -d'"' -f4)
            echo -e "${GREEN}Exit IP:${NC} $IP"
            echo -e "${GREEN}Country:${NC} $COUNTRY"
        else
            echo -e "${RED}Failed to get circuit info${NC}"
        fi
        ;;
    
    newcircuit|new)
        echo "🔄 Requesting new Tor circuit..."
        killall -HUP tor
        sleep 2
        echo "✅ New circuit requested"
        echo "   Run 'tide circuit' to verify new exit IP"
        ;;
    
    web|dashboard)
        echo "🌐 Opening web dashboard..."
        echo "   URL: http://tide.bodegga.net"
        echo "   or:  http://10.101.101.10"
        ;;
    
    clients)
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📱 CONNECTED CLIENTS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        if [ -f /var/lib/misc/dnsmasq.leases ]; then
            if [ -s /var/lib/misc/dnsmasq.leases ]; then
                echo ""
                awk '{printf "%-15s %-17s %s\n", $3, $2, $4}' /var/lib/misc/dnsmasq.leases | \
                    (echo "IP              MAC               HOSTNAME"; cat)
                echo ""
                TOTAL=$(wc -l < /var/lib/misc/dnsmasq.leases)
                echo "Total: $TOTAL client(s)"
            else
                echo ""
                echo "No clients currently connected"
            fi
        else
            echo ""
            echo "DHCP not active (proxy mode?)"
        fi
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ;;
    
    logs)
        echo "📜 Tide Gateway Logs (last 50 lines)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if [ -f /var/log/tor/notices.log ]; then
            tail -50 /var/log/tor/notices.log
        else
            echo "No Tor logs found"
        fi
        ;;
    
    arp)
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔥 ARP POISONING STATUS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        if pgrep -f "arp-poison" >/dev/null 2>&1; then
            echo -e "${RED}Status: ACTIVE${NC}"
            echo ""
            echo "Poisoning processes:"
            ps aux | grep -E "arp-poison|network-scanner" | grep -v grep
        else
            echo -e "${GREEN}Status: Inactive${NC}"
        fi
        
        echo ""
        echo "ARP Table:"
        arp -a
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ;;
    
    help|--help|-h)
        echo "🌊 Tide Gateway CLI"
        echo ""
        echo "Usage: tide <command>"
        echo ""
        echo "Commands:"
        echo "  status        Show gateway status (default)"
        echo "  check         Verify Tor connectivity"
        echo "  circuit       Show current Tor exit IP"
        echo "  newcircuit    Request new Tor circuit"
        echo "  web           Show dashboard URL"
        echo "  clients       List connected DHCP clients"
        echo "  logs          Show Tor logs"
        echo "  arp           Show ARP poisoning status"
        echo "  help          Show this help message"
        echo ""
        echo "Web Dashboard: http://tide.bodegga.net"
        echo "API Endpoint:  http://10.101.101.10:9051/status"
        ;;
    
    *)
        echo "Unknown command: $CMD"
        echo "Run 'tide help' for usage"
        exit 1
        ;;
esac
