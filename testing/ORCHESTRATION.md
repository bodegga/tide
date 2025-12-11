# Tide Gateway - Test Orchestration System

**Version:** 1.0  
**Created:** December 10, 2024  
**Status:** ✅ Ready to Use

---

## Overview

Automated testing orchestration system that manages parallel testing across multiple platforms and provides centralized result reporting.

### What It Does

1. **Parallel Execution** - Runs tests on Docker, Hetzner, QEMU, VirtualBox simultaneously
2. **Result Aggregation** - Collects and parses results from all platforms
3. **HTML Dashboard** - Generates beautiful visual dashboard of test results
4. **History Tracking** - Archives all test sessions with timestamps
5. **JSON Reports** - Machine-readable test data for CI/CD integration

---

## Quick Start

### Run All Tests

```bash
cd /Users/abiasi/Documents/Personal-Projects/tide/testing
./orchestrate-tests.sh run
```

This will:
1. Start Docker and Hetzner tests in parallel
2. Wait for all tests to complete
3. Parse and aggregate results
4. Generate summary report
5. Save results to `results/<timestamp>/`

### View Latest Results

```bash
./orchestrate-tests.sh latest
```

### Generate Visual Dashboard

```bash
./generate-dashboard.sh
# Open the displayed file:// URL in your browser
```

---

## Architecture

```
Testing Orchestration System
├── orchestrate-tests.sh      # Main orchestration engine
├── generate-dashboard.sh     # HTML dashboard generator
└── results/                  # All test sessions
    ├── 20241210-153045/      # Example session
    │   ├── logs/             # Individual platform logs
    │   │   ├── docker.log
    │   │   └── hetzner.log
    │   ├── docker-results.json
    │   ├── hetzner-results.json
    │   └── SUMMARY.md        # Markdown summary report
    ├── dashboard.html        # Visual dashboard (latest)
    └── test-data.json        # JSON data for dashboard
```

---

## Commands

### `orchestrate-tests.sh`

Main orchestration engine with multiple subcommands:

#### `run` (default)
Run all enabled tests in parallel.

```bash
./orchestrate-tests.sh run
# or just:
./orchestrate-tests.sh
```

**Output:**
- Real-time progress updates
- Pass/fail status for each platform
- Test duration per platform
- Overall summary
- Results directory location

**Exit codes:**
- `0` - All tests passed
- `1` - One or more tests failed

---

#### `latest`
Show results from the most recent test session.

```bash
./orchestrate-tests.sh latest
```

**Output:**
- Displays SUMMARY.md from latest session
- Platform-by-platform results
- Log excerpts
- Test statistics

---

#### `list`
List all test sessions with pass/fail status.

```bash
./orchestrate-tests.sh list
```

**Output:**
```
Session                | Status
-----------------------|------------------
20241210-153045       | PASS
20241210-142301       | FAIL
20241210-135512       | PASS
```

---

#### `show <session>`
Show detailed results for a specific session.

```bash
./orchestrate-tests.sh show 20241210-153045
```

**Output:**
- Full SUMMARY.md for that session
- Platform results
- Log excerpts
- Test statistics

---

#### `clean [N]`
Clean old test results, keeping only the last N sessions (default: 10).

```bash
# Keep last 10 sessions
./orchestrate-tests.sh clean

# Keep last 5 sessions
./orchestrate-tests.sh clean 5
```

**Output:**
- List of sessions to be deleted
- Confirmation of cleanup

---

### `generate-dashboard.sh`

Generate visual HTML dashboard from latest test results.

```bash
./generate-dashboard.sh
```

**Output:**
- `results/dashboard.html` - Beautiful visual dashboard
- `results/test-data.json` - JSON data for dashboard
- File URL to open in browser

**Features:**
- Overall pass/fail status
- Total tests passed/failed
- Duration metrics
- Per-platform results
- Log previews
- Refresh button
- Responsive design

**Serve Locally:**
```bash
cd results
python3 -m http.server 8080
# Visit: http://localhost:8080/dashboard.html
```

---

## Configuration

### Enabled Platforms

Edit `orchestrate-tests.sh` to change which platforms are tested:

```bash
# Line ~35
PLATFORMS=("docker" "hetzner")

# Add more platforms:
PLATFORMS=("docker" "hetzner" "qemu" "virtualbox")
```

