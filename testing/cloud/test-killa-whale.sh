#!/bin/bash
# Test Killa Whale Mode - Validate ARP poisoning and traffic interception
# This test validates that killa-whale mode ACTUALLY works, not just that it's enabled

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

TIDE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_NAME="tide-kw-test-$(date +%s)"
VICTIM_NAME="tide-victim-$(date +%s)"
LOCATION="hil"  # Hillsboro, OR
SERVER_TYPE="${1:-cpx11}"
IMAGE="ubuntu-22.04"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 Tide Gateway - Killa Whale Mode Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This test validates that killa-whale mode actually:"
echo "  1. Performs ARP poisoning"
echo "  2. Intercepts traffic from other devices"
echo "  3. Forces ALL traffic through Tor"
echo "  4. Prevents direct internet access"
echo ""

# Load Hetzner token
if [ -f ~/.config/tide/hetzner.env ]; then
    source ~/.config/tide/hetzner.env
    export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"
else
    echo -e "${RED}Error: Hetzner token not found${NC}"
    exit 1
fi

echo -e "${CYAN}Configuration:${NC}"
echo "  Tide Gateway: $SERVER_NAME"
echo "  Victim Device: $VICTIM_NAME"
echo "  Network: Hetzner private network (simulates LAN)"
echo "  Location: $LOCATION (Hillsboro, OR)"
echo ""

# Check SSH key
SSH_KEY_NAME="tide-testing"
if ! hcloud ssh-key list | grep -q "$SSH_KEY_NAME"; then
    echo -e "${YELLOW}Creating SSH key...${NC}"
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "tide-testing"
    fi
    hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key-from-file ~/.ssh/id_ed25519.pub
fi

echo -e "${GREEN}✓ SSH key ready${NC}"
echo ""

# Create private network for testing
echo -e "${CYAN}[1/10] Creating private network...${NC}"
NETWORK_NAME="tide-test-net-$(date +%s)"
hcloud network create \
    --name "$NETWORK_NAME" \
    --ip-range 10.101.101.0/24

NETWORK_ID=$(hcloud network list | grep "$NETWORK_NAME" | awk '{print $1}')

hcloud network add-subnet "$NETWORK_ID" \
    --network-zone us-west \
    --type cloud \
    --ip-range 10.101.101.0/24

echo -e "${GREEN}✓ Private network created (10.101.101.0/24)${NC}"
echo ""

# Create Tide Gateway server
echo -e "${CYAN}[2/10] Creating Tide Gateway server...${NC}"
hcloud server create \
    --name "$SERVER_NAME" \
    --type "$SERVER_TYPE" \
    --image "$IMAGE" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY_NAME" \
    --network "$NETWORK_ID"

TIDE_IP=$(hcloud server ip "$SERVER_NAME")
echo -e "${GREEN}✓ Tide Gateway created: $TIDE_IP${NC}"
echo ""

# Create victim server
echo -e "${CYAN}[3/10] Creating victim device...${NC}"
hcloud server create \
    --name "$VICTIM_NAME" \
    --type cpx11 \
    --image "$IMAGE" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY_NAME" \
    --network "$NETWORK_ID"

VICTIM_IP=$(hcloud server ip "$VICTIM_NAME")
echo -e "${GREEN}✓ Victim device created: $VICTIM_IP${NC}"
echo ""

# Wait for SSH
echo -e "${CYAN}[4/10] Waiting for SSH (45 seconds)...${NC}"
sleep 45

# Install Tide Gateway
echo -e "${CYAN}[5/10] Installing Tide Gateway...${NC}"
ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" bash << 'EOFINSTALL'
set -e
apt-get update -qq
apt-get install -y curl git python3 tor iptables nmap iputils-arping netcat-openbsd nginx-light >/dev/null 2>&1

mkdir -p /etc/tide
echo "killa-whale" > /etc/tide/mode
echo "standard" > /etc/tide/security

cd /tmp
git clone -q https://github.com/bodegga/tide.git
cd tide
mkdir -p /opt/tide
cp -r scripts /opt/tide/
cp -r config /opt/tide/
cp VERSION /opt/tide/

# Install services
cp config/nginx/tide-dashboard.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/tide-dashboard.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

cp config/systemd/tide-web.service /etc/systemd/system/
cp config/systemd/tide-api.service /etc/systemd/system/
systemctl daemon-reload

systemctl enable nginx tide-web tide-api tor
systemctl start tor
sleep 5
systemctl restart nginx
systemctl start tide-web tide-api

echo "✓ Tide Gateway installed"
EOFINSTALL

