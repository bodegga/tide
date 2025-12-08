#!/bin/sh
# This script runs inside the Alpine VM during image creation

# Install required packages
apk add --no-cache tor iptables ip6tables openssh

# Enable IP forwarding
cat >> /etc/sysctl.conf << 'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
SYSCTL

# Configure network - eth1 for host-only
cat >> /etc/network/interfaces << 'NETCONF'

auto eth1
iface eth1 inet static
    address 10.101.101.10
    netmask 255.255.255.0
NETCONF

# Configure Tor
cat > /etc/tor/torrc << 'TORRC'
# Tide Gateway - Tor Configuration
SocksPort 10.101.101.10:9050
DNSPort 10.101.101.10:5353
TransPort 10.101.101.10:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
Log notice file /var/log/tor/notices.log
ControlPort 10.101.101.10:9051
CookieAuthentication 1
TORRC

# Create Tor log directory
mkdir -p /var/log/tor
chown tor:tor /var/log/tor
chmod 700 /var/log/tor

# Configure iptables
cat > /etc/iptables/rules-save << 'IPTABLES'
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
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
-A INPUT -i eth1 -s 10.101.101.0/24 -p tcp --dport 9051 -j ACCEPT
-A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
COMMIT
IPTABLES

# Load iptables rules on boot
cat > /etc/local.d/iptables.start << 'SCRIPT'
#!/bin/sh
iptables-restore < /etc/iptables/rules-save
SCRIPT
chmod +x /etc/local.d/iptables.start

# Enable services
rc-update add tor default
rc-update add iptables default
rc-update add sshd default
rc-update add local default

# Set root password to 'tide'
echo "root:tide" | chpasswd

# Mark setup complete
echo "Tide Gateway configured on $(date)" > /root/SETUP_COMPLETE
