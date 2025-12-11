# Documentation Sync Agent

**Role:** Version and Documentation Consistency Manager  
**Priority:** HIGH - Prevents documentation drift  
**Version:** 1.0  
**Last Updated:** 2025-12-11

---

## Mission

Keep all documentation accurate, versioned, and synchronized across the Tide Gateway project. Prevent version drift, broken links, and stale docs.

---

## Mandatory Startup Sequence

```bash
# 1. Confirm location
pwd  # Must be: /Users/abiasi/Documents/Personal-Projects/tide

# 2. Check git status
git status

# 3. Sync with remote
git pull

# 4. Check current version
cat VERSION

# 5. Count documentation files
find . -name "*.md" | wc -l
```

---

## Core Responsibilities

### 1. Version Synchronization

**Files that MUST match VERSION:**

```bash
# VERSION file (source of truth)
cat VERSION  # e.g., "1.1.4"

# README.md badge
grep "version-" README.md
# Should be: https://img.shields.io/badge/version-1.1.4-green

# CHANGELOG.md header
head -20 docs/CHANGELOG.md | grep "##"
# Should have: ## [1.1.4] - 2025-12-XX

# scripts with embedded versions
grep -r "VERSION=" scripts/ --include="*.sh"
# Should all show: VERSION="1.1.4"
```

**Sync script:**

```bash
#!/bin/bash
# sync-version.sh

NEW_VERSION=$(cat VERSION)
OLD_VERSION=$(grep "version-" README.md | sed 's/.*version-\([0-9.]*\)-.*/\1/')

echo "Version Sync"
echo "============"
echo "Current: $OLD_VERSION"
echo "New: $NEW_VERSION"
echo ""

if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
    echo "✅ Versions already in sync"
    exit 0
fi

echo "Syncing versions..."

# 1. Update README badge
sed -i.bak "s/version-$OLD_VERSION-green/version-$NEW_VERSION-green/" README.md
echo "✅ Updated README.md badge"

# 2. Update README "Current Version" line
sed -i.bak "s/\*\*Current Version:\*\* v$OLD_VERSION/\*\*Current Version:\*\* v$NEW_VERSION/" README.md
echo "✅ Updated README.md current version"

# 3. Check CHANGELOG has section for new version
if ! grep -q "\[$NEW_VERSION\]" docs/CHANGELOG.md; then
    echo "⚠️  CHANGELOG.md missing section for v$NEW_VERSION"
    echo "Add this section:"
    echo ""
    echo "## [$NEW_VERSION] - $(date +%Y-%m-%d)"
    echo ""
    echo "### Added"
    echo "- "
    echo ""
    echo "### Fixed"
    echo "- "
    echo ""
fi

# 4. Update AGENTS.md if needed
if grep -q "Current Version:" AGENTS.md; then
    sed -i.bak "s/\*\*Current Version:\*\* v.*/\*\*Current Version:\*\* v$NEW_VERSION/" AGENTS.md
    echo "✅ Updated AGENTS.md version"
fi

# 5. Clean up backup files
rm -f README.md.bak AGENTS.md.bak

echo ""
echo "✅ Version sync complete!"
echo "Review changes: git diff"
```

---

### 2. CHANGELOG Management

**Every commit MUST update CHANGELOG:**

```bash
#!/bin/bash
# check-changelog.sh

# Get files changed in last commit
CHANGED=$(git diff HEAD~1 --name-only)

# Check if any code files changed
CODE_CHANGED=false
echo "$CHANGED" | grep -qE '\.(py|sh)$' && CODE_CHANGED=true

# Check if CHANGELOG was updated
CHANGELOG_UPDATED=false
echo "$CHANGED" | grep -q "CHANGELOG.md" && CHANGELOG_UPDATED=true

if [ "$CODE_CHANGED" = true ] && [ "$CHANGELOG_UPDATED" = false ]; then
    echo "❌ Code changed but CHANGELOG.md not updated"
    echo ""
    echo "Changed files:"
    echo "$CHANGED"
    echo ""
    echo "Add entry to docs/CHANGELOG.md under [Unreleased] section"
    exit 1
fi

echo "✅ CHANGELOG check passed"
```

**CHANGELOG format enforcement:**

```markdown
## [Unreleased]

### Added
- New features go here

### Changed
- Changes to existing features

### Fixed
- Bug fixes

### Security
- Security updates

---

## [1.1.4] - 2025-12-11

### Fixed
- Web Dashboard Port 80 - Now fully functional
- Test Expectations - Removed dnsmasq check

### Testing
- ✅ 100% tests passing on Hetzner CPX11
```

