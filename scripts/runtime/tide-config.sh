#!/bin/sh
# Tide Gateway Configuration Tool
# Change mode and security profile on-the-fly (no redeploy needed)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CONFIG_DIR="/etc/tide"
MODE_FILE="$CONFIG_DIR/mode"
SECURITY_FILE="$CONFIG_DIR/security"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

show_header() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌊 TIDE GATEWAY CONFIGURATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

show_current() {
    echo -e "${CYAN}Current Configuration:${NC}"
    echo ""
    
    if [ -f "$MODE_FILE" ]; then
        CURRENT_MODE=$(cat "$MODE_FILE")
        echo -e "  Mode:     ${GREEN}$CURRENT_MODE${NC}"
    else
        echo -e "  Mode:     ${RED}not set${NC}"
        CURRENT_MODE="unknown"
    fi
    
    if [ -f "$SECURITY_FILE" ]; then
        CURRENT_SECURITY=$(cat "$SECURITY_FILE")
        echo -e "  Security: ${GREEN}$CURRENT_SECURITY${NC}"
    else
        echo -e "  Security: ${RED}not set${NC}"
        CURRENT_SECURITY="unknown"
    fi
    
    echo ""
}

select_mode() {
    echo -e "${YELLOW}Select Deployment Mode:${NC}"
    echo ""
    echo "  1) 🔌 proxy         - SOCKS5 only (manual client config)"
    echo "  2) 🌐 router        - DHCP + transparent proxy (auto-config)"
    echo "  3) 🐋 killa-whale   - Router + fail-closed + ARP ready (RECOMMENDED)"
    echo "  4) ☠️  takeover      - Killa Whale + active ARP hijacking (AGGRESSIVE)"
    echo ""
    echo -n "Choose mode [1-4]: "
    read -r MODE_CHOICE
    
    case "$MODE_CHOICE" in
        1) NEW_MODE="proxy" ;;
        2) NEW_MODE="router" ;;
        3) NEW_MODE="killa-whale" ;;
        4) NEW_MODE="takeover" ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    echo "$NEW_MODE" > "$MODE_FILE"
    echo -e "${GREEN}✓ Mode set to: $NEW_MODE${NC}"
    echo ""
}

select_security() {
    echo -e "${YELLOW}Select Security Profile:${NC}"
    echo ""
    echo "  1) 🔐 standard  - Default Tor settings (fastest)"
    echo "  2) 🛡️  hardened  - Exclude 14-eyes countries (balanced)"
    echo "  3) 🔒 paranoid  - Maximum isolation (slowest, highest privacy)"
    echo "  4) 🌉 bridges   - Use obfs4 bridges (censorship bypass)"
    echo ""
    echo -n "Choose profile [1-4]: "
    read -r SEC_CHOICE
    
    case "$SEC_CHOICE" in
        1) NEW_SECURITY="standard" ;;
        2) NEW_SECURITY="hardened" ;;
        3) NEW_SECURITY="paranoid" ;;
        4) NEW_SECURITY="bridges" ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    echo "$NEW_SECURITY" > "$SECURITY_FILE"
    echo -e "${GREEN}✓ Security set to: $NEW_SECURITY${NC}"
    echo ""
}

apply_changes() {
    echo -e "${YELLOW}Apply Changes:${NC}"
    echo ""
    echo "Changes will take effect after restarting services."
    echo ""
    echo "  1) Restart services now (recommended)"
    echo "  2) Reboot entire system"
    echo "  3) Manual restart later"
    echo ""
    echo -n "Choose action [1-3]: "
    read -r APPLY_CHOICE
    
    case "$APPLY_CHOICE" in
        1)
            echo ""
            echo -e "${CYAN}Restarting Tide services...${NC}"
            
            # Kill existing services
            killall -9 dnsmasq 2>/dev/null || true
            killall -9 tor 2>/dev/null || true
            killall -9 python3 2>/dev/null || true
            killall -f arp-poison 2>/dev/null || true
            killall -f network-scanner 2>/dev/null || true
            
            sleep 2
            
            # Restart via OpenRC if available
            if command -v rc-service >/dev/null 2>&1; then
                rc-service tide restart 2>/dev/null || {
                    echo -e "${YELLOW}⚠️  OpenRC service not found, starting manually...${NC}"
                    /usr/local/bin/gateway-start.sh &
                }
            else
                # Manual restart
                /usr/local/bin/gateway-start.sh &
            fi
            
            sleep 3
            echo -e "${GREEN}✓ Services restarted${NC}"
            echo ""
            echo "Run 'tide status' to verify"
            ;;
        2)
            echo ""
            echo -e "${CYAN}Rebooting system...${NC}"
            sleep 2
            reboot
            ;;
        3)
            echo ""
            echo -e "${YELLOW}Manual restart required.${NC}"
            echo ""
            echo "Run one of:"
            echo "  rc-service tide restart"
            echo "  /usr/local/bin/gateway-start.sh"
            echo "  reboot"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
}

