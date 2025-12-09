#!/bin/sh
# Tide Gateway - One-Command Installer
# =====================================
# Boot Alpine Linux ISO (standard, NOT virt), login as root, then run:
#
#   wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
#
# This will install Alpine to disk and configure as Tor gateway.
# After reboot: Login root/tide, Gateway at 10.101.101.10
#
# Tested on: Parallels Desktop, UTM, VMware Fusion, VirtualBox
# Requires: Alpine Linux 3.20+ Standard ISO (ARM64 or x86_64)

set -e

echo ""
echo "=========================================="
echo "   🌊 TIDE GATEWAY INSTALLER"  
echo "=========================================="
echo ""

# Verify we're in Alpine live environment
if [ ! -f /etc/alpine-release ]; then
    echo "ERROR: Run this from Alpine Linux live environment"
    echo "       Boot the Alpine Standard ISO first!"
    exit 1
fi

ALPINE_VER=$(cat /etc/alpine-release)
echo ">>> Alpine version: $ALPINE_VER"

# Step 1: Setup networking (required to download packages)
echo ""
echo ">>> Step 1/6: Configuring network..."
setup-interfaces -a -r 2>/dev/null || {
    # Fallback: manual DHCP
    cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
    ifup eth0 2>/dev/null || true
}

# Wait for network with better feedback
echo ">>> Waiting for network..."
TRIES=0
while [ $TRIES -lt 10 ]; do
    if ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1; then
        echo ">>> Network OK!"
        break
    fi
    TRIES=$((TRIES + 1))
    echo "    Attempt $TRIES/10..."
    sleep 2
done

if ! ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1; then
    echo ""
    echo "ERROR: No network connection!"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check VM network adapter is set to 'Shared' or 'NAT'"
    echo "  2. Try: ifup eth0"
    echo "  3. Check: ip addr"
    exit 1
fi

# Step 2: Find and confirm target disk
echo ""
echo ">>> Step 2/6: Detecting disk..."

DISK=""
for d in /dev/sda /dev/vda /dev/nvme0n1 /dev/hda; do
    if [ -b "$d" ]; then
        DISK="$d"
        break
    fi
done

if [ -z "$DISK" ]; then
    echo "ERROR: No disk found!"
    echo "Available block devices:"
    ls -la /dev/sd* /dev/vd* /dev/nvme* /dev/hd* 2>/dev/null || echo "  (none)"
    exit 1
fi

DISK_SIZE=$(blockdev --getsize64 "$DISK" 2>/dev/null | awk '{printf "%.1f GB", $1/1024/1024/1024}')
echo ">>> Target disk: $DISK ($DISK_SIZE)"

echo ""
echo "⚠️  WARNING: This will ERASE ALL DATA on $DISK"
echo ""
printf "Type 'yes' to continue: "
read CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Step 3: Create answer file for setup-alpine
echo ""
echo ">>> Step 3/6: Installing Alpine base system..."

cat > /tmp/tide-answers <<EOF
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n tide-gateway"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys $DISK"
EOF

# Set root password before running setup-alpine
echo "root:tide" | chpasswd

# Run setup-alpine with answer file
export ERASE_DISKS="$DISK"
setup-alpine -e -f /tmp/tide-answers

echo ""
echo ">>> Base system installed!"

# Step 4: Mount and configure installed system
echo ""
echo ">>> Step 4/6: Configuring Tor gateway..."

# Determine root partition (Alpine uses partition 3 for sys mode on MBR, 2 on some setups)
if echo "$DISK" | grep -q nvme; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

# Try common partition layouts
MOUNTED=0
for PART in "${PART_PREFIX}3" "${PART_PREFIX}2" "${PART_PREFIX}1"; do
    if [ -b "$PART" ]; then
        if mount "$PART" /mnt 2>/dev/null; then
            if [ -f /mnt/etc/alpine-release ]; then
                echo ">>> Mounted root partition: $PART"
                MOUNTED=1
                break
            else
                umount /mnt 2>/dev/null || true
            fi
        fi
    fi
done

