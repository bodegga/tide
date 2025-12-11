#!/bin/bash
# Full automated Killa Whale deployment using Parallels

set -e

VM_NAME="Tide-Killa-Whale"
ROOT_PASS="tide"

echo "🐋 Automated Killa Whale Deployment"
echo "===================================="
echo ""

# Wait for VM to boot
echo "⏳ Waiting for VM to boot (30 seconds)..."
sleep 30

echo "🔑 Setting root password via console injection..."
# We can't use prlctl exec without Parallels Tools, so we use console send-keys

# This is tricky - Parallels doesn't have easy keyboard injection like QEMU
# We need to use AppleScript to send keys to the Parallels window

osascript << APPLESCRIPT
tell application "Parallels Desktop"
    activate
    tell application "System Events"
        -- Wait a bit for window focus
        delay 2
        
        -- Login as root (press enter at login prompt)
        keystroke return
        delay 2
        
        -- Run setup-alpine with answer file
        keystroke "wget -O /tmp/answers.txt http://10.211.55.2/alpine-answers.txt"
        keystroke return
        delay 2
        
        keystroke "setup-alpine -f /tmp/answers.txt"
        keystroke return
        delay 2
        
        -- Set root password (will be prompted)
        keystroke "${ROOT_PASS}"
        keystroke return
        delay 1
        keystroke "${ROOT_PASS}"
        keystroke return
    end tell
end tell
APPLESCRIPT

echo "⚠️  AppleScript keyboard injection attempted"
echo "   This is fragile - manual is more reliable"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RECOMMENDED: Do it manually (takes 2 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