**Available platforms:**
- `docker` - Docker container testing (fast, free)
- `hetzner` - Hetzner Cloud testing (slow, costs ~$0.01)
- `qemu` - QEMU/KVM testing (requires manual setup)
- `virtualbox` - VirtualBox testing (requires VirtualBox installed)

### Test Timeout

Each platform test runs independently with its own timeout defined in the individual test scripts:

- Docker: ~3 minutes
- Hetzner: ~5 minutes
- QEMU: ~15 minutes
- VirtualBox: ~15 minutes

---

## Result Formats

### JSON Results (`<platform>-results.json`)

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

### Summary Report (`SUMMARY.md`)

Markdown file with:
- Platform results table
- Test statistics per platform
- Log excerpts (last 30 lines)
- Metadata (timestamp, Tide version)

### Dashboard Data (`test-data.json`)

```json
{
  "timestamp": "2024-12-10 15:30:45",
  "session": "20241210-153045",
  "overall": {
    "passed": 14,
    "failed": 0,
    "total_duration": 285
  },
  "platforms": [...]
}
```

---

## Integration Examples

### Daily Automated Testing

Add to crontab:

```cron
# Run tests every day at 3 AM
0 3 * * * cd /Users/abiasi/Documents/Personal-Projects/tide/testing && ./orchestrate-tests.sh run && ./generate-dashboard.sh
```

### Pre-Release Testing

```bash
#!/bin/bash
# test-before-release.sh

cd /Users/abiasi/Documents/Personal-Projects/tide/testing

echo "Running pre-release tests..."
./orchestrate-tests.sh run

if [ $? -eq 0 ]; then
    echo "✅ All tests passed - safe to release"
    ./generate-dashboard.sh
    exit 0
else
    echo "❌ Tests failed - do not release"
    ./orchestrate-tests.sh latest
    exit 1
fi
```

### CI/CD Integration (GitHub Actions)

```yaml
name: Tide Gateway Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Orchestrated Tests
        run: |
          cd testing
          ./orchestrate-tests.sh run
      
      - name: Generate Dashboard
        if: always()
        run: |
          cd testing
          ./generate-dashboard.sh
      
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: testing/results/
```

---

## Workflow Examples

### Development Workflow

```bash
# 1. Make changes to Tide Gateway
vim scripts/runtime/tide-cli.sh

# 2. Run quick Docker test
cd testing/containers
./test-docker.sh

# 3. If Docker passes, run full orchestrated tests
cd ..
./orchestrate-tests.sh run

# 4. View results
./orchestrate-tests.sh latest

# 5. Generate dashboard for visual inspection
./generate-dashboard.sh
open results/dashboard.html  # macOS
```

### Release Workflow

```bash
# 1. Update version
echo "v1.3.0" > VERSION

# 2. Run full test suite
cd testing
./orchestrate-tests.sh run

# 3. Check if all passed
if [ $? -eq 0 ]; then
    echo "Safe to release"
else
    echo "Fix failures first"
    ./orchestrate-tests.sh latest
    exit 1
fi

# 4. Generate dashboard for release notes
./generate-dashboard.sh

# 5. Tag release
git tag v1.3.0
git push origin v1.3.0
```

---

## Troubleshooting

### Tests Not Running

**Check:**
```bash
# Verify scripts are executable
ls -la orchestrate-tests.sh generate-dashboard.sh

# If not executable:
chmod +x orchestrate-tests.sh generate-dashboard.sh
```

### Platform Tests Failing

**Debug individual platform:**
```bash
# Run platform test directly
cd containers && ./test-docker.sh
cd cloud && ./test-hetzner.sh

# Check logs
cat results/<latest-session>/logs/docker.log
cat results/<latest-session>/logs/hetzner.log
```

### Dashboard Not Generating

**Requirements:**
- `jq` must be installed: `brew install jq`
- Latest test session must exist
- JSON result files must be valid

**Check:**
```bash
# Verify jq
which jq

# Check latest session
ls -la results/$(ls -t results | grep -E '^[0-9]{8}' | head -1)

# Validate JSON
jq . results/<session>/docker-results.json
```

### Results Directory Full

**Clean old results:**
```bash
# Keep last 5 sessions
./orchestrate-tests.sh clean 5

# Or manually
rm -rf results/20241210-*
```

---

## Advanced Usage

### Custom Platform Sets

Create platform-specific orchestration:

