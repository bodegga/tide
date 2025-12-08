#!/bin/sh
# Tide Gateway - Quick Setup Script
# Usage: wget -qO- https://.../setup-tide.sh | sh

echo ">>> Setting up Tide Gateway..."

# 1. Install Packages
apk update
apk add tor iptables ip6tables

# 2. Configure Tor
cat > /etc/tor/torrc <<'TOR'
User tor
DataDirectory /var/lib/tor
TransPort 0.0.0.0:9040
DNSPort 0.0.0.0:5353
SocksPort 0.0.0.0:9050
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
Log notice syslog
TOR

# 3. Configure Network (Static LAN on eth1)
# Note: Checks if eth1 exists first
if ip link show eth1 >/dev/null 2>&1; then
    cat >> /etc/network/interfaces <<'NET'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
NET
    echo ">>> Configured eth1 as LAN (10.101.101.10)"
else
    echo "!!! WARNING: eth1 not found. Please add a second network adapter!"
fi

# 4. Configure IPTables (Transparent Routing)
cat > /etc/iptables/rules.v4 <<'FW'
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
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
COMMIT
FW

# 5. Enable Services
rc-update add tor default
rc-update add iptables default
/etc/init.d/iptables save
service tor start
service iptables start
service networking restart

echo ">>> Tide Gateway Setup Complete."
echo ">>> Gateway IP: 10.101.101.10 (Ensure eth1 is connected to Host-Only network)"
