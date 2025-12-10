# Release Process for Tide Gateway

This document outlines the complete process for creating and publishing new releases of Tide Gateway. Follow this checklist to ensure consistent, professional releases.

---

## 📋 Pre-Release Checklist

### 1. Version Planning

- [ ] Decide version number using [Semantic Versioning](https://semver.org/)
  - **MAJOR** (X.0.0): Breaking changes, major architectural shifts
  - **MINOR** (1.X.0): New features, backward compatible additions
  - **PATCH** (1.1.X): Bug fixes, security patches, minor improvements

- [ ] Determine release name/theme (optional but fun)
  - Examples: "Killa Whale Template", "Universal Tor Appliance"

- [ ] Review all commits since last release
  ```bash
  git log v{LAST_VERSION}..HEAD --oneline
  ```

- [ ] Ensure all intended features/fixes are merged

### 2. Code Quality

- [ ] All tests passing
  ```bash
  # Add your test commands here
  ./test-deployment.sh
  ```

- [ ] No known critical bugs

- [ ] Security audit completed (if applicable)

- [ ] Documentation is up-to-date

### 3. Version Number Updates

Update version numbers in these files:

- [ ] `VERSION` file
  ```bash
  echo "1.X.X" > VERSION
  ```

- [ ] `README.md` badge
  ```markdown
  [![Version](https://img.shields.io/badge/version-1.X.X-green)]
  ```

- [ ] Any config files that embed version
  ```bash
  # Example
  sed -i '' 's/VERSION=.*/VERSION="1.X.X"/' setup-tide.sh
  ```

- [ ] Commit version updates
  ```bash
  git add VERSION README.md
  git commit -m "Bump version to v1.X.X"
  ```

---

## 📝 Documentation Updates

### 1. Update CHANGELOG.md

Follow the [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [1.X.X] - YYYY-MM-DD

### Added
- New features

### Changed
- Improvements and modifications

### Fixed
- Bug fixes

### Deprecated
- Features being phased out (if any)

### Removed
- Features removed (if any)

### Security
- Security-related changes (if any)
```

**Checklist:**
- [ ] Add new version section to CHANGELOG.md
- [ ] Document all notable changes since last release
- [ ] Group changes by category (Added, Changed, Fixed, etc.)
- [ ] Write clear, user-focused descriptions
- [ ] Update [Unreleased] section for next development

### 2. Update HISTORY.md (If Major Changes)

For significant releases, add narrative context:

- [ ] Add development story/timeline
- [ ] Document key decisions and rationale
- [ ] Include technical architecture changes
- [ ] Add lessons learned
- [ ] Update statistics (commit count, development time)

### 3. Commit Documentation

```bash
git add CHANGELOG.md HISTORY.md
git commit -m "Update CHANGELOG and HISTORY for v1.X.X"
```

---

## 🏷️ Git Tagging

### 1. Create Annotated Tag

```bash
# Annotated tag with message
git tag -a v1.X.X -m "Tide Gateway v1.X.X - {RELEASE_NAME}

{Brief description of release}

Key changes:
- Feature 1
- Feature 2
- Fix 3
"
```

### 2. Verify Tag

```bash
# View tag details
git show v1.X.X

# List all tags
git tag -l
```

### 3. Push Tag to GitHub

```bash
# Push the tag
git push origin v1.X.X

# Or push all tags
git push --tags
```

---

## 📦 Build Release Artifacts

### 1. Build VM Template (if applicable)

```bash
# Clean build environment
cd /path/to/tide
./PACKAGE-RELEASE.sh

# This should create:
# - tide-gateway-template.pvm/ (Parallels VM)
# - tide-gateway-template.zip (compressed)
```

### 2. Build Other Artifacts

```bash
# QEMU cloud image (if updated)
./build-qemu-image.sh

# ISO installers (if updated)
./build-iso.sh

# Client applications (if updated)
cd client
./build-macos.sh
./build-linux.sh
./build-windows.sh
```

### 3. Generate Checksums

```bash
# Generate SHA256 checksums for all release files
sha256sum tide-gateway-template.zip > SHA256SUMS
sha256sum tide-gateway.qcow2 >> SHA256SUMS
sha256sum cloud-init.iso >> SHA256SUMS
# Add others as needed

# Display for verification
cat SHA256SUMS
```

### 4. Test Artifacts

- [ ] Test VM template deployment
  ```bash
  # Deploy and verify it works
  ./DEPLOY-TEMPLATE.sh
  ```

- [ ] Test fresh install
  ```bash
  # Run installer in clean Alpine VM
  wget https://tide.bodegga.net/install.sh
  ./install.sh
  ```

- [ ] Verify Tor routing works
  ```bash
  curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip
  ```

---

## 🚀 Create GitHub Release

### 1. Prepare Release Notes

- [ ] Copy `.github/release-template.md` to working document
- [ ] Fill in all sections:
  - Overview and highlights
  - What's new (from CHANGELOG.md)
  - Installation methods
  - Configuration details
  - Security notes
  - Known issues
  - Download links and checksums

### 2. Create Release via GitHub CLI

```bash
# Create draft release
gh release create v1.X.X \
  --title "Tide Gateway v1.X.X - {RELEASE_NAME}" \
  --notes-file release-notes.md \
  --draft

# Upload artifacts
gh release upload v1.X.X \
  tide-gateway-template.zip \
  tide-gateway.qcow2 \
  cloud-init.iso \
  SHA256SUMS

# Once ready, publish
gh release edit v1.X.X --draft=false
```

### 3. Or Create Release via GitHub Web UI

1. Go to https://github.com/bodegga/tide/releases
2. Click "Draft a new release"
3. Choose tag: `v1.X.X`
4. Release title: `Tide Gateway v1.X.X - {RELEASE_NAME}`
5. Paste formatted release notes
6. Upload all artifacts
7. Check "Set as latest release" (if applicable)
8. Click "Publish release"

---

## 📢 Announcement

### 1. Update README Badges

Ensure README.md shows latest version:

```markdown
[![Version](https://img.shields.io/badge/version-1.X.X-green)]
```

### 2. Update Project Links

- [ ] Update https://tide.bodegga.net (if you have a website)
- [ ] Update any external documentation links
- [ ] Verify download links work

### 3. Social Media / Community (Optional)

If you have social channels or community:

- [ ] Post release announcement on Twitter/X
- [ ] Update Reddit post (if applicable)
- [ ] Announce in Discord/Slack (if applicable)
- [ ] Send email to interested users (if you have a list)

**Example Announcement:**

```
🌊 Tide Gateway v1.X.X is out!

New features:
- Feature 1
- Feature 2
- Fix 3

Download: https://github.com/bodegga/tide/releases/latest
Quick start: curl -sSL https://tide.bodegga.net/deploy | bash

#privacy #tor #opensource
```

---

## ✅ Post-Release Checklist

### 1. Verify Everything Works

- [ ] GitHub release page displays correctly
- [ ] All download links work
- [ ] Checksums are correct
- [ ] Installation instructions are accurate

### 2. Update Development Branch

```bash
# Merge release back to main (if using release branches)
git checkout main
git merge v1.X.X

# Create new development branch (optional)
git checkout -b dev-v1.{X+1}.0
```

### 3. Plan Next Release

- [ ] Update [Unreleased] section in CHANGELOG.md
- [ ] Add planned features to ROADMAP.md
- [ ] Create GitHub milestones for next version
- [ ] Create issues for planned work

### 4. Monitor Feedback

- [ ] Watch GitHub issues for bug reports
- [ ] Respond to questions
- [ ] Track download metrics
- [ ] Collect user feedback

---

## 🐛 Hotfix Process

If critical bugs are found after release:

### 1. Create Hotfix Branch

```bash
git checkout -b hotfix-v1.X.{X+1} v1.X.X
```

### 2. Fix the Bug

```bash
# Make fixes
git add {fixed-files}
git commit -m "Fix critical bug in {component}"
```

### 3. Bump Patch Version

```bash
echo "1.X.{X+1}" > VERSION
git add VERSION
git commit -m "Bump version to v1.X.{X+1}"
```

### 4. Tag and Release

```bash
git tag -a v1.X.{X+1} -m "Hotfix release - {description}"
git push origin hotfix-v1.X.{X+1}
git push origin v1.X.{X+1}
```

### 5. Create Hotfix Release

Follow the normal release process, but:
- Mark as "hotfix" or "patch" release
- Clearly state what bug was fixed
- Recommend immediate upgrade

### 6. Merge Back

```bash
git checkout main
git merge hotfix-v1.X.{X+1}
git push origin main
```

---

## 📊 Release Metrics to Track

Consider tracking these metrics for each release:

- **Downloads per release**
  ```bash
  gh api repos/bodegga/tide/releases | jq '.[].download_count'
  ```

- **Issues closed**
  ```bash
  gh issue list --state closed --milestone "v1.X.X"
  ```

- **Time between releases**
  ```bash
  git log --tags --simplify-by-decoration --pretty="format:%ai %d"
  ```

- **Contributor count**
  ```bash
  git shortlog -sn v{LAST}..v{CURRENT}
  ```

---

## 🎯 Version Numbering Examples

### When to bump MAJOR (X.0.0)

- Breaking API changes
- Complete architecture rewrite
- Removed deployment modes
- Changed network configuration (IPs, ports)
- Incompatible with previous client apps

**Example:** v1.5.3 → v2.0.0

### When to bump MINOR (1.X.0)

- New features added
- New deployment modes
- Client GUI added
- Web interface added
- Backward compatible improvements

**Example:** v1.5.3 → v1.6.0

### When to bump PATCH (1.1.X)

- Bug fixes
- Security patches
- Documentation improvements
- Performance optimizations (no API changes)
- Dependency updates

**Example:** v1.5.3 → v1.5.4

---

## 🔐 Security Releases

For security-related releases:

### 1. Private Disclosure Period

- [ ] Receive security report (via email or GitHub Security Advisory)
- [ ] Confirm vulnerability
- [ ] Develop fix in private branch
- [ ] Test fix thoroughly
- [ ] Coordinate disclosure timeline

### 2. Create Security Advisory

```bash
# Use GitHub Security Advisory feature
# Or announce via SECURITY.md
```

### 3. Release Urgency

- [ ] Mark release as "security update"
- [ ] Use clear subject lines: "SECURITY UPDATE: v1.X.X"
- [ ] Describe severity (Critical, High, Medium, Low)
- [ ] Provide CVE number (if applicable)
- [ ] Recommend immediate upgrade

### 4. Post-Release

- [ ] Update SECURITY.md with patch info
- [ ] Thank security researcher (if applicable)
- [ ] Add to security hall of fame (if you have one)

---

## 📋 Quick Reference Command Cheat Sheet

```bash
# View commits since last release
git log v{LAST}..HEAD --oneline

# Create annotated tag
git tag -a v1.X.X -m "Release message"

# Push tag
git push origin v1.X.X

# Create GitHub release
gh release create v1.X.X --notes-file release-notes.md

# Upload artifacts
gh release upload v1.X.X file1.zip file2.iso

# View release info
gh release view v1.X.X

# Generate checksums
sha256sum *.zip *.iso > SHA256SUMS

# View all tags
git tag -l

# Delete tag (if mistake)
git tag -d v1.X.X
git push origin :refs/tags/v1.X.X
```

---

## 🎓 Best Practices

### Do's ✅

- **Do** test releases before publishing
- **Do** write clear, user-focused changelog entries
- **Do** use semantic versioning consistently
- **Do** include checksums for all artifacts
- **Do** keep release notes concise but complete
- **Do** respond to issues quickly after release

### Don'ts ❌

- **Don't** delete releases (except for true mistakes)
- **Don't** reuse version numbers
- **Don't** skip changelog updates
- **Don't** rush releases without testing
- **Don't** use vague commit messages
- **Don't** forget to update documentation

---

## 📞 Questions or Issues?

If you have questions about the release process:

1. Check this document first
2. Review previous releases as examples
3. Open a discussion on GitHub
4. Reach out to maintainers

---

**Remember:** Good releases make users happy. Take the time to do it right!

---

*Last updated: 2025-12-09*  
*Tide Gateway - freedom within the shell* 🌊
