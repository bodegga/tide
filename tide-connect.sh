#!/bin/bash
# Tide Client Configuration Script
# ================================
# Automates routing setup for machines connecting to Tide Gateway
#
# Usage: ./tide-connect.sh [gateway_ip]
#   gateway_ip: Optional, defaults to auto-discovery

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
GATEWAY_IP=""
SOCKS_PORT=9050
DNS_PORT=5353
API_PORT=9051

# Functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Discover gateway IP
discover_gateway() {
    log_info "Searching for Tide Gateway..."

    # Common IPs to check
    CANDIDATES=("10.101.101.1" "192.168.1.1" "192.168.0.1" "10.0.0.1")

    # Add default gateway if available
    if command -v ip >/dev/null 2>&1; then
        DEFAULT_GW=$(ip route | grep default | awk '{print $3}' | head -1)
        if [ -n "$DEFAULT_GW" ]; then
            CANDIDATES=("$DEFAULT_GW" "${CANDIDATES[@]}")
        fi
    elif command -v route >/dev/null 2>&1; then
        DEFAULT_GW=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}')
        if [ -n "$DEFAULT_GW" ]; then
            CANDIDATES=("$DEFAULT_GW" "${CANDIDATES[@]}")
        fi
    fi

    # Check each candidate
    for IP in "${CANDIDATES[@]}"; do
        if check_gateway "$IP"; then
            GATEWAY_IP="$IP"
            return 0
        fi
    done

    return 1
}

# Check if IP is Tide gateway
check_gateway() {
    local IP="$1"
    if curl -s --max-time 2 "http://$IP:$API_PORT/status" | grep -q '"gateway":"tide"'; then
        return 0
    fi
    return 1
}

# Configure system proxy
configure_proxy() {
    local ACTION="$1"

    case "$(uname -s)" in
        Darwin)
            configure_macos "$ACTION"
            ;;
        Linux)
            configure_linux "$ACTION"
            ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            return 1
            ;;
    esac
}

# macOS configuration
configure_macos() {
    local ACTION="$1"

    if [ "$ACTION" = "connect" ]; then
        log_info "Configuring macOS proxy settings..."

        # Get network services
        SERVICES=$(networksetup -listallnetworkservices | grep -v "*")

        for SERVICE in $SERVICES; do
            if networksetup -setsocksfirewallproxy "$SERVICE" "$GATEWAY_IP" "$SOCKS_PORT" >/dev/null 2>&1; then
                networksetup -setsocksfirewallproxystate "$SERVICE" on >/dev/null 2>&1
                log_success "Configured $SERVICE"
            fi
        done

        # Set DNS
        for SERVICE in $SERVICES; do
            if networksetup -setdnsservers "$SERVICE" "$GATEWAY_IP" >/dev/null 2>&1; then
                log_success "Set DNS for $SERVICE"
            fi
        done

    elif [ "$ACTION" = "disconnect" ]; then
        log_info "Removing macOS proxy settings..."

        SERVICES=$(networksetup -listallnetworkservices | grep -v "*")

        for SERVICE in $SERVICES; do
            networksetup -setsocksfirewallproxystate "$SERVICE" off >/dev/null 2>&1
            networksetup -setdnsservers "$SERVICE" Empty >/dev/null 2>&1
        done

        log_success "Disconnected"
    fi
}

# Linux configuration
configure_linux() {
    local ACTION="$1"

    if [ "$ACTION" = "connect" ]; then
        log_info "Configuring Linux proxy settings..."

        # Set environment variables
        export ALL_PROXY="socks5://$GATEWAY_IP:$SOCKS_PORT"
        export all_proxy="socks5://$GATEWAY_IP:$SOCKS_PORT"
        export SOCKS_PROXY="socks5://$GATEWAY_IP:$SOCKS_PORT"
        export socks_proxy="socks5://$GATEWAY_IP:$SOCKS_PORT"

        # Try to set system-wide proxy
        if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.gnome.system.proxy mode 'manual' 2>/dev/null || true
            gsettings set org.gnome.system.proxy.socks host "$GATEWAY_IP" 2>/dev/null || true
            gsettings set org.gnome.system.proxy.socks port "$SOCKS_PORT" 2>/dev/null || true
        fi

        # Set DNS in resolv.conf (backup original first)
        if [ ! -f /etc/resolv.conf.tide_backup ]; then
            cp /etc/resolv.conf /etc/resolv.conf.tide_backup
        fi
        echo "nameserver $GATEWAY_IP" | tee /etc/resolv.conf >/dev/null

        log_success "Connected (environment variables and DNS set)"

    elif [ "$ACTION" = "disconnect" ]; then
        log_info "Removing Linux proxy settings..."

        unset ALL_PROXY all_proxy SOCKS_PROXY socks_proxy

        if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.gnome.system.proxy mode 'none' 2>/dev/null || true
        fi

        # Restore DNS
        if [ -f /etc/resolv.conf.tide_backup ]; then
            mv /etc/resolv.conf.tide_backup /etc/resolv.conf
        fi

        log_success "Disconnected"
    fi
}

# Show status
show_status() {
    if [ -z "$GATEWAY_IP" ]; then
        log_error "No gateway configured"
        return 1
    fi

    log_info "Checking Tide Gateway status..."

    STATUS=$(curl -s --max-time 5 "http://$GATEWAY_IP:$API_PORT/status" 2>/dev/null || echo "{}")
    CIRCUIT=$(curl -s --max-time 10 "http://$GATEWAY_IP:$API_PORT/circuit" 2>/dev/null || echo "{}")

    echo "Gateway: $GATEWAY_IP"
    echo "Mode: $(echo "$STATUS" | grep -o '"mode":"[^"]*"' | cut -d'"' -f4)"
    echo "Security: $(echo "$STATUS" | grep -o '"security":"[^"]*"' | cut -d'"' -f4)"
    echo "Tor Status: $(echo "$STATUS" | grep -o '"tor":"[^"]*"' | cut -d'"' -f4)"
    echo "Exit IP: $(echo "$CIRCUIT" | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)"
}

# Main logic
main() {
    # Parse arguments
    if [ $# -gt 0 ]; then
        GATEWAY_IP="$1"
        if ! check_gateway "$GATEWAY_IP"; then
            log_error "Specified IP is not a Tide Gateway"
            exit 1
        fi
    else
        if ! discover_gateway; then
            log_error "Could not find Tide Gateway on network"
            log_info "Try: $0 <gateway_ip>"
            exit 1
        fi
    fi

    log_success "Found Tide Gateway: $GATEWAY_IP"

    # Show menu
    echo
    echo "Tide Client Configuration"
    echo "========================"
    echo "Gateway: $GATEWAY_IP"
    echo
    echo "1) Connect (set proxy and DNS)"
    echo "2) Disconnect (remove proxy and DNS)"
    echo "3) Status"
    echo "4) Exit"
    echo

    while true; do
        read -p "Choice: " CHOICE
        case $CHOICE in
            1)
                configure_proxy "connect"
                ;;
            2)
                configure_proxy "disconnect"
                ;;
            3)
                show_status
                ;;
            4)
                exit 0
                ;;
            *)
                log_warning "Invalid choice"
                ;;
        esac
        echo
    done
}

# Run main function
main "$@"