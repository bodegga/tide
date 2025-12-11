#!/bin/bash
# Install Tide Gateway systemd services
# Run this on the VM to enable web dashboard and API

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌊 Tide Gateway - Service Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Error: Must run as root${NC}"
   exit 1
fi

# Check if /opt/tide exists
if [ ! -d "/opt/tide" ]; then
    echo -e "${RED}Error: /opt/tide not found${NC}"
    echo "Are you on a Tide Gateway VM?"
    exit 1
fi

echo -e "${CYAN}[1/5] Installing systemd service files...${NC}"

# Install web dashboard service
cp /opt/tide/config/systemd/tide-web.service /etc/systemd/system/
echo "  ✓ tide-web.service"

# Install API service
cp /opt/tide/config/systemd/tide-api.service /etc/systemd/system/
echo "  ✓ tide-api.service"

echo ""
echo -e "${CYAN}[2/5] Reloading systemd...${NC}"
systemctl daemon-reload
echo "  ✓ Daemon reloaded"

echo ""
echo -e "${CYAN}[3/5] Enabling services...${NC}"
systemctl enable tide-web.service
echo "  ✓ tide-web enabled"

systemctl enable tide-api.service
echo "  ✓ tide-api enabled"

echo ""
echo -e "${CYAN}[4/5] Starting services...${NC}"

systemctl start tide-web.service
if systemctl is-active --quiet tide-web.service; then
    echo -e "  ${GREEN}✓ tide-web started${NC}"
else
    echo -e "  ${RED}✗ tide-web failed to start${NC}"
    echo "  Check logs: journalctl -u tide-web -n 50"
fi

systemctl start tide-api.service
if systemctl is-active --quiet tide-api.service; then
    echo -e "  ${GREEN}✓ tide-api started${NC}"
else
    echo -e "  ${RED}✗ tide-api failed to start${NC}"
    echo "  Check logs: journalctl -u tide-api -n 50"
fi

echo ""
echo -e "${CYAN}[5/5] Checking status...${NC}"
echo ""

systemctl status tide-web --no-pager | head -10
echo ""
systemctl status tide-api --no-pager | head -10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Installation complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Services installed:"
echo "  • tide-web (Web Dashboard) - http://localhost/"
echo "  • tide-api (API Server) - http://localhost:9051/status"
echo ""
echo "Management commands:"
echo "  systemctl status tide-web"
echo "  systemctl restart tide-web"
echo "  journalctl -u tide-web -f"
echo ""