quick_mode_switch() {
    # Quick mode switch without interactive menu
    MODE="$1"
    
    if [ -z "$MODE" ]; then
        echo "Usage: tide-config mode <proxy|router|killa-whale|takeover>"
        exit 1
    fi
    
    case "$MODE" in
        proxy|router|killa-whale|takeover)
            echo "$MODE" > "$MODE_FILE"
            echo -e "${GREEN}✓ Mode set to: $MODE${NC}"
            echo -e "${YELLOW}Restarting services...${NC}"
            
            killall -9 dnsmasq tor python3 2>/dev/null || true
            killall -f arp-poison network-scanner 2>/dev/null || true
            sleep 2
            /usr/local/bin/gateway-start.sh &
            
            echo -e "${GREEN}✓ Done. Run 'tide status' to verify${NC}"
            ;;
        *)
            echo -e "${RED}Invalid mode: $MODE${NC}"
            echo "Valid modes: proxy, router, killa-whale, takeover"
            exit 1
            ;;
    esac
}

quick_security_switch() {
    # Quick security switch without interactive menu
    PROFILE="$1"
    
    if [ -z "$PROFILE" ]; then
        echo "Usage: tide-config security <standard|hardened|paranoid|bridges>"
        exit 1
    fi
    
    case "$PROFILE" in
        standard|hardened|paranoid|bridges)
            echo "$PROFILE" > "$SECURITY_FILE"
            echo -e "${GREEN}✓ Security set to: $PROFILE${NC}"
            echo -e "${YELLOW}Restarting Tor...${NC}"
            
            killall -HUP tor 2>/dev/null || {
                killall -9 tor 2>/dev/null
                sleep 2
                /usr/local/bin/gateway-start.sh &
            }
            
            echo -e "${GREEN}✓ Done. Run 'tide check' to verify${NC}"
            ;;
        *)
            echo -e "${RED}Invalid security profile: $PROFILE${NC}"
            echo "Valid profiles: standard, hardened, paranoid, bridges"
            exit 1
            ;;
    esac
}

# Main menu
main_menu() {
    show_header
    show_current
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "What would you like to configure?"
    echo ""
    echo "  1) Change mode"
    echo "  2) Change security profile"
    echo "  3) Change both"
    echo "  4) Show current config"
    echo "  5) Exit"
    echo ""
    echo -n "Choose option [1-5]: "
    read -r MAIN_CHOICE
    
    echo ""
    
    case "$MAIN_CHOICE" in
        1)
            select_mode && apply_changes
            ;;
        2)
            select_security && apply_changes
            ;;
        3)
            select_mode && select_security && apply_changes
            ;;
        4)
            show_current
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Parse arguments
CMD="${1:-interactive}"

case "$CMD" in
    mode)
        quick_mode_switch "$2"
        ;;
    security)
        quick_security_switch "$2"
        ;;
    show|status)
        show_header
        show_current
        ;;
    interactive)
        main_menu
        ;;
    help|--help|-h)
        echo "Tide Gateway Configuration Tool"
        echo ""
        echo "Usage:"
        echo "  tide-config                          Interactive menu"
        echo "  tide-config mode <mode>              Quick mode switch"
        echo "  tide-config security <profile>       Quick security switch"
        echo "  tide-config show                     Show current config"
        echo ""
        echo "Modes:"
        echo "  proxy, router, killa-whale, takeover"
        echo ""
        echo "Security Profiles:"
        echo "  standard, hardened, paranoid, bridges"
        echo ""
        echo "Examples:"
        echo "  tide-config mode killa-whale"
        echo "  tide-config security hardened"
        ;;
    *)
        echo "Unknown command: $CMD"
        echo "Run 'tide-config help' for usage"
        exit 1
        ;;
esac
