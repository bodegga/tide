#!/bin/bash
# Make Tor Gateway configuration permanent
# Run this on Gateway VM as root

set -e

echo "Making Tor Gateway configuration permanent..."
echo ""

# 1. Save firewall rules
echo "1. Saving firewall rules to /etc/nftables.conf..."
curl -s https://paste.rs/Jse4z -o /etc/nftables.conf
chmod 644 /etc/nftables.conf

# 2. Enable nftables service
echo "2. Enabling nftables service..."
systemctl enable nftables

# 3. Make IP forwarding permanent
echo "3. Making IP forwarding permanent..."
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1

# 4. Ensure Tor starts on boot
echo "4. Ensuring Tor starts on boot..."
systemctl enable tor

# 5. Disable systemd-resolved (conflicts with Tor DNSPort 53)
echo "5. Disabling systemd-resolved..."
systemctl disable systemd-resolved
systemctl stop systemd-resolved 2>/dev/null || true

echo ""
echo "=========================================="
echo "Configuration now permanent!"
echo "=========================================="
echo ""
echo "Services enabled on boot:"
echo "  - nftables (firewall)"
echo "  - tor (Tor daemon)"
echo "  - IP forwarding"
echo ""
echo "Reboot to verify everything starts automatically:"
echo "  sudo reboot"
echo ""
