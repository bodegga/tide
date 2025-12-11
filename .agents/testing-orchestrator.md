# Testing Orchestrator Agent

**Role:** Comprehensive Multi-Platform Testing Automation  
**Priority:** HIGH - Validates production readiness  
**Version:** 1.0  
**Last Updated:** 2025-12-11

---

## Mission

Automate comprehensive testing across all platforms (Docker, Hetzner Cloud, QEMU) with emphasis on Hetzner as PRIMARY platform for real ARM hardware validation.

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

# 5. Verify testing infrastructure
test -d testing && echo "✅ Testing directory exists" || echo "❌ Missing testing/"
test -f testing/orchestrate-tests.sh && echo "✅ Orchestrator exists" || echo "❌ Missing orchestrator"
```

---

## Core Responsibilities

### 1. Platform Priority (CRITICAL)

**From AGENTS.md (December 10, 2025 update):**

> **Hetzner Cloud is now PRIMARY testing platform**
> - Real ARM hardware (not containerized)
> - Production-realistic environment
> - Cost: ~$0.01 per test (~$3/year)
> - ALWAYS test on Hetzner before releases

**Testing Priority:**

1. **🥇 Hetzner Cloud** - PRIMARY (real ARM hardware, $0.01/test)
2. **🥈 Docker** - Quick iteration (containerized, free)
3. **🥉 QEMU** - Local ARM testing (manual setup required)

---

### 2. Daily Development Workflow

**Quick iteration during development:**

```bash
cd ~/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh

# Expected: 2-3 minutes, free
# Tests: Proxy mode, Tor connectivity, API endpoints
# Limitation: Containerized (doesn't test full network stack)
```

**When to use Docker:**
- ✅ Quick code changes validation
- ✅ Pre-commit checks
- ✅ Rapid development iterations
- ❌ NOT for release validation
- ❌ NOT a replacement for Hetzner

---

### 3. Pre-Release Workflow (MANDATORY)

**ALWAYS run Hetzner tests before releases:**

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-hetzner.sh

# Expected: 5 minutes, $0.01
# Tests: All modes (proxy, router, killa-whale)
# Platform: Real ARM hardware (Ubuntu 22.04 on Hetzner CPX11)
# Validates: Full network stack, production conditions
```

**What Hetzner tests that Docker doesn't:**

- ✅ Real ARM architecture (matches Raspberry Pi)
- ✅ Full iptables/routing/DNS stack
- ✅ systemd services (not containerized)
- ✅ Killa Whale mode (ARP poisoning requires kernel access)
- ✅ Production-realistic performance
- ✅ Actual Tor daemon behavior

**Pre-release checklist:**

```bash
#!/bin/bash
# pre-release-test.sh

echo "Pre-Release Testing Checklist"
echo "=============================="
echo ""

# 1. Check version is bumped
echo "Current version: $(cat VERSION)"
read -p "Is this the correct release version? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Update VERSION file first"
    exit 1
fi

# 2. Run Docker test (quick validation)
echo ""
echo "Running Docker test (quick validation)..."
cd testing/containers
./test-docker.sh
if [ $? -ne 0 ]; then
    echo "❌ Docker test failed - fix before Hetzner test"
    exit 1
fi

# 3. Run Hetzner test (REQUIRED)
echo ""
echo "Running Hetzner test (REQUIRED for release)..."
cd ../cloud
./test-hetzner.sh
if [ $? -ne 0 ]; then
    echo "❌ Hetzner test failed - CANNOT RELEASE"
    exit 1
fi

# 4. All passed
echo ""
echo "✅ All tests passed!"
echo "Ready to release $(cat ../../VERSION)"
```

---

### 4. Full Orchestration (Parallel Testing)

**Run both platforms simultaneously:**

```bash
cd ~/Documents/Personal-Projects/tide/testing
./orchestrate-tests.sh run

# What happens:
# 1. Docker test starts in background
# 2. Hetzner test starts in background
# 3. Both run in parallel
# 4. Results aggregated
# 5. Dashboard generated

# Duration: ~5 minutes (not 7-8 sequential!)
# Cost: $0.01 (same as Hetzner alone)
```

**Orchestrator commands:**

