#!/bin/sh
# Tide Gateway - First Boot Auto-Configuration
# =============================================
# This script runs ONCE on first boot to configure the gateway.
# After configuration, it removes itself from boot sequence.
#
# Place this at /etc/local.d/tide-firstboot.start on a fresh Alpine install.

MARKER="/root/.tide-configured"

# Skip if already configured
if [ -f "$MARKER" ]; then
    exit 0
fi

echo ">>> Tide Gateway: First boot configuration starting..."

# Wait for network
echo ">>> Waiting for network..."
for i in $(seq 1 30); do
    if ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

if ! ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1; then
    echo "!!! No network - will retry on next boot"
    exit 1
fi

echo ">>> Installing packages..."
apk update
apk add --no-cache tor iptables ip6tables

echo ">>> Configuring Tor..."
cat > /etc/tor/torrc <<'EOF'
User tor
DataDirectory /var/lib/tor
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:5353
TransPort 0.0.0.0:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice syslog
EOF

echo ">>> Configuring LAN interface..."
cat >> /etc/network/interfaces <<'EOF'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
EOF

echo ">>> Configuring sysctl..."
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/tide.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
EOF
sysctl -p /etc/sysctl.d/tide.conf

echo ">>> Configuring firewall..."
mkdir -p /etc/iptables
cat > /etc/iptables/rules-save <<'EOF'
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
EOF
iptables-restore < /etc/iptables/rules-save

echo ">>> Enabling services..."
rc-update add tor default
rc-update add iptables default
/etc/init.d/iptables save
rc-service tor start
ifup eth1 2>/dev/null || true

echo ">>> Setting MOTD..."
cat > /etc/motd <<'EOF'

  🌊 TIDE GATEWAY
  ═══════════════════════════════════════
  Gateway IP:  10.101.101.10
  Tor SOCKS5:  10.101.101.10:9050
  
  Status:  rc-service tor status
  ═══════════════════════════════════════

EOF

# Mark as configured
date > "$MARKER"
echo ">>> Tide Gateway configured!"

# Remove self from future boots
rm -f /etc/local.d/tide-firstboot.start
