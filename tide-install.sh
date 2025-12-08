#!/bin/sh
# Tide Gateway - One-Command Installer
# =====================================
# Boot Alpine Linux ISO, login as root, then run:
#   wget -qO- tide.sh | sh
#   OR
#   wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
#
# This will install Alpine to disk and configure as Tor gateway.
# After reboot: Login root/tide, Gateway at 10.101.101.10

set -e

echo ""
echo "=========================================="
echo "   TIDE GATEWAY INSTALLER"  
echo "=========================================="
echo ""

# Verify we're in Alpine
if [ ! -f /etc/alpine-release ]; then
    echo "ERROR: Run this from Alpine Linux live environment"
    exit 1
fi

# Setup networking
echo ">>> Configuring network..."
cat > /tmp/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
cp /tmp/interfaces /etc/network/interfaces
rc-service networking restart 2>/dev/null || ifup eth0

# Wait for network
echo ">>> Waiting for network..."
for i in 1 2 3 4 5; do
    ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1 && break
    sleep 2
done

if ! ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1; then
    echo "ERROR: No network. Check your connection."
    exit 1
fi
echo ">>> Network OK"

# Find target disk
DISK=""
for d in /dev/sda /dev/vda /dev/nvme0n1; do
    [ -b "$d" ] && DISK="$d" && break
done
[ -z "$DISK" ] && echo "ERROR: No disk found" && exit 1
echo ">>> Target disk: $DISK"

# Confirm
echo ""
echo "WARNING: This will ERASE $DISK"
echo "Press Enter to continue or Ctrl-C to cancel..."
read dummy

# Install Alpine to disk
echo ">>> Installing Alpine to $DISK..."
export ERASE_DISKS="$DISK"

# Use setup-alpine with answers piped in
setup-alpine -q <<EOF
us
us
tide-gateway
eth0
dhcp
no
tide
tide
UTC
none
1
openssh
chrony
$DISK
sys
y
EOF

echo ""
echo ">>> Base system installed. Configuring Tide Gateway..."

# Mount installed system
if echo "$DISK" | grep -q nvme; then
    ROOT="${DISK}p3"
else
    ROOT="${DISK}3"
fi
mount "$ROOT" /mnt 2>/dev/null || mount "${DISK}2" /mnt

# Install Tor and iptables
echo ">>> Installing Tor..."
chroot /mnt apk add --no-cache tor iptables ip6tables

# Configure Tor
echo ">>> Configuring Tor..."
cat > /mnt/etc/tor/torrc <<'TORRC'
User tor
DataDirectory /var/lib/tor
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:5353
TransPort 0.0.0.0:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice syslog
TORRC

# Add eth1 (LAN) to network config
echo ">>> Configuring LAN interface..."
cat >> /mnt/etc/network/interfaces <<'NET'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
NET

# Sysctl for forwarding
mkdir -p /mnt/etc/sysctl.d
cat > /mnt/etc/sysctl.d/tide.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
SYSCTL

# IPTables rules
mkdir -p /mnt/etc/iptables
cat > /mnt/etc/iptables/rules-save <<'IPTABLES'
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
-A PREROUTING -i eth1 -p tcp --dport 53 -j REDIRECT --to-ports 5353
-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -s 10.101.101.0/24 -p udp --dport 5353 -j ACCEPT
-A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
COMMIT
IPTABLES

# Enable services
echo ">>> Enabling services..."
chroot /mnt rc-update add tor default
chroot /mnt rc-update add iptables default

# Create iptables loader
cat > /mnt/etc/local.d/iptables.start <<'IPTLOAD'
#!/bin/sh
iptables-restore < /etc/iptables/rules-save 2>/dev/null || true
sysctl -p /etc/sysctl.d/tide.conf 2>/dev/null || true
IPTLOAD
chmod +x /mnt/etc/local.d/iptables.start
chroot /mnt rc-update add local default

# Enable root SSH (already set by setup-alpine, but ensure it)
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config

# Done
echo "Tide Gateway installed $(date)" > /mnt/root/INSTALL_COMPLETE

sync
umount /mnt 2>/dev/null || true

echo ""
echo "=========================================="
echo "   INSTALLATION COMPLETE!"
echo "=========================================="
echo ""
echo "   1. Remove the ISO from the VM"
echo "   2. Reboot: reboot"
echo ""
echo "   Login:    root / tide"
echo "   Gateway:  10.101.101.10"
echo ""
echo "=========================================="
