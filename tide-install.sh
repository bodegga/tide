#!/bin/sh
# ═══════════════════════════════════════════════════════════════
#   🌊 TIDE - Transparent Internet Defense Engine
# ═══════════════════════════════════════════════════════════════
#
#   wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
#
# ═══════════════════════════════════════════════════════════════

set -e

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
echo "  Select deployment mode:"
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  [1]  PROXY ONLY                                        │"
echo "  │       • Just a Tor SOCKS5 proxy + DNS                   │"
echo "  │       • Point apps at 10.101.101.1:9050                 │"
echo "  │       • Minimal, lightweight                            │"
echo "  │       • Good for: Single VM, testing                    │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  [2]  ROUTER (Passive)                                  │"
echo "  │       • Full gateway with DHCP + DNS                    │"
echo "  │       • Clients auto-configure                          │"
echo "  │       • Plays nice with existing networks               │"
echo "  │       • Good for: VM lab, isolated network              │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  [3]  ROUTER (Forced)                                   │"
echo "  │       • Everything in mode 2, plus:                     │"
echo "  │       • Blocks non-Tor egress attempts                  │"
echo "  │       • Kills traffic if Tor dies                       │"
echo "  │       • Good for: High security, paranoid setup         │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  [4]  TAKEOVER (Aggressive) ⚠️                          │"
echo "  │       • Everything in mode 3, plus:                     │"
echo "  │       • ARP poisons the subnet                          │"
echo "  │       • Hijacks existing gateway                        │"
echo "  │       • Forces ALL devices through Tor                  │"
echo "  │       • Good for: Full subnet control                   │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
printf "  Select [1-4]: "
read MODE_NUM

case "$MODE_NUM" in
    1) TIDE_MODE="proxy" ;;
    2) TIDE_MODE="router" ;;
    3) TIDE_MODE="forced" ;;
    4) TIDE_MODE="takeover" ;;
    *) echo "Invalid selection"; exit 1 ;;
esac

echo ""
echo "  ► Mode selected: $TIDE_MODE"
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

# Mount installed system
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

# Base packages for all modes
PKGS="tor iptables ip6tables"

# Add packages based on mode
case "$TIDE_MODE" in
    router|forced|takeover)
        PKGS="$PKGS dnsmasq"
        ;;
esac

case "$TIDE_MODE" in
    takeover)
        PKGS="$PKGS arping nmap ettercap-ng"
        ;;
esac

chroot /mnt sh -c "apk update >/dev/null && apk add --no-cache $PKGS >/dev/null 2>&1"
echo "        Packages installed"

# ═══════════════════════════════════════════════════════════════
# PHASE 5: Tor Configuration
# ═══════════════════════════════════════════════════════════════
echo "  [5/7] Configuring Tor..."

cat > /mnt/etc/tor/torrc << 'EOF'
# Tide Gateway - Tor Configuration
User tor
DataDirectory /var/lib/tor
Log notice syslog
SafeLogging 1

# SOCKS5 Proxy (always available)
SocksPort 0.0.0.0:9050

# DNS through Tor
DNSPort 0.0.0.0:5353

# Transparent Proxy (for router modes)
TransPort 0.0.0.0:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
EOF

echo "        Tor configured"

# ═══════════════════════════════════════════════════════════════
# PHASE 6: Network & Security Configuration
# ═══════════════════════════════════════════════════════════════
echo "  [6/7] Configuring network & security..."

# Save mode for runtime
mkdir -p /mnt/etc/tide
echo "$TIDE_MODE" > /mnt/etc/tide/mode

# --- Network Interfaces ---
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

# --- Sysctl ---
mkdir -p /mnt/etc/sysctl.d
cat > /mnt/etc/sysctl.d/tide.conf << 'EOF'
# Tide Security Sysctl
net.ipv4.ip_forward=1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
EOF

# --- DNSMASQ (Router modes) ---
if [ "$TIDE_MODE" != "proxy" ]; then
cat > /mnt/etc/dnsmasq.conf << 'EOF'
# Tide DHCP + DNS Server
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

# --- IPTABLES (varies by mode) ---
mkdir -p /mnt/etc/iptables

