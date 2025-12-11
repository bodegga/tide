# 🌊 Tide Gateway - Testing Quick Start

**Get your testing infrastructure running in 5 minutes**

---

## What You Have

A complete automated testing orchestration system:

```
testing/
├── orchestrate-tests.sh          # 🎯 Main orchestrator
├── generate-dashboard.sh         # 📊 Dashboard generator
├── containers/test-docker.sh     # 🐳 Docker testing
├── cloud/test-hetzner.sh         # ☁️  Cloud testing
└── results/                      # 📁 All test sessions
```

---

## Prerequisites Check

Run these commands to check if you're ready:

```bash
# Check Docker
docker info > /dev/null 2>&1 && echo "✅ Docker running" || echo "❌ Start Docker Desktop"

# Check Hetzner token
test -f ~/.config/tide/hetzner.env && echo "✅ Hetzner configured" || echo "❌ Need Hetzner token"

# Check you're in the right directory
pwd | grep -q "tide/testing" && echo "✅ In testing directory" || cd ~/Documents/Personal-Projects/tide/testing
```

**Your status:**
- Docker: ❌ Not running (start Docker Desktop)
- Hetzner: ✅ Configured
- Location: ✅ Ready

---

## Three Ways To Test

### 🥇 Option 1: Docker Only (Fastest)

**Best for:** Daily development, quick validation  
**Time:** 2-3 minutes  
**Cost:** Free  
**What it tests:** Proxy mode, Tor connectivity, API endpoints

```bash
# Start Docker Desktop first!
cd ~/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh
```

**Expected output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 TIDE GATEWAY - DOCKER TEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/6] Building Docker image...
✓ Image built

[2/6] Creating test network...
✓ Network created

[3/6] Starting Tide container...
✓ Container started

[4/6] Waiting for Tor bootstrap...
✓ Tor ready

[5/6] Running tests...
✓ TEST 1: Configuration files exist
✓ TEST 2: Tor daemon running
✓ TEST 3: Tor connectivity working
✓ TEST 4: Exit IP verified
✓ TEST 5: API responding

[6/6] Cleanup...
✓ Cleaned up

🎉 All tests passed!
```

---

### 🥈 Option 2: Hetzner Cloud (Production Realistic)

**Best for:** Before releases, production validation  
**Time:** 5 minutes  
**Cost:** ~$0.01 USD (one penny)  
**What it tests:** All modes, real ARM hardware, full network stack

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-hetzner.sh
```

**What happens:**
1. Creates ARM server in Hillsboro, OR (closest to Petaluma)
2. Installs Tide Gateway v1.2.0
3. Runs comprehensive test suite
4. Asks if you want to destroy or keep server
5. Total cost: ~$0.01

**Expected output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 Tide Gateway - Hetzner Cloud Testing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration:
  Server: tide-test-1733889045
  Type: cpx11 (2 vCPU, 2GB RAM)
  Location: hil (Hillsboro, OR)
  Cost: ~$0.006/hr

[1/6] Creating Hetzner server...
✓ Server created

[2/6] Getting server IP...
✓ Server IP: 135.181.45.123

[3/6] Waiting for SSH (30 seconds)...
✓ SSH ready

[4/6] Installing Tide Gateway v1.2.0...
✓ Tide installed

[5/6] Running tests...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ TEST 1: CLI Command
✓ TEST 2: Configuration Files
✓ TEST 3: Services Running
✓ TEST 4: Web Dashboard
✓ TEST 5: API Endpoint
✓ TEST 6: Mode Switching
✓ TEST 7: Tor Connectivity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[6/6] Server is still running.

Options:
  1) Destroy server now (recommended)
  2) Keep server for manual exploration
  3) Show SSH command and keep running

Choose [1-3]: 1

✓ Server destroyed

Test complete!
```

---

### 🥇 Option 3: Full Orchestration (Both Platforms in Parallel)

**Best for:** Comprehensive validation, CI/CD  
**Time:** ~5 minutes (parallel, not 7-8 sequential!)  
**Cost:** ~$0.01 USD  
**What it tests:** Everything, simultaneously

```bash
cd ~/Documents/Personal-Projects/tide/testing
./orchestrate-tests.sh run
```

**What happens:**
1. Starts Docker test in background
2. Starts Hetzner test in background
3. Waits for both to complete
4. Aggregates results
5. Generates summary report
6. Creates visual dashboard

**Expected output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 TIDE GATEWAY - TEST ORCHESTRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Session: 20241210-223045
Results: /Users/abiasi/Documents/Personal-Projects/tide/testing/results/20241210-223045

Starting parallel test execution...

[START] Testing on docker...
[START] Testing on hetzner...
[PASS] docker (142s)
[PASS] hetzner (183s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ docker - 142s
✅ hetzner - 183s

Overall: 2 passed, 0 failed

Results saved to:
  /Users/abiasi/Documents/Personal-Projects/tide/testing/results/20241210-223045

Summary report:
  /Users/abiasi/Documents/Personal-Projects/tide/testing/results/20241210-223045/SUMMARY.md

🎉 All tests passed!
```

