#!/usr/bin/env bash
set -euo pipefail

# Tide Gateway: Build Universal Autoinstall ISO (ARM64)
# Uses Alpine's APKOVL feature to force an automated install script on boot.

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
if [[ ! -f answerfile || ! -f setup-tide.sh ]]; then
  echo "Required files (answerfile, setup-tide.sh) missing." >&2
  exit 1
fi

echo ">>> Extracting Base ISO..."
bsdtar -C "$WORKDIR" -xf "$BASE_ISO"
chmod -R u+w "$WORKDIR"

echo ">>> Building Autoinstall Overlay..."
# Create overlay structure
mkdir -p "$OVLDIR/etc/local.d"
mkdir -p "$OVLDIR/etc/runlevels/default"
mkdir -p "$OVLDIR/root"

# Copy config files to overlay root
cp answerfile "$OVLDIR/root/"
cp setup-tide.sh "$OVLDIR/root/"
chmod +x "$OVLDIR/root/setup-tide.sh"

# Create the autoinstall script
cat > "$OVLDIR/etc/local.d/tide-install.start" <<'EOF'
#!/bin/sh

# Redirect all output to the console so we can see it in QEMU logs
exec >/dev/console 2>&1
set -x

# Only run if we are in the live environment (not installed system)
if [ ! -f /sbin/apk ]; then exit 0; fi

echo "=========================================="
echo "   TIDE GATEWAY AUTO-INSTALLER STARTING   "
echo "=========================================="
sleep 2

# Ensure networking is up for APK fetches
rc-service networking start
rc-service syslog start

echo ">>> TIDE DEBUG: Network Status"
ip addr show

echo ">>> Starting Alpine Setup..."
# Force yes to any disk erase prompts
# setup-alpine arguments: -e (empty passwords/defaults), -f (answerfile)
export ERASE_DISKS="/dev/vda"
yes | setup-alpine -e -f /root/answerfile

EXIT_CODE=$?
echo ">>> TIDE DEBUG: setup-alpine finished with code $EXIT_CODE"

if [ $EXIT_CODE -eq 0 ]; then
    echo ">>> Base Install Complete. Configuring Gateway..."
    
    # Mount the new root partition (usually partition 3 for sys install on EFI)
    # We try vda3 then vda2
    mount /dev/vda3 /mnt 2>/dev/null || mount /dev/vda2 /mnt
    
    if [ -d /mnt/root ]; then
        # Copy post-install script
        cp /root/setup-tide.sh /mnt/root/
        
        # Run it in chroot
        echo ">>> Running setup-tide.sh in chroot..."
        chroot /mnt /bin/sh /root/setup-tide.sh
        
        # Mark complete
        echo "Tide Gateway Installed: $(date)" > /mnt/root/INSTALL_LOG
        
        echo "=========================================="
        echo "   INSTALLATION SUCCESSFUL                "
        echo "   Shutting down in 5 seconds...          "
        echo "=========================================="
        sleep 5
        poweroff
    else
        echo "!!! ERROR: Could not mount target partition. Dropping to shell."
        mount
        ls -la /dev/vda*
    fi
else
    echo "!!! ERROR: setup-alpine failed. Dropping to shell."
fi
EOF

chmod +x "$OVLDIR/etc/local.d/tide-install.start"

# Register the script to run on boot
ln -s /etc/init.d/local "$OVLDIR/etc/runlevels/default/local"

# Pack the overlay
# Note: owner must be root:root
current_dir=$(pwd)
cd "$OVLDIR"
tar -czf "$WORKDIR/localhost.apkovl.tar.gz" *
cd "$current_dir"

echo ">>> Patching GRUB to default to 'Tide Autoinstall'..."
GRUB_CFG="$WORKDIR/boot/grub/grub.cfg"
chmod u+w "$GRUB_CFG"
# Overwrite GRUB to default to the first entry and use our overlay
cat > "$GRUB_CFG" <<'GRUB'
set default=0
set timeout=1

menuentry "Tide Gateway Autoinstall" {
  linux  /boot/vmlinuz-virt modules=loop,squashfs,sd-mod,usb-storage console=tty0 console=ttyAMA0
  initrd /boot/initramfs-virt
}
GRUB

# Note: We rely on Alpine finding localhost.apkovl.tar.gz automatically in the root of the media.

echo ">>> Repacking EFI ISO..."
mkisofs \
  -R -J -V "$VOLUME" \
  -eltorito-alt-boot -eltorito-platform efi -b boot/grub/efi.img -no-emul-boot \
  -o "$OUT_ISO" "$WORKDIR"

echo ">>> Done. Created $OUT_ISO"
