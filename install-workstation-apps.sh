#!/bin/bash
# OPSEC VM Workstation - Application Installation Script
# Run this AFTER restoring from golden image snapshot
# Date: 2025-12-07

set -e

echo "=================================================="
echo "OPSEC Workstation - Installing Essential Apps"
echo "=================================================="
echo ""

# Update package lists
echo "[1/6] Updating package lists..."
sudo apt update

# Install text editors and development tools
echo ""
echo "[2/6] Installing text editors and development tools..."
sudo apt install -y \
    vim \
    nano \
    gedit \
    mousepad \
    git \
    curl \
    wget \
    tree \
    htop \
    neofetch

# Install Tor Browser (separate from system Tor)
echo ""
echo "[3/6] Installing Tor Browser..."
# Create tor-browser directory
mkdir -p ~/tor-browser
cd ~/tor-browser

# Download Tor Browser for Linux ARM64
# Note: You may need to check https://www.torproject.org/download/ for latest ARM64 version
echo "Downloading Tor Browser..."
wget -O tor-browser.tar.xz "https://www.torproject.org/dist/torbrowser/13.5.7/tor-browser-linux-arm64-13.5.7.tar.xz"

echo "Extracting Tor Browser..."
tar -xf tor-browser.tar.xz
rm tor-browser.tar.xz

# Create desktop shortcut
cat > ~/Desktop/tor-browser.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Tor Browser
Exec=/home/$USER/tor-browser/tor-browser/Browser/start-tor-browser
Icon=/home/$USER/tor-browser/tor-browser/Browser/browser/chrome/icons/default/default128.png
Terminal=false
Categories=Network;WebBrowser;
EOF
chmod +x ~/Desktop/tor-browser.desktop

cd ~

# Install communication tools
echo ""
echo "[4/6] Installing communication tools..."
sudo apt install -y \
    hexchat \
    pidgin \
    pidgin-otr

# Install crypto and security tools
echo ""
echo "[5/6] Installing crypto and security tools..."
sudo apt install -y \
    keepassxc \
    gnupg \
    kleopatra \
    veracrypt \
    qrencode \
    zbar-tools

# Install additional useful utilities
echo ""
echo "[6/6] Installing additional utilities..."
sudo apt install -y \
    libreoffice \
    vlc \
    gimp \
    scrot \
    transmission-gtk \
    remmina \
    gparted

echo ""
echo "=================================================="
echo "✅ Installation Complete!"
echo "=================================================="
echo ""
echo "Installed Applications:"
echo ""
echo "📝 TEXT EDITORS:"
echo "  - vim (terminal editor)"
echo "  - nano (simple terminal editor)"
echo "  - gedit (GUI text editor)"
echo "  - mousepad (lightweight GUI editor)"
echo ""
echo "🌐 WEB BROWSERS:"
echo "  - Firefox ESR (already installed)"
echo "  - Tor Browser (installed to ~/tor-browser/)"
echo "    → Desktop shortcut created"
echo ""
echo "💬 COMMUNICATION:"
echo "  - HexChat (IRC client)"
echo "  - Pidgin (multi-protocol messenger with OTR encryption)"
echo ""
echo "🔐 CRYPTO & SECURITY:"
echo "  - KeePassXC (password manager)"
echo "  - GnuPG / Kleopatra (PGP encryption)"
echo "  - VeraCrypt (disk encryption)"
echo "  - QR code tools (qrencode, zbar)"
echo ""
echo "🛠 DEVELOPMENT:"
echo "  - git"
echo "  - curl, wget"
echo "  - tree, htop"
echo ""
echo "📦 UTILITIES:"
echo "  - LibreOffice (office suite)"
echo "  - VLC (media player)"
echo "  - GIMP (image editor)"
echo "  - Transmission (torrent client)"
echo "  - Remmina (remote desktop)"
echo ""
echo "=================================================="
echo ""
echo "Next Steps:"
echo "1. Launch Tor Browser from Desktop shortcut or:"
echo "   ~/tor-browser/tor-browser/Browser/start-tor-browser"
echo ""
echo "2. Configure KeePassXC for password management"
echo ""
echo "3. Set up GPG keys:"
echo "   gpg --full-generate-key"
echo ""
echo "4. Verify Tor routing is working:"
echo "   curl https://check.torproject.org/api/ip"
echo ""
echo "=================================================="
