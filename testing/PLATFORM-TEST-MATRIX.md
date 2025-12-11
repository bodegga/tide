# Tide Gateway - Platform Testing Matrix

## Testing Goals

Ensure Tide Gateway deploys easily on **every major virtualization platform** with minimal user interaction.

---

## Target Platforms

### Cloud Providers
- [x] **Hetzner Cloud** - Linux KVM (TESTED ✅)
- [ ] **AWS EC2** - Xen/Nitro hypervisor
- [ ] **DigitalOcean** - KVM
- [ ] **Linode** - KVM
- [ ] **Vultr** - KVM
- [ ] **Google Cloud** - Custom hypervisor

### Hypervisors (Type 1 - Bare Metal)
- [ ] **Proxmox VE** - KVM-based (open source)
- [ ] **VMware ESXi** - Industry standard
- [ ] **Microsoft Hyper-V** - Windows Server
- [ ] **Citrix Hypervisor** (XenServer)
- [ ] **oVirt/RHEV** - Red Hat KVM

### Hypervisors (Type 2 - Hosted)
- [ ] **VirtualBox** - Cross-platform (Windows, macOS, Linux)
- [ ] **VMware Workstation** - Windows/Linux
- [ ] **VMware Fusion** - macOS
- [ ] **Parallels Desktop** - macOS (partial testing done)
- [ ] **QEMU/KVM** - Linux (partial testing done)
- [ ] **UTM** - macOS (QEMU-based)
- [ ] **Hyper-V** - Windows 10/11

### Container Platforms
- [ ] **Docker** - All platforms
- [ ] **Podman** - Linux/macOS
- [ ] **LXC/LXD** - Linux containers
- [ ] **Kubernetes** - Container orchestration

### Bare Metal / Direct Install
- [ ] **Alpine Linux** - x86_64
- [ ] **Alpine Linux** - ARM64
- [ ] **Ubuntu Server** - x86_64
- [ ] **Debian** - x86_64
- [ ] **Raspberry Pi** - ARM (Pi 4/5)

---

## Test Criteria

For each platform, we need to verify:

### ✅ Deployment
- [ ] Can create VM/container with minimal steps
- [ ] Automated installation script works
- [ ] Network configuration is automatic or simple
- [ ] Takes <5 minutes from start to working gateway

