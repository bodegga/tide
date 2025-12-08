#!/bin/bash
# Install Parallels Tools for clipboard sharing
# Fixed version for Debian ARM64

set -e

echo "=========================================="
echo "Parallels Tools Installation"
echo "=========================================="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root or with sudo"
    exit 1
fi

echo "Detecting kernel version..."
KERNEL_VERSION=$(uname -r)
echo "Running kernel: $KERNEL_VERSION"

echo ""
echo "Installing required packages..."
apt update

# Try to install kernel headers, fallback if not available
if apt-cache search linux-headers-${KERNEL_VERSION} | grep -q linux-headers; then
    apt install -y linux-headers-${KERNEL_VERSION}
else
    echo "WARNING: Exact kernel headers not found, installing generic headers..."
    apt install -y linux-headers-arm64 || apt install -y linux-headers-generic || true
fi

# Install build tools
apt install -y \
    build-essential \
    dkms \
    gcc \
    make \
    perl

echo ""
echo "Checking for Parallels Tools ISO..."

# Try different mount points
if [ -e /dev/cdrom ]; then
    CDROM_DEV=/dev/cdrom
elif [ -e /dev/sr0 ]; then
    CDROM_DEV=/dev/sr0
elif [ -e /dev/sr1 ]; then
    CDROM_DEV=/dev/sr1
else
    echo "ERROR: No CD-ROM device found!"
    echo "Make sure you mounted Parallels Tools from: Actions → Install Parallels Tools"
    exit 1
fi

echo "Found CD-ROM at: $CDROM_DEV"

mkdir -p /media/cdrom
mount $CDROM_DEV /media/cdrom 2>/dev/null || {
    echo "ERROR: Failed to mount CD-ROM"
    echo "Make sure Parallels Tools ISO is mounted from Parallels menu"
    exit 1
}

echo ""
echo "Running Parallels Tools installer..."
cd /media/cdrom

if [ -f ./install ]; then
    ./install --install-unattended-with-deps || {
        echo ""
        echo "Automated install failed. Trying manual install..."
        ./install
    }
else
    echo "ERROR: install script not found on CD-ROM"
    ls -la /media/cdrom
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Reboot for changes to take effect:"
echo "  sudo reboot"
echo ""
