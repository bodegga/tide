#!/bin/bash
set -euo pipefail

# ============================================================
# Tide Gateway - Custom Alpine ISO Builder
# ============================================================
# Uses Docker to build a custom Alpine ISO with Tide pre-configured.
# The resulting ISO boots directly into a working Tor gateway.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RELEASE_DIR="release"
ARCH="${1:-aarch64}"  # aarch64 or x86_64

echo "=========================================="
echo "   🌊 Tide Gateway - ISO Builder"
echo "   Architecture: $ARCH"
echo "=========================================="

mkdir -p "$RELEASE_DIR"

# Create the mkimg profile for Tide
cat > /tmp/mkimg.tide.sh << 'MKIMG'
profile_tide() {
    profile_base
    title="Tide Gateway"
    desc="Transparent Tor Gateway"
    arch="aarch64 x86_64"
    kernel_flavors="virt"
    kernel_cmdline="console=tty0 console=ttyS0,115200"
    apks="$apks tor iptables ip6tables openssh"
    apkovl="genapkovl-tide.sh"
}
MKIMG

# Create the overlay generator
cat > /tmp/genapkovl-tide.sh << 'OVERLAY'
#!/bin/sh

hostname="tide-gateway"
tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

makefile() {
    owner="$1"
    perms="$2"
    file="$3"
    install -Dm "$perms" -o "${owner%:*}" -g "${owner#*:}" /dev/stdin "$file"
}

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world << EOF
alpine-base
tor
iptables
ip6tables
openssh
EOF

# Network interfaces
mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOF

# Tor config
mkdir -p "$tmp"/etc/tor
makefile root:root 0644 "$tmp"/etc/tor/torrc << EOF
User tor
DataDirectory /var/lib/tor
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:5353
TransPort 0.0.0.0:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice syslog
EOF

# iptables rules
mkdir -p "$tmp"/etc/iptables
makefile root:root 0644 "$tmp"/etc/iptables/rules-save << EOF
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
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
COMMIT
EOF

# sysctl
mkdir -p "$tmp"/etc/sysctl.d
makefile root:root 0644 "$tmp"/etc/sysctl.d/tide.conf << EOF
net.ipv4.ip_forward=1
net.ipv6.conf.all.disable_ipv6=1
EOF

# Init script
mkdir -p "$tmp"/etc/local.d
makefile root:root 0755 "$tmp"/etc/local.d/tide.start << EOF
#!/bin/sh
echo 'root:tide' | chpasswd
sysctl -p /etc/sysctl.d/tide.conf
iptables-restore < /etc/iptables/rules-save
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
EOF

# Enable services
mkdir -p "$tmp"/etc/runlevels/default
ln -s /etc/init.d/tor "$tmp"/etc/runlevels/default/tor
ln -s /etc/init.d/iptables "$tmp"/etc/runlevels/default/iptables
ln -s /etc/init.d/sshd "$tmp"/etc/runlevels/default/sshd
ln -s /etc/init.d/local "$tmp"/etc/runlevels/default/local

# MOTD
makefile root:root 0644 "$tmp"/etc/motd << EOF

  🌊 TIDE GATEWAY
  Gateway: 10.101.101.10 | Login: root/tide

EOF

# Hostname
makefile root:root 0644 "$tmp"/etc/hostname << EOF
tide-gateway
EOF

# Create the tarball
tar -C "$tmp" -cvzf /tmp/tide.apkovl.tar.gz . >/dev/null 2>&1
echo "/tmp/tide.apkovl.tar.gz"
OVERLAY

chmod +x /tmp/genapkovl-tide.sh

echo ">>> Building ISO in Docker container..."

docker run --rm --platform linux/$ARCH \
    -v /tmp/mkimg.tide.sh:/aports/scripts/mkimg.tide.sh:ro \
    -v /tmp/genapkovl-tide.sh:/aports/scripts/genapkovl-tide.sh:ro \
    -v "$RELEASE_DIR":/out \
    alpine:3.21 sh -c '
        set -e
        apk add --no-cache alpine-sdk alpine-conf syslinux xorriso squashfs-tools grub grub-efi mtools git
        abuild-keygen -a -n
        git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git /aports-git
        cp /aports/scripts/mkimg.tide.sh /aports-git/scripts/
        cp /aports/scripts/genapkovl-tide.sh /aports-git/scripts/
        chmod +x /aports-git/scripts/genapkovl-tide.sh
        cd /aports-git/scripts
        sh mkimage.sh \
            --tag v3.21 \
            --outdir /out \
            --arch '"$ARCH"' \
            --repository https://dl-cdn.alpinelinux.org/alpine/v3.21/main \
            --repository https://dl-cdn.alpinelinux.org/alpine/v3.21/community \
            --profile tide
        echo "Done!"
    '

echo ""
echo "=========================================="
echo "   ✅ ISO BUILD COMPLETE"
echo "=========================================="
ls -lh "$RELEASE_DIR"/*.iso 2>/dev/null || echo "No ISO found"
echo ""
echo "Boot this ISO in any VM. Tide is pre-configured."
echo "Login: root/tide | Gateway: 10.101.101.10"
