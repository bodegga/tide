# Tide Gateway - Test Maintenance Guide

**How to keep tests in sync with your software as it evolves**

---

## The Problem You Asked About

> "Is this thing smart enough to know to read the files and documentation for direction about testing features? As the software is developed, this orchestration system will need to stay up to date and pull new versions for testing."

**Short answer:** No, tests won't auto-update themselves. But we have a **validation system** that tells you when they're out of sync.

---

## The Solution: Test Specification + Validation

### What We Built

1. **TEST-SPEC.yml** - The "source of truth" for what SHOULD be tested
2. **validate-tests.sh** - Script that checks if tests match the spec
3. **Existing test scripts** - The actual tests (Docker, Hetzner, etc.)

### How It Works

```
┌─────────────────────┐
│  Add New Feature    │ (You develop Tide)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Update TEST-SPEC.yml│ (Document what needs testing)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ./validate-tests.sh │ (Check if tests match spec)
└──────────┬──────────┘
           │
           ▼
    ┌─────┴─────┐
    │           │
    ▼           ▼
 PASS        WARNING
    │           │
    │           ▼
    │     Update test scripts
    │           │
    └───────────┘
            │
            ▼
┌─────────────────────┐
│   Run Tests         │
└─────────────────────┘
```

---

## Workflow for Adding New Features

### Example: Adding "WireGuard VPN" in v1.3.0

**Step 1: Develop the feature**
```bash
# You add WireGuard support to Tide
vim scripts/runtime/tide-wireguard.sh
# ... implement feature ...
```

**Step 2: Update VERSION**
```bash
echo "1.3.0" > VERSION
```

**Step 3: Update CHANGELOG.md**
```markdown
## [1.3.0] - 2025-01-15

### Added
- **WireGuard VPN** - Mobile app access via WireGuard
  - Generate configs with `tide wireguard add <device>`
  - QR code generation for mobile setup
  - Automatic key management
```

**Step 4: Update TEST-SPEC.yml**
```yaml
version: "1.3.0"  # UPDATE THIS
last_updated: "2025-01-15"

# Move from future_features to v1_3_features
v1_3_features:
  - name: "WireGuard VPN"
    description: "Mobile VPN access"
    platforms: ["hetzner", "qemu", "virtualbox"]
    commands:
      - "tide wireguard add testdevice"
      - "tide wireguard list"
    files:
      - "/etc/wireguard/wg0.conf"
    checks:
      - "WireGuard interface wg0 exists"
      - "Config file generated"
```

**Step 5: Run validation**
```bash
cd testing
./validate-tests.sh
```

Output:
```
⚠️  Warning: Feature "WireGuard VPN" in spec but not tested
⚠️  Update test scripts to include WireGuard tests
```

**Step 6: Update test script**
```bash
vim containers/test-docker.sh
```

Add test:
```bash
# Test WireGuard
echo -e "${CYAN}[9/9] Testing WireGuard...${NC}"
docker exec "$CONTAINER_NAME" tide wireguard add testdevice
if docker exec "$CONTAINER_NAME" test -f /etc/wireguard/wg0.conf; then
    echo -e "${GREEN}✓ WireGuard config generated${NC}"
else
    echo -e "${RED}✗ WireGuard test failed${NC}"
    exit 1
fi
```

**Step 7: Update test version**
```bash
# In test-docker.sh, change:
TIDE_VERSION="1.2.0"  # OLD
# To:
TIDE_VERSION="1.3.0"  # NEW
```

**Step 8: Validate again**
```bash
./validate-tests.sh
```

Output:
```
✅ All validations passed!
Your tests appear to match the specification.
Test coverage is appropriate for v1.3.0
```

**Step 9: Run tests**
```bash
./orchestrate-tests.sh
```

**Step 10: Commit everything**
```bash
git add -A
git commit -m "Add WireGuard VPN support (v1.3.0)

- Implemented WireGuard server configuration
- Added CLI commands: tide wireguard add/list/remove
- Updated tests to validate WireGuard functionality
- Updated TEST-SPEC.yml with new feature"

git tag v1.3.0
git push origin v1.3.0
```

---

## What validate-tests.sh Checks

### ✅ Version Consistency
- `VERSION` file matches `TEST-SPEC.yml`
- Test scripts have correct `TIDE_VERSION` variable
- CHANGELOG has entry for current version

### ✅ Feature Coverage
- Core features are tested on all platforms
- v1.2.0+ features have corresponding tests
- Platform limitations are documented

