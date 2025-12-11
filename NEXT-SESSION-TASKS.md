# Tide Gateway - Next Session Task List

**Last Session:** December 10, 2025 (v1.1.2 released)  
**Current Version:** v1.1.2 (testing infrastructure)  
**VM Template Version:** v1.1.1 (Killa Whale)  
**Next Target:** v1.2.0 (web dashboard in VM template)

---

## Priority Tasks

### 🔥 Priority 1: Validate Test Infrastructure (30 minutes)

**Goal:** Confirm the testing system we built actually works

**Tasks:**
1. Start Docker Desktop
2. Run Docker test:
   ```bash
   cd ~/Documents/Personal-Projects/tide/testing/containers
   ./test-docker.sh
   ```
3. If passes, run full orchestration:
   ```bash
   cd ~/Documents/Personal-Projects/tide/testing
   ./orchestrate-tests.sh
   ```
4. Generate dashboard:
   ```bash
   ./generate-dashboard.sh
   open results/dashboard.html
   ```

**Expected Outcome:**
- All tests pass ✅
- Dashboard generates ✅
- Validation confirms everything works ✅

**If Fails:**
- Check logs in `results/<session>/logs/`
- Fix issues
- Re-run tests

---

### 🔥 Priority 2: Rebuild VM Template with v1.2.0 Features (2-3 hours)

**Goal:** Create v1.2.0 VM template with web dashboard and CLI

**Current State:**
- Code exists in git (web dashboard, CLI, API)
- Not in v1.1.1 VM template
- Need to rebuild template

**Options:**

#### Option A: Update Existing v1.1.1 Template
```bash
# 1. Start v1.1.1 VM
cd deployment/parallels
./MANAGE-GATEWAYS.sh

# 2. SSH into VM
ssh root@10.101.101.10

# 3. Install v1.2.0 features
# Copy tide-web-dashboard.py, tide-cli.sh, etc.
# Configure services to auto-start

# 4. Test everything works

# 5. Package as v1.2.0
cd deployment/parallels
./PACKAGE-RELEASE.sh
```

#### Option B: Fresh Build with Cloud-Init
```bash
# 1. Update cloud-init config with v1.2.0 scripts
# 2. Build new image
# 3. Test
# 4. Package
```

#### Option C: Create Update Script
```bash
# Create deployment/UPDATE-TO-V1.2.sh
# Users run on existing v1.1.1 VMs
# Pulls latest scripts from GitHub
# Installs web dashboard + CLI
```

**Recommended:** Option C (update script)
- Fastest
- Works for existing users
- Can build new template later

**Tasks:**
1. Create `deployment/UPDATE-TO-V1.2.sh`
2. Test on fresh v1.1.1 VM
3. Verify web dashboard works
4. Verify CLI works
5. Document upgrade process

**Expected Outcome:**
- v1.1.1 → v1.2.0 upgrade script working
- Web dashboard accessible
- CLI commands functional

---

### 🔥 Priority 3: Release v1.2.0 (30 minutes)

**Prerequisites:**
- VM template rebuilt OR update script tested
- All features working
- Documentation updated

**Tasks:**
1. Update VERSION to 1.2.0
2. Update TEST-SPEC.yml (v1_2_features)
3. Update test scripts (TIDE_VERSION="1.2.0")
4. Update CHANGELOG (move v1.2.0 from [Unreleased])
5. Run full test suite:
   ```bash
   cd testing
   ./validate-tests.sh  # Check consistency
   ./orchestrate-tests.sh  # Run all tests
   ```
6. If all pass, tag and release:
   ```bash
   git add -A
   git commit -m "Release v1.2.0 - Web Dashboard & Enhanced CLI"
   git tag -a v1.2.0 -m "Tide Gateway v1.2.0"
   git push origin main v1.2.0
   gh release create v1.2.0 --title "..." --notes "..."
   ```
7. Upload VM template or link to update script

**Expected Outcome:**
- v1.2.0 released on GitHub
- Users can download/upgrade
- All features work

---

## Priority 2 Tasks (Nice to Have)

### 📱 WireGuard VPN Implementation (3-4 hours)

**Goal:** Mobile device access via WireGuard

**Status:**
- Design complete (`docs/MOBILE-APP-DESIGN.md`)
- Implementation plan exists (`docs/WIREGUARD-LIGHTWEIGHT-PLAN.md`)
- Not yet implemented

**Tasks:**
1. Create `scripts/runtime/tide-wireguard.sh`
2. Implement commands:
   - `tide wireguard add <device>` - Generate config
   - `tide wireguard list` - Show devices
   - `tide wireguard remove <device>` - Remove device
   - `tide wireguard qr <device>` - Show QR code
3. Install WireGuard packages (~300KB)
4. Configure server (wg0 interface)
5. Test with mobile device
6. Document setup process

**Expected Outcome:**
- WireGuard server running
- Can connect from iPhone/Android
- All traffic routes through Tor
- QR code setup works

**Version:** Would be v1.3.0 (new feature = MINOR)

---

### 🧪 Run Hetzner Cloud Test (10 minutes, $0.01)

**Goal:** Validate on real ARM hardware

**Tasks:**
```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-hetzner.sh
```

**What It Does:**
1. Creates ARM server in Hillsboro, OR
2. Installs Tide v1.1.2
3. Runs comprehensive tests
4. Shows results
5. Asks to destroy or keep

**Choose:** Destroy (costs $0.01)

**Expected Outcome:**
- Validation on production ARM hardware
- Confidence in release quality
- Real-world testing complete

