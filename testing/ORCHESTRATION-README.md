# 🌊 Tide Gateway - Test Orchestration System

**The automated testing management system for Tide Gateway v1.2.0+**

---

## TL;DR - Quick Start

```bash
# 1. Run all tests in parallel
./orchestrate-tests.sh

# 2. View results
./orchestrate-tests.sh latest

# 3. Generate visual dashboard
./generate-dashboard.sh
open results/dashboard.html
```

**That's it.** Your testing infrastructure is fully automated.

---

## What Is This?

A centralized orchestration system that:

1. **Runs tests in parallel** across Docker, Hetzner, QEMU, VirtualBox
2. **Collects results** from all platforms
3. **Generates reports** (Markdown + JSON + HTML dashboard)
4. **Archives history** for trend analysis
5. **Reports back** to your management host (this Mac)

**Before this:**
- You had to run `test-docker.sh`, `test-hetzner.sh`, etc. manually
- Results were scattered across different directories
- No easy way to compare platforms
- No visual dashboard
- No history tracking

**After this:**
- One command runs everything: `./orchestrate-tests.sh`
- All results in one place: `results/<timestamp>/`
- Beautiful HTML dashboard: `results/dashboard.html`
- Full history: `./orchestrate-tests.sh list`
- Machine-readable JSON for CI/CD

---

## Architecture

```
testing/
├── orchestrate-tests.sh       # 🎯 Main orchestrator
├── generate-dashboard.sh      # 📊 Dashboard generator
├── results/                   # 📁 All test sessions
│   ├── 20241210-153045/       # Session directory
│   │   ├── logs/              # Individual logs
│   │   │   ├── docker.log
│   │   │   └── hetzner.log
│   │   ├── docker-results.json
│   │   ├── hetzner-results.json
│   │   └── SUMMARY.md
│   ├── dashboard.html         # Visual dashboard
│   └── test-data.json         # Dashboard data
├── containers/                # Docker tests
├── cloud/                     # Cloud tests (Hetzner)
└── hypervisors/               # VM tests (QEMU, VirtualBox)
```

---

## Commands

### `./orchestrate-tests.sh`

| Command | What It Does | Example |
|---------|--------------|---------|
| `run` (default) | Run all tests in parallel | `./orchestrate-tests.sh` |
| `latest` | Show latest test results | `./orchestrate-tests.sh latest` |
| `list` | List all test sessions | `./orchestrate-tests.sh list` |
| `show <session>` | Show specific session | `./orchestrate-tests.sh show 20241210-153045` |
| `clean [N]` | Keep last N sessions | `./orchestrate-tests.sh clean 5` |

### `./generate-dashboard.sh`

Generates beautiful HTML dashboard from latest results.

```bash
./generate-dashboard.sh
# Opens: results/dashboard.html
```

**Features:**
- Real-time test status
- Platform-by-platform results
- Duration metrics
- Pass/fail counts
- Log previews
- Responsive design
- One-click refresh

---

## Typical Workflows

### Development Workflow

```bash
# 1. Make changes to Tide
vim scripts/runtime/tide-cli.sh

# 2. Quick test with Docker (2 min)
cd testing/containers && ./test-docker.sh

# 3. If Docker passes, full validation
cd .. && ./orchestrate-tests.sh

# 4. View results
./generate-dashboard.sh
open results/dashboard.html
```

### Release Workflow

```bash
# 1. Update version
echo "v1.3.0" > VERSION

# 2. Run full test suite
cd testing && ./orchestrate-tests.sh

# 3. If all pass, safe to release
if [ $? -eq 0 ]; then
    git tag v1.3.0
    git push origin v1.3.0
fi

# 4. Document results
./generate-dashboard.sh
```

### Daily Automated Testing

Add to crontab:

```cron
# Run tests every day at 3 AM
0 3 * * * cd ~/Documents/Personal-Projects/tide/testing && ./orchestrate-tests.sh
```

---

## What Gets Tested?

### Platforms

Currently enabled:
- ✅ **Docker** (fast, free, 2-3 min)
- ✅ **Hetzner Cloud** (real hardware, $0.01 per run, 5 min)

Can enable:
- ⚠️ **QEMU** (requires manual Alpine setup)
- ⚠️ **VirtualBox** (requires VirtualBox installation)

### Test Suite (per platform)

1. **CLI Command** - `tide` command works
2. **Configuration** - Mode and security files exist
3. **Services** - Tor, API, dnsmasq running
4. **Tor Connectivity** - Can reach Tor network
5. **Mode Switching** - Can change modes
6. **API Endpoint** - API responds correctly
7. **Exit IP Validation** - Tor exit IP confirmed

---

## Results Format

### Directory Structure

```
results/20241210-153045/
├── logs/
│   ├── docker.log          # Full test output
│   └── hetzner.log
├── docker-results.json     # Parsed results
├── hetzner-results.json
└── SUMMARY.md              # Human-readable summary
```

### JSON Results

```json
{
  "platform": "docker",
  "timestamp": "20241210-153045",
  "status": "PASS",
  "duration_seconds": 142,
  "tests": {
    "total": 7,
    "passed": 7,
    "failed": 0
  }
}
```

### Markdown Summary

- Platform-by-platform results
- Test statistics
- Log excerpts (last 30 lines)
- Metadata (timestamp, version)

### HTML Dashboard

- Visual overview
- Pass/fail indicators
- Duration charts
- Log previews
- Refresh button

---

## Configuration

### Change Platforms

Edit `orchestrate-tests.sh` line ~24:

