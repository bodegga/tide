#!/bin/bash
# Build, install, test Tide Gateway - COMPLETE AUTOMATION

set -e

echo "🌊 TIDE GATEWAY - COMPLETE BUILD & TEST"
echo "========================================"
echo ""

# Step 1: Create expect script for automated Alpine install
cat > alpine-auto-install.exp << 'EOFEXPECT'
#!/usr/bin/expect -f
set timeout 300

spawn qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -smp 2 \
    -m 1024 \
    -nographic \
    -drive file=tide-gateway.qcow2,if=virtio,format=qcow2 \
    -cdrom alpine-virt-3.21.0-aarch64.iso \
    -boot d \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0

# Wait for login prompt
expect "login:"
send "root\r"

# Run setup-alpine
expect "#"
send "setup-alpine\r"

# Keyboard
expect "keyboard layout"
send "us\r"
expect "variant"
send "us\r"

# Hostname
expect "hostname"
send "tide\r"

# Network
expect "interface"
send "eth0\r"
expect "Ip address"
send "dhcp\r"
expect "gateway"
send "none\r"
expect "manual"
send "n\r"

# Password
expect "password"
send "tide\r"
expect "password"
send "tide\r"

# Timezone
expect "timezone"
send "UTC\r"

# Proxy
expect "proxy"
send "none\r"

# Mirror
expect "mirror"
send "1\r"

# SSH
expect "SSH"
send "openssh\r"

# Disk
expect "disk"
send "vda\r"
expect "use"
send "sys\r"
expect "Erase"
send "y\r"

# Wait for install to complete
expect "reboot"
send "reboot\r"

expect eof
EOFEXPECT

chmod +x alpine-auto-install.exp

echo "Step 1: Automated Alpine install script created"
echo "Step 2: You'll need to install expect: brew install expect"
echo "Step 3: Run: ./alpine-auto-install.exp"
echo ""
echo "For now, let's create the manual install guide..."

