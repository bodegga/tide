# Type This Into Alpine Gateway

**After Alpine is installed and you've rebooted, login as root and type:**

```sh
cat > /tmp/s.sh << 'SCRIPT'
cat >> /etc/network/interfaces << 'NET'

auto eth1
iface eth1 inet static
    address 10.152.152.10
    netmask 255.255.255.0
NET
ifup eth1
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p
apk add tor iptables ip6tables
cat > /etc/tor/torrc << 'TOR'
SocksPort 10.152.152.10:9050
DNSPort 10.152.152.10:5353
TransPort 10.152.152.10:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
Log notice file /var/log/tor/notices.log
TOR
mkdir -p /var/log/tor
chown tor:tor /var/log/tor
chmod 700 /var/log/tor
cat > /etc/iptables/rules-save << 'FW'
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
-A INPUT -i eth1 -s 10.152.152.0/24 -p tcp -m multiport --dports 9050,9040,22,9051 -j ACCEPT
-A INPUT -i eth1 -s 10.152.152.0/24 -p udp --dport 5353 -j ACCEPT
COMMIT
FW
iptables-restore < /etc/iptables/rules-save
rc-update add tor
rc-update add iptables
rc-service tor start
tail -f /var/log/tor/notices.log
SCRIPT
sh /tmp/s.sh
```

That's it. One paste. Done.