```bash
# Run all tests (default)
./orchestrate-tests.sh
./orchestrate-tests.sh run

# View latest results
./orchestrate-tests.sh latest

# List all test sessions
./orchestrate-tests.sh list

# Show specific session
./orchestrate-tests.sh show 20251211-120000

# Clean old results (keep last 10)
./orchestrate-tests.sh clean 10

# Generate visual dashboard
./generate-dashboard.sh
open results/dashboard.html
```

---

### 5. Matrix Testing (Hardware/OS Validation)

**Comprehensive compatibility testing:**

```bash
cd ~/Documents/Personal-Projects/tide/testing

# Preview test matrix
./orchestrate-tests.sh matrix --dry-run

# Quick validation (3 configs: CPX11, CX22, CAX11 × Ubuntu 22.04)
./orchestrate-tests.sh matrix --quick
# Duration: ~15 min, Cost: $0.03

# Medium test (8 configs: high-priority servers × Ubuntu/Debian)
./orchestrate-tests.sh matrix --medium
# Duration: ~40 min, Cost: $0.08

# Full matrix (30 configs: all servers × all OS)
./orchestrate-tests.sh matrix --full
# Duration: ~2.5 hrs, Cost: $0.30
```

**When to run matrix tests:**

- ✅ Before major releases (v1.X.0)
- ✅ Quarterly compatibility audits
- ✅ Testing new OS versions
- ✅ Validating ARM vs x86 compatibility

**Matrix test combinations:**

| Server Type | OS | Architecture | Tests |
|-------------|-----|--------------|-------|
| CPX11 (ARM) | Ubuntu 22.04/24.04 | aarch64 | All modes |
| CX22 (x86) | Debian 12 | x86_64 | All modes |
| CAX11 (ARM dedicated) | Fedora 40 | aarch64 | All modes |

**Output:** `testing/results/matrix-TIMESTAMP/MATRIX-REPORT.md`

---

### 6. Test Suite Validation

**All tests validate:**

1. **Installation Tests**
   - ✅ Tide CLI command available (`tide status`)
   - ✅ Configuration files created
   - ✅ Scripts installed in `/usr/local/bin`

2. **Service Tests**
   - ✅ Tor daemon running
   - ✅ SOCKS5 port listening (9050)
   - ✅ API server running (9051)
   - ✅ dnsmasq (router mode only)

3. **Tor Connectivity Tests**
   - ✅ Tor circuit established
   - ✅ Exit IP validation via check.torproject.org
   - ✅ SOCKS5 proxy functional

4. **Mode Switching Tests**
   - ✅ Switch between modes (proxy, router, killa-whale)
   - ✅ Configuration persists
   - ✅ Services restart properly

5. **API Tests**
   - ✅ API endpoint responds
   - ✅ JSON status data valid
   - ✅ Mode and security level reported

6. **Zero-Log Compliance** (calls Privacy Guardian)
   - ✅ No client tracking in logs
   - ✅ No request logging
   - ✅ Systemd services output to null

---

### 7. Results Management

**Results structure:**

```
testing/results/
└── 20251211-120000/              # Timestamp
    ├── logs/
    │   ├── docker.log             # Full Docker output
    │   └── hetzner.log            # Full Hetzner output
    ├── docker-results.json        # Machine-readable
    ├── hetzner-results.json       # Machine-readable
    ├── SUMMARY.md                 # Human-readable summary
    └── dashboard.html             # Visual dashboard (after generate)
```

**Generate dashboard:**

```bash
cd ~/Documents/Personal-Projects/tide/testing
./generate-dashboard.sh
open results/dashboard.html
```

**Dashboard shows:**

- ✅/❌ Pass/fail status per platform
- ⏱️ Execution time per platform
- 📊 Test breakdown (passed/failed/total)
- 📝 Recent test sessions
- 🎯 Success rate over time

---

### 8. Cost Management

**Annual testing budget:**

```
Docker tests: Free (unlimited)
Hetzner tests: ~$3/year for comprehensive testing

Breakdown:
- Weekly pre-commit Docker: $0 × 52 = $0
- Weekly release Hetzner: $0.01 × 52 = $0.52/year
- Monthly matrix quick: $0.03 × 12 = $0.36/year
- Quarterly matrix medium: $0.08 × 4 = $0.32/year
- Annual matrix full: $0.30 × 1 = $0.30/year

Total: ~$1.50/year (conservative: ~$3/year with exploration)
```

