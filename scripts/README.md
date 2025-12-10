# Tide Gateway Scripts

Utility scripts for maintaining and releasing Tide Gateway.

---

## 📋 Available Scripts

### bump-version.sh

Automatically updates version numbers across all project files.

**Usage:**
```bash
./scripts/bump-version.sh <new-version>
```

**Example:**
```bash
./scripts/bump-version.sh 1.2.0
```

**What it does:**
1. Updates `VERSION` file
2. Updates version badge in `README.md`
3. Updates embedded version strings in shell scripts
4. Shows git diff of changes
5. Provides next steps checklist

**Files updated:**
- `VERSION`
- `README.md`
- `setup-tide.sh` (if exists)
- `tide-install.sh` (if exists)
- `DEPLOY-TEMPLATE.sh` (if exists)
- `ONE-COMMAND-DEPLOY.sh` (if exists)

---

## 🎯 Typical Workflow

### Creating a New Release

```bash
# 1. Bump version
./scripts/bump-version.sh 1.2.0

# 2. Review changes
git diff

# 3. Update CHANGELOG.md manually
# Add new release section with changes

# 4. Commit version bump
git add VERSION README.md CHANGELOG.md *.sh
git commit -m "Bump version to v1.2.0"

# 5. Create annotated tag
git tag -a v1.2.0 -m "Tide Gateway v1.2.0 - Release Name

Key changes:
- Feature 1
- Feature 2
- Fix 3"

# 6. Push everything
git push
git push --tags

# 7. Create GitHub release
# Use .github/release-template.md as guide
```

---

## 📚 Documentation

For complete release process, see:
- [Release Process Guide](../.github/RELEASE_PROCESS.md)
- [Versioning Guidelines](../.github/VERSIONING.md)
- [Maintenance Guide](../.github/MAINTENANCE.md)

---

## 🛠️ Future Scripts (Planned)

### check-project-health.sh
Monitor project metrics and health indicators.

### update-changelog.sh
Automatically generate changelog from git commits.

### validate-release.sh
Pre-release validation and testing.

---

*Tide Gateway - freedom within the shell* 🌊
