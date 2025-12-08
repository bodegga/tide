# Building Tide

## Goal
Lightweight Tor gateway that works on ANY ARM64 hypervisor.

## Best Approach: Alpine Linux

**Why:** 150MB vs 3GB (Debian). Minimal, fast, secure.

## Steps

1. Download Alpine ARM64 ISO
2. Create VM (512MB RAM, 2GB disk, 2 network adapters)
3. Install Alpine (`setup-alpine`)
4. Configure Tor + firewall
5. Export as universal OVA

Full automation scripts in development.

## Current Release

v1.0.0 uses Debian (tested, working, stable).

Alpine version coming soon.
