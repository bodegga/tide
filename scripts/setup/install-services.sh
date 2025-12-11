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

echo -e "${CYAN}[1/6] Installing nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt-get update -qq
    apt-get install -y nginx-light
    echo "  ✓ nginx installed"
else
    echo "  ✓ nginx already installed"
fi

echo ""
echo -e "${CYAN}[2/6] Configuring nginx...${NC}"
# Install nginx config
cp /opt/tide/config/nginx/tide-dashboard.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/tide-dashboard.conf /etc/nginx/sites-enabled/
# Remove default nginx site
rm -f /etc/nginx/sites-enabled/default
echo "  ✓ nginx configured"

# Test nginx config
if nginx -t 2>&1 | grep -q "successful"; then
    echo "  ✓ nginx config valid"
else
    echo -e "  ${RED}✗ nginx config invalid${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}[3/6] Installing systemd service files...${NC}"

# Install web dashboard service
cp /opt/tide/config/systemd/tide-web.service /etc/systemd/system/
echo "  ✓ tide-web.service"

# Install API service
cp /opt/tide/config/systemd/tide-api.service /etc/systemd/system/
echo "  ✓ tide-api.service"

echo ""
echo -e "${CYAN}[4/6] Reloading systemd...${NC}"
systemctl daemon-reload
echo "  ✓ Daemon reloaded"

echo ""
echo -e "${CYAN}[5/6] Enabling services...${NC}"
systemctl enable nginx.service
echo "  ✓ nginx enabled"

systemctl enable tide-web.service
echo "  ✓ tide-web enabled"

systemctl enable tide-api.service
echo "  ✓ tide-api enabled"

echo ""
echo -e "${CYAN}[6/6] Starting services...${NC}"

systemctl restart nginx.service
if systemctl is-active --quiet nginx.service; then
    echo -e "  ${GREEN}✓ nginx started${NC}"
else
    echo -e "  ${RED}✗ nginx failed to start${NC}"
    echo "  Check logs: journalctl -u nginx -n 50"
fi

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
echo -e "${CYAN}Checking status...${NC}"
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
echo "  • nginx (Reverse Proxy) - Port 80"
echo "  • tide-web (Web Dashboard) - Port 8080 (internal)"
echo "  • tide-api (API Server) - Port 9051"
echo ""
echo "Access dashboard:"
echo "  http://tide.bodegga.net (or http://10.101.101.10)"
echo ""
echo "Management commands:"
echo "  systemctl status nginx"
echo "  systemctl status tide-web"
echo "  systemctl restart tide-web"
echo "  journalctl -u tide-web -f"
echo ""