echo -e "${GREEN}✓ Tide Gateway ready${NC}"
echo ""

# Setup victim device
echo -e "${CYAN}[6/10] Setting up victim device...${NC}"
ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" bash << 'EOFVICTIM'
set -e
apt-get update -qq
apt-get install -y curl tcpdump net-tools >/dev/null 2>&1

# Get private network IP
PRIVATE_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
echo "Private IP: $PRIVATE_IP"

# Check ARP table before attack
echo "ARP table before:"
arp -a

echo "✓ Victim device ready"
EOFVICTIM

echo -e "${GREEN}✓ Victim device ready${NC}"
echo ""

# Get private IPs
echo -e "${CYAN}[7/10] Getting private network IPs...${NC}"
TIDE_PRIVATE_IP=$(ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "ip addr show eth1 | grep 'inet ' | awk '{print \$2}' | cut -d'/' -f1")
VICTIM_PRIVATE_IP=$(ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "ip addr show eth1 | grep 'inet ' | awk '{print \$2}' | cut -d'/' -f1")

echo "  Tide Gateway: $TIDE_PRIVATE_IP (eth1)"
echo "  Victim Device: $VICTIM_PRIVATE_IP (eth1)"
echo ""

# Start killa-whale mode
echo -e "${CYAN}[8/10] Activating KILLA WHALE mode...${NC}"
ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" bash << EOFKW
set -e
cd /opt/tide/scripts/runtime
./arp-takeover.sh eth1 10.101.101.0/24 $TIDE_PRIVATE_IP > /tmp/arp-takeover.log 2>&1 &
sleep 10
echo "✓ ARP takeover initiated"
EOFKW

echo -e "${GREEN}✓ Killa Whale activated${NC}"
echo ""

# Run tests from victim
echo -e "${CYAN}[9/10] Running validation tests...${NC}"
echo ""

ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" bash << EOFTEST
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 KILLA WHALE COMPREHENSIVE VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Testing that killa-whale mode ACTUALLY:"
echo "  1. Poisons ARP cache"
echo "  2. Intercepts ALL traffic"
echo "  3. Forces traffic through Tor"
echo "  4. Blocks direct internet access"
echo "  5. Hijacks DNS"
echo "  6. Acts as default gateway"
echo ""