case "$TIDE_MODE" in
    proxy)
        # Proxy mode: Minimal rules, just protect the gateway
        cat > /mnt/etc/iptables/rules-save << 'EOF'
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p udp --sport 67 --dport 68 -j ACCEPT
COMMIT
EOF
        ;;

    router)
        # Router mode: DHCP/DNS, transparent proxy, permissive output
        cat > /mnt/etc/iptables/rules-save << 'EOF'
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
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
-A INPUT -i eth1 -p tcp --dport 53 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth1 -p icmp -j ACCEPT
-A INPUT -i eth0 -p udp --sport 67 --dport 68 -j ACCEPT
COMMIT
EOF
        ;;

    forced|takeover)
        # Forced/Takeover: Leak-proof, fail-closed
        cat > /mnt/etc/iptables/rules-save << 'EOF'
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i eth1 -p tcp -j REDIRECT --to-ports 9040
-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 53
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
# Input
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i eth1 -p udp --dport 67 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 53 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 53 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
-A INPUT -i eth1 -p icmp -j ACCEPT
-A INPUT -i eth0 -p udp --sport 67 --dport 68 -j ACCEPT
# Output: ONLY Tor talks to internet
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

# --- TAKEOVER MODE: ARP Hijacking ---
if [ "$TIDE_MODE" = "takeover" ]; then

cat > /mnt/etc/tide/takeover.sh << 'TAKEOVER'
#!/bin/sh
# Tide Takeover - ARP Hijack
IFACE="eth1"
MY_IP="10.101.101.1"

log() { logger "TIDE-TAKEOVER: $1"; echo "$1"; }
log "Starting subnet takeover on $IFACE..."

# Enable proxy ARP
echo 1 > /proc/sys/net/ipv4/conf/$IFACE/proxy_arp
echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp

# Find the real gateway by checking for other DHCP servers or common gateway IPs
NETWORK="10.101.101.0/24"

# Continuously announce ourselves as THE gateway
(
    while true; do
        # Gratuitous ARP: "I am 10.101.101.1"
        arping -U -c 3 -I $IFACE $MY_IP >/dev/null 2>&1
        
        # Also claim common gateway addresses
        for gw in 10.101.101.254 10.101.101.1 192.168.1.1 192.168.0.1; do
            arping -U -c 1 -I $IFACE -s $MY_IP $gw >/dev/null 2>&1
        done
        
        sleep 5
    done
) &
echo $! > /var/run/tide-takeover.pid

log "Takeover active. All ARP requests will be answered by Tide."
TAKEOVER
chmod +x /mnt/etc/tide/takeover.sh

cat > /mnt/etc/tide/release.sh << 'RELEASE'
#!/bin/sh
# Stop takeover
[ -f /var/run/tide-takeover.pid ] && kill $(cat /var/run/tide-takeover.pid) 2>/dev/null
rm -f /var/run/tide-takeover.pid
echo 0 > /proc/sys/net/ipv4/conf/eth1/proxy_arp
logger "TIDE: Takeover released"
RELEASE
chmod +x /mnt/etc/tide/release.sh

fi

# --- Mode Switch Utility ---
cat > /mnt/usr/local/bin/tide << 'TIDECMD'
#!/bin/sh
case "$1" in
    status)
        echo "Mode: $(cat /etc/tide/mode 2>/dev/null || echo 'unknown')"
        echo "Tor:  $(rc-service tor status 2>/dev/null | grep -o 'started\|stopped')"
        echo "IP:   $(ip -4 addr show eth1 2>/dev/null | grep inet | awk '{print $2}')"
        ;;
    mode)
        cat /etc/tide/mode 2>/dev/null
        ;;
    takeover)
        [ -f /etc/tide/takeover.sh ] && /etc/tide/takeover.sh || echo "Takeover not available in this mode"
        ;;
    release)
        [ -f /etc/tide/release.sh ] && /etc/tide/release.sh || echo "Nothing to release"
        ;;
    check)
        echo "Testing Tor connectivity..."
        curl -s --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip 2>/dev/null || echo "Tor not working"
        ;;
    *)
        echo "Tide Gateway Control"
        echo "Usage: tide [status|mode|check|takeover|release]"
        ;;
esac
TIDECMD
chmod +x /mnt/usr/local/bin/tide