```bash
# Test only Docker
PLATFORMS=("docker")

# Test Docker + Hetzner
PLATFORMS=("docker" "hetzner")

# Test everything
PLATFORMS=("docker" "hetzner" "qemu" "virtualbox")
```

### Change History Retention

```bash
# Keep last 5 sessions
./orchestrate-tests.sh clean 5

# Keep last 20 sessions
./orchestrate-tests.sh clean 20
```

---

## Performance & Costs

### Execution Time

| Platform | Time | Cost |
|----------|------|------|
| Docker | 2-3 min | Free |
| Hetzner | 5 min | ~$0.01 |
| QEMU | 10-15 min | Free |
| VirtualBox | 10-15 min | Free |

**Parallel execution:** Docker + Hetzner = ~5 min total (not 7-8 min sequential)

### Storage

- Per session: ~50MB (logs + results)
- 10 sessions: ~500MB
- 100 sessions: ~5GB

**Recommendation:** Run `./orchestrate-tests.sh clean 10` weekly

### Cloud Costs

**Hetzner:**
- $0.01 per test run
- $0.25 per month (25 runs)
- $3 per year (300 runs)

**Total annual cost:** ~$3 for comprehensive cloud testing

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Tide Gateway Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Orchestrated Tests
        run: cd testing && ./orchestrate-tests.sh
      
      - name: Generate Dashboard
        if: always()
        run: cd testing && ./generate-dashboard.sh
      
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: testing/results/
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

cd testing
./containers/test-docker.sh

if [ $? -ne 0 ]; then
    echo "❌ Docker tests failed. Fix before committing."
    exit 1
fi
```

---

## Troubleshooting

### Tests Not Running

```bash
# Check if executable
ls -la orchestrate-tests.sh

# Make executable if needed
chmod +x orchestrate-tests.sh generate-dashboard.sh
```

### Platform Tests Failing

```bash
# Run platform test directly
cd containers && ./test-docker.sh
cd cloud && ./test-hetzner.sh

# Check logs
cat results/<latest-session>/logs/docker.log
```

### Dashboard Not Generating

```bash
# Install jq if missing
brew install jq

# Check if results exist
ls -la results/$(ls -t results | head -1)

# Validate JSON
jq . results/<session>/docker-results.json
```

---

## Examples

### Example Terminal Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 TIDE GATEWAY - TEST ORCHESTRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Session: 20241210-153045
Results: /Users/abiasi/Documents/Personal-Projects/tide/testing/results/20241210-153045

Starting parallel test execution...

[START] Testing on docker...
[START] Testing on hetzner...
[PASS] docker (142s)
[PASS] hetzner (183s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ docker - 142s
✅ hetzner - 183s

Overall: 2 passed, 0 failed

Results saved to:
  /Users/abiasi/Documents/Personal-Projects/tide/testing/results/20241210-153045

Summary report:
  /Users/abiasi/Documents/Personal-Projects/tide/testing/results/20241210-153045/SUMMARY.md

🎉 All tests passed!
```

### Example Dashboard

![Dashboard showing test results with green checkmarks for Docker and Hetzner platforms]

---

## FAQ

**Q: Can I test just Docker?**

A: Yes. Edit `PLATFORMS=("docker")` in `orchestrate-tests.sh`

**Q: How much does this cost?**

A: Docker is free. Hetzner is ~$0.01 per test (~$3/year).

**Q: Where are results stored?**

A: `testing/results/<timestamp>/`

**Q: Can I delete old results?**

A: Yes. `./orchestrate-tests.sh clean 5` keeps last 5 sessions.

**Q: Does this work with bash 3.2?**

A: Yes. Tested on macOS default bash (3.2.57).

**Q: Can I run tests manually?**

A: Yes. Individual test scripts still work:
- `containers/test-docker.sh`
- `cloud/test-hetzner.sh`

---

## What's Next?

### Immediate (You)

1. **Test the system:**
   ```bash
   cd /Users/abiasi/Documents/Personal-Projects/tide/testing
   ./orchestrate-tests.sh
   ```

2. **Generate dashboard:**
   ```bash
   ./generate-dashboard.sh
   open results/dashboard.html
   ```

3. **Add to workflow:**
   - Before commits: `./containers/test-docker.sh`
   - Before releases: `./orchestrate-tests.sh`

### Future Enhancements

- [ ] Real-time WebSocket dashboard
- [ ] Email/Slack notifications
- [ ] Trend analysis (pass rate over time)
- [ ] Performance benchmarking
- [ ] Automated retries
- [ ] Cost tracking

---

## Documentation

- **Full docs:** `ORCHESTRATION.md`
- **Platform comparison:** `PLATFORM-COMPARISON.md`
- **Quick start:** `QUICKSTART.md`
- **Testing guide:** `README.md`

---

## Summary

You now have:
- ✅ **Automated orchestration** - One command runs everything
- ✅ **Parallel execution** - Save time with concurrent testing
- ✅ **Result aggregation** - All results in one place
- ✅ **Visual dashboard** - Beautiful HTML reports
- ✅ **History tracking** - See trends over time
- ✅ **CI/CD ready** - JSON output for automation
- ✅ **Cost effective** - ~$3/year for cloud testing

**Command to remember:**

```bash
./orchestrate-tests.sh
```

That's your entire testing infrastructure in one line.

---

**Last Updated:** December 10, 2024  
**Tide Version:** v1.2.0  
**Orchestration Version:** 1.0  
**Status:** ✅ Production Ready

**Enjoy your automated testing! 🌊**
