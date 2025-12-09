#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RELEASE_DIR="release"
WORK_DIR="$(mktemp -d)"
trap "rm -rf $WORK_DIR" EXIT

ALPINE_IMG="nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2"
BIOS="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"

echo "=========================================="
echo "   🌊 Tide Gateway - Image Builder"
echo "=========================================="

# Always download fresh
echo ">>> Downloading fresh Alpine cloud image..."
curl -sL -o "$WORK_DIR/alpine.qcow2" "$ALPINE_URL"

mkdir -p "$RELEASE_DIR"

echo ">>> Creating cloud-init seed..."
cat > "$WORK_DIR/meta-data" << 'EOF'
instance-id: tide-$(date +%s)
local-hostname: tide-gateway
EOF

cat > "$WORK_DIR/user-data" << 'EOF'
#cloud-config
hostname: tide-gateway

write_files:
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

  - path: /etc/tor/torrc
    content: |
      User tor
      DataDirectory /var/lib/tor
      SocksPort 0.0.0.0:9050
      DNSPort 0.0.0.0:5353
      TransPort 0.0.0.0:9040
      VirtualAddrNetworkIPv4 10.192.0.0/10
      AutomapHostsOnResolve 1
      Log notice syslog

  - path: /etc/iptables/rules-save
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
      -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
      -A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT
      -A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT
      -A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT
      -A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
      -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
      COMMIT

  - path: /etc/sysctl.d/tide.conf
    content: |
      net.ipv4.ip_forward=1
      net.ipv6.conf.all.disable_ipv6=1

  - path: /etc/local.d/tide.start
    permissions: '0755'
    content: |
      #!/bin/sh
      sysctl -p /etc/sysctl.d/tide.conf 2>/dev/null
      iptables-restore < /etc/iptables/rules-save 2>/dev/null

  - path: /etc/motd
    content: |
      
        🌊 TIDE GATEWAY
        Gateway: 10.101.101.10 | Login: root/tide
      

packages:
  - tor
  - iptables

runcmd:
  - echo 'root:tide' | chpasswd
  - sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - rc-update add sshd default
  - rc-update add tor default  
  - rc-update add iptables default
  - rc-update add local default
  - /etc/init.d/iptables save
  - touch /etc/cloud/cloud-init.disabled
  - sync
  - poweroff
EOF

mkisofs -quiet -o "$WORK_DIR/seed.iso" -V cidata -J -r "$WORK_DIR/meta-data" "$WORK_DIR/user-data"

qemu-img resize "$WORK_DIR/alpine.qcow2" 1G 2>/dev/null

echo ">>> Booting VM to configure (2-3 min)..."

# Start QEMU with SSH forwarding so we can check progress
qemu-system-aarch64 \
    -M virt -cpu cortex-a72 -m 1024 \
    -nographic -no-reboot \
    -bios "$BIOS" \
    -drive if=virtio,file="$WORK_DIR/alpine.qcow2",format=qcow2 \
    -drive if=virtio,file="$WORK_DIR/seed.iso",format=raw,media=cdrom \
    -netdev user,id=n0,hostfwd=tcp::2222-:22 \
    -device virtio-net-device,netdev=n0 &

QEMU_PID=$!

# Wait for VM to complete (check if QEMU is still running)
echo "    Waiting for cloud-init to complete..."
while kill -0 $QEMU_PID 2>/dev/null; do
    sleep 5
    echo -n "."
done
echo ""
echo ">>> VM shutdown complete."

# Copy and convert
cp "$WORK_DIR/alpine.qcow2" "$RELEASE_DIR/tide-gateway.qcow2"
qemu-img convert -f qcow2 -O vmdk "$WORK_DIR/alpine.qcow2" "$RELEASE_DIR/tide-gateway.vmdk"
qemu-img convert -f qcow2 -O vdi "$WORK_DIR/alpine.qcow2" "$RELEASE_DIR/tide-gateway.vdi"

echo ""
echo "=========================================="
echo "   ✅ BUILD COMPLETE"
echo "=========================================="
ls -lh "$RELEASE_DIR"/tide-gateway.*
echo ""
echo "Import → Add Host-Only NIC → Boot → Done"
echo "Login: root/tide | Gateway: 10.101.101.10"
