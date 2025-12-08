#!/bin/bash
set -euo pipefail

# Tide Gateway - Cloud Image Builder
# ----------------------------------
# 1. Takes official Alpine Cloud Image.
# 2. Injects 'tide-seed.iso' (Cloud-Init).
# 3. Boots once to apply config (install Tor, set IP).
# 4. Result: Ready-to-use Gateway Disk.

BASE_IMG="alpine-cloud.qcow2"
OUTPUT_IMG="tide-gateway.qcow2"
SEED_ISO="tide-seed.iso"

# Clean previous runs
rm -f "$OUTPUT_IMG" "$SEED_ISO"

echo ">>> creating tide-gateway.qcow2 from base..."
cp "$BASE_IMG" "$OUTPUT_IMG"
# Resize to give space for logs/cache (2GB total)
qemu-img resize "$OUTPUT_IMG" 2G

echo ">>> generating cloud-init config..."
mkdir -p cidata

# 1. meta-data
cat > cidata/meta-data <<EOF
instance-id: tide-gateway-v1
local-hostname: tide-gateway
EOF

# 2. user-data (The Payload)
cat > cidata/user-data <<EOF
#cloud-config
password: tide
chpasswd: { expire: False }
ssh_pwauth: True

# Install packages
packages:
  - tor
  - iptables
  - ip6tables

# Write Configuration Files
write_files:
  - path: /etc/tor/torrc
    content: |
      User tor
      DataDirectory /var/lib/tor
      TransPort 0.0.0.0:9040
      DNSPort 0.0.0.0:5353
      SocksPort 0.0.0.0:9050
      VirtualAddrNetworkIPv4 10.192.0.0/10
      AutomapHostsOnResolve 1
      Log notice syslog

  - path: /etc/iptables/rules.v4
    content: |
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

  - path: /etc/network/interfaces
    content: |
      auto lo
      iface lo inet loopback
      
      auto eth0
      iface eth0 inet dhcp
      
      auto eth1
      iface eth1 inet static
        address 10.101.101.10
        netmask 255.255.255.0

# Run commands on first boot
runcmd:
  - rc-update add tor default
  - rc-update add iptables default
  - echo "Tide Gateway (Configured)" > /etc/issue
  - iptables-restore < /etc/iptables/rules.v4
  - /etc/init.d/iptables save
  # Signal completion and shutdown
  - echo "TIDE_SETUP_COMPLETE" > /root/SETUP_COMPLETE
  - poweroff

EOF

echo ">>> building seed ISO..."
mkisofs -output "$SEED_ISO" -volid cidata -joliet -rock cidata/

echo ">>> booting VM to apply configuration (This takes ~60s)..."
# We attach seed.iso as a CD-ROM. Cloud-init (nocloud) finds it by label 'cidata'.
qemu-system-aarch64 \
  -M virt -cpu cortex-a72 -m 1024 -nographic \
  -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -drive if=virtio,file="$OUTPUT_IMG",format=qcow2 \
  -drive file="$SEED_ISO",format=raw,if=virtio,media=cdrom \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
  -boot order=c

echo ">>> build complete."
echo ">>> cleaning up..."
rm -rf cidata "$SEED_ISO"

echo ">>> converting for parallels..."
qemu-img convert -O parallels "$OUTPUT_IMG" tide-gateway.hdd

echo ">>> DONE. Artifacts:"
ls -lh tide-gateway.qcow2 tide-gateway.hdd
