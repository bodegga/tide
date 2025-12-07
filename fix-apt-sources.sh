#!/bin/bash
# Fix APT sources for Debian 12 (Bookworm)
# Removes cdrom entries and sets up proper Tor-friendly repos

set -e

echo "Backing up current sources.list..."
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d-%H%M%S)

echo "Creating clean sources.list for Debian 12 (Bookworm)..."
cat > /etc/apt/sources.list << 'APTEOF'
# Debian 12 (Bookworm) - Main repositories
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

# Security updates
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

# Updates
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware

# Backports (optional, disabled by default)
# deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
APTEOF

echo "Cleaning apt cache..."
apt clean

echo "Updating package lists..."
apt update

echo ""
echo "=========================================="
echo "APT sources fixed!"
echo "=========================================="
echo ""
echo "Backup saved to: /etc/apt/sources.list.backup.*"
echo "New sources.list configured for Debian 12 (Bookworm)"
echo ""
APTEOF

chmod +x /Users/abiasi/Documents/Personal-Projects/opsec-vm/fix-apt-sources.sh
curl --data-binary @/Users/abiasi/Documents/Personal-Projects/opsec-vm/fix-apt-sources.sh https://paste.rs
