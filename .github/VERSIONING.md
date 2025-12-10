# Versioning Guidelines for Tide Gateway

This document explains the versioning strategy for Tide Gateway and provides guidelines for determining version numbers.

---

## 📖 Semantic Versioning

Tide Gateway follows [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

Given a version number **MAJOR.MINOR.PATCH**, increment the:

1. **MAJOR** version when you make incompatible API changes
2. **MINOR** version when you add functionality in a backward compatible manner
3. **PATCH** version when you make backward compatible bug fixes

---

## 🎯 Version Number Rules

### MAJOR Version (X.0.0)

**Increment when:**
- Breaking changes to network configuration (IPs, ports, protocols)
- Removal of deployment modes
- Changes to authentication/security that break existing clients
- Complete architecture rewrites
- Incompatible VM template formats
- Changes requiring user intervention to upgrade

**Examples:**
- `v1.5.3` → `v2.0.0`: Changed gateway IP from 10.101.101.10 to 192.168.100.1
- `v1.8.0` → `v2.0.0`: Removed Proxy Mode entirely
- `v2.3.1` → `v3.0.0`: Switched from iptables to nftables (requires config migration)

**Migration Required:**
- ✅ Always provide migration guide
- ✅ Document breaking changes clearly
- ✅ Offer migration script if possible
- ✅ Give users advance notice

---

### MINOR Version (1.X.0)

**Increment when:**
- Adding new features
- Adding new deployment modes
- Adding client applications
- New configuration options (backward compatible)
- Significant improvements without breaking changes
- Adding new security profiles

**Examples:**
- `v1.5.3` → `v1.6.0`: Added web-based admin interface
- `v1.3.2` → `v1.4.0`: Added Takeover Mode
- `v1.7.1` → `v1.8.0`: Added native client GUI apps

**User Impact:**
- ✅ Existing setups continue working
- ✅ New features are opt-in
- ✅ No migration required
- ⚠️ May require new dependencies

---

### PATCH Version (1.1.X)

**Increment when:**
- Fixing bugs
- Security patches
- Performance improvements
- Documentation updates
- Dependency updates (security/bug fixes)
- Minor configuration tweaks
- Improved error messages

**Examples:**
- `v1.1.1` → `v1.1.2`: Fixed DNS resolution bug
- `v1.5.0` → `v1.5.1`: Security patch for Tor configuration
- `v1.8.3` → `v1.8.4`: Improved startup script error handling

**User Impact:**
- ✅ Drop-in replacement
- ✅ No configuration changes
- ✅ Immediate upgrade recommended (especially security patches)

---

## 🏷️ Pre-Release Versions

### Alpha Releases

Format: `vX.Y.Z-alpha.N`

**Use when:**
- Early development of major features
- Experimental functionality
- Not ready for production
- Breaking changes still possible

**Example:** `v2.0.0-alpha.1`

**Labels:**
- ⚠️ "Alpha - Not for production use"
- 🧪 "Experimental"

### Beta Releases

Format: `vX.Y.Z-beta.N`

**Use when:**
- Feature complete but needs testing
- API/configuration stable
- Bug fixes and polish remaining
- Ready for brave early adopters

**Example:** `v2.0.0-beta.2`

**Labels:**
- ⚠️ "Beta - Use with caution"
- 🔬 "Testing phase"

### Release Candidates

Format: `vX.Y.Z-rc.N`

**Use when:**
- Final testing before release
- No new features being added
- Only critical bug fixes
- Production-ready unless major bug found

**Example:** `v2.0.0-rc.1`

**Labels:**
- ✅ "Release Candidate"
- 🎯 "Final testing"

---

## 📅 Version Lifecycle

### Active Development

Current version: `v1.1.1`

```
main branch → v1.2.0-alpha.1 → v1.2.0-beta.1 → v1.2.0-rc.1 → v1.2.0
```

### Long-Term Support (LTS)

If we implement LTS:

- **Current**: Latest stable version (always supported)
- **LTS**: Selected versions with extended support
- **EOL**: End-of-life versions (no longer supported)

**Example LTS Timeline:**
```
v1.0.0 (EOL)
v1.1.0 (LTS) ← Security fixes only for 1 year
v1.2.0 (Current) ← Active development
v2.0.0-beta.1 (Future)
```

---

## 🎨 Version Naming

### Optional: Release Names

Release names are optional but add personality:

**v1.1.1** - "Killa Whale Template"  
**v1.1.0** - "Universal Tor Appliance"  
**v2.0.0** - "Breaking Wave" *(example)*

**Naming Themes:**
- Ocean/water related (matches Tide brand)
- Bay Area culture references
- Security/privacy concepts
- Keep it professional but fun

---

## 🔢 Version Number Examples

### Real Tide Gateway History

| Version | Date | Type | Description |
|---------|------|------|-------------|
| v1.0.0 | 2025-12-07 | Major | Initial public release |
| v1.1.0 | 2025-12-07 | Minor | Cloud-init + multi-arch |
| v1.1.1 | 2025-12-09 | Patch | Template deployment fix |
| v1.2.0 | TBD | Minor | (Planned) Stability improvements |
| v2.0.0 | TBD | Major | (Planned) Breaking changes |

### Hypothetical Future Versions

| Change | Old → New | Reasoning |
|--------|-----------|-----------|
| Add web UI | v1.5.0 → v1.6.0 | New feature (minor) |
| Fix Tor bug | v1.6.0 → v1.6.1 | Bug fix (patch) |
| Change gateway IP | v1.6.1 → v2.0.0 | Breaking change (major) |
| Security patch | v2.0.0 → v2.0.1 | Security fix (patch) |
| Add mobile app | v2.0.1 → v2.1.0 | New feature (minor) |

---

## 🚦 Decision Tree

Use this flowchart to determine version bump:

```
Does it break existing setups?
├── Yes → MAJOR version (X.0.0)
└── No
    ├── Does it add new features?
    │   ├── Yes → MINOR version (1.X.0)
    │   └── No → PATCH version (1.1.X)
    └── Is it just a bug fix?
        └── Yes → PATCH version (1.1.X)
```

### Detailed Questions

**Ask yourself:**

1. **Will existing VMs work without changes?**
   - No → MAJOR
   - Yes → Continue

2. **Will existing config files work?**
   - No → MAJOR
   - Yes → Continue

3. **Are you adding new capabilities?**
   - Yes → MINOR
   - No → Continue

4. **Are you fixing bugs or improving performance?**
   - Yes → PATCH

5. **Is it only documentation?**
   - Yes → PATCH (or no version bump)

---

## 📝 Changelog Categories

Map changelog categories to version types:

| Changelog Section | Usually Triggers |
|-------------------|------------------|
| **Added** | MINOR (new features) |
| **Changed** | MINOR or MAJOR (depends on compatibility) |
| **Deprecated** | MINOR (warning about future removal) |
| **Removed** | MAJOR (breaking change) |
| **Fixed** | PATCH (bug fixes) |
| **Security** | PATCH (or MINOR if new security features) |

---

## 🎯 Special Cases

### Documentation-Only Changes

**Question:** Do documentation updates require version bump?

**Answer:** 
- ✅ **Yes (PATCH)** if:
  - Fixing incorrect documentation that might mislead users
  - Adding critical security warnings
  - Correcting installation instructions

- ❌ **No** if:
  - Fixing typos
  - Improving wording
  - Adding examples

**Recommendation:** Bundle doc fixes with next release

### Dependency Updates

**Question:** Version bump for dependency updates?

**Answer:**
- **PATCH** if:
  - Security patches
  - Bug fixes in dependencies
  - No functional changes

- **MINOR** if:
  - New features in dependencies that you expose
  - Significant version jumps

- **MAJOR** if:
  - Breaking changes in dependencies that affect users

### Configuration Changes

**Question:** Version bump for config changes?

**Answer:**
- **MAJOR** if:
  - Old configs don't work
  - Requires user intervention

- **MINOR** if:
  - New optional config options
  - Backward compatible defaults

- **PATCH** if:
  - Default value changes (still compatible)
  - Config file format improvements

---

## 🚨 Mistakes and Corrections

### What If You Release Wrong Version?

**Scenario 1: Released v1.5.0 but should have been v2.0.0**

**Don't:**
- ❌ Delete the release
- ❌ Reuse version numbers
- ❌ Force-push tags

**Do:**
- ✅ Release v2.0.0 immediately
- ✅ Mark v1.5.0 as "superseded" in release notes
- ✅ Explain the mistake in CHANGELOG
- ✅ Update documentation to point to v2.0.0

**Example:**
```markdown
## [2.0.0] - 2025-12-10

### Breaking Changes
- (This should have been v2.0.0, not v1.5.0)
- All breaking changes from v1.5.0 apply

## [1.5.0] - 2025-12-09 [SUPERSEDED]

**Note:** This release contained breaking changes and should have been 
v2.0.0. Please use v2.0.0 instead.
```

### What If You Deleted a Release?

**Like Tide's v1.0.0 and v1.2.0:**

**Do:**
- ✅ Document it in CHANGELOG
- ✅ Explain why in HISTORY.md
- ✅ Preserve git tags
- ✅ Note which commit had that version

**Example:** (See CHANGELOG.md sections for v1.0.0 and v1.2.0)

---

## 🔄 Version Comparison Chart

### Valid Version Progressions

```
v1.0.0 → v1.0.1 ✅ (patch)
v1.0.0 → v1.1.0 ✅ (minor)
v1.0.0 → v2.0.0 ✅ (major)
v1.0.1 → v1.0.2 ✅ (patch)
v1.0.1 → v1.1.0 ✅ (minor + patch)
v1.5.9 → v1.6.0 ✅ (minor)
v1.9.9 → v1.10.0 ✅ (minor - no limit on minor numbers)
v1.9.9 → v2.0.0 ✅ (major)
```

### Invalid Version Progressions

```
v1.0.0 → v1.0.0 ❌ (same version)
v1.1.0 → v1.0.5 ❌ (backwards)
v2.0.0 → v1.5.0 ❌ (backwards)
v1.0.1 → v1.1 ❌ (must have three parts)
v1.1 → v1.1.0 ⚠️ (technically valid but confusing)
```

---

## 📊 Version Tracking

### Files That Must Be Updated

Create a checklist for version bumps:

- [ ] `VERSION` file
- [ ] `README.md` (version badge)
- [ ] `CHANGELOG.md` (new version section)
- [ ] Any scripts that embed version (e.g., `setup-tide.sh`)
- [ ] Git tag
- [ ] GitHub release

### Automation

Consider creating a script:

```bash
#!/bin/bash
# bump-version.sh

NEW_VERSION=$1

# Update VERSION file
echo "$NEW_VERSION" > VERSION

# Update README badge
sed -i '' "s/version-[0-9.]*-green/version-$NEW_VERSION-green/" README.md

# Update scripts that embed version
sed -i '' "s/VERSION=.*/VERSION=\"$NEW_VERSION\"/" setup-tide.sh

# Commit
git add VERSION README.md setup-tide.sh
git commit -m "Bump version to v$NEW_VERSION"

# Tag
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

echo "✅ Version bumped to v$NEW_VERSION"
echo "Next steps:"
echo "1. Update CHANGELOG.md"
echo "2. Push: git push && git push --tags"
echo "3. Create GitHub release"
```

---

## 🎓 Learning Resources

### Semantic Versioning
- Official spec: https://semver.org/
- FAQ: https://semver.org/#faq

### Keep a Changelog
- Format guide: https://keepachangelog.com/
- Best practices

### Git Tagging
- Git tag documentation
- Annotated vs lightweight tags

---

## 💡 Quick Tips

### For Maintainers

1. **When in doubt, go up** - Better to bump too high than too low
2. **Communicate breaking changes** - Warn users well in advance
3. **Be consistent** - Follow these rules every time
4. **Document everything** - Future you will thank present you
5. **Test before tagging** - Can't un-release easily

### For Contributors

1. **Don't update VERSION in PRs** - Maintainers handle versioning
2. **Describe changes clearly** - Helps maintainers categorize
3. **Label PRs appropriately** - "bug", "enhancement", "breaking"
4. **Update CHANGELOG draft** - Add to [Unreleased] section

---

## 🔮 Future Versioning Plans

### When Tide hits v2.0.0

Consider implementing:
- **LTS versions** - Long-term support for major versions
- **Stable branches** - `stable/v1.x`, `stable/v2.x`
- **Backports** - Security fixes to old versions
- **EOL policy** - When to stop supporting old versions

### When Tide hits v10.0.0

Celebrate! 🎉 But keep going. Version numbers are infinite.

---

**Questions about versioning?** Open a discussion on GitHub.

---

*Last updated: 2025-12-09*  
*Tide Gateway - freedom within the shell* 🌊
