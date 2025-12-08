#!/bin/sh

# Tide Gateway - Universal "Brute Force" Installer
# ------------------------------------------------
# This script runs automatically from the ISO.
# It detects the target disk, wipes it, installs Alpine + Tor Gateway, and reboots.
# No prompts. No waiting.

exec >/dev/console 2>&1
set -x

echo "=========================================="
echo "   TIDE GATEWAY: UNIVERSAL INSTALLER      "
echo "=========================================="
sleep 3

# 1. Detect Target Disk (NVMe or VirtIO)
TARGET_DISK=""
for disk in /dev/vda /dev/sda /dev/nvme0n1; do
    if [ -b "$disk" ]; then
        TARGET_DISK="$disk"
        break
    fi
done

if [ -z "$TARGET_DISK" ]; then
    echo "!!! ERROR: No suitable target disk found (vda, sda, nvme0n1)."
    exit 1
fi

echo ">>> Target Disk Detected: $TARGET_DISK"
echo ">>> Wiping and Partitioning..."

# Ensure tools are present
apk add --no-cache e2fsprogs parted dosfstools util-linux

# Wipe partition table
dd if=/dev/zero of=$TARGET_DISK bs=1M count=10

# Create partitions:
# 1. EFI System Partition (100MB)
# 2. Swap (512MB)
# 3. Root (Remaining)
parted -s $TARGET_DISK mklabel gpt
parted -s $TARGET_DISK mkpart primary fat32 1MiB 101MiB
parted -s $TARGET_DISK set 1 esp on
parted -s $TARGET_DISK mkpart primary linux-swap 101MiB 613MiB
parted -s $TARGET_DISK mkpart primary ext4 613MiB 100%

# Wait for device nodes
mdev -s
sleep 2

# Identify partitions (handling nvme naming p1/p2 vs vda1/vda2)
if echo "$TARGET_DISK" | grep -q "nvme"; then
    PART_EFI="${TARGET_DISK}p1"
    PART_SWAP="${TARGET_DISK}p2"
    PART_ROOT="${TARGET_DISK}p3"
else
    PART_EFI="${TARGET_DISK}1"
    PART_SWAP="${TARGET_DISK}2"
    PART_ROOT="${TARGET_DISK}3"
fi

echo ">>> Formatting..."
mkfs.vfat -F32 "$PART_EFI"
mkswap "$PART_SWAP"
mkfs.ext4 -F "$PART_ROOT"

# Mount Target
mkdir -p /mnt
mount "$PART_ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$PART_EFI" /mnt/boot/efi

echo ">>> Installing System (Base + Tor + Kernel)..."
# Setup repositories
mkdir -p /mnt/etc/apk
echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/main" > /mnt/etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /mnt/etc/apk/repositories

# Install packages into /mnt
apk add --root /mnt --initdb --no-cache \
    alpine-base linux-virt mkinitfs \
    grub-efi efibootmgr \
    tor iptables ip6tables \
    openssh openrc \
    util-linux e2fsprogs

echo ">>> Configuring System..."

# 1. Bootloader (GRUB EFI)
# We need to install GRUB from within the chroot or using host tools mapped to target
# Doing it via chroot is safer for paths
mount -t proc /proc /mnt/proc
mount -t sysfs /sys /mnt/sys
mount -t devtmpfs /dev /mnt/dev

cat <<EOF > /mnt/install_boot.sh
#!/bin/sh
grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=alpine --recheck --no-nvram --removable
grub-mkconfig -o /boot/grub/grub.cfg
EOF
chmod +x /mnt/install_boot.sh
chroot /mnt /bin/sh /install_boot.sh

# 2. Network Configuration (Static 10.101.101.10)
cat <<EOF > /mnt/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOF

# 3. Services
# We can't use rc-update in chroot easily without openrc softlevel, so we link manually
ln -s /etc/init.d/networking /mnt/etc/runlevels/boot/networking
ln -s /etc/init.d/sshd /mnt/etc/runlevels/default/sshd
ln -s /etc/init.d/tor /mnt/etc/runlevels/default/tor
ln -s /etc/init.d/iptables /mnt/etc/runlevels/default/iptables

# 4. Tor Config
cat <<EOF > /mnt/etc/tor/torrc
User tor
DataDirectory /var/lib/tor

# Transparent Proxy (TransPort) for traffic
TransPort 0.0.0.0:9040
DNSPort 0.0.0.0:5353

# SOCKS5 Proxy
SocksPort 0.0.0.0:9050

# Circuit settings
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
EOF

# 5. IP Tables (Tide routing)
cat <<EOF > /mnt/etc/iptables/rules-save
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# Redirect DNS to Tor
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
-A PREROUTING -i eth1 -p tcp --dport 53 -j REDIRECT --to-ports 5353

# Redirect TCP traffic to Tor TransPort
-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040

# Masquerade outbound (if we allow non-Tor traffic, usually we don't for strict opsec)
# For now, we only pass through Tor.
COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback
-A INPUT -i lo -j ACCEPT

# Allow established
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow SSH from internal net
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT

# Allow DNS/TransPort inputs from internal net
-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT

COMMIT
EOF

# 6. User Setup (root:tide)
# Set root password to 'tide'
echo "root:tide" | chroot /mnt chpasswd
# Allow root login for now (convenience)
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config

# 7. fstab
UUID_ROOT=\$(blkid -s UUID -o value $PART_ROOT)
UUID_EFI=\$(blkid -s UUID -o value $PART_EFI)
UUID_SWAP=\$(blkid -s UUID -o value $PART_SWAP)

cat <<EOF > /mnt/etc/fstab
UUID=\$UUID_ROOT / ext4 rw,relatime 0 1
UUID=\$UUID_EFI /boot/efi vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2
UUID=\$UUID_SWAP none swap sw 0 0
EOF

# 8. Branding
echo "Tide Gateway v1.0" > /mnt/etc/issue

echo "=========================================="
echo "   INSTALLATION COMPLETE.                 "
echo "   Powering off in 5 seconds...           "
echo "=========================================="
sleep 5
poweroff
