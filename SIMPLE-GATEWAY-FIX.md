# The Practical Solution: Use What Works

Alpine ISO boot issues on ARM64 Parallels are common. Here's the fix:

## Option 1: Use Your Existing Debian Gateway (FASTEST - 2 minutes)

You already have `Tor-Gateway.pvm` with Debian installed!

**Just configure it properly:**

```bash
# 1. Start the Debian gateway
prlctl start Tor-Gateway

# 2. Wait for it to boot, then configure via prlctl exec:
prlctl exec Tor-Gateway --user root --password <your-password> /bin/bash -c '
# Install Tor
apt update && apt install -y tor iptables

# Configure Tor
cat > /etc/tor/torrc << "TORRC"
SocksPort 10.152.152.10:9050
DNSPort 10.152.152.10:5353
TransPort 10.152.152.10:9040
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
Log notice file /var/log/tor/notices.log
TORRC

# Configure eth1
cat >> /etc/network/interfaces << "NET"

auto enp0s10
iface enp0s10 inet static
    address 10.152.152.10
    netmask 255.255.255.0
NET

ifup enp0s10

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Firewall rules
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0\; policy drop\; }
nft add rule inet filter input iif lo accept
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input iif enp0s10 ip saddr 10.152.152.0/24 tcp dport {9050,9040,22,9051} accept
nft add rule inet filter input iif enp0s10 ip saddr 10.152.152.0/24 udp dport 5353 accept

nft add table ip nat
nft add chain ip nat prerouting { type nat hook prerouting priority -100\; }
nft add rule ip nat prerouting iif enp0s10 udp dport 53 redirect to :5353
nft add rule ip nat prerouting iif enp0s10 tcp dport {80,443} redirect to :9040

# Start Tor
systemctl enable tor
systemctl start tor
'
```

## Option 2: Download Pre-Built Alpine (Better approach)

Alpine has pre-built cloud images that work better:

```bash
# Download Alpine Cloud image (works with ARM64 better)
curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/nocloud_alpine-3.19.1-aarch64-bios-cloudinit-r0.qcow2

# Convert to Parallels format
qemu-img convert -f qcow2 -O parallels nocloud_alpine-3.19.1-aarch64-bios-cloudinit-r0.qcow2 alpine.hdd

# Use this as base disk
```

## Option 3: Just Use Debian (It Works)

Stop fighting Alpine boot issues. Debian works, you have it installed, let's use it:

**Debian Gateway: 700MB vs Alpine 150MB**

Who cares? You have a 1TB SSD. The 550MB difference is irrelevant.

**What matters:**
- ✅ Works now (not in 2 hours after debugging)
- ✅ You know it boots
- ✅ Same Tor configuration
- ✅ Same security model
- ✅ Actually deployed today

**Anthony's rule:** "Working solutions over perfect theories"

Want me to just configure your existing Debian gateway in 2 minutes?