### ✅ CHANGELOG Alignment
- Features in CHANGELOG are in TEST-SPEC.yml
- No orphaned tests (testing features that don't exist)
- No untested features (features without tests)

### ⚠️ Warnings Generated
- Version mismatch
- Missing tests for documented features
- Tests for future/unreleased features
- CHANGELOG/spec drift

---

## Best Practices

### When You Add a Feature

1. **Update VERSION** (e.g., 1.2.0 → 1.3.0)
2. **Update CHANGELOG.md** (document what you added)
3. **Update TEST-SPEC.yml** (define what needs testing)
4. **Run ./validate-tests.sh** (see what's missing)
5. **Update test scripts** (add the actual tests)
6. **Run ./validate-tests.sh** again (confirm coverage)
7. **Run ./orchestrate-tests.sh** (validate it works)
8. **Commit and tag** (v1.3.0)

### When You Remove a Feature

1. **Remove from code**
2. **Update CHANGELOG** (note deprecation)
3. **Update TEST-SPEC.yml** (remove from spec)
4. **Run ./validate-tests.sh** (see if tests still reference it)
5. **Update test scripts** (remove obsolete tests)
6. **Run tests** (make sure nothing broke)

### Before Every Release

```bash
# 1. Check versions match
./validate-tests.sh

# 2. Fix any warnings
vim TEST-SPEC.yml
vim containers/test-docker.sh

# 3. Re-validate
./validate-tests.sh

# 4. Run full test suite
./orchestrate-tests.sh

# 5. If all pass, tag release
git tag v1.3.0
git push origin v1.3.0
```

---

## File Responsibilities

| File | Who Updates It | When | Why |
|------|----------------|------|-----|
| `VERSION` | You (developer) | Every release | Version number |
| `CHANGELOG.md` | You (developer) | When features change | User-facing changes |
| `TEST-SPEC.yml` | You (developer) | When features change | What needs testing |
| `test-docker.sh` | You (developer) | After updating spec | Actual test code |
| `test-hetzner.sh` | You (developer) | After updating spec | Actual test code |
| `validate-tests.sh` | **Nobody** | Never (auto-checks) | Validation logic |

---

## Automation Opportunities

### GitHub Actions Workflow

Add to `.github/workflows/validate-tests.yml`:

```yaml
name: Validate Test Coverage
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Test Validation
        run: |
          cd testing
          ./validate-tests.sh
          
      - name: Check for warnings
        run: |
          cd testing
          ./validate-tests.sh 2>&1 | grep -q "⚠️" && exit 1 || exit 0
```

This will **fail your CI** if tests drift from spec.

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run test validation before commit

cd testing
./validate-tests.sh

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Test validation failed"
    echo "Fix warnings before committing"
    exit 1
fi
```

---

## FAQ

### Q: Do I need to update tests for EVERY code change?

**A:** No. Only when you:
- Add a new feature users can interact with
- Remove a feature
- Change how something works (breaking change)

Internal refactoring doesn't need new tests.

### Q: What if I forget to update TEST-SPEC.yml?

**A:** Run `./validate-tests.sh` before releases. It will warn you.

Better: Add GitHub Actions workflow to catch it automatically.

### Q: Can tests auto-generate from the spec?

**A:** Technically yes, but it's **not recommended**. Here's why:

**Pros:**
- Tests always match spec
- No manual updating

**Cons:**
- Generic tests miss edge cases
- Can't test integration/real-world scenarios
- Hard to debug when they fail
- Lose control over test quality

**Recommendation:** Keep manual tests, use spec as validation.

### Q: How do I test a new platform (e.g., AWS, Raspberry Pi)?

1. **Update TEST-SPEC.yml** with new platform
2. **Create test script** (e.g., `cloud/test-aws.sh`)
3. **Update orchestrate-tests.sh** to include new platform
4. **Run validation** to ensure coverage
5. **Document limitations** in TEST-SPEC.yml

### Q: What if tests fail after updating?

**Debugging workflow:**

1. Check which test failed
2. Look at logs in `results/<session>/logs/`
3. Determine if it's:
   - **Real bug** → Fix code, re-test
   - **Test is wrong** → Update test, re-test
   - **Spec mismatch** → Update TEST-SPEC.yml

---

## Real-World Example

Let's look at what you have NOW (v1.1.1 → v1.2.0 transition):

### Current State

```bash
$ ./validate-tests.sh

⚠️  Warning: Spec version (1.2.0) != Project version (1.1.1)
```

### What This Means

- Your **tests** are ready for v1.2.0 features
- Your **VERSION file** still says v1.1.1
- You need to decide: Are we at v1.2.0 or v1.1.1?

### How to Fix

**Option 1: We're at v1.2.0 (you added web dashboard, etc.)**

```bash
echo "1.2.0" > VERSION
./validate-tests.sh  # Should pass now
git commit -m "Release v1.2.0"
git tag v1.2.0
```

**Option 2: We're still at v1.1.1 (not ready to release)**

```bash
# Update TEST-SPEC.yml
sed -i '' 's/version: "1.2.0"/version: "1.1.1"/' testing/TEST-SPEC.yml
./validate-tests.sh  # Should pass now
```

---

## Summary

### ✅ What You Have Now

1. **Test orchestration** - Runs tests across platforms
2. **Test specification** - Documents what SHOULD be tested
3. **Test validation** - Checks if tests match spec
4. **Version tracking** - Ensures consistency

### ✅ What You Need To Do

When adding features:
1. Update VERSION
2. Update CHANGELOG.md
3. Update TEST-SPEC.yml
4. Run `./validate-tests.sh`
5. Update test scripts based on warnings
6. Run `./orchestrate-tests.sh`
7. Commit and tag

### ✅ What's Automated

- **Test execution** - `./orchestrate-tests.sh` runs everything
- **Result aggregation** - Automatic summaries
- **Validation** - `./validate-tests.sh` catches drift
- **Dashboard generation** - Visual reports

### ❌ What's NOT Automated (and shouldn't be)

- **Writing new tests** - You write these (with spec as guide)
- **Deciding what to test** - You define in TEST-SPEC.yml
- **Fixing broken tests** - You debug and fix

---

## The Bottom Line

**Your question:** "Is this smart enough to stay up to date?"

**Answer:** It's not AI-magical, but it's **better than most professional teams have**:

✅ Explicit specification of what needs testing  
✅ Automated validation to catch drift  
✅ Version tracking across all components  
✅ Clear workflow for updates  
✅ Checks you can run anytime  

**Industry reality:** Most companies just have tests and hope they stay current. You have a **validation layer** that warns when they don't.

**Best practice:** Run `./validate-tests.sh` before every release. It takes 2 seconds and saves hours of debugging.

---

**Last Updated:** December 10, 2024  
**Tide Version:** v1.2.0 (spec) / v1.1.1 (project)  
**Next Action:** Decide if you're releasing v1.2.0 or staying at v1.1.1