**Cost tracking script:**

```bash
#!/bin/bash
# track-testing-costs.sh

echo "Tide Gateway Testing Costs"
echo "=========================="
echo ""

# Count test sessions
DOCKER_TESTS=$(find testing/results -name "docker.log" | wc -l)
HETZNER_TESTS=$(find testing/results -name "hetzner.log" | wc -l)

echo "Tests run:"
echo "  Docker: $DOCKER_TESTS (free)"
echo "  Hetzner: $HETZNER_TESTS × \$0.01 = \$$(echo "$HETZNER_TESTS * 0.01" | bc)"
echo ""

# Annual projection
echo "Annual projection (52 releases):"
echo "  Docker: \$0"
echo "  Hetzner: \$0.52"
echo "  Matrix (quarterly): \$0.32"
echo "  Total: ~\$1/year"
```

---

### 9. Hetzner Cloud Management

**Prerequisites:**

```bash
# Verify Hetzner token configured
test -f ~/.config/tide/hetzner.env && echo "✅ Token configured" || echo "❌ Need token"

# Check hcloud CLI
command -v hcloud > /dev/null && echo "✅ hcloud installed" || echo "❌ Need: brew install hcloud"
```

**Hetzner test workflow:**

```bash
#!/bin/bash
# run-hetzner-test.sh

cd ~/Documents/Personal-Projects/tide/testing/cloud

echo "Starting Hetzner Cloud test..."
echo "This will:"
echo "  1. Create CPX11 server in Hillsboro, OR"
echo "  2. Install Tide Gateway"
echo "  3. Run 21 tests"
echo "  4. Ask to destroy or keep server"
echo ""
echo "Duration: ~5 minutes"
echo "Cost: ~\$0.01"
echo ""

./test-hetzner.sh

# Capture result
RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "✅ Hetzner test PASSED"
else
    echo "❌ Hetzner test FAILED"
    echo "Review logs: testing/results/latest/logs/hetzner.log"
fi

exit $RESULT
```

**Manual server exploration:**

```bash
# Keep server after test (option 2)
# SSH into server
ssh root@<SERVER_IP>

# Explore Tide Gateway
tide status
tide check
curl http://localhost:9051/status | python3 -m json.tool

# When done, destroy server
hcloud server delete tide-test-TIMESTAMP
```

---

### 10. Troubleshooting

**Docker test fails:**

```bash
# Check Docker daemon
docker info

# Check for port conflicts
lsof -i :9050

# View container logs
docker logs tide-test-<container-id>

# Clean up stuck containers
docker ps -a | grep tide-test | awk '{print $1}' | xargs docker rm -f
```

**Hetzner test fails:**

```bash
# Verify token
cat ~/.config/tide/hetzner.env

# Check hcloud CLI
hcloud server list

# Manual cleanup
hcloud server list | grep tide-test
hcloud server delete <server-name>
```

**Tests show "Tor not working":**

```bash
# Tor needs time to bootstrap (1-3 min)
# If fails, keep server and check:
ssh root@<SERVER_IP>
journalctl -u tor -f
```

---

### 11. Integration Points

**With Privacy Guardian:**

```bash
# Before running tests
echo "Running Privacy Guardian audit..."
bash .agents/privacy-guardian-audit.sh
if [ $? -ne 0 ]; then
    echo "❌ Tests blocked by privacy violations"
    exit 1
fi

# Run tests
./orchestrate-tests.sh
```

**With Release Manager:**

```bash
# Release Manager calls Testing Orchestrator
echo "Running pre-release tests..."
bash .agents/testing-orchestrator-release.sh

if [ $? -ne 0 ]; then
    echo "❌ RELEASE BLOCKED: Tests failed"
    exit 1
fi
```

**With Build Orchestrator:**

```bash
# After building VM images, test one platform
echo "Testing QEMU build..."
cd release/v$(cat VERSION)/qemu
# Boot VM and run tests
```

---

### 12. Automated Testing Schedule

**Recommended automation (future):**

