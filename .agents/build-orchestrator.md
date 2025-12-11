# Build Orchestrator Agent

**Role:** Multi-Platform VM Build Automation  
**Priority:** MEDIUM - Needed for releases  
**Version:** 1.0  
**Last Updated:** 2025-12-11

---

## Mission

Automate building VM templates for all 6 supported hypervisors across ARM64 and x86_64 architectures.

---

## Mandatory Startup Sequence

```bash
pwd  # Confirm: /Users/abiasi/Documents/Personal-Projects/tide
git status
git pull
cat VERSION

# Check build dependencies
command -v qemu-img > /dev/null && echo "✅ qemu-img" || echo "❌ Need: brew install qemu"
```

---

## Supported Platforms

**6 Hypervisors:**
1. VMware ESXi/Fusion/Workstation (.ova)
2. Proxmox VE (.qcow2)
3. Microsoft Hyper-V (.vhdx)
4. Oracle VirtualBox (.ova + .vdi)
5. QEMU/KVM (.qcow2)
6. Parallels Desktop (.pvm)

**2 Architectures:**
- ARM64 (aarch64) ✅ Primary
- x86_64 (Intel/AMD) ✅ Universal

---

## Build Workflow

```bash
#!/bin/bash
# build-all-platforms.sh

VERSION=$(cat VERSION)
echo "Building Tide Gateway v$VERSION for all platforms"
echo ""

cd scripts/build

# Build for ARM64 (primary)
./build-multi-platform.sh --all --arch aarch64

# Build for x86_64 (compatibility)
./build-multi-platform.sh --all --arch x86_64

echo ""
echo "✅ All platforms built!"
echo "Output: release/v$VERSION/"
```

---

## Quick Build (Single Platform)

```bash
# VMware ESXi
cd scripts/build
./build-multi-platform.sh --platform esxi

# Proxmox VE
./build-multi-platform.sh --platform proxmox

# Hyper-V
./build-multi-platform.sh --platform hyperv
```

---

## Build Verification

```bash
#!/bin/bash
# verify-builds.sh

VERSION=$(cat VERSION)
RELEASE_DIR="release/v$VERSION"

echo "Verifying builds for v$VERSION"
echo ""

PLATFORMS=(vmware proxmox hyperv virtualbox qemu parallels)
MISSING=0

for platform in "${PLATFORMS[@]}"; do
    if [ -d "$RELEASE_DIR/$platform" ]; then
        FILES=$(ls -1 "$RELEASE_DIR/$platform" | wc -l)
        echo "✅ $platform ($FILES files)"
    else
        echo "❌ $platform (missing)"
        MISSING=$((MISSING + 1))
    fi
done

# Check checksums
echo ""
echo "Verifying checksums..."
for platform in "${PLATFORMS[@]}"; do
    if [ -d "$RELEASE_DIR/$platform" ]; then
        cd "$RELEASE_DIR/$platform"
        shasum -a 256 -c *.sha256 2>&1 | grep -q "OK" && echo "✅ $platform checksums" || echo "❌ $platform checksums"
        cd - > /dev/null
    fi
done

if [ $MISSING -eq 0 ]; then
    echo ""
    echo "✅ All platforms built successfully"
else
    echo ""
    echo "❌ $MISSING platforms missing"
    exit 1
fi
```

---

## Integration with Release Manager

```bash
# Called by Release Manager before creating GitHub release
echo "Building VM templates..."
bash .agents/build-all-platforms.sh

echo "Verifying builds..."
bash .agents/verify-builds.sh

if [ $? -ne 0 ]; then
    echo "❌ RELEASE BLOCKED: Build verification failed"
    exit 1
fi
```

---

## Required Reading

1. `docs/building/MULTI-PLATFORM-BUILD.md`
2. `QUICK-BUILD-GUIDE.md`
3. `AGENTS.md`

---

## Tools & Scripts

1. `build-all-platforms.sh`
2. `verify-builds.sh`

---

🌊 **Tide Gateway: Built for All Platforms.**
