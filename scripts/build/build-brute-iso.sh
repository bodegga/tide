#!/usr/bin/env bash
set -euo pipefail

# Tide Gateway: Build BRUTE-FORCE Autoinstall ISO (ARM64)
# Method: Replaces Alpine's setup scripts with our own 'tide-install.sh'
#         bundled in an APKOVL overlay that runs on boot.

BASE_ISO="alpine-virt-3.19.6-aarch64.iso"
WORKDIR="$(mktemp -d /tmp/tide-iso.XXXX)"
OVLDIR="$(mktemp -d /tmp/tide-ovl.XXXX)"
OUT_ISO="tide-autoinstall-efi.iso"
VOLUME="TIDE_INSTALL"

cleanup() {
  rm -rf "$WORKDIR" "$OVLDIR"
}
trap cleanup EXIT

if [[ ! -f "$BASE_ISO" ]]; then
  echo "Base ISO not found: $BASE_ISO" >&2
  exit 1
fi
if [[ ! -f tide-install.sh ]]; then
  echo "tide-install.sh missing." >&2
  exit 1
fi

echo ">>> Extracting Base ISO..."
bsdtar -C "$WORKDIR" -xf "$BASE_ISO"
chmod -R u+w "$WORKDIR"

echo ">>> Building Installer Overlay..."
# Create overlay structure
mkdir -p "$OVLDIR/etc/local.d"
mkdir -p "$OVLDIR/etc/runlevels/default"
mkdir -p "$OVLDIR/root"

# Copy the installer script
cp tide-install.sh "$OVLDIR/root/"
chmod +x "$OVLDIR/root/tide-install.sh"

# Create the autoinstall script
cat > "$OVLDIR/etc/local.d/tide-install.start" <<'EOF'
#!/bin/sh

# Redirect output
exec >/dev/console 2>&1
set -x

# Only run if we are in the live environment
if [ ! -f /sbin/apk ]; then exit 0; fi

echo "=========================================="
echo "   TIDE GATEWAY AUTO-INSTALLER STARTING   "
echo "=========================================="
sleep 2

# Mount searching
mkdir -p /media/install_source
FOUND=0

# Try all likely block devices
for dev in $(blkid | cut -d: -f1); do
    mount -t iso9660 $dev /media/install_source 2>/dev/null && \
    if [ -f /media/install_source/tide-install.sh ]; then
        echo ">>> Found installer on $dev"
        cp /media/install_source/tide-install.sh /root/
        chmod +x /root/tide-install.sh
        FOUND=1
        umount /media/install_source
        break
    fi
    umount /media/install_source 2>/dev/null
done

if [ $FOUND -eq 1 ]; then
    echo ">>> Starting Installer..."
    /root/tide-install.sh
else
    echo "!!! ERROR: Installer script not found on any device."
    echo "Devices detected:"
    blkid
fi
EOF
chmod +x "$OVLDIR/etc/local.d/tide-install.start"

# Enable local service
ln -s /etc/init.d/local "$OVLDIR/etc/runlevels/default/local"

# Pack the overlay
current_dir=$(pwd)
cd "$OVLDIR"
tar -czf "$WORKDIR/localhost.apkovl.tar.gz" *
cd "$current_dir"

echo ">>> Patching GRUB..."
GRUB_CFG="$WORKDIR/boot/grub/grub.cfg"
chmod u+w "$GRUB_CFG"
# Patch GRUB with rootdelay and modules to fix Parallels race condition
cat > "$GRUB_CFG" <<'GRUB'
set default=0
set timeout=1

menuentry "Tide Gateway Installer" {
  linux  /boot/vmlinuz-virt modules=loop,squashfs,sd-mod,usb-storage,sr_mod,cdrom,virtio_scsi,virtio_blk console=tty0 console=ttyAMA0 root=LABEL=TIDE_INSTALL rootdelay=10
  initrd /boot/initramfs-virt
}
GRUB

echo ">>> Repacking EFI ISO..."
mkisofs \
  -R -J -V "$VOLUME" \
  -eltorito-alt-boot -eltorito-platform efi -b boot/grub/efi.img -no-emul-boot \
  -o "$OUT_ISO" "$WORKDIR"

echo ">>> Done. Created $OUT_ISO"