### ✅ Core Features
- [ ] Tor connects successfully
- [ ] Web dashboard accessible (http://tide.bodegga.net)
- [ ] CLI commands work (`tide status`, `tide mode`, etc.)
- [ ] Mode switching works without redeploy
- [ ] DHCP server works (router/killa-whale modes)
- [ ] DNS hijacking works for tide.bodegga.net

### ✅ Performance
- [ ] Boots in <60 seconds
- [ ] Uses <512MB RAM idle
- [ ] Uses <2GB disk space
- [ ] Tor circuit establishes in <30 seconds

### ✅ User Experience
- [ ] Clear documentation for platform
- [ ] One-command or one-click deployment
- [ ] No manual networking configuration needed
- [ ] Error messages are helpful

---

## Testing Priority

### Tier 1 (MUST WORK - Most Common)
1. ✅ **Hetzner Cloud** (tested, works)
2. **VirtualBox** - Most accessible for testing
3. **Proxmox VE** - Popular homelab platform
4. **Docker** - Easiest deployment
5. **AWS EC2** - Enterprise standard

### Tier 2 (SHOULD WORK - Common Platforms)
6. **VMware ESXi** - Enterprise standard
7. **Hyper-V** - Windows shops
8. **DigitalOcean** - Popular VPS
9. **QEMU/KVM** - Linux standard
10. **UTM** - macOS users

### Tier 3 (NICE TO HAVE - Niche)
11. Parallels Desktop (macOS)
12. VMware Fusion/Workstation
13. Linode/Vultr
14. Bare metal Alpine
15. Raspberry Pi

---

## Automated Testing Plan

### Phase 1: Cloud Platforms (API-driven)
- [x] Hetzner Cloud (done - `deployment/hetzner/test-on-hetzner.sh`)
- [ ] DigitalOcean (doctl CLI)
- [ ] AWS EC2 (aws CLI)
- [ ] Linode (linode-cli)

**Deliverable:** Script for each that:
1. Creates VM via API
2. Installs Tide
3. Runs test suite
4. Destroys VM
5. Reports results

### Phase 2: Local Hypervisors (CLI-driven)
- [ ] VirtualBox (VBoxManage CLI)
- [ ] QEMU/KVM (qemu-system-* CLI)
- [ ] Hyper-V (PowerShell)
- [ ] UTM (scripted)

**Deliverable:** Script for each that:
1. Creates VM programmatically
2. Boots Alpine ISO
3. Runs automated install
4. Tests gateway
5. Can be run in CI/CD

### Phase 3: Enterprise Hypervisors (API-driven)
- [ ] Proxmox VE (pvesh/API)
- [ ] VMware ESXi (govc/PowerCLI)
- [ ] oVirt (REST API)

**Deliverable:** Script + documentation for each

### Phase 4: Containers
- [ ] Docker (Dockerfile + docker-compose)
- [ ] Podman (compatible with Docker)
- [ ] LXC (template)

**Deliverable:** One-command deployment for each

---

## Current Status

### ✅ Tested & Working
- **Hetzner Cloud (KVM)** - Full automated testing
  - Script: `deployment/hetzner/test-on-hetzner.sh`
  - Cost: $0.003 per test
  - Time: 3-4 minutes
  - Results: All v1.2.0 features work

### ⚠️ Partial Testing
- **Parallels Desktop (macOS)** - Manual testing only
  - VMs deployed but not automated
  - No Parallels Tools (keeping lightweight)
  - Manual console access required

### ❌ Not Tested Yet
- Everything else

---

## Next Steps

### Immediate (This Session)
1. **VirtualBox** - Most accessible, cross-platform
   - Create automated test using VBoxManage
   - Works on macOS, Windows, Linux
   - Free and open source

2. **Docker** - Easiest deployment
   - Create Dockerfile for Tide Gateway
   - docker-compose for easy setup
   - Most portable option

3. **Proxmox VE** - Popular homelab
   - Test on Hetzner (they offer Proxmox hosts)
   - or spin up Proxmox VM for testing

### Short Term (Next Week)
4. **AWS EC2** - Enterprise validation
5. **VMware ESXi** - Enterprise validation
6. **DigitalOcean** - VPS validation

### Long Term (Future)
7. Raspberry Pi support
8. Bare metal Alpine install
9. All other platforms

---

## Test Automation Architecture

```
testing/
├── cloud/
│   ├── test-hetzner.sh     (DONE)
│   ├── test-digitalocean.sh
│   ├── test-aws-ec2.sh
│   └── test-linode.sh
│
├── hypervisors/
│   ├── test-virtualbox.sh
│   ├── test-qemu.sh
│   ├── test-proxmox.sh
│   ├── test-esxi.sh
│   └── test-hyperv.ps1
│
├── containers/
│   ├── test-docker.sh
│   ├── test-podman.sh
│   └── test-lxc.sh
│
└── results/
    └── platform-test-results.json
```

Each test script:
1. Creates environment
2. Deploys Tide Gateway
3. Runs standard test suite
4. Outputs JSON results
5. Cleans up

---

## Success Criteria

**Tide Gateway should:**
- Deploy on 10+ platforms with <5 minutes setup
- Have automated tests for top 5 platforms
- Have clear docs for top 10 platforms
- Work identically across all platforms

**User should be able to:**
- Choose their preferred platform
- Run one command (or click one button)
- Have working gateway in <5 minutes
- Switch modes without redeployment

---

**Current Coverage:** 1/30 platforms (3%)  
**Goal:** 10/30 platforms (33%) with automated tests  
**Stretch Goal:** 20/30 platforms (67%) documented

Let's get testing! 🌊
