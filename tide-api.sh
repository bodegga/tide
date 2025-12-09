#!/bin/sh
# ═══════════════════════════════════════════════════════════════
#   Tide API & Discovery Service
# ═══════════════════════════════════════════════════════════════
# Provides HTTP API for Tide Client auto-discovery and control.
# Runs on port 9051.
# ═══════════════════════════════════════════════════════════════

PORT=9051
FIFO="/tmp/tide-api.fifo"

# Cleanup
cleanup() {
    rm -f "$FIFO"
    exit 0
}
trap cleanup INT TERM

# Create FIFO for netcat
rm -f "$FIFO"
mkfifo "$FIFO"

log() {
    logger -t tide-api "$1"
}

# Get Tor status
tor_status() {
    if ! pgrep -x tor >/dev/null 2>&1; then
        echo "offline"
        return
    fi
    
    # Check bootstrap status
    if nc -z 127.0.0.1 9050 2>/dev/null; then
        echo "connected"
    else
        echo "bootstrapping"
    fi
}

# HTTP Response
respond() {
    CODE="$1"
    BODY="$2"
    LEN=$(printf '%s' "$BODY" | wc -c)
    printf 'HTTP/1.1 %s\r
Content-Type: application/json\r
Content-Length: %d\r
Access-Control-Allow-Origin: *\r
Connection: close\r
\r
%s' "$CODE" "$LEN" "$BODY"
}

# Handle request
handle() {
    read -r REQ
    PATH=$(echo "$REQ" | cut -d' ' -f2)
    
    case "$PATH" in
        /status)
            MODE=$(cat /etc/tide/mode 2>/dev/null || echo "unknown")
            SEC=$(cat /etc/tide/security 2>/dev/null || echo "standard")
            TOR=$(tor_status)
            UP=$(cut -d. -f1 /proc/uptime)
            
            respond "200 OK" "{\"gateway\":\"tide\",\"version\":\"1.0\",\"mode\":\"$MODE\",\"security\":\"$SEC\",\"tor\":\"$TOR\",\"uptime\":$UP,\"ip\":\"10.101.101.1\",\"ports\":{\"socks\":9050,\"dns\":5353,\"api\":$PORT}}"
            ;;
            
        /circuit)
            IP=$(curl -s --socks5 127.0.0.1:9050 --max-time 5 https://check.torproject.org/api/ip 2>/dev/null || echo '{"error":"timeout"}')
            respond "200 OK" "$IP"
            ;;
            
        /newcircuit)
            killall -HUP tor 2>/dev/null
            respond "200 OK" '{"success":true}'
            ;;
            
        /check)
            CHECK=$(curl -s --socks5 127.0.0.1:9050 --max-time 10 https://check.torproject.org/api/ip 2>/dev/null)
            if echo "$CHECK" | grep -q "IsTor.*true"; then
                respond "200 OK" "$CHECK"
            else
                respond "503 Service Unavailable" '{"IsTor":false}'
            fi
            ;;
            
        /discover|/)
            respond "200 OK" '{"service":"tide","version":"1.0"}'
            ;;
            
        *)
            respond "404 Not Found" '{"error":"not found"}'
            ;;
    esac
}

log "Starting on port $PORT"

# Main loop - simple HTTP server
while true; do
    cat "$FIFO" | nc -l -p $PORT > >(
        while read -r line; do
            echo "$line"
        done | handle
    ) > "$FIFO" 2>/dev/null
done
