#!/bin/bash
# Create Golden Images for Fast Testing
# Run this monthly to keep snapshots updated with latest packages

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏗️  Creating Golden Images for Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This creates pre-configured VM snapshots for:"
echo "  1. Real Gateway (with NAT/routing)"
echo "  2. Tide Gateway (with Tor/arping)"
echo "  3. Victim Device (minimal)"
echo ""
echo "Cost: ~€0.10/month for storage"
echo "Benefit: Tests run in ~30 seconds instead of 6 minutes"
echo ""

# Load token
if [ -f ~/.config/tide/hetzner.env ]; then
    source ~/.config/tide/hetzner.env
    export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"
else
    echo "Error: Hetzner token not found"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d)

# Check if snapshots already exist
EXISTING_GW=$(hcloud image list -o noheader | grep "tide-golden-gateway" | awk '{print $1}' || echo "")
EXISTING_TIDE=$(hcloud image list -o noheader | grep "tide-golden-tide" | awk '{print $1}' || echo "")
EXISTING_VICTIM=$(hcloud image list -o noheader | grep "tide-golden-victim" | awk '{print $1}' || echo "")

if [ -n "$EXISTING_GW" ] || [ -n "$EXISTING_TIDE" ] || [ -n "$EXISTING_VICTIM" ]; then
    echo -e "${YELLOW}⚠️  Found existing golden images:${NC}"
    [ -n "$EXISTING_GW" ] && echo "  - tide-golden-gateway (ID: $EXISTING_GW)"
    [ -n "$EXISTING_TIDE" ] && echo "  - tide-golden-tide (ID: $EXISTING_TIDE)"
    [ -n "$EXISTING_VICTIM" ] && echo "  - tide-golden-victim (ID: $EXISTING_VICTIM)"
    echo ""
    read -p "Delete and recreate? [y/N]: " RECREATE
    if [ "$RECREATE" = "y" ] || [ "$RECREATE" = "Y" ]; then
        echo "Deleting old snapshots..."
        [ -n "$EXISTING_GW" ] && hcloud image delete "$EXISTING_GW"
        [ -n "$EXISTING_TIDE" ] && hcloud image delete "$EXISTING_TIDE"
        [ -n "$EXISTING_VICTIM" ] && hcloud image delete "$EXISTING_VICTIM"
        echo -e "${GREEN}✓ Old snapshots deleted${NC}"
    else
        echo "Keeping existing snapshots. Exiting."
        exit 0
    fi
fi

echo ""
echo -e "${CYAN}[1/6] Creating temporary VMs...${NC}"

# Cloud-init for gateway (FULL setup with all packages)
cat > /tmp/gateway-golden.yaml << 'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - iptables
  - dnsmasq
  - net-tools
runcmd:
  # Disable systemd-resolved (conflicts with dnsmasq)
  - systemctl stop systemd-resolved
  - systemctl disable systemd-resolved
  - echo "nameserver 8.8.8.8" > /etc/resolv.conf
  
  # Enable IP forwarding permanently
  - echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  - sysctl -p
  
  # Configure dnsmasq
  - |
    cat > /etc/dnsmasq.conf << 'DNSMASQ'
    interface=enp7s0
    dhcp-range=192.168.100.50,192.168.100.200,12h
    dhcp-option=3,192.168.100.1
    dhcp-option=6,8.8.8.8
    no-resolv
    server=8.8.8.8
    DNSMASQ
  - systemctl enable dnsmasq
  
  # Note: iptables rules will be added at test time (need actual interface)
  - touch /root/gateway-ready
EOF

# Cloud-init for Tide gateway (with Tide + Tor)
cat > /tmp/tide-golden.yaml << 'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - iputils-arping
  - tor
  - iptables
  - curl
  - git
  - python3
  - nginx-light
  - net-tools
  - nmap
  - netcat-openbsd