---

### 📚 Documentation Improvements

**Optional tasks to improve docs:**

1. **Create VIDEO walkthrough**
   - Screen recording of setup
   - Upload to YouTube
   - Link from README

2. **Improve README.md**
   - Add screenshots
   - Clearer quick start
   - Better feature highlights

3. **Create FAQ.md**
   - Common questions
   - Troubleshooting
   - Best practices

4. **Update ROADMAP.md**
   - Mark v1.2.0 features complete
   - Add v1.3.0 plans
   - Timeline estimates

---

## Priority 3 Tasks (Future Ideas)

### 🔄 CI/CD Integration

**Goal:** Automated testing on every commit

**Tasks:**
1. Create `.github/workflows/test.yml`
2. Configure to run Docker tests on push
3. Add test status badges to README
4. Set up Hetzner testing for releases

**Benefits:**
- Catch bugs early
- Automated validation
- Professional workflow

---

### 📊 Bandwidth Monitoring

**Goal:** Track bandwidth usage over time

**Features:**
- Total bytes through Tor
- Per-client usage
- Historical graphs
- Alerts for high usage

**Implementation:**
- iptables counters
- Database storage (SQLite)
- Web dashboard integration
- CLI command (`tide bandwidth`)

**Version:** v1.3.0 or v1.4.0

---

### 🌐 WebSocket Live Updates

**Goal:** Real-time dashboard without refresh

**Current:** Dashboard auto-refreshes every 30s

**Improved:**
- WebSocket connection
- Live updates
- No page refresh
- Better UX

**Implementation:**
- Python websockets library
- JavaScript WebSocket client
- Update dashboard.py

**Version:** v1.3.0 or v1.4.0

---

## Session Preparation Checklist

**Before starting next session:**

- [ ] Read `docs/SESSION-2025-12-10.md` (this session's summary)
- [ ] Review `docs/VERSION-HISTORY.md` (understand version state)
- [ ] Check `VERSION` file (currently 1.1.2)
- [ ] Review `docs/CHANGELOG.md` (what's unreleased)
- [ ] Read `testing/GETTING-STARTED.md` (if testing)
- [ ] Have Docker Desktop ready (if testing)
- [ ] Have Hetzner token ready (if cloud testing)

---

## Quick Reference Commands

**Check current state:**
```bash
cd ~/Documents/Personal-Projects/tide
cat VERSION                    # See version
git status                     # Check changes
git log --oneline -5           # Recent commits
gh release list --limit 3      # GitHub releases
```

**Run tests:**
```bash
cd testing
./validate-tests.sh            # Check test coverage
./containers/test-docker.sh    # Quick Docker test
./orchestrate-tests.sh         # Full test suite
./generate-dashboard.sh        # Generate dashboard
```

**Development:**
```bash
cd deployment/parallels
./MANAGE-GATEWAYS.sh           # Manage VMs
ssh root@10.101.101.10         # Connect to VM
```

---

## Files to Review Before Next Session

**Essential:**
1. `docs/SESSION-2025-12-10.md` - What we built today
2. `docs/VERSION-HISTORY.md` - Complete version timeline
3. `docs/CHANGELOG.md` - What's released vs unreleased
4. `testing/GETTING-STARTED.md` - How to run tests

**If Building v1.2.0:**
5. `docs/guides/WEB-DASHBOARD-README.md` - Dashboard docs
6. `scripts/runtime/tide-web-dashboard.py` - Dashboard code
7. `scripts/runtime/tide-cli.sh` - CLI code

**If Implementing WireGuard:**
8. `docs/MOBILE-APP-DESIGN.md` - Mobile app design
9. `docs/WIREGUARD-LIGHTWEIGHT-PLAN.md` - Implementation plan

---

## Decision Points for Next Session

**You'll need to decide:**

1. **Testing first or v1.2.0 first?**
   - Recommended: Testing (30 min) then v1.2.0 (2-3 hrs)

2. **VM rebuild approach?**
   - Option A: Update existing template
   - Option B: Fresh build
   - Option C: Update script (recommended)

3. **WireGuard now or later?**
   - Now: Would be part of v1.2.0 (bigger release)
   - Later: Separate v1.3.0 release (cleaner)

4. **Hetzner testing?**
   - Yes: $0.01, confirms everything works
   - No: Skip, rely on Docker testing

---

## Blockers / Dependencies

**None currently**

Everything is ready to go:
- ✅ Code committed
- ✅ Tests ready
- ✅ Documentation complete
- ✅ Version strategy clear
- ✅ GitHub up to date

**Only blocker is time/decision to rebuild VM template**

---

## Success Criteria for Next Session

**Minimum (1-2 hours):**
- [ ] Docker tests run successfully
- [ ] Validation confirms test infrastructure works

**Target (3-4 hours):**
- [ ] VM template updated with v1.2.0 features
- [ ] v1.2.0 released on GitHub
- [ ] Update script or new template available

**Stretch (5-6 hours):**
- [ ] v1.2.0 released
- [ ] WireGuard implementation started
- [ ] Hetzner testing completed

---

## Notes

- All work from Dec 10 session is committed and pushed
- Version 1.1.2 is released (testing infrastructure)
- Web dashboard code exists but not in VM template
- v1.2.0 saved for when template is rebuilt
- No blockers, just execution

**Good luck! 🌊**

---

**Created:** December 10, 2025  
**Current Version:** v1.1.2  
**Next Version:** v1.2.0  
**Status:** Ready to execute
