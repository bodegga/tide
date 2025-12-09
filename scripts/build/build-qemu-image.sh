#!/bin/bash
set -e

# Build Tide Gateway image using QEMU + expect automation
# This creates a fully configured qcow2 that can be converted for any hypervisor

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

ALPINE_ISO="alpine-standard-3.21.2-aarch64.iso"
OUTPUT_IMG="tide-gateway-built.qcow2"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

echo "=========================================="
echo "   Tide Gateway - QEMU Image Builder"
echo "=========================================="

# Download Alpine if needed
if [ ! -f "$ALPINE_ISO" ]; then
    echo ">>> Downloading Alpine ISO..."
    curl -LO "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/$ALPINE_ISO"
fi

# Create fresh disk
echo ">>> Creating disk image..."
rm -f "$OUTPUT_IMG"
qemu-img create -f qcow2 "$OUTPUT_IMG" 2G

echo ">>> Starting automated install with expect..."
echo ">>> This will take 3-5 minutes..."

# Use expect to automate the install
expect << 'EXPECT_SCRIPT'
set timeout 300

# Start QEMU
spawn qemu-system-aarch64 \
    -name "Tide-Build" \
    -M virt -cpu cortex-a72 -m 1024 \
    -nographic \
    -drive if=virtio,file=tide-gateway-built.qcow2,format=qcow2 \
    -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
    -cdrom alpine-standard-3.21.2-aarch64.iso \
    -boot d \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0

# Wait for login prompt
expect {
    "localhost login:" { send "root\r" }
    timeout { puts "Timeout waiting for login"; exit 1 }
}

# At shell prompt
expect "localhost:~#"
sleep 1

# Setup network
send "setup-interfaces -a -r\r"
expect "localhost:~#"
send "ifup eth0\r"
expect "localhost:~#"
sleep 3

# Run setup-alpine with automated answers
send "setup-alpine\r"

# Keyboard
expect "keyboard layout"
send "us\r"
expect "variant"
send "us\r"

# Hostname
expect "hostname"
send "tide-gateway\r"

# Network interface
expect "interface"
send "eth0\r"
expect "Ip address"
send "dhcp\r"
expect "manual network"
send "no\r"

# Root password
expect "New password"
send "tide\r"
expect "Retype"
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

# Setup apk cache
expect "apk cache"
send "\r"

# User
expect "user"
send "no\r"

# SSH
expect "ssh server"
send "openssh\r"

# Disk
expect "disk"
send "vda\r"
expect "use it"
send "sys\r"
expect "Erase"
send "y\r"

# Wait for install to complete
expect {
    "Installation is complete" { puts "\n>>> Base install done" }
    "localhost:~#" { puts "\n>>> Install complete" }
    timeout { puts "Timeout during install"; exit 1 }
}

# Now install Tor and configure
send "mount /dev/vda3 /mnt\r"
expect "localhost:~#"

send "chroot /mnt apk add --no-cache tor iptables ip6tables\r"
expect "localhost:~#"

# Configure Tor
send "cat > /mnt/etc/tor/torrc << 'EOF'\r"
send "User tor\r"
send "DataDirectory /var/lib/tor\r"
send "SocksPort 0.0.0.0:9050\r"
send "DNSPort 0.0.0.0:5353\r"
send "TransPort 0.0.0.0:9040\r"
send "VirtualAddrNetworkIPv4 10.192.0.0/10\r"
send "AutomapHostsOnResolve 1\r"
send "Log notice syslog\r"
send "EOF\r"
expect "localhost:~#"

# Configure eth1 (LAN)
send "cat >> /mnt/etc/network/interfaces << 'EOF'\r"
send "\r"
send "auto eth1\r"
send "iface eth1 inet static\r"
send "    address 10.101.101.10\r"
send "    netmask 255.255.255.0\r"
send "EOF\r"
expect "localhost:~#"

# Configure sysctl
send "mkdir -p /mnt/etc/sysctl.d\r"
expect "localhost:~#"
send "echo 'net.ipv4.ip_forward = 1' > /mnt/etc/sysctl.d/tide.conf\r"
expect "localhost:~#"
send "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /mnt/etc/sysctl.d/tide.conf\r"
expect "localhost:~#"

# Configure iptables
send "mkdir -p /mnt/etc/iptables\r"
expect "localhost:~#"
send "cat > /mnt/etc/iptables/rules-save << 'EOF'\r"
send "*nat\r"
send ":PREROUTING ACCEPT \[0:0\]\r"
send ":INPUT ACCEPT \[0:0\]\r"
send ":OUTPUT ACCEPT \[0:0\]\r"
send ":POSTROUTING ACCEPT \[0:0\]\r"
send "-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353\r"
send "-A PREROUTING -i eth1 -p tcp --dport 53 -j REDIRECT --to-ports 5353\r"
send "-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040\r"
send "COMMIT\r"
send "*filter\r"
send ":INPUT DROP \[0:0\]\r"
send ":FORWARD DROP \[0:0\]\r"
send ":OUTPUT ACCEPT \[0:0\]\r"
send "-A INPUT -i lo -j ACCEPT\r"
send "-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\r"
send "-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT\r"
send "-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT\r"
send "-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT\r"
send "-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT\r"
send "-A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT\r"
send "COMMIT\r"
send "EOF\r"
expect "localhost:~#"

# Enable services
send "chroot /mnt rc-update add tor default\r"
expect "localhost:~#"
send "chroot /mnt rc-update add iptables default\r"
expect "localhost:~#"

# Create iptables loader
send "cat > /mnt/etc/local.d/iptables.start << 'EOF'\r"
send "#!/bin/sh\r"
send "iptables-restore < /etc/iptables/rules-save\r"
send "sysctl -p /etc/sysctl.d/tide.conf\r"
send "EOF\r"
expect "localhost:~#"
send "chmod +x /mnt/etc/local.d/iptables.start\r"
expect "localhost:~#"
send "chroot /mnt rc-update add local default\r"
expect "localhost:~#"

# Mark complete
send "echo 'Tide Gateway built' > /mnt/root/BUILD_COMPLETE\r"
expect "localhost:~#"

# Shutdown
send "umount /mnt\r"
expect "localhost:~#"
send "poweroff\r"

# Wait for QEMU to exit
expect eof
EXPECT_SCRIPT

echo ""
echo "=========================================="
echo "   Build Complete!"  
echo "=========================================="
echo ""
ls -lh "$OUTPUT_IMG"
echo ""
echo "Image ready: $OUTPUT_IMG"
echo "Login: root / tide"
echo "Gateway: 10.101.101.10"
