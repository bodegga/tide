#!/bin/sh
cd /root/tide
cp scripts/gateway-start.sh /usr/local/bin/tide-gateway
chmod +x /usr/local/bin/tide-gateway
mkdir -p /etc/tide
echo "MODE=killa-whale" > /etc/tide/gateway.conf
echo "INTERFACE=eth1" >> /etc/tide/gateway.conf
echo "NETWORK=10.101.101.0/24" >> /etc/tide/gateway.conf
echo "GATEWAY_IP=10.101.101.10" >> /etc/tide/gateway.conf
echo "DNS_SERVER=8.8.8.8" >> /etc/tide/gateway.conf
echo "TOR_TRANS_PORT=9040" >> /etc/tide/gateway.conf
echo "TOR_DNS_PORT=5353" >> /etc/tide/gateway.conf
cat > /etc/init.d/tide-gateway << 'EOFSVC'
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
EOFSVC
chmod +x /etc/init.d/tide-gateway
rc-update add tide-gateway default
rc-service tide-gateway start
rc-service tide-gateway status
echo "Done!"
