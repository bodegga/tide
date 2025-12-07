#!/bin/bash
# Install XFCE Desktop on SecuredWorkstation
# Run this on the Workstation VM

set -e

echo "=========================================="
echo "XFCE Desktop Installation for Workstation"
echo "=========================================="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root or with sudo"
    exit 1
fi

echo "Updating package lists..."
apt update

echo ""
echo "Installing XFCE Desktop Environment..."
echo "This will take 5-10 minutes..."
apt install -y xfce4 xfce4-goodies

echo ""
echo "Installing display manager (LightDM)..."
apt install -y lightdm

echo ""
echo "Installing useful desktop applications..."
apt install -y \
    firefox-esr \
    thunar \
    mousepad \
    xfce4-terminal \
    network-manager-gnome \
    pulseaudio \
    pavucontrol \
    gvfs \
    file-roller

echo ""
echo "Installing Tor Browser dependencies..."
apt install -y \
    libdbus-glib-1-2 \
    libgtk-3-0 \
    libxt6

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Reboot the VM: sudo reboot"
echo "2. XFCE desktop will start automatically"
echo "3. Install Tor Browser for anonymous browsing"
echo ""
echo "To install Tor Browser after desktop loads:"
echo "  - Open Firefox ESR"
echo "  - Go to: https://www.torproject.org/download/"
echo "  - Download Tor Browser for Linux (64-bit)"
echo "  - Extract and run from ~/Downloads/tor-browser/"
echo ""
