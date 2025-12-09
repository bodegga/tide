#!/bin/sh
# ═══════════════════════════════════════════════════════════════
#   🌊 TIDE - Transparent Internet Defense Engine
# ═══════════════════════════════════════════════════════════════
#
#   wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
#
# ═══════════════════════════════════════════════════════════════

set -e

# ═══════════════════════════════════════════════════════════════
# WELCOME SCREEN
# ═══════════════════════════════════════════════════════════════
clear
echo ""
echo "  ╔═══════════════════════════════════════════════════════════╗"
echo "  ║                                                           ║"
echo "  ║            🌊  T I D E   G A T E W A Y  🌊                ║"
echo "  ║                                                           ║"
echo "  ║        Transparent Internet Defense Engine                ║"
echo "  ║                                                           ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════
# MODE SELECTION
# ═══════════════════════════════════════════════════════════════
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  DEPLOYMENT MODE                                        │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  [1]  PROXY      - SOCKS5 + DNS only                    │"
echo "  │  [2]  ROUTER     - DHCP + DNS + transparent proxy       │"
echo "  │  [3]  FORCED     - Router + leak-proof firewall         │"
echo "  │  [4]  TAKEOVER   - Forced + ARP hijack ⚠️                │"
echo "  └─────────────────────────────────────────────────────────┘"
printf "  Select [1-4]: "
read MODE_NUM

case "$MODE_NUM" in
    1) TIDE_MODE="proxy" ;;
    2) TIDE_MODE="router" ;;
    3) TIDE_MODE="forced" ;;
    4) TIDE_MODE="takeover" ;;
    *) echo "Invalid"; exit 1 ;;
esac

# ═══════════════════════════════════════════════════════════════
# SECURITY PROFILE
# ═══════════════════════════════════════════════════════════════
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  SECURITY PROFILE                                       │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  [1]  STANDARD   - Default Tor settings                 │"
echo "  │  [2]  HARDENED   - Avoid 14-eyes, strict isolation      │"
echo "  │  [3]  PARANOID   - Maximum anonymity, slower            │"
echo "  │  [4]  BRIDGES    - Use bridges (anti-censorship)        │"
echo "  └─────────────────────────────────────────────────────────┘"
printf "  Select [1-4]: "
read SEC_NUM

case "$SEC_NUM" in
    1) SECURITY="standard" ;;
    2) SECURITY="hardened" ;;
    3) SECURITY="paranoid" ;;
    4) SECURITY="bridges" ;;
    *) SECURITY="standard" ;;
esac

# Bridge configuration
BRIDGE_ADDR=""
if [ "$SECURITY" = "bridges" ]; then
    echo ""
    echo "  Get bridges from: https://bridges.torproject.org"
    echo "  Or email: bridges@torproject.org"
    echo ""
    printf "  Enter bridge line (or press Enter to skip): "
    read BRIDGE_ADDR
fi

# ═══════════════════════════════════════════════════════════════
# ADDITIONAL OPTIONS
# ═══════════════════════════════════════════════════════════════
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  ADDITIONAL OPTIONS                                     │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  Enable hidden service (.onion) for SSH access?         │"
echo "  └─────────────────────────────────────────────────────────┘"
printf "  Enable SSH onion? [y/N]: "
read ONION_SSH
case "$ONION_SSH" in
    y|Y) ENABLE_ONION_SSH="yes" ;;
    *) ENABLE_ONION_SSH="no" ;;
esac

echo ""
echo "  ► Mode: $TIDE_MODE | Security: $SECURITY | Onion SSH: $ENABLE_ONION_SSH"
echo ""

# Verify Alpine
[ -f /etc/alpine-release ] || { echo "ERROR: Run from Alpine Linux"; exit 1; }

# ═══════════════════════════════════════════════════════════════
# PHASE 1: Network Bootstrap
# ═══════════════════════════════════════════════════════════════
echo "  [1/7] Bootstrapping network..."

