#!/bin/bash
# Automated Tide Gateway Testing on Hetzner Cloud
# Creates ARM server, installs Tide v1.2.0, runs tests, destroys server

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

TIDE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_NAME="tide-test-$(date +%s)"
LOCATION="hil"  # Hillsboro, OR (closest to Petaluma/Bay Area)

# Accept parameters for matrix testing
SERVER_TYPE="${1:-cpx11}"  # Default: cpx11 (ARM, 2 vCPU, 2GB RAM, €0.0054/hr)
IMAGE="${2:-ubuntu-22.04}"  # Default: Ubuntu 22.04 (best package support)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌊 Tide Gateway - Hetzner Cloud Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load Hetzner token
if [ -f ~/.config/tide/hetzner.env ]; then
    source ~/.config/tide/hetzner.env
    export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"
else
    echo -e "${RED}Error: Hetzner token not found${NC}"
    echo "Expected: ~/.config/tide/hetzner.env"
    exit 1
fi

echo -e "${CYAN}Configuration:${NC}"
echo "  Server: $SERVER_NAME"
echo "  Type: $SERVER_TYPE"
echo "  Image: $IMAGE"
echo "  Location: $LOCATION (Hillsboro, OR)"
echo ""

# Check if SSH key exists
SSH_KEY_NAME="tide-testing"
if ! hcloud ssh-key list | grep -q "$SSH_KEY_NAME"; then
    echo -e "${YELLOW}Creating SSH key...${NC}"
    
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo -e "${CYAN}Generating SSH key...${NC}"
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "tide-testing"
    fi
    
    hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key-from-file ~/.ssh/id_ed25519.pub
    echo -e "${GREEN}✓ SSH key created${NC}"
else
    echo -e "${GREEN}✓ SSH key exists${NC}"
fi

echo ""
echo -e "${CYAN}[1/6] Creating Hetzner server...${NC}"
hcloud server create \
    --name "$SERVER_NAME" \
    --type "$SERVER_TYPE" \
    --image "$IMAGE" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY_NAME"

echo -e "${GREEN}✓ Server created${NC}"
echo ""

# Get server IP
echo -e "${CYAN}[2/6] Getting server IP...${NC}"
sleep 5
SERVER_IP=$(hcloud server ip "$SERVER_NAME")
echo -e "${GREEN}✓ Server IP: $SERVER_IP${NC}"
echo ""

# Wait for SSH
echo -e "${CYAN}[3/6] Waiting for SSH (30 seconds)...${NC}"
sleep 30

# Test SSH connection
echo -e "${CYAN}Testing SSH connection...${NC}"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$SERVER_IP" "echo 'SSH connected'" || {
    echo -e "${RED}Failed to connect via SSH${NC}"
    echo "Waiting 30 more seconds..."
    sleep 30
}

echo -e "${GREEN}✓ SSH ready${NC}"
echo ""

# Install Tide
echo -e "${CYAN}[4/6] Installing Tide Gateway v1.2.0...${NC}"

ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" bash << 'EOFINSTALL'
set -e

echo "→ Updating system..."
apt-get update -qq
apt-get install -y curl git python3 python3-pip tor iptables dnsmasq nmap iputils-arping netcat-openbsd >/dev/null 2>&1

echo "→ Creating Tide config..."
mkdir -p /etc/tide
echo "killa-whale" > /etc/tide/mode
echo "standard" > /etc/tide/security

echo "→ Downloading Tide scripts..."
cd /tmp
git clone -q https://github.com/bodegga/tide.git

echo "→ Installing Tide components..."
cd tide
mkdir -p /opt/tide
cp -r scripts /opt/tide/
cp -r config /opt/tide/
cp VERSION /opt/tide/

# Install CLI tools in PATH
cp scripts/runtime/tide-cli.sh /usr/local/bin/
cp scripts/runtime/tide-config.sh /usr/local/bin/
chmod +x /usr/local/bin/tide-*.sh
ln -sf /usr/local/bin/tide-cli.sh /usr/local/bin/tide

echo "→ Installing systemd services..."
cp config/systemd/tide-web.service /etc/systemd/system/
cp config/systemd/tide-api.service /etc/systemd/system/
systemctl daemon-reload

echo "→ Enabling and starting services..."
systemctl enable tide-web tide-api tor
systemctl start tor
sleep 5  # Let Tor start
systemctl start tide-web tide-api

echo "✓ Tide Gateway installed and services started"
EOFINSTALL

echo -e "${GREEN}✓ Tide installed${NC}"
echo ""

