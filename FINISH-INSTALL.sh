#!/bin/sh
set -e

cd /root
git clone https://github.com/bodegga/tide.git
cd tide
chmod +x scripts/gateway-start.sh
cp scripts/gateway-start.sh /usr/local/bin/tide-gateway
mkdir -p /etc/tide

cat > /etc/tide/gateway.conf << 'EOFCONFIG'
MODE=killa-whale
INTERFACE=eth1
NETWORK=10.101.101.0/24
GATEWAY_IP=10.101.101.10
DNS_SERVER=8.8.8.8
TOR_TRANS_PORT=9040
TOR_DNS_PORT=5353
EOFCONFIG

cat > /etc/init.d/tide-gateway << 'EOFSERVICE'
#!/sbin/openrc-run

name="Tide Gateway"
description="Tide Tor Gateway (Killa Whale Mode)"
command="/usr/local/bin/tide-gateway"
command_background="yes"
pidfile="/run/tide-gateway.pid"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --mode 0755 /var/log/tide
}
EOFSERVICE

chmod +x /etc/init.d/tide-gateway
rc-update add tide-gateway default
rc-service tide-gateway start
rc-service tide-gateway status

echo "Done!"