setup-interfaces -a -r 2>/dev/null || {
    cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF
    ifup eth0 2>/dev/null || true
}

for i in $(seq 1 15); do
    ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1 && break
    sleep 2
done
ping -c1 -W2 dl-cdn.alpinelinux.org >/dev/null 2>&1 || { echo "ERROR: No network"; exit 1; }
echo "        Network OK"

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Disk Setup
# ═══════════════════════════════════════════════════════════════
echo "  [2/7] Detecting disk..."

DISK=""
for d in /dev/sda /dev/vda /dev/nvme0n1 /dev/hda; do
    [ -b "$d" ] && DISK="$d" && break
done
[ -z "$DISK" ] && { echo "ERROR: No disk found"; exit 1; }
echo "        Found: $DISK"

echo ""
echo "  ⚠️  WARNING: This will ERASE $DISK"
printf "  Type 'yes' to continue: "
read CONFIRM
[ "$CONFIRM" = "yes" ] || { echo "Aborted."; exit 1; }
echo ""

# ═══════════════════════════════════════════════════════════════
# PHASE 3: Alpine Installation
# ═══════════════════════════════════════════════════════════════
echo "  [3/7] Installing Alpine Linux..."

cat > /tmp/answers << EOF
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n tide"
INTERFACESOPTS="auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys $DISK"
EOF

echo "root:tide" | chpasswd
export ERASE_DISKS="$DISK"
setup-alpine -e -f /tmp/answers >/dev/null 2>&1

PART_PREFIX="$DISK"
echo "$DISK" | grep -q nvme && PART_PREFIX="${DISK}p"
for P in "${PART_PREFIX}3" "${PART_PREFIX}2"; do
    [ -b "$P" ] && mount "$P" /mnt 2>/dev/null && [ -f /mnt/etc/alpine-release ] && break
done

echo "        Alpine installed"

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Package Installation
# ═══════════════════════════════════════════════════════════════
echo "  [4/7] Installing packages..."

PKGS="tor iptables ip6tables curl"

case "$TIDE_MODE" in
    router|forced|takeover) PKGS="$PKGS dnsmasq" ;;
esac

case "$TIDE_MODE" in
    takeover) PKGS="$PKGS arping nmap" ;;
esac

# Bridges need obfs4proxy
case "$SECURITY" in
    bridges) PKGS="$PKGS obfs4proxy" ;;
esac

chroot /mnt sh -c "apk update >/dev/null && apk add --no-cache $PKGS >/dev/null 2>&1"
echo "        Packages installed"

# ═══════════════════════════════════════════════════════════════
# PHASE 5: Tor Configuration
# ═══════════════════════════════════════════════════════════════
echo "  [5/7] Configuring Tor ($SECURITY profile)..."

mkdir -p /mnt/etc/tor
mkdir -p /mnt/etc/tide

# Save config for runtime
echo "$TIDE_MODE" > /mnt/etc/tide/mode
echo "$SECURITY" > /mnt/etc/tide/security

# Base Tor config
cat > /mnt/etc/tor/torrc << 'EOF'
# Tide Gateway - Tor Configuration
User tor
DataDirectory /var/lib/tor
Log notice syslog

# Proxy ports
SocksPort 0.0.0.0:9050 IsolateClientAddr IsolateSOCKSAuth
DNSPort 0.0.0.0:5353
TransPort 0.0.0.0:9040 IsolateClientAddr

# Virtual addressing for .onion
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1

# Security defaults
SafeLogging 1
AvoidDiskWrites 1
EOF

# Add security profile settings
case "$SECURITY" in
    hardened)
        cat >> /mnt/etc/tor/torrc << 'EOF'

