# Tide Gateway v1.1.0 Release Session

**Date:** December 7, 2025  
**Project:** Tide Gateway (opsec-vm)  
**Release:** [v1.1.0](https://github.com/bodegga/tide/releases/tag/v1.1.0)

---

## Summary

Completed the Tide Gateway v1.1.0 release with significant bug fixes to cloud-init configuration and build process. The release now produces working artifacts that boot properly and configure Tor transparent proxy on first run.

---

## Issues Found & Fixed

### 1. Cloud-init ISO File Naming

**Problem:** ISO contained files named `cloud-init-userdata.yaml` and `cloud-init-metadata.yaml`, but cloud-init expects `user-data` and `meta-data` (no extensions, hyphenated).

**Fix:** Rebuilt ISO with correct file names:
```bash
mkisofs -output cloud-init.iso -volid cidata -joliet -rock user-data meta-data
```

### 2. Invalid Password Hash

**Problem:** The user-data file had a truncated/placeholder SHA512 hash that Alpine couldn't parse, causing login failures.

**Fix:** Replaced inline hash with `chpasswd` in runcmd:
```yaml
runcmd:
  - echo 'root:tide' | chpasswd
```

### 3. Release Artifact Was Untouched Base Image

**Problem:** The 141MB "release" qcow2 was identical to the vanilla Alpine cloud image - no customization applied.

**Fix:** Created `build-release.sh` to properly generate artifacts with cloud-init baked in.

### 4. Scattered Documentation

**Problem:** Multiple README files, build instructions spread across various locations.

**Fix:** Consolidated old docs into `dev-docs/`, created clean top-level `README.md` with clear instructions.

---

## Key Files Changed

| File | Change |
|------|--------|
| `.gitignore` | Exclude binary artifacts (*.qcow2, *.iso) |
| `README.md` | Complete rewrite - clean getting started guide |
| `cloud-init-userdata.yaml` | Fixed config with working password setup |
| `build-release.sh` | **New** - consolidated build script |
| `run-tide-qemu.sh` | Enhanced with `fresh`/`test` modes |
| `dev-docs/` | **New** - archived old documentation |

---

## Commands Reference

### Build Release Artifacts
```bash
./build-release.sh
# Outputs: cloud-init.iso, tide-gateway.qcow2
```

### Test the Gateway
```bash
# Fresh boot (no state)
./run-tide-qemu.sh fresh

# Test mode (SSH on localhost:2222)
./run-tide-qemu.sh test
ssh -p 2222 root@localhost  # password: tide
```

### Verify Tor is Working
```bash
# Inside the VM
curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
```

---

## Technical Specifications

| Component | Value |
|-----------|-------|
| Gateway IP | 10.101.101.10 |
| Login | root / tide |
| Tor TransPort | 9040 |
| Tor DNSPort | 5353 |
| SOCKS5 Proxy | 9050 |
| Platform | Alpine Linux 3.19 (ARM64) |

---

## Release Artifacts

Published to [GitHub Releases v1.1.0](https://github.com/bodegga/tide/releases/tag/v1.1.0):

- `tide-gateway.qcow2` - Pre-configured gateway image
- `cloud-init.iso` - Cloud-init configuration ISO
- `tide-autoinstall-efi.iso` - EFI bootable installer

---

## Next Steps / Future Improvements

1. **Auto-verify Tor connectivity** - Add health check to boot sequence
2. **Client configuration script** - Automate routing setup for connected machines
3. **Persistence options** - Document how to save state between reboots
4. **Multi-arch builds** - Add x86_64 support for broader compatibility
5. **Hardening** - Firewall audit, minimal attack surface review

---

*Session documented by The Scribe*
