#!/usr/bin/env bash
set -euo pipefail

# Tide Gateway: Build Universal Autoinstall ISO (ARM64)
# Uses Alpine's APKOVL feature to inject automated install on boot.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

BASE_ISO="alpine-virt-3.19.6-aarch64.iso"
WORKDIR="$(mktemp -d /tmp/tide-iso.XXXX)"
OVLDIR="$(mktemp -d /tmp/tide-ovl.XXXX)"
OUT_ISO="tide-autoinstall-efi.iso"

cleanup() {
  rm -rf "$WORKDIR" "$OVLDIR"
}
trap cleanup EXIT

if [[ ! -f "$BASE_ISO" ]]; then
  echo "ERROR: Base ISO not found: $BASE_ISO" >&2
  echo "Download from: https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/" >&2
  exit 1
fi

echo ">>> Extracting Base ISO..."
bsdtar -C "$WORKDIR" -xf "$BASE_ISO"
chmod -R u+w "$WORKDIR"

echo ">>> Building Autoinstall Overlay..."
mkdir -p "$OVLDIR/etc/local.d"
mkdir -p "$OVLDIR/etc/runlevels/default"
mkdir -p "$OVLDIR/root"

# Create answerfile for setup-alpine
cat > "$OVLDIR/root/answerfile" <<'ANSWERFILE'
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n tide-gateway"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
DNSOPTS=""
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1"
USEROPTS="-a -g 'audio video netdev' alpine"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys /dev/sda"
ANSWERFILE

# Create the Tide setup script (runs after base install)
cat > "$OVLDIR/root/setup-tide.sh" <<'SETUP'
#!/bin/sh
set -e
echo ">>> Installing Tor and iptables..."
apk add tor iptables ip6tables openssh

echo ">>> Configuring Tor..."
cat > /etc/tor/torrc <<'TOR'
User tor
DataDirectory /var/lib/tor
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:5353
TransPort 0.0.0.0:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice syslog
TOR

echo ">>> Configuring network (eth1 = LAN)..."
cat >> /etc/network/interfaces <<'NET'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
NET

echo ">>> Configuring sysctl..."
cat > /etc/sysctl.d/tor-gateway.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
SYSCTL

echo ">>> Configuring iptables..."
mkdir -p /etc/iptables
cat > /etc/iptables/rules-save <<'FW'
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
FW

echo ">>> Enabling services..."
rc-update add tor default
rc-update add iptables default
rc-update add sshd default

echo ">>> Setting root password to 'tide'..."
echo "root:tide" | chpasswd

echo ">>> Enabling root SSH login..."
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

echo ">>> Tide Gateway setup complete!"
SETUP
chmod +x "$OVLDIR/root/setup-tide.sh"

# Create the autoinstall trigger script
cat > "$OVLDIR/etc/local.d/tide-install.start" <<'EOF'
#!/bin/sh
exec >/dev/console 2>&1

# Only run in live environment
[ -f /etc/alpine-release ] || exit 0
[ ! -f /root/INSTALLED ] || exit 0

echo ""
echo "=========================================="
echo "   TIDE GATEWAY AUTO-INSTALLER"
echo "=========================================="
echo ""
sleep 2

# Setup networking
setup-interfaces -a -r
rc-service networking start || true

# Wait for network
sleep 3

echo ">>> Running setup-alpine..."
export ERASE_DISKS="/dev/sda"

# Run setup-alpine with answerfile
setup-alpine -f /root/answerfile <<'INPUT'
tide
tide
y
INPUT

if [ $? -eq 0 ]; then
    echo ">>> Base install complete. Configuring Tide..."
    
    # Mount installed system
    mount /dev/sda3 /mnt 2>/dev/null || mount /dev/sda2 /mnt
    
    # Copy and run setup script
    cp /root/setup-tide.sh /mnt/root/
    chroot /mnt /bin/sh /root/setup-tide.sh
    
    # Mark complete
    echo "Tide Gateway installed: $(date)" > /mnt/root/INSTALL_LOG
    touch /root/INSTALLED
    
    echo ""
    echo "=========================================="
    echo "   INSTALLATION COMPLETE!"
    echo "   System will shut down in 5 seconds..."
    echo "=========================================="
    sleep 5
    poweroff
else
    echo "!!! setup-alpine failed!"
fi
EOF
chmod +x "$OVLDIR/etc/local.d/tide-install.start"

# Enable local service
ln -sf /etc/init.d/local "$OVLDIR/etc/runlevels/default/local"

# Create the APKOVL tarball (Alpine's overlay format)
echo ">>> Creating APKOVL overlay..."
cd "$OVLDIR"
tar -czf "$WORKDIR/localhost.apkovl.tar.gz" --owner=0 --group=0 .
cd "$SCRIPT_DIR"

# Update GRUB config for autoinstall
echo ">>> Updating GRUB config..."
cat > "$WORKDIR/boot/grub/grub.cfg" <<'GRUB'
set timeout=3
set default=0

menuentry "Tide Gateway - Auto Install" {
    linux /boot/vmlinuz-virt modules=loop,squashfs,sd-mod,usb-storage quiet console=tty0 console=ttyAMA0
    initrd /boot/initramfs-virt
}
GRUB

# Repack ISO using xorriso for better compatibility
echo ">>> Repacking ISO..."
if command -v xorriso &>/dev/null; then
    xorriso -as mkisofs \
        -o "$OUT_ISO" \
        -R -J -joliet-long \
        -V "ALPINE" \
        -append_partition 2 0xef "$WORKDIR/boot/grub/efi.img" \
        -e --interval:appended_partition_2:all:: \
        -no-emul-boot -isohybrid-gpt-basdat \
        "$WORKDIR"
else
    # Fallback to mkisofs
    mkisofs \
        -o "$OUT_ISO" \
        -R -J -V "ALPINE" \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        "$WORKDIR"
fi

echo ""
echo ">>> Created: $OUT_ISO"
ls -lh "$OUT_ISO"