# === HARDENED PROFILE ===
# Avoid 14-eyes countries (US, UK, CA, AU, NZ, DK, FR, NL, NO, DE, BE, IT, ES, SE)
ExcludeNodes {us},{gb},{ca},{au},{nz},{dk},{fr},{nl},{no},{de},{be},{it},{es},{se}
ExcludeExitNodes {us},{gb},{ca},{au},{nz},{dk},{fr},{nl},{no},{de},{be},{it},{es},{se}
StrictNodes 1

# Enhanced isolation
IsolateDestAddr 1
IsolateDestPort 1

# Use distinct subnets
EnforceDistinctSubnets 1

# More guards
NumEntryGuards 4
NumPrimaryGuards 3
EOF
        ;;

    paranoid)
        cat >> /mnt/etc/tor/torrc << 'EOF'

# === PARANOID PROFILE ===
# Avoid 14-eyes + Russia, China, etc
ExcludeNodes {us},{gb},{ca},{au},{nz},{dk},{fr},{nl},{no},{de},{be},{it},{es},{se},{ru},{cn},{ir},{kp},{sy}
ExcludeExitNodes {us},{gb},{ca},{au},{nz},{dk},{fr},{nl},{no},{de},{be},{it},{es},{se},{ru},{cn},{ir},{kp},{sy}
StrictNodes 1

# Maximum isolation - every request gets new circuit
IsolateDestAddr 1
IsolateDestPort 1
IsolateClientAddr 1
IsolateSOCKSAuth 1

# Distinct subnets
EnforceDistinctSubnets 1

# Paranoid circuit settings
NewCircuitPeriod 15
MaxCircuitDirtiness 300

# More guards, faster rotation
NumEntryGuards 5
NumPrimaryGuards 4

# Don't cache
AvoidDiskWrites 1
EOF
        ;;

    bridges)
        cat >> /mnt/etc/tor/torrc << 'EOF'

# === BRIDGES PROFILE ===
UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
EOF
        if [ -n "$BRIDGE_ADDR" ]; then
            echo "Bridge $BRIDGE_ADDR" >> /mnt/etc/tor/torrc
        else
            cat >> /mnt/etc/tor/torrc << 'EOF'

# Add your bridges here:
# Bridge obfs4 <IP>:<PORT> <FINGERPRINT> cert=<CERT> iat-mode=0
# Get bridges: https://bridges.torproject.org
EOF
        fi
        ;;
esac

# Onion SSH service
if [ "$ENABLE_ONION_SSH" = "yes" ]; then
    mkdir -p /mnt/var/lib/tor/ssh_onion
    chroot /mnt chown -R tor:tor /var/lib/tor/ssh_onion
    cat >> /mnt/etc/tor/torrc << 'EOF'

# === SSH HIDDEN SERVICE ===
HiddenServiceDir /var/lib/tor/ssh_onion/
HiddenServicePort 22 127.0.0.1:22
EOF
fi

echo "        Tor configured ($SECURITY)"

# ═══════════════════════════════════════════════════════════════
# PHASE 6: Network & Security
# ═══════════════════════════════════════════════════════════════
echo "  [6/7] Configuring network & firewall..."

# Network interfaces
cat > /mnt/etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.101.101.1
    netmask 255.255.255.0
EOF

# Sysctl
mkdir -p /mnt/etc/sysctl.d
cat > /mnt/etc/sysctl.d/tide.conf << 'EOF'
net.ipv4.ip_forward=1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
EOF

# DNSMASQ (Router modes)
if [ "$TIDE_MODE" != "proxy" ]; then
cat > /mnt/etc/dnsmasq.conf << 'EOF'
interface=eth1
bind-interfaces
dhcp-range=10.101.101.100,10.101.101.200,255.255.255.0,1h
dhcp-option=option:router,10.101.101.1
dhcp-option=option:dns-server,10.101.101.1
server=127.0.0.1#5353
no-resolv
no-poll
bogus-priv
domain-needed
log-dhcp
EOF
fi

# IPTABLES
mkdir -p /mnt/etc/iptables

