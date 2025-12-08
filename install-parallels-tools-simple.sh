#!/bin/bash
# Simplified Parallels Tools installation
# Works without kernel headers for basic clipboard support

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root or with sudo"
    exit 1
fi

echo "Installing basic dependencies..."
apt update
apt install -y build-essential gcc make perl

echo ""
echo "Mounting Parallels Tools CD..."
mkdir -p /mnt/cdrom

# Try different CD-ROM devices
for dev in /dev/cdrom /dev/sr0 /dev/sr1; do
    if [ -e "$dev" ]; then
        mount $dev /mnt/cdrom 2>/dev/null && break
    fi
done

if ! mountpoint -q /mnt/cdrom; then
    echo "ERROR: Could not mount Parallels Tools CD"
    echo "Make sure you selected: Actions → Install Parallels Tools"
    exit 1
fi

echo "Running Parallels Tools installer..."
cd /mnt/cdrom

# Run installer, skip kernel modules if they fail
./install --skip-rclocal-setup 2>&1 | tee /tmp/prl-install.log

echo ""
echo "Installation complete!"
echo "Reboot to enable clipboard sharing:"
echo "  sudo reboot"