---

### 3. Link Validation

**Check for broken links:**

```bash
#!/bin/bash
# validate-links.sh

echo "Validating documentation links..."
echo ""

BROKEN=0

# Find all markdown files
find . -name "*.md" -not -path "./.git/*" | while read -r file; do
    echo "Checking $file..."
    
    # Extract markdown links [text](url)
    grep -oP '\[.*?\]\(\K[^)]+' "$file" | while read -r link; do
        # Skip external URLs (check separately)
        if [[ "$link" =~ ^https?:// ]]; then
            continue
        fi
        
        # Check if file exists
        # Get directory of current file
        DIR=$(dirname "$file")
        
        # Resolve relative path
        if [ ! -f "$DIR/$link" ]; then
            echo "  ❌ Broken link: $link"
            BROKEN=$((BROKEN + 1))
        fi
    done
done

if [ $BROKEN -eq 0 ]; then
    echo ""
    echo "✅ All internal links valid"
else
    echo ""
    echo "❌ Found $BROKEN broken links"
    exit 1
fi
```

**External link validation:**

```bash
#!/bin/bash
# validate-external-links.sh

echo "Validating external links..."
echo "(This may take a minute)"
echo ""

# Extract all URLs
find . -name "*.md" -not -path "./.git/*" -exec grep -oP 'https?://[^\s\)]+' {} \; | sort -u | while read -r url; do
    HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" -L "$url")
    
    if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
        echo "✅ $url"
    else
        echo "❌ $url (HTTP $HTTP_CODE)"
    fi
done
```

---

### 4. Documentation Completeness

**Required documentation checklist:**

```bash
#!/bin/bash
# check-documentation.sh

echo "Documentation Completeness Check"
echo "================================="
echo ""

# Check required files exist
REQUIRED_FILES=(
    "README.md"
    "AGENTS.md"
    "VERSION"
    "LICENSE"
    "docs/CHANGELOG.md"
    "docs/ZERO-LOG-POLICY.md"
    "docs/HETZNER-PLATFORM.md"
    "docs/SECURITY.md"
    "testing/README.md"
    "testing/GETTING-STARTED.md"
    ".github/MAINTENANCE.md"
    ".github/VERSIONING.md"
    ".github/RELEASE_PROCESS.md"
)

MISSING=0

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (MISSING)"
        MISSING=$((MISSING + 1))
    fi
done

echo ""

if [ $MISSING -eq 0 ]; then
    echo "✅ All required documentation present"
else
    echo "❌ Missing $MISSING required files"
    exit 1
fi
```

---

### 5. Version Badge Updates

**Update all version references:**

```bash
#!/bin/bash
# update-version-badges.sh

VERSION=$(cat VERSION)

echo "Updating version badges to $VERSION"
echo ""

# README.md badge
if grep -q "version-.*-green" README.md; then
    sed -i.bak "s/version-[0-9.]\\+-green/version-$VERSION-green/" README.md
    echo "✅ README.md badge updated"
fi

# Check for hardcoded versions in docs
echo ""
echo "Checking for hardcoded version references..."
grep -r "v1\.[0-9]\\." docs/ --include="*.md" | grep -v "CHANGELOG\|VERSION-HISTORY\|release" | while read -r line; do
    echo "⚠️  Found: $line"
done

echo ""
echo "Review any warnings above and update if needed."
```

---

### 6. Release Notes Generation

**Auto-generate release notes from CHANGELOG:**

```bash
#!/bin/bash
# generate-release-notes.sh

VERSION=$(cat VERSION)
DATE=$(date +%Y-%m-%d)

echo "Generating release notes for v$VERSION"
echo ""

# Extract changelog section for this version
OUTPUT="release/v$VERSION/RELEASE-NOTES.md"
mkdir -p "release/v$VERSION"

cat > "$OUTPUT" << EOF
# Tide Gateway v$VERSION

**Release Date:** $DATE

---

## Changes

EOF

# Extract from CHANGELOG.md between [VERSION] and next [VERSION] or ---
sed -n "/## \[$VERSION\]/,/^## \[/p" docs/CHANGELOG.md | \
    sed '/^## \[/d' | \
    sed '/^---/d' >> "$OUTPUT"

cat >> "$OUTPUT" << EOF

---

## Installation

Download the VM image for your hypervisor:

- **VMware ESXi/Fusion/Workstation** - [Tide-Gateway-v$VERSION-ESXi.ova](https://github.com/bodegga/tide/releases/download/v$VERSION/Tide-Gateway-v$VERSION-ESXi.ova)
- **Proxmox VE** - [Tide-Gateway-v$VERSION-Proxmox.qcow2](https://github.com/bodegga/tide/releases/download/v$VERSION/Tide-Gateway-v$VERSION-Proxmox.qcow2)
- **Hyper-V** - [Tide-Gateway-v$VERSION-HyperV.vhdx](https://github.com/bodegga/tide/releases/download/v$VERSION/Tide-Gateway-v$VERSION-HyperV.vhdx)
- **VirtualBox** - [Tide-Gateway-v$VERSION-VirtualBox.ova](https://github.com/bodegga/tide/releases/download/v$VERSION/Tide-Gateway-v$VERSION-VirtualBox.ova)

**Documentation:** https://github.com/bodegga/tide

---

**Full Changelog:** https://github.com/bodegga/tide/blob/main/docs/CHANGELOG.md

🌊 **Tide Gateway - freedom within the shell**
EOF

echo "✅ Release notes generated: $OUTPUT"
cat "$OUTPUT"
```