if [ $MOUNTED -eq 0 ]; then
    echo "ERROR: Could not mount installed system!"
    echo "Trying to find root partition..."
    lsblk -f 2>/dev/null || fdisk -l "$DISK"
    exit 1
fi

# Install packages in chroot
echo ">>> Installing Tor and iptables..."
chroot /mnt /bin/sh -c "apk update && apk add --no-cache tor iptables ip6tables"

# Configure Tor
echo ">>> Writing Tor configuration..."
cat > /mnt/etc/tor/torrc <<'TORRC'
# Tide Gateway - Tor Configuration
User tor
DataDirectory /var/lib/tor
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:5353
TransPort 0.0.0.0:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice syslog
TORRC

# Step 5: Configure LAN interface (eth1)
echo ""
echo ">>> Step 5/6: Configuring LAN interface..."

cat >> /mnt/etc/network/interfaces <<'NET'

# Tide Gateway LAN (connect client VMs here)
auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
NET

# Sysctl for IP forwarding and IPv6 disable
mkdir -p /mnt/etc/sysctl.d
cat > /mnt/etc/sysctl.d/tide.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
SYSCTL

# IPTables rules for transparent proxy
mkdir -p /mnt/etc/iptables
cat > /mnt/etc/iptables/rules-save <<'IPTABLES'
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# Redirect DNS to Tor
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
-A PREROUTING -i eth1 -p tcp --dport 53 -j REDIRECT --to-ports 5353
# Redirect all TCP to Tor transparent proxy
-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040
COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Allow loopback
-A INPUT -i lo -j ACCEPT
# Allow established connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Allow Tor services from LAN
-A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -s 10.101.101.0/24 -p udp --dport 5353 -j ACCEPT
# Allow SSH from LAN and WAN
-A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
COMMIT
IPTABLES

# Step 6: Enable services and finalize
echo ""
echo ">>> Step 6/6: Enabling services..."

chroot /mnt /bin/sh -c "rc-update add tor default"
chroot /mnt /bin/sh -c "rc-update add iptables default"
chroot /mnt /bin/sh -c "rc-update add local default"

# Create boot-time script to load iptables and sysctl
mkdir -p /mnt/etc/local.d
cat > /mnt/etc/local.d/tide-init.start <<'INIT'
#!/bin/sh
# Tide Gateway - Boot initialization
sysctl -p /etc/sysctl.d/tide.conf 2>/dev/null
iptables-restore < /etc/iptables/rules-save 2>/dev/null
# Log startup
echo "Tide Gateway started at $(date)" >> /var/log/tide.log
INIT
chmod +x /mnt/etc/local.d/tide-init.start

# Ensure root SSH is enabled
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config

# Create welcome message
cat > /mnt/etc/motd <<'MOTD'

  🌊 TIDE GATEWAY
  ═══════════════════════════════════════
  Gateway IP:  10.101.101.10
  Tor SOCKS:   10.101.101.10:9050
  Tor DNS:     10.101.101.10:5353

  Verify:  curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
  Status:  rc-service tor status
  ═══════════════════════════════════════

MOTD

# Mark installation complete
echo "Tide Gateway installed $(date)" > /mnt/root/INSTALL_COMPLETE
echo "Version: 1.2.0" >> /mnt/root/INSTALL_COMPLETE
echo "Installer: tide-install.sh" >> /mnt/root/INSTALL_COMPLETE

# Cleanup and sync
sync
umount /mnt 2>/dev/null || true

echo ""
echo "=========================================="
echo "   ✅ INSTALLATION COMPLETE!"
echo "=========================================="
echo ""
echo "   Next steps:"
echo "   1. Eject the ISO from the VM"
echo "   2. Add a second network adapter (Host-Only)"
echo "   3. Reboot: type 'reboot' and press Enter"
echo ""
echo "   After reboot:"
echo "   • Login:    root / tide"
echo "   • Gateway:  10.101.101.10"
echo ""
echo "   To test from a client VM:"
echo "   • Set gateway to 10.101.101.10"
echo "   • Set DNS to 10.101.101.10"
echo "   • Visit: https://check.torproject.org"
echo ""
echo "=========================================="
echo ""