# Get victim's real public IP (before any interception)
echo "📍 Pre-test: Getting victim's real public IP..."
REAL_PUBLIC_IP=\$(curl -s --max-time 5 https://api.ipify.org || echo "unknown")
echo "  Victim's real public IP: \$REAL_PUBLIC_IP"
echo ""

# ============================================
# TEST 1: ARP Poisoning Validation
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: ARP Poisoning (Gateway Spoofing)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ARP Table (full):"
arp -a
echo ""

# Check if Tide's MAC is in ARP table for gateway
TIDE_MAC=\$(ssh -o StrictHostKeyChecking=no root@$TIDE_IP "ip link show eth1 | grep ether | awk '{print \\\$2}'")
echo "  Tide Gateway MAC: \$TIDE_MAC"

# Check what MAC the victim thinks the gateway is
GATEWAY_MAC=\$(arp -n | grep "10.101.101.1" | awk '{print \$3}')
echo "  Gateway ARP entry MAC: \$GATEWAY_MAC"

if [ "\$TIDE_MAC" = "\$GATEWAY_MAC" ]; then
    echo "  ✅ SUCCESS: Victim's ARP cache is poisoned!"
    echo "  ✅ Victim thinks Tide ($TIDE_PRIVATE_IP) is the gateway"
else
    echo "  ❌ FAIL: ARP poisoning not working"
    echo "  ❌ Gateway MAC doesn't match Tide's MAC"
fi
echo ""

# ============================================
# TEST 2: Default Gateway Detection
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: Default Gateway (Routing Table)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Victim's routing table:"
route -n
echo ""

DEFAULT_GW=\$(route -n | grep "^0.0.0.0" | awk '{print \$2}')
echo "  Default gateway IP: \$DEFAULT_GW"

if [ "\$DEFAULT_GW" = "10.101.101.1" ]; then
    echo "  ✅ SUCCESS: Gateway is 10.101.101.1 (expected)"
else
    echo "  ⚠️  WARNING: Gateway is \$DEFAULT_GW (expected 10.101.101.1)"
fi
echo ""

# ============================================
# TEST 3: DNS Hijacking
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: DNS Hijacking (tide.bodegga.net)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TIDE_DNS_RESULT=\$(nslookup tide.bodegga.net 2>&1 | grep "Address:" | tail -1 | awk '{print \$2}')
echo "  tide.bodegga.net resolves to: \$TIDE_DNS_RESULT"

if [ "\$TIDE_DNS_RESULT" = "$TIDE_PRIVATE_IP" ] || [ "\$TIDE_DNS_RESULT" = "10.101.101.10" ]; then
    echo "  ✅ SUCCESS: DNS hijacking works!"
else
    echo "  ⚠️  WARNING: DNS result doesn't match Tide IP"
fi
echo ""

# ============================================
# TEST 4: Transparent Proxy (HTTP Interception)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: Transparent HTTP Interception"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Attempting HTTP request WITHOUT SOCKS proxy config..."
echo "(If killa-whale works, this should be intercepted and routed through Tor)"
echo ""

# Try to reach check.torproject.org WITHOUT using SOCKS
TRANSPARENT_RESULT=\$(timeout 15 curl -s http://check.torproject.org/api/ip 2>&1)

if echo "\$TRANSPARENT_RESULT" | grep -q '"IsTor":true'; then
    TRANSPARENT_EXIT_IP=\$(echo "\$TRANSPARENT_RESULT" | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)
    echo "  ✅ SUCCESS: HTTP traffic transparently routed through Tor!"
    echo "  Exit IP: \$TRANSPARENT_EXIT_IP"
    echo "  (Real IP was: \$REAL_PUBLIC_IP)"
else
    echo "  ❌ FAIL: Transparent interception not working"
    echo "  Response: \$TRANSPARENT_RESULT"
fi
echo ""

# ============================================
# TEST 5: Direct Internet Access (Fail-Closed)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 5: Fail-Closed (Block Direct Access)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Testing if victim can bypass Tor and reach internet directly..."
echo "(Should be BLOCKED by killa-whale mode)"
echo ""

# Try multiple endpoints to ensure fail-closed
BLOCKED_COUNT=0
TOTAL_TESTS=0

for TEST_URL in "http://example.com" "https://google.com" "http://1.1.1.1" "http://api.ipify.org"; do
    TOTAL_TESTS=\$((TOTAL_TESTS + 1))
    echo -n "  Testing \$TEST_URL... "
    
    if timeout 5 curl -s --max-time 3 "\$TEST_URL" >/dev/null 2>&1; then
        echo "❌ ACCESSIBLE (BAD)"
    else
        echo "✅ BLOCKED (GOOD)"
        BLOCKED_COUNT=\$((BLOCKED_COUNT + 1))
    fi
done

echo ""
echo "  Results: \$BLOCKED_COUNT/\$TOTAL_TESTS endpoints blocked"

if [ \$BLOCKED_COUNT -eq \$TOTAL_TESTS ]; then
    echo "  ✅ SUCCESS: Fail-closed working (all direct access blocked)"
else
    echo "  ❌ FAIL: Some direct access still possible (leak detected)"
fi
echo ""

# ============================================
# TEST 6: DNS Leak Test
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 6: DNS Leak Prevention"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Checking if DNS queries leak outside Tor..."
echo ""

# Check DNS resolution for a test domain
echo "  Resolving google.com via system DNS..."
DNS_TEST=\$(timeout 5 nslookup google.com 2>&1 | grep "Server:" | awk '{print \$2}')
echo "  DNS server used: \$DNS_TEST"

if [ "\$DNS_TEST" = "$TIDE_PRIVATE_IP" ] || [ "\$DNS_TEST" = "10.101.101.10" ]; then
    echo "  ✅ SUCCESS: DNS queries go through Tide Gateway"
else
    echo "  ⚠️  WARNING: DNS might be leaking (server: \$DNS_TEST)"
fi
echo ""

# ============================================
# TEST 7: Traceroute First Hop
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 7: First Hop Validation (Traceroute)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Checking if first hop is Tide Gateway..."
echo ""

FIRST_HOP=\$(timeout 10 traceroute -m 3 -n 8.8.8.8 2>&1 | grep "^ 1" | awk '{print \$2}')
echo "  First hop: \$FIRST_HOP"

if [ "\$FIRST_HOP" = "$TIDE_PRIVATE_IP" ] || [ "\$FIRST_HOP" = "10.101.101.10" ]; then
    echo "  ✅ SUCCESS: All traffic goes through Tide first"
else
    echo "  ⚠️  WARNING: First hop is not Tide Gateway"
fi
echo ""

# ============================================
# TEST 8: SOCKS Proxy Confirmation
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 8: Explicit SOCKS Proxy (Baseline)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Confirming SOCKS proxy works (for comparison)..."
echo ""

if curl -s --socks5 $TIDE_PRIVATE_IP:9050 --max-time 15 https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
    SOCKS_EXIT_IP=\$(curl -s --socks5 $TIDE_PRIVATE_IP:9050 https://check.torproject.org/api/ip | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)
    echo "  ✅ SUCCESS: SOCKS proxy working"
    echo "  Tor exit IP: \$SOCKS_EXIT_IP"
else
    echo "  ❌ FAIL: SOCKS proxy not working"
fi
echo ""

# ============================================
# TEST 9: Packet Capture Analysis
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 9: Packet Capture (Traffic Flow)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Capturing packets to analyze traffic patterns..."
echo ""

# Start packet capture in background
timeout 10 tcpdump -i eth1 -c 20 -n port not 22 > /tmp/packet-capture.txt 2>&1 &
TCPDUMP_PID=\$!

# Generate some traffic
sleep 2
curl -s --max-time 5 http://example.com >/dev/null 2>&1 || true
sleep 2

# Wait for capture
wait \$TCPDUMP_PID 2>/dev/null || true

echo "  Captured packets:"
cat /tmp/packet-capture.txt | head -15
echo ""

# ============================================
# TEST 10: ARP Persistence Check
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 10: ARP Poisoning Persistence"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Waiting 15 seconds to see if ARP poisoning persists..."
sleep 15

TIDE_MAC_AFTER=\$(ssh -o StrictHostKeyChecking=no root@$TIDE_IP "ip link show eth1 | grep ether | awk '{print \\\$2}'")
GATEWAY_MAC_AFTER=\$(arp -n | grep "10.101.101.1" | awk '{print \$3}')

echo "  Tide MAC (after): \$TIDE_MAC_AFTER"
echo "  Gateway MAC (after): \$GATEWAY_MAC_AFTER"

if [ "\$TIDE_MAC_AFTER" = "\$GATEWAY_MAC_AFTER" ]; then
    echo "  ✅ SUCCESS: ARP poisoning persists over time"
else
    echo "  ❌ FAIL: ARP poisoning degraded"
fi
echo ""

# ============================================
# FINAL SUMMARY
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 KILLA WHALE MODE - TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Critical Requirements:"
echo "  1. ARP Poisoning: Check above for ✅/❌"
echo "  2. Transparent Proxy: Check TEST 4"
echo "  3. Fail-Closed: Check TEST 5 (\$BLOCKED_COUNT/\$TOTAL_TESTS blocked)"
echo "  4. DNS Hijacking: Check TEST 3"
echo "  5. Traffic Interception: Check TEST 7 (first hop)"
echo ""
echo "🎯 Killa Whale Goal: Force ALL traffic through Tor"
echo "   WITHOUT requiring client configuration"
echo ""

EOFTEST

echo ""
echo -e "${GREEN}✓ Tests complete${NC}"
echo ""

# Cleanup prompt
echo -e "${CYAN}[10/10] Cleanup${NC}"
echo ""
echo -e "${YELLOW}Servers are still running.${NC}"
echo ""
echo "Options:"
echo "  1) Destroy both servers now (recommended)"
echo "  2) Keep for manual exploration"
echo "  3) Show SSH commands and keep running"
echo ""
read -p "Choose [1-3]: " CHOICE

case $CHOICE in
    1)
        echo "Destroying servers..."
        hcloud server delete "$SERVER_NAME"
        hcloud server delete "$VICTIM_NAME"
        hcloud network delete "$NETWORK_ID"
        echo -e "${GREEN}✓ Cleanup complete${NC}"
        ;;
    2)
        echo "Keeping servers running."
        echo "Cost: ~\$0.01/hour"
        echo ""
        echo "Tide Gateway: ssh root@$TIDE_IP"
        echo "Victim Device: ssh root@$VICTIM_IP"
        echo ""
        echo "Manual cleanup:"
        echo "  hcloud server delete $SERVER_NAME"
        echo "  hcloud server delete $VICTIM_NAME"
        echo "  hcloud network delete $NETWORK_ID"
        ;;
    3)
        echo "SSH Commands:"
        echo "  Tide Gateway: ssh root@$TIDE_IP"
        echo "  Victim Device: ssh root@$VICTIM_IP"
        echo ""
        echo "Private network:"
        echo "  Tide: $TIDE_PRIVATE_IP (eth1)"
        echo "  Victim: $VICTIM_PRIVATE_IP (eth1)"
        echo ""
        echo "Manual cleanup:"
        echo "  hcloud server delete $SERVER_NAME"
        echo "  hcloud server delete $VICTIM_NAME"
        echo "  hcloud network delete $NETWORK_ID"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 Killa Whale Test Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