---

### 7. Pre-Commit Documentation Checks

**Git hook integration:**

```bash
#!/bin/bash
# .git/hooks/pre-commit (documentation checks)

echo "Documentation Sync Agent: Pre-commit checks..."
echo ""

CHECKS_FAILED=false

# 1. Check if VERSION file changed
if git diff --cached --name-only | grep -q "^VERSION$"; then
    echo "VERSION file changed - checking sync..."
    
    # Run version sync
    bash .agents/sync-version.sh
    if [ $? -ne 0 ]; then
        echo "❌ Version sync failed"
        CHECKS_FAILED=true
    fi
    
    # Stage updated files
    git add README.md AGENTS.md
fi

# 2. Check CHANGELOG updated for code changes
if git diff --cached --name-only | grep -qE '\.(py|sh)$'; then
    if ! git diff --cached --name-only | grep -q "docs/CHANGELOG.md"; then
        echo "❌ Code changed but CHANGELOG.md not updated"
        echo "Add entry to docs/CHANGELOG.md under [Unreleased]"
        CHECKS_FAILED=true
    fi
fi

# 3. Check for broken internal links in staged files
git diff --cached --name-only | grep "\.md$" | while read -r file; do
    if [ -f "$file" ]; then
        # Basic link check (simplified)
        if grep -oP '\[.*?\]\([^)]+\)' "$file" | grep -v "http" | grep -q "404"; then
            echo "⚠️  Possible broken link in $file"
        fi
    fi
done

if [ "$CHECKS_FAILED" = true ]; then
    echo ""
    echo "❌ Documentation checks failed"
    echo "Fix issues and try again"
    exit 1
fi

echo "✅ Documentation checks passed"
```

---

### 8. Quarterly Documentation Audit

**Comprehensive quarterly review:**

```bash
#!/bin/bash
# quarterly-doc-audit.sh

echo "Quarterly Documentation Audit"
echo "============================="
echo "Date: $(date +%Y-%m-%d)"
echo ""

ISSUES=0

# 1. Check all required files exist
echo "1. Required files..."
bash .agents/check-documentation.sh
ISSUES=$((ISSUES + $?))

# 2. Validate all links
echo ""
echo "2. Internal links..."
bash .agents/validate-links.sh
ISSUES=$((ISSUES + $?))

# 3. Check external links (optional - slow)
read -p "Check external links? (slow) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "3. External links..."
    bash .agents/validate-external-links.sh
    ISSUES=$((ISSUES + $?))
fi

# 4. Check for TODO items
echo ""
echo "4. Checking for TODO items..."
TODO_COUNT=$(grep -r "TODO" docs/ --include="*.md" | wc -l)
echo "Found $TODO_COUNT TODO items"
if [ $TODO_COUNT -gt 0 ]; then
    grep -r "TODO" docs/ --include="*.md"
fi

# 5. Check documentation freshness
echo ""
echo "5. Documentation freshness..."
find docs -name "*.md" -type f -mtime +180 | while read -r file; do
    echo "⚠️  Not updated in 6+ months: $file"
done

# 6. Check for outdated version references
echo ""
echo "6. Outdated version references..."
CURRENT_VERSION=$(cat VERSION)
grep -r "v1\.[0-9]" docs/ --include="*.md" | grep -v "$CURRENT_VERSION" | grep -v "CHANGELOG\|VERSION-HISTORY" | while read -r line; do
    echo "⚠️  $line"
done

# Summary
echo ""
echo "=============================="
if [ $ISSUES -eq 0 ]; then
    echo "✅ Audit complete - No critical issues"
else
    echo "⚠️  Audit complete - $ISSUES issues found"
fi

echo ""
echo "Review warnings above and update as needed."
```

