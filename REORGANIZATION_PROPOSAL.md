# Tide Repository Reorganization Proposal

## Current Problem
Root directory has 60+ files including:
- 27 build scripts (`build-*.sh`, `create-*.sh`, `test-*.sh`)
- VM artifacts (`.ova`, `.ovf`, `.vmx`, `.mf`)
- Raw config files (`answerfile`, `grub.cfg`, `iptables-leak-proof.rules`)
- Cloud-init files scattered in root
- Binary files (gitignored but cluttering directory)

**Result:** Unprofessional, hard to navigate, unclear project structure.

---

## Proposed Professional Structure

```
tide/
├── README.md                    # Main project overview
├── LICENSE                      # Keep in root
├── .env.example                 # Environment template
├── .gitignore                   # Git configuration
│
├── docs/                        # ALL documentation
│   ├── README.md                # Docs index
│   ├── QUICK-START.md           # Getting started
│   ├── DOCKER-QUICKSTART.md     # Docker guide (move from root)
│   ├── DEPLOYMENT-SIMPLE.md     # Deployment guide (move from root)
│   ├── CONFIGURATION-STATUS.md  # Config docs (move from root)
│   ├── OPSEC-VM_ARCHIVE.md      # Archive notes (move from root)
│   ├── architecture/            # System design
│   └── testing/                 # Test reports
│       └── TIDE_GATEWAY_TEST_REPORT.md
│
├── scripts/                     # ALL scripts organized by purpose
│   ├── build/                   # Build scripts
│   │   ├── build-all-formats.sh
│   │   ├── build-autoinstall-iso.sh
│   │   ├── build-brute-iso.sh
│   │   ├── build-cloud-image.sh
│   │   ├── build-golden-image.sh
│   │   ├── build-master-image.sh
│   │   ├── build-parallels-image.sh
│   │   ├── build-parallels.sh
│   │   ├── build-qemu-image.sh
│   │   ├── build-release.sh
│   │   ├── build-tide-gateway-auto.sh
│   │   ├── build-tide-gateway.sh
│   │   ├── build-tide-image.sh
│   │   └── build-tide-iso.sh
│   ├── install/                 # Installation scripts
│   │   ├── tide-install.sh      # Main installer (keep symlink in root)
│   │   └── tide-firstboot.sh
│   ├── runtime/                 # Runtime utilities
│   │   ├── gateway-start.sh
│   │   └── tide-api.sh
│   ├── test/                    # Test scripts
│   │   ├── test-automated.sh
│   │   ├── test-simple.sh
│   │   ├── test-tide-network.sh
│   │   └── test-transparent-routing.sh
│   └── utils/                   # Other utilities
│       └── create-ova.sh
│
├── config/                      # Configuration files
│   ├── cloud-init/
│   │   ├── cloud-init-metadata.yaml
│   │   └── cloud-init-userdata.yaml
│   ├── iptables-leak-proof.rules
│   ├── grub.cfg
│   ├── answerfile
│   ├── tide-gateway.pkr.hcl     # Packer config
│   └── tide-setup-cmds.txt
│
├── docker/                      # Docker configurations
│   ├── Dockerfile               # Main Dockerfile (move from root)
│   ├── Dockerfile.gateway       # Gateway variant (move from root)
│   ├── docker-compose.yml       # Default compose (move from root)
│   ├── docker-compose.proxy.yml # Proxy variant (move from root)
│   └── docker-compose-test.yml  # Test variant (move from root)
│
├── client/                      # Client tools (already exists)
│   ├── tide-client.py
│   └── tide-connect.sh
│
├── iso_content/                 # ISO build content (keep as-is)
├── tide-validation/             # Validation tools (keep as-is)
├── tide-builder-vm/             # Builder VM config (keep as-is)
├── tide-pvm/                    # PVM config (keep as-is)
│
├── release/                     # Build artifacts (gitignored)
│   └── .gitkeep
│
└── _dev-archive/                # Old development files (keep as-is)
```

---

## Migration Plan

### Phase 1: Create New Structure
```bash
mkdir -p scripts/{build,install,runtime,test,utils}
mkdir -p config/cloud-init
mkdir -p docker
mkdir -p docs/architecture
```

### Phase 2: Move Build Scripts
```bash
mv build-*.sh scripts/build/
mv create-*.sh scripts/utils/
```

### Phase 3: Move Installation Scripts
```bash
mv tide-install.sh scripts/install/
mv tide-firstboot.sh scripts/install/
ln -s scripts/install/tide-install.sh tide-install.sh  # Symlink for wget compatibility
```

### Phase 4: Move Runtime Scripts
```bash
mv gateway-start.sh scripts/runtime/
mv tide-api.sh scripts/runtime/
```

### Phase 5: Move Test Scripts
```bash
mv test-*.sh scripts/test/
```

### Phase 6: Move Config Files
```bash
mv cloud-init-*.yaml config/cloud-init/
mv iptables-leak-proof.rules config/
mv grub.cfg config/
mv answerfile config/
mv tide-gateway.pkr.hcl config/
mv tide-setup-cmds.txt config/
```

### Phase 7: Move Docker Files
```bash
mv Dockerfile* docker/
mv docker-compose*.yml docker/
```

### Phase 8: Move Documentation
```bash
mv DOCKER-QUICKSTART.md docs/
mv DEPLOYMENT-SIMPLE.md docs/
mv CONFIGURATION-STATUS.md docs/
mv OPSEC-VM_ARCHIVE.md docs/
```

### Phase 9: Clean Up Artifacts
```bash
# These are build artifacts that shouldn't be in git
# (already gitignored, but remove from working directory)
rm -f *.ova *.ovf *.vmx *.mf
rm -f *.raw *.vhd
mv alpine-make-vm-image scripts/utils/
```

---

## Updated README References

After reorganization, update README.md installation command:
```bash
# OLD:
wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh

# NEW (still works due to symlink):
wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
```

---

## Benefits

✅ **Professional appearance** - Clean root with clear purpose  
✅ **Easy navigation** - Logical grouping by function  
✅ **Better documentation** - All docs in one place  
✅ **Simpler builds** - Build scripts grouped together  
✅ **Docker clarity** - Docker files in dedicated directory  
✅ **Backwards compatible** - Symlinks preserve old paths  
✅ **GitHub-friendly** - Standard open source structure

---

## Root Directory After (15 items vs 60+)

```
tide/
├── README.md
├── LICENSE
├── .env.example
├── .gitignore
├── tide-install.sh          # Symlink to scripts/install/tide-install.sh
├── client/                  # End-user tools
├── config/                  # Configuration files
├── docker/                  # Docker build files
├── docs/                    # Documentation
├── scripts/                 # All scripts organized
├── iso_content/             # ISO content
├── tide-validation/         # Validation
├── tide-builder-vm/         # Builder VM
├── tide-pvm/                # PVM tools
├── release/                 # Build artifacts
└── _dev-archive/            # Old dev files
```

---

**Ready to execute? This will make the repo look professional and maintainable.**
