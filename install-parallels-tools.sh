#!/bin/bash
# Install Parallels Tools for clipboard sharing
# Run this on BOTH Gateway and Workstation VMs

set -e

echo "=========================================="
echo "Parallels Tools Installation"
echo "=========================================="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root or with sudo"
    exit 1
fi

echo "BEFORE RUNNING THIS SCRIPT:"
echo "1. In Parallels menu bar: Actions → Install Parallels Tools"
echo "2. This will mount the tools ISO in the VM"
echo "3. Then run this script"
echo ""
read -p "Have you mounted Parallels Tools ISO? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. Mount the ISO first, then re-run this script."
    exit 1
fi

echo ""
echo "Installing required packages..."
apt update
apt install -y \
    build-essential \
    dkms \
    linux-headers-$(uname -r) \
    gcc \
    make \
    perl

echo ""
echo "Mounting Parallels Tools ISO..."
mkdir -p /media/cdrom
mount /dev/cdrom /media/cdrom 2>/dev/null || mount /dev/sr0 /media/cdrom

echo ""
echo "Running Parallels Tools installer..."
cd /media/cdrom
./install --install-unattended-with-deps

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Parallels Tools installed. Features enabled:"
echo "  - Clipboard sharing (copy/paste)"
echo "  - Drag and drop files"
echo "  - Shared folders"
echo "  - Dynamic resolution"
echo ""
echo "Reboot for changes to take effect:"
echo "  sudo reboot"
echo ""
