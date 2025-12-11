# Release Manager Agent

**Role:** Automated Semantic Versioning and GitHub Release Management  
**Priority:** HIGH - Ensures consistent releases  
**Version:** 1.0  
**Last Updated:** 2025-12-11

---

## Mission

Automate the release process with semantic versioning, comprehensive testing, and GitHub release creation.

---

## Mandatory Startup Sequence

```bash
pwd  # Confirm: /Users/abiasi/Documents/Personal-Projects/tide
git status
git pull
cat VERSION
git log --oneline -5  # Recent commits
```

---

## Semantic Versioning

**Format:** MAJOR.MINOR.PATCH

- **MAJOR (X.0.0):** Breaking changes
- **MINOR (1.X.0):** New features, backwards compatible
- **PATCH (1.1.X):** Bug fixes, no new features

**Decision tree:**

```bash
#!/bin/bash
# determine-version-bump.sh

CURRENT=$(cat VERSION)
echo "Current version: $CURRENT"
echo ""
echo "What changed?"
echo "1) Bug fixes only → PATCH"
echo "2) New features (backwards compatible) → MINOR"
echo "3) Breaking changes → MAJOR"
read -p "Select (1-3): " choice

case $choice in
    1) TYPE="patch" ;;
    2) TYPE="minor" ;;
    3) TYPE="major" ;;
    *) echo "Invalid"; exit 1 ;;
esac

# Calculate new version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case $TYPE in
    patch) PATCH=$((PATCH + 1)) ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo ""
echo "New version: $NEW_VERSION"
echo "$NEW_VERSION" > VERSION
```

---

## Pre-Release Checklist

```bash
#!/bin/bash
# pre-release-checklist.sh

VERSION=$(cat VERSION)
echo "Pre-Release Checklist for v$VERSION"
echo "===================================="
echo ""

FAILED=0

# 1. Privacy Guardian audit
echo "[1/7] Privacy Guardian audit..."
bash .agents/privacy-guardian-release-audit.sh
FAILED=$((FAILED + $?))

# 2. All tests pass
echo "[2/7] Running comprehensive tests..."
cd testing && ./orchestrate-tests.sh run
FAILED=$((FAILED + $?))

# 3. Hetzner test REQUIRED
echo "[3/7] Hetzner test (REQUIRED)..."
cd cloud && ./test-hetzner.sh
FAILED=$((FAILED + $?))

# 4. Documentation sync
echo "[4/7] Documentation sync..."
bash .agents/sync-version.sh
FAILED=$((FAILED + $?))

# 5. CHANGELOG has entry
echo "[5/7] Checking CHANGELOG..."
if ! grep -q "\[$VERSION\]" docs/CHANGELOG.md; then
    echo "❌ CHANGELOG missing v$VERSION section"
    FAILED=$((FAILED + 1))
fi

# 6. No uncommitted changes
echo "[6/7] Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Uncommitted changes detected"
    git status --short
fi

# 7. Branch is main
echo "[7/7] Checking branch..."
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
    echo "⚠️  Not on main branch (currently: $BRANCH)"
fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo "✅ Pre-release checks passed"
    echo "Ready to release v$VERSION"
else
    echo "❌ $FAILED checks failed"
    echo "Fix issues before releasing"
    exit 1
fi
```

---

## Release Workflow

```bash
#!/bin/bash
# create-release.sh

VERSION=$(cat VERSION)
DATE=$(date +%Y-%m-%d)

echo "Creating release v$VERSION"
echo ""

# 1. Run pre-release checks
bash .agents/pre-release-checklist.sh
if [ $? -ne 0 ]; then
    echo "❌ Pre-release checks failed"
    exit 1
fi

# 2. Build VM images (if needed)
read -p "Build VM images? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd scripts/build
    ./build-multi-platform.sh --all
fi

# 3. Generate release notes
bash .agents/generate-release-notes.sh

# 4. Commit version bump
git add VERSION README.md docs/CHANGELOG.md
git commit -m "Release v$VERSION"

# 5. Create tag
git tag -a "v$VERSION" -m "Tide Gateway v$VERSION

$(cat release/v$VERSION/RELEASE-NOTES.md)"

# 6. Push to GitHub
git push origin main
git push origin "v$VERSION"

# 7. Create GitHub release
gh release create "v$VERSION" \
    --title "Tide Gateway v$VERSION" \
    --notes-file "release/v$VERSION/RELEASE-NOTES.md" \
    release/v$VERSION/**/*.{qcow2,vmdk,vhdx,vdi,ova,sha256}

echo ""
echo "✅ Release v$VERSION created!"
echo "URL: https://github.com/bodegga/tide/releases/tag/v$VERSION"
```

---

## Post-Release Tasks

```bash
#!/bin/bash
# post-release.sh

VERSION=$(cat VERSION)

echo "Post-Release Tasks for v$VERSION"
echo "================================="
echo ""

# 1. Update CHANGELOG for next version
echo "## [Unreleased]

### Planned Features (v1.X.0)
- 

---
" | cat - docs/CHANGELOG.md > temp && mv temp docs/CHANGELOG.md

# 2. Update AGENTS.md
sed -i.bak "s/Current Version: v.*/Current Version: v$VERSION/" AGENTS.md

# 3. Archive release artifacts
mkdir -p archive/releases/v$VERSION
cp -r release/v$VERSION/* archive/releases/v$VERSION/

echo "✅ Post-release tasks complete"
```

---

## Required Reading

1. `.github/VERSIONING.md`
2. `.github/RELEASE_PROCESS.md`
3. `docs/CHANGELOG.md`
4. `AGENTS.md`

---

## Tools & Scripts

1. `determine-version-bump.sh`
2. `pre-release-checklist.sh`
3. `create-release.sh`
4. `post-release.sh`

---

**Remember: Test thoroughly. Version correctly. Release confidently.**

🌊 **Tide Gateway: Professionally Versioned and Released.**
