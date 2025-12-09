# opsec-vm → Tide Transformation Archive

**Original Project:** opsec-vm  
**Transformed To:** Tide Gateway  
**Transformation Date:** December 2025  
**Current Repository:** [bodegga/tide](https://github.com/bodegga/tide)

## Project Evolution

The `opsec-vm` project was originally conceived as a hardened operational security virtual machine. Through development, it evolved into **Tide Gateway** - a transparent Tor proxy system with multiple deployment modes.

### Key Transformations

1. **Branding:** opsec-vm → Tide Gateway
2. **Focus:** General OPSEC → Specialized Tor Gateway
3. **Features:** Expanded to include:
   - Multiple deployment modes (Proxy, Router, Forced, Takeover)
   - Security profiles (Standard, Hardened, Paranoid, Bridges)
   - Client applications for auto-discovery
   - Multi-hypervisor support

### Technical Improvements

- **Fail-closed security** - Traffic blocked if Tor fails
- **Immutable configuration** - Critical files locked with `chattr +i`
- **Zero-config clients** - DHCP + DNS handle everything
- **Discovery API** - HTTP API for gateway management
- **Multi-format builds** - Support for QEMU, VMware, VirtualBox, Parallels

## Archive Status

The transformation is complete. The project lives on as **Tide Gateway** with:
- ✅ GitHub repository renamed to `bodegga/tide`
- ✅ Local directory renamed to `tide/`
- ✅ All documentation updated
- ✅ All references migrated
- ✅ Build scripts updated

## Legacy Files

Original opsec-vm concept files are preserved in `tide/_dev-archive/` for historical reference.

---

*opsec-vm served its purpose as the prototype that evolved into Tide Gateway. The project's success lies in this transformation.*