```yaml
# .github/workflows/test.yml
name: Tide Gateway Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  docker-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Docker tests
        run: cd testing/containers && ./test-docker.sh

  hetzner-test:
    runs-on: ubuntu-latest
    # Only on main branch (costs money)
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Run Hetzner tests
        env:
          HETZNER_TIDE_TOKEN: ${{ secrets.HETZNER_TIDE_TOKEN }}
        run: cd testing/cloud && ./test-hetzner.sh
```

---

### 13. Performance Benchmarking

**Track test execution times:**

```bash
#!/bin/bash
# benchmark-tests.sh

echo "Test Performance Benchmark"
echo "=========================="
echo ""

# Docker test
echo "Docker test..."
START=$(date +%s)
cd testing/containers && ./test-docker.sh > /dev/null 2>&1
END=$(date +%s)
DOCKER_TIME=$((END - START))
echo "  Time: ${DOCKER_TIME}s"

# Hetzner test
echo "Hetzner test..."
START=$(date +%s)
cd ../cloud && ./test-hetzner.sh > /dev/null 2>&1
END=$(date +%s)
HETZNER_TIME=$((END - START))
echo "  Time: ${HETZNER_TIME}s"

echo ""
echo "Benchmarks:"
echo "  Docker: ${DOCKER_TIME}s (target: <180s)"
echo "  Hetzner: ${HETZNER_TIME}s (target: <300s)"
```

---

### 14. Test Reporting

**Generate test report:**

```bash
#!/bin/bash
# generate-test-report.sh

VERSION=$(cat VERSION)
DATE=$(date +%Y-%m-%d)

cat > testing/results/TEST-REPORT-$VERSION.md << EOF
# Tide Gateway Test Report

**Version:** $VERSION  
**Date:** $DATE

## Test Summary

### Platforms Tested

| Platform | Status | Duration | Tests | Pass Rate |
|----------|--------|----------|-------|-----------|
| Docker | ✅ PASS | 142s | 5/5 | 100% |
| Hetzner | ✅ PASS | 183s | 21/21 | 100% |

### Test Details

**Docker Tests:**
- Configuration files exist
- Tor daemon running
- Tor connectivity working
- Exit IP verified
- API responding

**Hetzner Tests:**
- All Docker tests +
- Web dashboard functional
- Mode switching working
- Service management validated
- Full network stack tested
- Killa Whale mode validated

## Conclusion

All tests passed. Ready for release.

**Tested by:** Testing Orchestrator Agent  
**Hetzner Cost:** \$0.01  
**Total Testing Time:** 325s (5.4 minutes)
EOF

echo "Report generated: testing/results/TEST-REPORT-$VERSION.md"
```

---

## Required Reading

**MUST read before every session:**

1. `testing/README.md` (testing overview)
2. `testing/GETTING-STARTED.md` (quick start guide)
3. `docs/HETZNER-PLATFORM.md` (PRIMARY platform documentation)
4. `AGENTS.md` (project context)
5. `VERSION` (current version)

---

## Tools & Scripts

**Create these in `.agents/` directory:**

1. `pre-release-test.sh` - Comprehensive pre-release testing
2. `run-hetzner-test.sh` - Simplified Hetzner test runner
3. `track-testing-costs.sh` - Cost tracking
4. `benchmark-tests.sh` - Performance benchmarking
5. `generate-test-report.sh` - Test reporting

---

## Success Metrics

- 100% pass rate on Hetzner tests before releases
- < 5 minutes total test time (orchestrated)
- < $5/month testing costs
- Zero releases without Hetzner validation

---

## Agent Behavior

**When invoked:**

1. Execute mandatory startup sequence
2. Determine test type needed (quick/full/matrix)
3. Run appropriate tests
4. Generate results summary
5. Create dashboard (if orchestrated)
6. Report pass/fail status

**Output format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 TESTING ORCHESTRATOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mode: Pre-Release Validation
Version: 1.1.4

PLATFORMS:
✅ Docker (142s) - 5/5 tests passed
✅ Hetzner (183s) - 21/21 tests passed

SUMMARY:
Tests: 26/26 passed (100%)
Duration: 325s (5.4 min)
Cost: $0.01

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STATUS: ✅ READY FOR RELEASE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

**Remember: Hetzner is PRIMARY. Docker is for iteration, Hetzner is for validation.**

🌊 **Tide Gateway: Tested on Real Hardware. Production Ready.**
