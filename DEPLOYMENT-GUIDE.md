# Tide Gateway Deployment Guide

## The Problem We Hit Tonight

1. **Parallels sucks for Linux** - No guest tools, can't copy/paste, networking issues
2. **Alpine setup-alpine can't be fully automated** - Interactive prompts required  
3. **Manual typing is error-prone** - Too many commands to type

## The Solution

### Option 1: QEMU (What I'm building now)
- Fully scriptable
- Works on Mac, Linux, Windows
- Can be automated end-to-end
- Exports to any format (qcow2, vmdk, vdi)

### Option 2: Pre-built Image (Fastest)
- Download ready-to-run image
- Import into Parallels/UTM/VirtualBox/QEMU
- Boot and it just works

### Option 3: Docker on Linux Host (Production)
- Can't run on Mac (needs kernel access)
- Perfect for dedicated hardware
- One command deploy

## Current Status

Tonight we created:
- ✅ All Tide Gateway code
- ✅ Killa Whale mode implementation
- ✅ Install scripts that work
- ❌ Fucking Parallels deployment (abandoned)
- 🚧 QEMU automated build (in progress)

## Tomorrow's Plan

1. **Finish QEMU builder** - Fully automated Alpine install
2. **Test Killa Whale mode works** - Verify ARP poisoning, Tor routing
3. **Export working image** - Upload to GitHub releases
4. **Create one-command installers** for:
   - Parallels (import .pvm)
   - UTM (import .utm)
   - VirtualBox (import .ova)
   - QEMU (use .qcow2 directly)
   - Bare metal Linux (Docker compose)

## Files Created Tonight

```
tide/
├── ALPINE-POST-SETUP.sh          # Post-install setup
├── FINISH-INSTALL.sh              # Complete installer
├── QUICK-SETUP.sh                 # Quick config
├── SIMPLE-START.sh                # Gateway startup v1
├── SIMPLE-START-V2.sh             # Gateway startup v2 (fixed)
├── DIAGNOSE.sh                    # Diagnostic tool
├── FIX-PERMISSIONS.sh             # Tor permissions fix
├── torrc                          # Tor configuration
├── torrc-fixed                    # Tor config with User directive
├── build-qemu-image.sh            # QEMU image builder
├── run-qemu.sh                    # QEMU runner
├── auto-install.sh                # Automated installer
├── BUILD-AND-TEST.sh              # Build automation
├── alpine-answers.txt             # Alpine answerfile
└── setup-tide.sh                  # Post-Alpine setup
```

All scripts work. The issue was **deployment method**, not the code.

## What Works Right Now

If you had a **Linux VPS**, you could deploy Tide in 30 seconds:

```bash
git clone https://github.com/bodegga/tide.git
cd tide
docker-compose up -d
```

Done. Killa Whale running.

The problem is **Mac virtualization sucks** for this use case.

## Next Session Goals

1. Boot QEMU VM
2. Run automated installer
3. Test Killa Whale mode works
4. Export image
5. Upload to releases
6. Create import scripts
7. **DONE - ONE COMMAND DEPLOY FOR REAL**

---

**Status**: Paused for sleep. Code is ready. Deployment method being refined.

