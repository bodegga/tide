#!/bin/bash
set -e

# Tide Gateway - Parallels Native Builder
# ---------------------------------------
# Uses `prlctl` to create a VM and perform an automated install via keyboard injection.
# This ensures the resulting VM is 100% native and valid.

VM_NAME="Tide-Gateway"
ISO_PATH="$(pwd)/tide/alpine-virt-3.19.6-aarch64.iso"
SEED_ISO="$(pwd)/tide/release/tide-seed.iso"

# Check dependencies
if ! command -v prlctl &> /dev/null; then
    echo "Error: Parallels 'prlctl' not found."
    exit 1
fi

echo ">>> Creating VM '$VM_NAME'..."
# Cleanup previous
prlctl stop "$VM_NAME" --kill 2>/dev/null || true
prlctl delete "$VM_NAME" 2>/dev/null || true

# Create
prlctl create "$VM_NAME" --distribution "alpine" --dst "$(pwd)/tide/tide-vm"

# Configure
prlctl set "$VM_NAME" --memsize 512 --cpus 1
prlctl set "$VM_NAME" --device-set net0 --type shared
prlctl set "$VM_NAME" --device-add net --type host-only

# Attach ISOs
echo ">>> Attaching Installation Media..."
prlctl set "$VM_NAME" --device-set cdrom0 --image "$ISO_PATH" --connect
# We don't attach seed yet; we do a base install first.

echo ">>> Starting Installation (Injecting Keys)..."
prlctl start "$VM_NAME"

# Wait for boot
sleep 15

# Function to type commands
type_cmd() {
    # This uses AppleScript to send keystrokes to the active Parallels window?
    # No, prlctl doesn't support send-keys directly.
    # We will use 'expect' or 'osascript' if needed, but prlctl exec requires tools.
    
    # WAIT. Since we can't type easily without Tools, we rely on the AUTOINSTALL ISO.
    :
}

echo "!!! MANUAL STEP REQUIRED !!!"
echo "1. The VM '$VM_NAME' is starting."
echo "2. Please type: 'setup-alpine' and follow prompts."
echo "   OR"
echo "   Wait for me to finish the 'Answerfile ISO' that actually works."

# ... This script is useless without keyboard injection.
# Reverting to the logic that WORKED in QEMU: The Answerfile ISO.