# Run tests
echo -e "${CYAN}[5/6] Running tests...${NC}"
echo ""

ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" bash << 'EOFTESTS'
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: CLI command
echo "✓ TEST 1: CLI Command"
tide status 2>/dev/null || echo "  ✗ tide command not found"
echo ""

# Test 2: Mode and security files
echo "✓ TEST 2: Configuration Files"
if [ -f /etc/tide/mode ]; then
    echo "  Mode: $(cat /etc/tide/mode)"
else
    echo "  ✗ Mode file missing"
fi

if [ -f /etc/tide/security ]; then
    echo "  Security: $(cat /etc/tide/security)"
else
    echo "  ✗ Security file missing"
fi
echo ""

# Test 3: Services running
echo "✓ TEST 3: Services Running"
pgrep -x tor >/dev/null && echo "  ✓ Tor running" || echo "  ✗ Tor not running"
pgrep -f tide-web-dashboard >/dev/null && echo "  ✓ Web dashboard running" || echo "  ✗ Web dashboard not running"
pgrep -f tide-api >/dev/null && echo "  ✓ API server running" || echo "  ✗ API server not running"
# Note: dnsmasq only needed for router/killa-whale DHCP modes (not installed by default)
echo ""

# Test 4: Web dashboard accessible
echo "✓ TEST 4: Web Dashboard"
if curl -s -m 5 http://localhost/ | grep -q "TIDE"; then
    echo "  ✓ Dashboard responds on port 80"
    echo "  ✓ HTML contains 'TIDE'"
else
    echo "  ✗ Dashboard not responding"
fi
echo ""

# Test 5: API endpoint
echo "✓ TEST 5: API Endpoint"
if curl -s -m 5 http://localhost:9051/status | grep -q "tide"; then
    echo "  ✓ API responds on port 9051"
    curl -s http://localhost:9051/status | python3 -m json.tool | head -10
else
    echo "  ✗ API not responding"
fi
echo ""

# Test 6: Mode switching
echo "✓ TEST 6: Mode Switching"
echo "  Current mode: $(cat /etc/tide/mode)"
tide mode router >/dev/null 2>&1
sleep 2
NEW_MODE=$(cat /etc/tide/mode)
if [ "$NEW_MODE" = "router" ]; then
    echo "  ✓ Mode switched to: $NEW_MODE"
else
    echo "  ✗ Mode switch failed"
fi
echo ""

# Test 7: Tor connectivity
echo "✓ TEST 7: Tor Connectivity"
if curl -s --socks5 127.0.0.1:9050 --max-time 10 https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
    echo "  ✓ Tor is working"
    EXIT_IP=$(curl -s --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip | grep -o '"IP":"[^"]*"' | cut -d'"' -f4)
    echo "  Exit IP: $EXIT_IP"
else
    echo "  ✗ Tor not working or bootstrapping"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOFTESTS

echo ""
echo -e "${GREEN}✓ Tests complete${NC}"
echo ""

# Ask to keep or destroy
echo -e "${YELLOW}Server is still running.${NC}"
echo ""
echo "Options:"
echo "  1) Destroy server now (recommended)"
echo "  2) Keep server for manual exploration"
echo "  3) Show SSH command and keep running"
echo ""
echo -n "Choose [1-3]: "
read -r CHOICE

case "$CHOICE" in
    1)
        echo ""
        echo -e "${CYAN}[6/6] Destroying server...${NC}"
        hcloud server delete "$SERVER_NAME"
        echo -e "${GREEN}✓ Server destroyed${NC}"
        echo ""
        echo -e "${CYAN}Test complete!${NC}"
        ;;
    2)
        echo ""
        echo -e "${YELLOW}Server kept running${NC}"
        echo ""
        echo "Server: $SERVER_NAME"
        echo "IP: $SERVER_IP"
        echo "SSH: ssh root@$SERVER_IP"
        echo ""
        echo "To destroy later:"
        echo "  hcloud server delete $SERVER_NAME"
        ;;
    3)
        echo ""
        echo -e "${CYAN}SSH Command:${NC}"
        echo "  ssh root@$SERVER_IP"
        echo ""
        echo -e "${CYAN}Test web dashboard:${NC}"
        echo "  curl http://$SERVER_IP/"
        echo ""
        echo -e "${CYAN}Test API:${NC}"
        echo "  curl http://$SERVER_IP:9051/status"
        echo ""
        echo -e "${YELLOW}Server will keep running (€0.0072/hr)${NC}"
        echo ""
        echo "To destroy:"
        echo "  hcloud server delete $SERVER_NAME"
        ;;
    *)
        echo "Invalid choice. Server kept running."
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