runcmd:
  # Enable IP forwarding permanently
  - echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  - sysctl -p
  
  # Install Tide
  - mkdir -p /opt/tide /etc/tide
  - echo "killa-whale" > /etc/tide/mode
  - echo "standard" > /etc/tide/security
  
  # Clone Tide repo
  - cd /tmp && git clone -q https://github.com/bodegga/tide.git
  - cd tide && cp -r scripts config VERSION /opt/tide/
  
  # Setup Tor
  - systemctl enable tor
  - systemctl start tor
  
  # Setup nginx (minimal config)
  - systemctl enable nginx
  
  - touch /root/tide-ready
EOF

# Cloud-init for victim (minimal - just tools needed for testing)
cat > /tmp/victim-golden.yaml << 'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - curl
  - net-tools
runcmd:
  - echo "nameserver 8.8.8.8" > /etc/resolv.conf
  - touch /root/victim-ready
EOF

echo "  Creating 3 temporary VMs..."

# Create VMs in parallel
hcloud server create --name golden-gateway-temp --type cx23 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --user-data-from-file /tmp/gateway-golden.yaml >/dev/null 2>&1 &

hcloud server create --name golden-tide-temp --type cx23 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --user-data-from-file /tmp/tide-golden.yaml >/dev/null 2>&1 &

hcloud server create --name golden-victim-temp --type cx23 --image ubuntu-22.04 --location hil \
    --ssh-key tide-testing --user-data-from-file /tmp/victim-golden.yaml >/dev/null 2>&1 &

wait
rm -f /tmp/gateway-golden.yaml /tmp/tide-golden.yaml /tmp/victim-golden.yaml

echo -e "${GREEN}✓ VMs created${NC}"

# Get IPs
GW_IP=$(hcloud server ip golden-gateway-temp)
TIDE_IP=$(hcloud server ip golden-tide-temp)
VICTIM_IP=$(hcloud server ip golden-victim-temp)

echo ""
echo -e "${CYAN}[2/6] Waiting for cloud-init to finish (this takes 2-3 minutes)...${NC}"
echo "  Gateway:  $GW_IP"
echo "  Tide:     $TIDE_IP"
echo "  Victim:   $VICTIM_IP"
echo ""

# Wait for cloud-init to complete on all VMs
for i in {1..60}; do
    GW_DONE=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$GW_IP" "test -f /root/gateway-ready && echo 1 || echo 0" 2>/dev/null || echo 0)
    TIDE_DONE=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$TIDE_IP" "test -f /root/tide-ready && echo 1 || echo 0" 2>/dev/null || echo 0)
    VICTIM_DONE=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@"$VICTIM_IP" "test -f /root/victim-ready && echo 1 || echo 0" 2>/dev/null || echo 0)
    
    if [ "$GW_DONE" = "1" ] && [ "$TIDE_DONE" = "1" ] && [ "$VICTIM_DONE" = "1" ]; then
        echo -e "${GREEN}✓ All VMs configured (took $((i*5)) seconds)${NC}"
        break
    fi
    
    # Show progress
    TOTAL=$((GW_DONE + TIDE_DONE + VICTIM_DONE))
    echo -n "  Progress: $TOTAL/3 ready..."
    echo -ne "\r"
    sleep 5
done

echo ""
echo -e "${CYAN}[3/6] Verifying installations...${NC}"

# Verify gateway
GW_CHECK=$(ssh -o StrictHostKeyChecking=no root@"$GW_IP" "which dnsmasq && echo OK" 2>/dev/null || echo "FAIL")
echo "  Gateway - dnsmasq: $GW_CHECK"

# Verify Tide
TIDE_CHECK=$(ssh -o StrictHostKeyChecking=no root@"$TIDE_IP" "which tor && which arping && test -d /opt/tide && echo OK" 2>/dev/null || echo "FAIL")
echo "  Tide - packages: $TIDE_CHECK"

# Verify victim
VICTIM_CHECK=$(ssh -o StrictHostKeyChecking=no root@"$VICTIM_IP" "which curl && echo OK" 2>/dev/null || echo "FAIL")
echo "  Victim - tools: $VICTIM_CHECK"