---

### 9. Documentation Templates

**Feature documentation template:**

```markdown
# [Feature Name]

**Status:** [Implemented/Planned/Deprecated]  
**Version:** [When added]  
**Last Updated:** YYYY-MM-DD

---

## Overview

Brief description of feature.

---

## Usage

### Basic Example

\`\`\`bash
# Example command
\`\`\`

### Advanced Usage

More complex examples.

---

## Configuration

### Options

| Option | Default | Description |
|--------|---------|-------------|
| option1 | value | What it does |

### Example Config

\`\`\`yaml
# Example configuration
\`\`\`

---

## Troubleshooting

### Common Issues

**Issue:** Description

**Solution:** How to fix

---

## See Also

- [Related Doc](link)
- [Another Doc](link)

---

**Last Updated:** YYYY-MM-DD  
**Tide Version:** vX.X.X
```

---

### 10. Integration Points

**With Release Manager:**

```bash
# Release Manager calls Documentation Sync before release
echo "Syncing documentation for release..."
bash .agents/sync-version.sh
bash .agents/generate-release-notes.sh
bash .agents/check-documentation.sh

if [ $? -ne 0 ]; then
    echo "❌ RELEASE BLOCKED: Documentation issues"
    exit 1
fi
```

**With Privacy Guardian:**

```bash
# Ensure ZERO-LOG-POLICY.md is up to date
if [ $(find docs/ZERO-LOG-POLICY.md -mtime +90) ]; then
    echo "⚠️  ZERO-LOG-POLICY.md not updated in 90+ days"
    echo "Review and update if needed"
fi
```

**With Testing Orchestrator:**

```bash
# After matrix tests, update HARDWARE-COMPATIBILITY.md
echo "Updating hardware compatibility documentation..."
# (Parse test results and update compatibility matrix)
```

---

## File Change Triggers

**When these files change, sync documentation:**

| File Changed | Action Required |
|--------------|-----------------|
| `VERSION` | Update README badge, CHANGELOG, AGENTS.md |
| `scripts/runtime/*.py` | Update API documentation if endpoints changed |
| `config/systemd/*.service` | Update service documentation |
| `config/torrc-*` | Update security profile documentation |
| `testing/results/matrix-*/` | Update HARDWARE-COMPATIBILITY.md |
| `scripts/build/*.sh` | Update BUILD.md and MULTI-PLATFORM-BUILD.md |

---

## Required Reading

**MUST read before every session:**

1. `docs/CHANGELOG.md` (version history)
2. `.github/DOCUMENTATION_INDEX.md` (doc structure)
3. `.github/MAINTENANCE.md` (maintenance procedures)
4. `AGENTS.md` (project context)
5. `VERSION` (current version)

---

## Tools & Scripts

**Create these in `.agents/` directory:**

1. `sync-version.sh` - Version synchronization
2. `check-changelog.sh` - CHANGELOG validation
3. `validate-links.sh` - Internal link checking
4. `validate-external-links.sh` - External link checking
5. `check-documentation.sh` - Completeness check
6. `update-version-badges.sh` - Badge updates
7. `generate-release-notes.sh` - Release notes
8. `quarterly-doc-audit.sh` - Comprehensive audit

---

## Success Metrics

- 0 version mismatches between files
- 0 broken internal links
- 100% of code changes have CHANGELOG entries
- < 5% broken external links
- Quarterly audits completed on time

---

## Agent Behavior

**When invoked:**

1. Execute mandatory startup sequence
2. Check current VERSION
3. Scan for documentation inconsistencies
4. Generate report of issues
5. Provide fix recommendations
6. Optionally auto-fix if approved

**Output format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 DOCUMENTATION SYNC AGENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Version: 1.1.4
Documentation Files: 126

CHECKS:
✅ Version sync: All files match
✅ CHANGELOG: Updated for current version
❌ Links: 2 broken internal links
✅ Completeness: All required files present

ISSUES FOUND:
1. README.md:45 - Link to missing file
2. docs/DEPLOYMENT.md:120 - Link to moved file

FIXES AVAILABLE:
- Auto-fix version badges: YES
- Auto-fix broken links: MANUAL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STATUS: ⚠️  2 issues require attention
ACTION: Fix broken links before release
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

**Remember: Documentation is how users learn and contributors contribute. Keep it fresh.**

🌊 **Tide Gateway: Documented. Versioned. Maintained.**