echo "        Security configured"

# ═══════════════════════════════════════════════════════════════
# PHASE 7: Finalize & Lock
# ═══════════════════════════════════════════════════════════════
echo "  [7/7] Finalizing..."

# Boot script
cat > /mnt/etc/local.d/tide.start << 'BOOT'
#!/bin/sh
sysctl -p /etc/sysctl.d/tide.conf >/dev/null 2>&1
iptables-restore < /etc/iptables/rules-save

# Verify firewall loaded
MODE=$(cat /etc/tide/mode 2>/dev/null)
if [ "$MODE" = "forced" ] || [ "$MODE" = "takeover" ]; then
    if ! iptables -L OUTPUT | grep -q "policy DROP"; then
        iptables -P INPUT DROP
        iptables -P OUTPUT DROP
        iptables -P FORWARD DROP
        logger "TIDE: Emergency lockdown"
    fi
fi

# Auto-start takeover if in that mode
if [ "$MODE" = "takeover" ] && [ -f /etc/tide/takeover.sh ]; then
    sleep 5
    /etc/tide/takeover.sh &
fi

logger "Tide Gateway ($MODE) active"
BOOT
chmod +x /mnt/etc/local.d/tide.start

# Enable services
chroot /mnt rc-update add tor default >/dev/null
chroot /mnt rc-update add iptables default >/dev/null
chroot /mnt rc-update add local default >/dev/null
chroot /mnt rc-update add sshd default >/dev/null
[ "$TIDE_MODE" != "proxy" ] && chroot /mnt rc-update add dnsmasq default >/dev/null

# SSH config
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config

# MOTD
cat > /mnt/etc/motd << MOTD

  ╔═══════════════════════════════════════════════════════════╗
  ║            🌊  T I D E   G A T E W A Y  🌊                ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  Mode:     $(printf "%-45s" "$TIDE_MODE") ║
  ║  Gateway:  10.101.101.1                                   ║
  ║  SOCKS5:   10.101.101.1:9050                              ║
  ║  DNS:      10.101.101.1:5353                              ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  Commands:                                                ║
  ║    tide status   - Show current status                    ║
  ║    tide check    - Test Tor connectivity                  ║
  ╚═══════════════════════════════════════════════════════════╝

MOTD

# Lock critical files (immutable)
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
echo "  ║                                                           ║"
echo "  ║              ✅  INSTALLATION COMPLETE                    ║"
echo "  ║                                                           ║"
echo "  ╠═══════════════════════════════════════════════════════════╣"
echo "  ║                                                           ║"
echo "  ║  Mode:     $TIDE_MODE"
echo "  ║  Gateway:  10.101.101.1                                   ║"
echo "  ║  Login:    root / tide                                    ║"
echo "  ║                                                           ║"
echo "  ╠═══════════════════════════════════════════════════════════╣"
echo "  ║                                                           ║"
case "$TIDE_MODE" in
    proxy)
echo "  ║  PROXY MODE:                                              ║"
echo "  ║    • Point apps at SOCKS5 10.101.101.1:9050               ║"
echo "  ║    • Or use DNS 10.101.101.1:5353                         ║"
        ;;
    router)
echo "  ║  ROUTER MODE:                                             ║"
echo "  ║    • Clients get DHCP automatically                       ║"
echo "  ║    • All traffic routes through Tor                       ║"
        ;;
    forced)
echo "  ║  FORCED MODE:                                             ║"
echo "  ║    • All traffic MUST go through Tor                      ║"
echo "  ║    • If Tor dies, traffic is BLOCKED                      ║"
echo "  ║    • No clearnet leaks possible                           ║"
        ;;
    takeover)
echo "  ║  TAKEOVER MODE: ⚠️                                        ║"
echo "  ║    • ARP hijacking active                                 ║"
echo "  ║    • ALL subnet devices forced through Tor                ║"
echo "  ║    • Run 'tide release' to stop                           ║"
        ;;
esac
echo "  ║                                                           ║"
echo "  ╠═══════════════════════════════════════════════════════════╣"
echo "  ║                                                           ║"
echo "  ║  Next: Eject ISO and type 'reboot'                        ║"
echo "  ║                                                           ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo ""