case "$TIDE_MODE" in
    proxy)
        cat > /mnt/etc/iptables/rules-save << 'EOF'
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9051 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p udp --sport 67 --dport 68 -j ACCEPT
COMMIT
EOF
        ;;

    router)
        cat > /mnt/etc/iptables/rules-save << 'EOF'
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -i eth1 -p tcp -j REDIRECT --to-ports 9040
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 53
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i eth1 -p udp --dport 67 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 53 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9051 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth1 -p icmp -j ACCEPT
-A INPUT -i eth0 -p udp --sport 67 --dport 68 -j ACCEPT
COMMIT
EOF
        ;;

    forced|takeover)
        cat > /mnt/etc/iptables/rules-save << 'EOF'
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -i eth1 -p tcp -j REDIRECT --to-ports 9040
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 53
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i eth1 -p udp --dport 67 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 53 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9051 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth1 -p icmp -j ACCEPT
-A INPUT -i eth0 -p udp --sport 67 --dport 68 -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -o eth0 -m owner --uid-owner tor -j ACCEPT
-A OUTPUT -o eth0 -p udp --dport 67 -j ACCEPT
-A OUTPUT -o eth0 -p udp --dport 123 -j ACCEPT
-A OUTPUT -o eth1 -j ACCEPT
COMMIT
EOF
        ;;
esac

# Takeover mode scripts
if [ "$TIDE_MODE" = "takeover" ]; then
cat > /mnt/etc/tide/takeover.sh << 'TAKEOVER'
#!/bin/sh
IFACE="eth1"
MY_IP="10.101.101.1"
logger "TIDE: Starting takeover"
echo 1 > /proc/sys/net/ipv4/conf/$IFACE/proxy_arp
(
    while true; do
        arping -U -c 3 -I $IFACE $MY_IP >/dev/null 2>&1
        sleep 5
    done
) &
echo $! > /var/run/tide-takeover.pid
TAKEOVER
chmod +x /mnt/etc/tide/takeover.sh

cat > /mnt/etc/tide/release.sh << 'RELEASE'
#!/bin/sh
[ -f /var/run/tide-takeover.pid ] && kill $(cat /var/run/tide-takeover.pid) 2>/dev/null
rm -f /var/run/tide-takeover.pid
echo 0 > /proc/sys/net/ipv4/conf/eth1/proxy_arp
logger "TIDE: Takeover released"
RELEASE
chmod +x /mnt/etc/tide/release.sh
fi

echo "        Network configured"

# ═══════════════════════════════════════════════════════════════
# PHASE 7: Finalize
# ═══════════════════════════════════════════════════════════════
echo "  [7/7] Finalizing..."

# Tide API service for client discovery
cat > /mnt/usr/local/bin/tide-api << 'TIDEAPI'
#!/bin/sh
# Tide API & Discovery Service - Port 9051
PORT=9051
FIFO="/tmp/tide-api.fifo"

cleanup() { rm -f "$FIFO"; exit 0; }
trap cleanup INT TERM

rm -f "$FIFO"
mkfifo "$FIFO"

tor_status() {
    if ! pgrep -x tor >/dev/null 2>&1; then echo "offline"; return; fi
    if nc -z 127.0.0.1 9050 2>/dev/null; then echo "connected"; else echo "bootstrapping"; fi
}

respond() {
    CODE="$1"; BODY="$2"; LEN=$(printf '%s' "$BODY" | wc -c)
    printf 'HTTP/1.1 %s\r
Content-Type: application/json\r
Content-Length: %d\r
Access-Control-Allow-Origin: *\r
Connection: close\r
\r
%s' "$CODE" "$LEN" "$BODY"
}

