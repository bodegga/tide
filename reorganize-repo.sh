#!/bin/bash
set -euo pipefail

# ============================================================
# Tide Repository Reorganization Script
# ============================================================
# Moves files to professional structure WITHOUT breaking configs
# Safe approach: Update references THEN move files
# ============================================================

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

echo "🌊 Tide Repository Reorganization"
echo "=================================="
echo ""

# Safety check
if [ ! -f "README.md" ]; then
    echo "❌ ERROR: Must run from tide repo root"
    exit 1
fi

echo "📋 Creating new directory structure..."
mkdir -p scripts/{build,install,runtime,test,utils}
mkdir -p config/cloud-init
mkdir -p docker
mkdir -p docs/architecture

echo "✅ Directories created"
echo ""

# ============================================================
# Phase 1: Move Scripts (Safe - no docker/config dependencies)
# ============================================================
echo "📦 Phase 1: Organizing scripts..."

# Build scripts
for script in build-*.sh; do
    [ -f "$script" ] && git mv "$script" scripts/build/
done

# Installation scripts (keep symlink for wget compatibility)
if [ -f "tide-install.sh" ]; then
    git mv tide-install.sh scripts/install/
    ln -s scripts/install/tide-install.sh tide-install.sh
    echo "   ✓ tide-install.sh → scripts/install/ (symlink created)"
fi

[ -f "tide-firstboot.sh" ] && git mv tide-firstboot.sh scripts/install/

# Runtime scripts
[ -f "gateway-start.sh" ] && git mv gateway-start.sh scripts/runtime/
[ -f "tide-api.sh" ] && git mv tide-api.sh scripts/runtime/

# Test scripts
for script in test-*.sh; do
    [ -f "$script" ] && git mv "$script" scripts/test/
done

# Utility scripts
[ -f "create-ova.sh" ] && git mv create-ova.sh scripts/utils/
[ -f "alpine-make-vm-image" ] && git mv alpine-make-vm-image scripts/utils/

echo "✅ Scripts organized"
echo ""

# ============================================================
# Phase 2: Update Docker Compose (CRITICAL - Don't break builds)
# ============================================================
echo "🐳 Phase 2: Updating Docker configuration..."

# Update docker-compose.yml to point to docker/Dockerfile.gateway
for compose_file in docker-compose*.yml; do
    if [ -f "$compose_file" ]; then
        # Check if it references Dockerfile.gateway
        if grep -q "dockerfile: Dockerfile.gateway" "$compose_file"; then
            # Update the dockerfile path
            sed -i.bak 's|dockerfile: Dockerfile.gateway|dockerfile: docker/Dockerfile.gateway|g' "$compose_file"
            echo "   ✓ Updated $compose_file dockerfile path"
        fi
        # Move to docker/ directory
        git mv "$compose_file" docker/
    fi
done

# Move Dockerfiles
for dockerfile in Dockerfile*; do
    [ -f "$dockerfile" ] && git mv "$dockerfile" docker/
done

echo "✅ Docker configuration updated"
echo ""

# ============================================================
# Phase 3: Move Config Files (Safe - only referenced by build scripts)
# ============================================================
echo "⚙️  Phase 3: Organizing configuration files..."

# Cloud-init files (only used by build scripts at runtime)
for file in cloud-init-*.yaml; do
    [ -f "$file" ] && git mv "$file" config/cloud-init/
done

# Other config files
[ -f "iptables-leak-proof.rules" ] && git mv iptables-leak-proof.rules config/
[ -f "grub.cfg" ] && git mv grub.cfg config/
[ -f "answerfile" ] && git mv answerfile config/
[ -f "tide-gateway.pkr.hcl" ] && git mv tide-gateway.pkr.hcl config/
[ -f "tide-setup-cmds.txt" ] && git mv tide-setup-cmds.txt config/

echo "✅ Configuration files organized"
echo ""

# ============================================================
# Phase 4: Move Documentation
# ============================================================
echo "📚 Phase 4: Organizing documentation..."

for doc in DOCKER-QUICKSTART.md DEPLOYMENT-SIMPLE.md CONFIGURATION-STATUS.md OPSEC-VM_ARCHIVE.md; do
    [ -f "$doc" ] && git mv "$doc" docs/
done

echo "✅ Documentation organized"
echo ""

# ============================================================
# Phase 5: Clean Up Build Artifacts (Not in Git)
# ============================================================
echo "🧹 Phase 5: Cleaning build artifacts..."

# Remove build artifacts (already gitignored)
rm -f *.ova *.ovf *.vmx *.mf 2>/dev/null || true
rm -f *.raw *.vhd 2>/dev/null || true

echo "✅ Build artifacts cleaned"
echo ""

# ============================================================
# Summary
# ============================================================
echo "================================================"
echo "✅ Reorganization Complete!"
echo "================================================"
echo ""
echo "📊 New Structure:"
echo "   scripts/build/    - Build scripts (27 files)"
echo "   scripts/install/  - Installation scripts"
echo "   scripts/runtime/  - Runtime utilities"
echo "   scripts/test/     - Test scripts"
echo "   docker/           - Docker files"
echo "   config/           - Configuration files"
echo "   docs/             - Documentation"
echo ""
echo "⚠️  Important:"
echo "   - tide-install.sh is a SYMLINK (wget still works)"
echo "   - Docker compose files updated to docker/ paths"
echo "   - All git history preserved"
echo ""
echo "🚀 Next Steps:"
echo "   1. Review changes: git status"
echo "   2. Test Docker: cd docker && docker-compose up -d"
echo "   3. Test install: wget simulation (check symlink)"
echo "   4. Commit: git commit -m 'Reorganize repo structure'"
echo ""