```bash
# test-docker-only.sh
#!/bin/bash
PLATFORMS=("docker")
./orchestrate-tests.sh run
```

```bash
# test-cloud-only.sh
#!/bin/bash
PLATFORMS=("hetzner")
./orchestrate-tests.sh run
```

### Notification Integration

Add Slack/email notifications:

```bash
# In orchestrate-tests.sh, add to display_summary():

if [ $total_failed -gt 0 ]; then
    # Send Slack notification
    curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"🔴 Tide Gateway tests failed: $total_failed platforms\"}"
fi
```

### Performance Tracking

Track test duration over time:

```bash
# extract-durations.sh
for session in results/*/; do
    timestamp=$(basename "$session")
    total_duration=$(jq '.overall.total_duration' "$session/test-data.json" 2>/dev/null || echo "N/A")
    echo "$timestamp,$total_duration"
done > test-performance.csv
```

---

## File Reference

| File | Purpose | Lines | Generated |
|------|---------|-------|-----------|
| `orchestrate-tests.sh` | Main orchestration engine | ~450 | Manual |
| `generate-dashboard.sh` | HTML dashboard generator | ~200 | Manual |
| `results/<session>/SUMMARY.md` | Markdown summary | ~100 | Auto |
| `results/<session>/<platform>-results.json` | Platform results | ~10 | Auto |
| `results/<session>/logs/<platform>.log` | Full test output | Varies | Auto |
| `results/dashboard.html` | Visual dashboard | ~300 | Auto |
| `results/test-data.json` | Dashboard data | ~50 | Auto |

---

## Performance

### Resource Usage

**During Tests:**
- CPU: 2-4 cores (parallel execution)
- RAM: ~4GB (for Docker + Hetzner + logs)
- Disk: ~50MB per session (logs + results)

**Storage Growth:**
- 10 sessions: ~500MB
- 50 sessions: ~2.5GB
- 100 sessions: ~5GB

**Recommended:** Run `./orchestrate-tests.sh clean 10` weekly

---

## Future Enhancements

Potential additions:

- [ ] **Real-time dashboard** - WebSocket live updates during test runs
- [ ] **Parallel visual progress** - Live terminal UI with platform status
- [ ] **Email reports** - Send summary emails after test completion
- [ ] **Trend analysis** - Graph test durations and pass rates over time
- [ ] **Platform health checks** - Pre-flight checks before starting tests
- [ ] **Automated retries** - Retry failed tests once automatically
- [ ] **Custom test suites** - Define different test sets for different scenarios
- [ ] **Cost tracking** - Track Hetzner costs over time

---

## Success Metrics

### Coverage
- ✅ Orchestrates 2+ platforms simultaneously
- ✅ Collects and parses results from all platforms
- ✅ Generates machine-readable JSON
- ✅ Creates human-readable markdown summary
- ✅ Provides visual HTML dashboard

### Efficiency
- ✅ Parallel execution (2x faster than sequential)
- ✅ Auto-cleanup options
- ✅ Session history tracking
- ✅ One-command testing

### Reliability
- ✅ Exit codes for CI/CD integration
- ✅ Individual platform logs preserved
- ✅ JSON validation for dashboard
- ✅ Graceful handling of platform failures

---

## Examples

### Example Session Output

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

---

## API Reference

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All tests passed |
| `1` | One or more tests failed |
| `2` | No test results found (for `latest`, `show` commands) |

### Environment Variables

None required. All configuration is embedded in scripts.

### Dependencies

- `bash` (4.0+)
- `jq` (for JSON parsing)
- `curl` (for Hetzner API)
- Individual platform tools (docker, hcloud, etc.)

---

## Real-World Usage

**For Anthony (Personal Projects):**

```bash
# Daily development workflow
cd ~/Documents/Personal-Projects/tide/testing

# Quick check before committing
./containers/test-docker.sh

# Full validation before pushing
./orchestrate-tests.sh run

# View results
./generate-dashboard.sh
open results/dashboard.html
```

**Cost estimate:**
- Docker tests: Free (unlimited)
- Hetzner tests: ~$0.01 per run
- Monthly (25 Hetzner runs): ~$0.25
- Yearly: ~$3

---

**Last Updated:** December 10, 2024  
**Tide Version:** v1.2.0  
**Orchestration Version:** 1.0  
**Status:** ✅ Production Ready