handle() {
    read -r REQ
    PATH=$(echo "$REQ" | cut -d' ' -f2)
    case "$PATH" in
        /status)
            MODE=$(cat /etc/tide/mode 2>/dev/null || echo "unknown")
            SEC=$(cat /etc/tide/security 2>/dev/null || echo "standard")
            TOR=$(tor_status)
            UP=$(cut -d. -f1 /proc/uptime)
            respond "200 OK" "{\"gateway\":\"tide\",\"version\":\"1.0\",\"mode\":\"$MODE\",\"security\":\"$SEC\",\"tor\":\"$TOR\",\"uptime\":$UP,\"ip\":\"10.101.101.1\",\"ports\":{\"socks\":9050,\"dns\":5353,\"api\":$PORT}}"
            ;;
        /circuit)
            IP=$(curl -s --socks5 127.0.0.1:9050 --max-time 5 https://check.torproject.org/api/ip 2>/dev/null || echo '{"error":"timeout"}')
            respond "200 OK" "$IP"
            ;;
        /newcircuit) killall -HUP tor 2>/dev/null; respond "200 OK" '{"success":true}' ;;
        /check)
            CHECK=$(curl -s --socks5 127.0.0.1:9050 --max-time 10 https://check.torproject.org/api/ip 2>/dev/null)
            if echo "$CHECK" | grep -q "IsTor.*true"; then respond "200 OK" "$CHECK"; else respond "503 Service Unavailable" '{"IsTor":false}'; fi
            ;;
        /discover|/) respond "200 OK" '{"service":"tide","version":"1.0"}' ;;
        *) respond "404 Not Found" '{"error":"not found"}' ;;
    esac
}

logger -t tide-api "Starting on port $PORT"
while true; do cat "$FIFO" | nc -l -p $PORT > >(while read -r line; do echo "$line"; done | handle) > "$FIFO" 2>/dev/null; done
TIDEAPI
chmod +x /mnt/usr/local/bin/tide-api

# Tide API init script
cat > /mnt/etc/init.d/tide-api << 'INITAPI'
#!/sbin/openrc-run
name="Tide API"
description="Tide Gateway Discovery API"
command="/usr/local/bin/tide-api"
command_background="yes"
pidfile="/run/tide-api.pid"
depend() { after tor; }
INITAPI
chmod +x /mnt/etc/init.d/tide-api

# tide CLI utility
cat > /mnt/usr/local/bin/tide << 'TIDECMD'
#!/bin/sh
case "$1" in
    status)
        echo "═══════════════════════════════════════"
        echo "Mode:     $(cat /etc/tide/mode 2>/dev/null)"
        echo "Security: $(cat /etc/tide/security 2>/dev/null)"
        echo "Tor:      $(rc-service tor status 2>/dev/null | grep -oE 'started|stopped')"
        echo "Gateway:  $(ip -4 addr show eth1 2>/dev/null | grep -oP 'inet \K[\d.]+')"
        echo "═══════════════════════════════════════"
        ;;
    check)
        echo "Testing Tor..."
        IP=$(curl -s --socks5 127.0.0.1:9050 --max-time 30 https://check.torproject.org/api/ip 2>/dev/null)
        if echo "$IP" | grep -q "IsTor.*true"; then
            echo "✓ Connected via Tor"
            echo "$IP" | grep -oP '"IP":"\K[^"]+'
        else
            echo "✗ Tor not working"
        fi
        ;;
    newcircuit)
        echo "Requesting new circuit..."
        killall -HUP tor
        echo "Done. New circuit requested."
        ;;
    onion)
        if [ -f /var/lib/tor/ssh_onion/hostname ]; then
            echo "SSH Onion: $(cat /var/lib/tor/ssh_onion/hostname)"
        else
            echo "No onion service configured"
        fi
        ;;
    takeover)
        [ -f /etc/tide/takeover.sh ] && /etc/tide/takeover.sh || echo "N/A"
        ;;
    release)
        [ -f /etc/tide/release.sh ] && /etc/tide/release.sh || echo "N/A"
        ;;
    *)
        echo "Tide Gateway Control"
        echo ""
        echo "Usage: tide <command>"
        echo ""
        echo "Commands:"
        echo "  status      Show current status"
        echo "  check       Test Tor connectivity"
        echo "  newcircuit  Request new Tor circuit"
        echo "  onion       Show .onion address (if configured)"
        echo "  takeover    Start ARP takeover (if available)"
        echo "  release     Stop ARP takeover"
        ;;