Then view the dashboard:
```bash
./generate-dashboard.sh
open results/dashboard.html
```

---

## Orchestrator Commands

```bash
# Run all tests (default)
./orchestrate-tests.sh
./orchestrate-tests.sh run

# View latest results
./orchestrate-tests.sh latest

# List all test sessions
./orchestrate-tests.sh list

# Show specific session
./orchestrate-tests.sh show 20241210-223045

# Clean old results (keep last 10)
./orchestrate-tests.sh clean 10

# Generate visual dashboard
./generate-dashboard.sh
```

---

## Results Structure

After running tests, you get:

```
results/20241210-223045/
├── logs/
│   ├── docker.log              # Full Docker test output
│   └── hetzner.log             # Full Hetzner test output
├── docker-results.json         # Machine-readable Docker results
├── hetzner-results.json        # Machine-readable Hetzner results
└── SUMMARY.md                  # Human-readable summary

Plus (after running generate-dashboard.sh):
├── dashboard.html              # Beautiful visual dashboard
└── test-data.json              # Dashboard data feed
```

---

## Typical Workflows

### Development Workflow (Daily)

```bash
# Make changes to Tide
vim ~/Documents/Personal-Projects/tide/scripts/runtime/tide-cli.sh

# Quick Docker test
cd ~/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh

# If passes, commit
git add -A
git commit -m "Add feature X"
git push
```

### Release Workflow (Weekly)

```bash
# Update version
cd ~/Documents/Personal-Projects/tide
echo "v1.3.0" > VERSION

# Run full orchestrated tests
cd testing
./orchestrate-tests.sh

# If all pass, tag and release
git tag v1.3.0
git push origin v1.3.0

# Generate dashboard for release notes
./generate-dashboard.sh
open results/dashboard.html
```

### Before Pushing Code

```bash
# Quick validation
cd ~/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh

# If passes, safe to push
git push origin main
```

---

## Troubleshooting

### Docker test fails with "Cannot connect to Docker daemon"

**Fix:** Start Docker Desktop

```bash
open -a Docker
# Wait 30 seconds for Docker to start
docker info
```

### Hetzner test fails with "token not found"

**Fix:** Verify token is configured

```bash
cat ~/.config/tide/hetzner.env
# Should show: HETZNER_TIDE_TOKEN=your-token-here
```

### Orchestrator shows "Unknown" status

**Fix:** Test session was incomplete, clean it up

```bash
cd ~/Documents/Personal-Projects/tide/testing
./orchestrate-tests.sh clean 1
```

---

## Performance & Costs

### Execution Times

| Platform | Time | Cost | When to Use |
|----------|------|------|-------------|
| Docker | 2-3 min | Free | Daily development |
| Hetzner | 5 min | $0.01 | Before releases |
| Both (parallel) | 5 min | $0.01 | Full validation |

### Annual Costs

Assuming 25 Hetzner tests per year:
- **Docker:** $0 (unlimited)
- **Hetzner:** ~$0.25/year
- **Total:** ~$3/year for comprehensive testing

**Worth it?** Absolutely. That's less than a coffee for production-grade testing.

---

## What's Next?

### Immediate (Pick One)

1. **Start Docker Desktop** and run your first Docker test
2. **Run Hetzner test** now (costs a penny, worth it!)
3. **Explore commands** without running tests

### Regular (Ongoing)

1. **Before every commit:** Quick Docker test
2. **Before every release:** Full orchestrated test
3. **Weekly cleanup:** `./orchestrate-tests.sh clean 10`

### Future (Optional)

1. Add GitHub Actions workflow for automated testing
2. Set up cron job for nightly tests
3. Add email notifications on failures

---

## Quick Reference

```bash
# Most common commands
cd ~/Documents/Personal-Projects/tide/testing

# Quick test (2 min, free)
./containers/test-docker.sh

# Production test (5 min, $0.01)
./cloud/test-hetzner.sh

# Full orchestration (5 min, $0.01)
./orchestrate-tests.sh

# View results
./orchestrate-tests.sh latest
./generate-dashboard.sh

# Cleanup
./orchestrate-tests.sh clean 10
```

---

## Ready to Test?

**Choose your first test:**

### Option A: Docker (Safe, Free)
```bash
# 1. Start Docker Desktop
open -a Docker

# 2. Wait 30 seconds, then:
cd ~/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh
```

### Option B: Hetzner (Real Hardware, Costs a Penny)
```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-hetzner.sh
```

### Option C: Full Orchestration (Both)
```bash
# Start Docker Desktop first!
cd ~/Documents/Personal-Projects/tide/testing
./orchestrate-tests.sh
```

---

**You're all set! Your testing infrastructure is ready to go.** 🌊

**Questions?** Check:
- `ORCHESTRATION-README.md` - Quick reference
- `ORCHESTRATION.md` - Full documentation
- `PLATFORM-COMPARISON.md` - Platform pros/cons

**Last Updated:** December 10, 2024  
**Tide Version:** v1.2.0  
**Orchestration Version:** 1.0
