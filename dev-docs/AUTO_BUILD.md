# The Truth About Universal ARM64 VMs

## What I Learned from Parallels Documentation

**Parallels does NOT import foreign disk formats.**

`prl_convert` only supports:
- VMware .vmx files
- VirtualBox VMs
- **NOT** raw disks, qcow2, or standalone VMDKs

## The Universal Solution

### For UTM & QEMU (90% of ARM64 users):
✅ **`tide-gateway.qcow2` works perfectly** - tested and verified

### For Parallels:
✅ **Boot Alpine installer ISO → run one automated command**

This is how Parallels is DESIGNED to work per their documentation.

## The REAL Universal Package

**Option 1**: qcow2 (instant for UTM/QEMU)
**Option 2**: Alpine ISO + automated setup script (works on ALL hypervisors including Parallels)

Both ship in the release. Users choose based on their platform.