esac
TIDECMD
chmod +x /mnt/usr/local/bin/tide

# Boot script
cat > /mnt/etc/local.d/tide.start << 'BOOT'
#!/bin/sh
sysctl -p /etc/sysctl.d/tide.conf >/dev/null 2>&1
iptables-restore < /etc/iptables/rules-save

MODE=$(cat /etc/tide/mode 2>/dev/null)
if [ "$MODE" = "forced" ] || [ "$MODE" = "takeover" ]; then
    if ! iptables -L OUTPUT | grep -q "policy DROP"; then
        iptables -P INPUT DROP
        iptables -P OUTPUT DROP
        iptables -P FORWARD DROP
        logger "TIDE: Emergency lockdown"
    fi
fi

if [ "$MODE" = "takeover" ] && [ -f /etc/tide/takeover.sh ]; then
    sleep 5 && /etc/tide/takeover.sh &
fi

logger "Tide Gateway active ($MODE)"
BOOT
chmod +x /mnt/etc/local.d/tide.start

# Enable services
chroot /mnt rc-update add tor default >/dev/null
chroot /mnt rc-update add iptables default >/dev/null
chroot /mnt rc-update add local default >/dev/null
chroot /mnt rc-update add sshd default >/dev/null
chroot /mnt rc-update add tide-api default >/dev/null
[ "$TIDE_MODE" != "proxy" ] && chroot /mnt rc-update add dnsmasq default >/dev/null

sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config

# MOTD
cat > /mnt/etc/motd << MOTD

  ╔═══════════════════════════════════════════════════════════╗
  ║            🌊  T I D E   G A T E W A Y  🌊                ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  Mode:     $(printf "%-47s" "$TIDE_MODE")║
  ║  Security: $(printf "%-47s" "$SECURITY")║
  ║  Gateway:  10.101.101.1                                   ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  tide status  │  tide check  │  tide newcircuit           ║
  ╚═══════════════════════════════════════════════════════════╝

MOTD

# Lock config files
chroot /mnt sh -c '
    chattr +i /etc/iptables/rules-save 2>/dev/null
    chattr +i /etc/tor/torrc 2>/dev/null
    chattr +i /etc/sysctl.d/tide.conf 2>/dev/null
' 2>/dev/null || true

sync
umount /mnt 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════
# COMPLETE
# ═══════════════════════════════════════════════════════════════
clear
echo ""
echo "  ╔═══════════════════════════════════════════════════════════╗"
echo "  ║              ✅  INSTALLATION COMPLETE                    ║"
echo "  ╠═══════════════════════════════════════════════════════════╣"
echo "  ║  Mode:     $TIDE_MODE"
echo "  ║  Security: $SECURITY"
echo "  ║  Gateway:  10.101.101.1                                   ║"
echo "  ║  Login:    root / tide                                    ║"
echo "  ╠═══════════════════════════════════════════════════════════╣"

case "$SECURITY" in
    hardened)
echo "  ║  🔒 14-eyes countries excluded from circuits              ║" ;;
    paranoid)
echo "  ║  🔒 Maximum isolation + hostile country exclusion         ║" ;;
    bridges)
echo "  ║  🌉 Using bridges for censorship circumvention            ║" ;;
esac

if [ "$ENABLE_ONION_SSH" = "yes" ]; then
echo "  ║  🧅 SSH onion service enabled (run 'tide onion')          ║"
fi

echo "  ╠═══════════════════════════════════════════════════════════╣"
echo "  ║  Eject ISO and type 'reboot'                              ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo ""