if [ "$GW_CHECK" != "OK" ] || [ "$TIDE_CHECK" != "OK" ] || [ "$VICTIM_CHECK" != "OK" ]; then
    echo -e "${YELLOW}⚠️  Some verifications failed. Continue anyway? [y/N]:${NC}"
    read -p "" CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        echo "Cleaning up and exiting..."
        hcloud server delete golden-gateway-temp golden-tide-temp golden-victim-temp 2>/dev/null
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}[4/6] Stopping VMs (required for snapshot)...${NC}"
hcloud server poweroff golden-gateway-temp >/dev/null 2>&1
hcloud server poweroff golden-tide-temp >/dev/null 2>&1
hcloud server poweroff golden-victim-temp >/dev/null 2>&1

# Wait for poweroff
sleep 10

echo -e "${GREEN}✓ VMs stopped${NC}"

echo ""
echo -e "${CYAN}[5/6] Creating snapshots (this takes 30-60 seconds)...${NC}"

# Create snapshots in parallel
hcloud server create-image --description "Tide Golden Gateway - $TIMESTAMP" \
    --type snapshot golden-gateway-temp -o noheader | awk '{print $2}' > /tmp/gw_snapshot_id &

hcloud server create-image --description "Tide Golden Tide - $TIMESTAMP" \
    --type snapshot golden-tide-temp -o noheader | awk '{print $2}' > /tmp/tide_snapshot_id &

hcloud server create-image --description "Tide Golden Victim - $TIMESTAMP" \
    --type snapshot golden-victim-temp -o noheader | awk '{print $2}' > /tmp/victim_snapshot_id &

wait
echo -e "${GREEN}✓ Snapshots created${NC}"

# Get snapshot IDs
GW_SNAPSHOT=$(cat /tmp/gw_snapshot_id 2>/dev/null || hcloud image list | grep "Tide Golden Gateway" | head -1 | awk '{print $1}')
TIDE_SNAPSHOT=$(cat /tmp/tide_snapshot_id 2>/dev/null || hcloud image list | grep "Tide Golden Tide" | head -1 | awk '{print $1}')
VICTIM_SNAPSHOT=$(cat /tmp/victim_snapshot_id 2>/dev/null || hcloud image list | grep "Tide Golden Victim" | head -1 | awk '{print $1}')

rm -f /tmp/gw_snapshot_id /tmp/tide_snapshot_id /tmp/victim_snapshot_id

# Label snapshots with consistent names
hcloud image update "$GW_SNAPSHOT" --label name=tide-golden-gateway >/dev/null 2>&1
hcloud image update "$TIDE_SNAPSHOT" --label name=tide-golden-tide >/dev/null 2>&1
hcloud image update "$VICTIM_SNAPSHOT" --label name=tide-golden-victim >/dev/null 2>&1

echo ""
echo -e "${CYAN}[6/6] Cleaning up temporary VMs...${NC}"
hcloud server delete golden-gateway-temp golden-tide-temp golden-victim-temp >/dev/null 2>&1
echo -e "${GREEN}✓ Temp VMs deleted${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Golden Images Created Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Snapshot IDs (save these):"
echo "  Gateway:  $GW_SNAPSHOT"
echo "  Tide:     $TIDE_SNAPSHOT"
echo "  Victim:   $VICTIM_SNAPSHOT"
echo ""

# Save to config file
mkdir -p ~/.config/tide
cat > ~/.config/tide/golden-images.env << EOF
# Golden Image Snapshot IDs
# Created: $(date)
# Last updated: $TIMESTAMP
GOLDEN_GATEWAY_ID=$GW_SNAPSHOT
GOLDEN_TIDE_ID=$TIDE_SNAPSHOT
GOLDEN_VICTIM_ID=$VICTIM_SNAPSHOT
EOF

echo "Saved to: ~/.config/tide/golden-images.env"
echo ""
echo "Storage cost: ~€0.10/month for all 3 snapshots"
echo "Test speed: ~30 seconds (vs 6 minutes with fresh VMs)"
echo ""
echo "Next steps:"
echo "  1. Run: ./test-killa-whale-snapshot.sh"
echo "  2. Re-run this script monthly to refresh images"
echo ""
echo "To delete snapshots later:"
echo "  hcloud image delete $GW_SNAPSHOT $TIDE_SNAPSHOT $VICTIM_SNAPSHOT"
echo ""
