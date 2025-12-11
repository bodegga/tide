# Hetzner Cloud - Primary Testing & Future Hosting Platform

**Status:** Active | **Version:** 1.0 | **Last Updated:** December 10, 2025

---

## Table of Contents

1. [Why Hetzner for Tide Gateway](#why-hetzner-for-tide-gateway)
2. [Current Testing Usage](#current-testing-usage)
3. [Matrix Testing](#matrix-testing)
4. [Future Migration Plans](#future-migration-plans)
5. [Hetzner Setup Guide](#hetzner-setup-guide)
6. [Server Types & Pricing](#server-types--pricing)
7. [Automated Testing Workflow](#automated-testing-workflow)
8. [Manual Testing on Hetzner](#manual-testing-on-hetzner)

---

## Why Hetzner for Tide Gateway

Hetzner Cloud is the **primary platform** for Tide Gateway testing and planned future hosting. Here's why:

### Cost Comparison

| Provider | Server Type | vCPU | RAM | Price/Hour | Price/Month |
|----------|-------------|------|-----|------------|-------------|
| **Hetzner** | CPX11 (ARM) | 2 | 2GB | €0.0054 (~$0.006) | ~$4.32 |
| **DigitalOcean** | Basic Droplet | 1 | 1GB | $0.00744 | ~$6.00 |
| **Hetzner** | CPX21 (ARM) | 3 | 4GB | €0.0108 (~$0.012) | ~$8.64 |
| **DigitalOcean** | Basic Droplet | 2 | 2GB | $0.02232 | ~$18.00 |

**Savings:** ~28-52% cheaper than DigitalOcean for comparable specs.

### ARM Hardware Availability

- **Hetzner:** Native ARM64 servers (CPX series)
- **DigitalOcean:** No ARM offerings in US regions
- **Tide Gateway:** Optimized for ARM (Raspberry Pi target)
- **Testing:** Real ARM hardware = production-realistic testing

### Location: Hillsboro, OR

- **Data Center:** Hillsboro, Oregon (`hil`)
- **Distance:** Closest US location to Petaluma/Bay Area (~650 miles)
- **Latency:** Low latency for testing and future production use
- **Alternative:** Ashburn, VA (`ash`) - East Coast option

### Testing on Real Bare Metal

Unlike Docker containers:
- **Real network stack** - Full iptables, routing, DNS
- **Real hardware** - ARM architecture matches Raspberry Pi
- **Real services** - systemd, Tor daemon, full OS
- **Real performance** - Actual production conditions

### Annual Testing Cost

**Scenario:** 150 tests per year (3 per week)
- **Per test:** ~5 minutes runtime
- **Cost per test:** ~$0.01 (one penny)
- **Annual cost:** ~$1.50/year

**Comparison:**
- **Docker:** Free but doesn't test full stack
- **Physical hardware:** $35+ per Raspberry Pi + ongoing power costs
- **DigitalOcean:** Would cost ~$2.25/year for same testing

**Verdict:** Hetzner is the sweet spot - real hardware at pennies per test.

---

## Current Testing Usage

Tide Gateway v1.1.2+ includes automated Hetzner Cloud testing integrated into the orchestration system.

### How It Works

1. **Automated creation:** Script creates ARM server in Hillsboro, OR
2. **Installation:** Installs Tide Gateway from GitHub
3. **Testing:** Runs comprehensive 7-test suite
4. **Results:** Aggregates with Docker test results
5. **Cleanup:** Destroys server automatically (or keeps for manual exploration)

### Cost Per Test

- **Server type:** CPX11 (2 vCPU, 2GB RAM)
- **Runtime:** ~5 minutes (including creation and destruction)
- **Cost:** €0.0054/hr × 0.083hr = €0.00045 (~$0.005)
- **Rounded:** ~$0.01 per test

### Time Per Test

- **Server creation:** 30 seconds
- **SSH availability:** 30 seconds
- **Tide installation:** 90 seconds
- **Test execution:** 60 seconds
- **Server destruction:** 10 seconds
- **Total:** ~4-5 minutes

### Integration with Orchestration

The Hetzner test runs in parallel with Docker testing:

```bash
cd ~/Documents/Personal-Projects/tide/testing
./orchestrate-tests.sh
```

**What happens:**
1. Launches Docker test in background
2. Launches Hetzner test in background
3. Both run simultaneously
4. Results aggregated when both complete
5. Dashboard generated with combined results

**Benefit:** No time penalty - total runtime is ~5 minutes (same as Hetzner alone).

---

## Matrix Testing

**NEW:** Comprehensive hardware and OS compatibility testing.

### What is Matrix Testing?

Matrix testing validates Tide Gateway across **all combinations** of:
- **Server types:** CPX (ARM shared), CAX (ARM dedicated), CX (x86)
- **Operating systems:** Ubuntu 22.04/24.04, Debian 12, Fedora 40
- **All modes:** proxy, router, killa-whale
- **Full stack:** Tor, services, API, mode switching

### Run Matrix Tests

```bash
cd ~/Documents/Personal-Projects/tide/testing

# Preview test matrix
./orchestrate-tests.sh matrix --dry-run

# Quick validation (3 configs: CPX11, CX22, CAX11 × Ubuntu 22.04)
./orchestrate-tests.sh matrix --quick

# Medium test (8 configs: high-priority servers × Ubuntu/Debian)
./orchestrate-tests.sh matrix --medium

# Full matrix (30 configs: all servers × all OS)
./orchestrate-tests.sh matrix --full
```

### Cost Estimates

| Mode | Configurations | Duration | Cost | When to Use |
|------|----------------|----------|------|-------------|
| `--quick` | 3 | ~15 min | $0.03 | Weekly validation |
| `--medium` | 8 | ~40 min | $0.08 | Pre-release testing |
| `--full` | 30 | ~2.5 hrs | $0.30 | Major releases |

### Results

Matrix tests generate:
- **Compatibility matrix** showing what works on what hardware
- **Performance benchmarks** per configuration
- **Cost analysis** for each server type
- **Recommendations** for production deployment

Results saved to: `testing/results/matrix-TIMESTAMP/MATRIX-REPORT.md`

### Documentation

Full hardware compatibility matrix: `docs/HARDWARE-COMPATIBILITY.md`

---

## Future Migration Plans

### Current Production Infrastructure

Anthony currently runs:
- **Car Flipper VPS:** DigitalOcean @ 64.225.89.120
- **Active services:** Python/Flask app, PostgreSQL, Celery
- **Monthly cost:** ~$24/month (estimate)
- **Platform:** x86_64 architecture

### Why Migrate to Hetzner?

**Cost Savings:**
- Current DigitalOcean: ~$24/month
- Hetzner CPX21 (3 vCPU, 4GB): ~$8.64/month
- Hetzner CPX31 (4 vCPU, 8GB): ~$17.28/month
- **Savings:** $7-15/month ($84-180/year)

**Better Performance:**
- Newer hardware
- Dedicated CPU cores (vs shared)
- Better network performance
- More storage included

**ARM vs x86 Considerations:**
- Car Flipper: x86_64 app (Docker-based)
- Hetzner: Offers both ARM (CPX) and x86 (CX) servers
- **Solution:** Use CX series for x86 workloads
- Tide Gateway: Use CPX series for ARM workloads

### Migration Timeline

**Phase 1: Validation (In Progress)**
- ✅ Hetzner account created
- ✅ API token configured
- ✅ Testing infrastructure working
- ⏳ Validate reliability over 3-6 months

**Phase 2: Tide Gateway Production (TBD)**
- Deploy Tide Gateway on Hetzner CPX11
- Use for personal privacy appliance
- Monitor performance and reliability
- Document production setup

**Phase 3: Car Flipper Migration (TBD)**
- Create Hetzner CX-series server (x86)
- Test Car Flipper deployment
- Migrate database and services
- Update DNS records
- Switch production traffic
- **Estimated savings:** $84-180/year

**Phase 4: Other Services (Future)**
- Evaluate other DigitalOcean services
- Migrate suitable workloads
- Maximize cost savings

### What Needs to Be Migrated

**Car Flipper VPS:**
- [ ] Python/Flask application
- [ ] PostgreSQL database
- [ ] Celery task queue
- [ ] Nginx reverse proxy
- [ ] SSL certificates (Let's Encrypt)
- [ ] Backup scripts
- [ ] DNS records (cars.bodegga.net)

**Tide Gateway (Future Production):**
- [ ] Deploy on Hetzner CPX11
- [ ] Configure Tor
- [ ] Set up WireGuard (v1.3.0)
- [ ] Document access instructions
- [ ] Monitor bandwidth/performance

---

## Hetzner Setup Guide

### Step 1: Get Hetzner API Token

1. **Sign up for Hetzner Cloud**
   - Go to https://console.hetzner.cloud/
   - Create account (requires payment method)
   - Activate account

2. **Create API Token**
   - In Hetzner Console, go to "Security" → "API Tokens"
   - Click "Generate API Token"
   - Name: `tide-testing` (or similar)
   - Permissions: **Read & Write**
   - Copy token (shows only once!)

3. **Save token securely**
   - Store in password manager
   - Do NOT commit to git
   - Do NOT share publicly

### Step 2: Configure Local Environment

Create the Hetzner configuration file:

```bash
# Create config directory
mkdir -p ~/.config/tide

# Create config file
cat > ~/.config/tide/hetzner.env << 'EOF'
# Hetzner Cloud API Tokens
HETZNER_TIDE_TOKEN=your-token-here
EOF

# Secure the file
chmod 600 ~/.config/tide/hetzner.env
```

**Replace `your-token-here` with your actual API token.**

### Step 3: Install Hetzner CLI (Optional)

The `hcloud` CLI is required for testing scripts:

**macOS (Homebrew):**
```bash
brew install hcloud
```

**Linux:**
```bash
# Download latest release
wget https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz
tar xzf hcloud-linux-amd64.tar.gz
sudo mv hcloud /usr/local/bin/
```

**Verify installation:**
```bash
hcloud version
```

### Step 4: Test Connection

Authenticate the CLI:

```bash
# Load token
source ~/.config/tide/hetzner.env
export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"

# Test connection
hcloud server list
```

**Expected output:** Empty list (no servers yet) or list of existing servers.

**If error:** Check token is correct and has Read & Write permissions.

### Step 5: Run First Test

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-hetzner.sh
```

**What to expect:**
1. Creates server in Hillsboro, OR
2. Installs Tide Gateway
3. Runs 7 tests
4. Shows results
5. Asks to destroy or keep server

**Choose option 1** (destroy) to minimize costs.

---

## Server Types & Pricing

Hetzner offers two ARM server families: CPX (shared) and CAX (dedicated).

### CPX Series (Shared ARM) - Recommended

| Type | vCPU | RAM | Storage | Price/Hour | Price/Month | Use Case |
|------|------|-----|---------|------------|-------------|----------|
| **CPX11** | 2 | 2GB | 40GB | €0.0054 | ~$4.32 | Testing, small apps |
| **CPX21** | 3 | 4GB | 80GB | €0.0108 | ~$8.64 | Small production |
| **CPX31** | 4 | 8GB | 160GB | €0.0216 | ~$17.28 | Production |
| **CPX41** | 8 | 16GB | 240GB | €0.0432 | ~$34.56 | Heavy workloads |

**Notes:**
- All prices in EUR, converted at ~$1 = €1 (varies)
- Shared vCPUs (good performance for price)
- 20TB traffic included
- ARM64 architecture

### CAX Series (Dedicated ARM)

| Type | vCPU | RAM | Storage | Price/Hour | Price/Month | Use Case |
|------|------|-----|---------|------------|-------------|----------|
| **CAX11** | 2 | 4GB | 40GB | €0.0072 | ~$5.76 | Dedicated performance |
| **CAX21** | 4 | 8GB | 80GB | €0.0144 | ~$11.52 | Dedicated production |
| **CAX31** | 8 | 16GB | 160GB | €0.0288 | ~$23.04 | Heavy production |

**Notes:**
- Dedicated vCPUs (better performance)
- 20TB traffic included
- ARM64 architecture

### CX Series (x86 Standard)

For x86 workloads (Car Flipper, etc.):

| Type | vCPU | RAM | Storage | Price/Hour | Price/Month | Use Case |
|------|------|-----|---------|------------|-------------|----------|
| **CX22** | 2 | 4GB | 40GB | €0.0072 | ~$5.76 | Small x86 apps |
| **CX32** | 4 | 8GB | 80GB | €0.0144 | ~$11.52 | Production x86 |
| **CX42** | 8 | 16GB | 160GB | €0.0288 | ~$23.04 | Heavy x86 |

### Recommended Configurations

**Tide Gateway Testing:**
- **Type:** CPX11
- **Why:** Cheapest ARM option, sufficient for testing
- **Cost per test:** ~$0.01

**Tide Gateway Production:**
- **Type:** CPX21 or CAX11
- **Why:** 4GB RAM for headroom, good performance
- **Cost:** ~$8.64/month or ~$5.76/month

**Car Flipper Migration:**
- **Type:** CX32 (x86)
- **Why:** 4 vCPU, 8GB RAM for Python/PostgreSQL/Celery
- **Cost:** ~$11.52/month (saves ~$12/month vs DigitalOcean)

### Traffic Costs

- **Included:** 20TB/month per server
- **Overage:** €1.19/TB (~$1.19/TB)
- **Typical Tide usage:** <100GB/month (well under limit)

---

## Automated Testing Workflow

### How Orchestration Uses Hetzner

The `orchestrate-tests.sh` script runs tests in parallel:

```bash
cd ~/Documents/Personal-Projects/tide/testing
./orchestrate-tests.sh
```

**Execution flow:**

```
START: orchestrate-tests.sh
  ├─► Docker test (background) ────► Results to docker.log
  └─► Hetzner test (background) ───► Results to hetzner.log
        ↓
     WAIT for both to complete
        ↓
     AGGREGATE results
        ├─► docker-results.json
        ├─► hetzner-results.json
        └─► SUMMARY.md
        ↓
     GENERATE dashboard
        └─► dashboard.html
```

### Test Results Location

All results are saved in timestamped directories:

```
testing/results/
└── 20241210-153045/              # Session timestamp
    ├── logs/
    │   ├── docker.log             # Full Docker test output
    │   └── hetzner.log            # Full Hetzner test output
    ├── docker-results.json        # Machine-readable
    ├── hetzner-results.json       # Machine-readable
    ├── SUMMARY.md                 # Human-readable summary
    └── dashboard.html             # Visual dashboard (after generate)
```

### Dashboard Visualization

After tests complete, generate the dashboard:

```bash
cd ~/Documents/Personal-Projects/tide/testing
./generate-dashboard.sh
open results/dashboard.html
```

**Dashboard shows:**
- ✅ Pass/fail status for each platform
- ⏱️ Execution time per platform
- 📊 Test breakdown (passed/failed/total)
- 📝 Recent test sessions
- 🎯 Success rate over time

### Viewing Results

**Latest results:**
```bash
./orchestrate-tests.sh latest
```

**All sessions:**
```bash
./orchestrate-tests.sh list
```

**Specific session:**
```bash
./orchestrate-tests.sh show 20241210-153045
```

---

## Manual Testing on Hetzner

Sometimes you want to explore the server instead of auto-destroying it.

### Create Server for Manual Testing

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-hetzner.sh
```

When prompted:
```
Options:
  1) Destroy server now (recommended)
  2) Keep server for manual exploration
  3) Show SSH command and keep running

Choose [1-3]: 2
```

**Result:**
- Server stays running
- Script shows IP address and SSH command
- You can connect and explore

### Connect to Server

```bash
ssh root@<SERVER_IP>
```

**Example:**
```bash
ssh root@135.181.45.123
```

**Note:** Uses your `~/.ssh/id_ed25519` key (created by test script).

### Explore the Server

Once connected, you can:

```bash
# Check Tide status
tide status

# View current mode
cat /etc/tide/mode

# Change mode
tide mode killa-whale

# Check Tor status
systemctl status tor

# View web dashboard
curl http://localhost/

# Check API
curl http://localhost:9051/status | python3 -m json.tool

# View logs
journalctl -u tor -n 50
tail -f /var/log/tide-web.log

# Test Tor connectivity
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```

### Keep Server Running

**Cost per hour:** €0.0054 (~$0.006)
**Cost per day:** ~$0.14
**Cost per week:** ~$1.00

**Use cases for keeping server:**
- Extended testing (multiple hours)
- Performance monitoring
- Load testing
- Development iteration

**Remember:** Stop the clock by destroying when done!

### Destroy Server When Done

**Option 1: Use server name**
```bash
hcloud server delete tide-test-1733889045
```

**Option 2: List and delete**
```bash
# List all servers
hcloud server list

# Delete by name
hcloud server delete <SERVER_NAME>
```

**Option 3: Delete all Tide test servers**
```bash
hcloud server list | grep tide-test | awk '{print $2}' | xargs -I {} hcloud server delete {}
```

---

## Best Practices

### Testing Frequency

**Recommended:**
- **Every commit:** Docker test (free, fast)
- **Before releases:** Full orchestration (Docker + Hetzner)
- **Weekly cleanup:** `./orchestrate-tests.sh clean 10`

**Cost estimate:**
- 52 releases/year × $0.01 = **$0.52/year**
- Plus exploratory testing: **~$3/year total**

### Server Management

**Do:**
- ✅ Destroy test servers after use
- ✅ Use descriptive server names
- ✅ Set up billing alerts in Hetzner Console
- ✅ Monitor monthly costs (should be <$5/month)

**Don't:**
- ❌ Leave test servers running overnight
- ❌ Create servers without auto-destroy
- ❌ Share API tokens publicly
- ❌ Commit tokens to git

### Security

**API Token:**
- Store in `~/.config/tide/hetzner.env`
- Never commit to git (already in `.gitignore`)
- Regenerate if exposed
- Use separate tokens for different purposes

**SSH Keys:**
- Test script creates `~/.ssh/id_ed25519` if missing
- Uploaded to Hetzner as `tide-testing`
- Used for all test servers
- Secure with passphrase for production use

**Firewall:**
- Hetzner test servers are temporary (5 min lifetime)
- Default: all ports open (test environment)
- For production: configure Hetzner Cloud Firewall
- See `docs/SECURITY.md` for hardening guide

---

## Troubleshooting

### Error: "token not found"

**Problem:** Hetzner token not configured

**Solution:**
```bash
# Verify file exists
ls -l ~/.config/tide/hetzner.env

# If missing, create it:
mkdir -p ~/.config/tide
cat > ~/.config/tide/hetzner.env << 'EOF'
# Hetzner Cloud API Tokens
HETZNER_TIDE_TOKEN=your-token-here
EOF
```

### Error: "hcloud: command not found"

**Problem:** Hetzner CLI not installed

**Solution:**
```bash
# macOS
brew install hcloud

# Linux
wget https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz
tar xzf hcloud-linux-amd64.tar.gz
sudo mv hcloud /usr/local/bin/
```

### Error: "Server creation failed"

**Problem:** Location unavailable or quota exceeded

**Solution:**
```bash
# Check available locations
hcloud datacenter list

# Check server types in location
hcloud server-type list

# Try different location (edit test-hetzner.sh)
LOCATION="ash"  # Ashburn, VA instead of Hillsboro, OR
```

### Test shows "Tor not working"

**Problem:** Tor still bootstrapping (needs more time)

**Solution:**
- Tor can take 1-3 minutes to fully bootstrap
- Script waits 30 seconds (usually sufficient)
- If fails, keep server and SSH in to check:
  ```bash
  journalctl -u tor -f
  ```

### Server won't destroy

**Problem:** Server in locked state

**Solution:**
```bash
# Force delete
hcloud server delete <SERVER_NAME> --force

# Or delete all Tide test servers
hcloud server list | grep tide-test | awk '{print $2}' | xargs -I {} hcloud server delete {} --force
```

---

## Cost Tracking

### Monthly Budget

**Recommended budget:** $5/month for testing

**Breakdown:**
- Regular testing: ~$0.50/month (2 tests/week)
- Exploratory testing: ~$1.50/month (25 hours/month)
- Buffer: ~$3/month

**Total:** ~$5/month = $60/year

### Set Up Billing Alerts

1. Go to Hetzner Console: https://console.hetzner.cloud/
2. Navigate to "Billing" → "Settings"
3. Set alert threshold: €5 (~$5)
4. Add email notification

**Alert triggers:** When monthly spending exceeds threshold.

### View Costs

**Hetzner Console:**
- Go to "Billing" → "Overview"
- View current month costs
- Export invoices for tax records

**CLI:**
```bash
# Not available in hcloud CLI
# Use web console for billing info
```

---

## Next Steps

### For Testing

1. **Run first test**
   ```bash
   cd ~/Documents/Personal-Projects/tide/testing/cloud
   ./test-hetzner.sh
   ```

2. **Review results**
   - Check test output
   - Verify all 7 tests pass
   - Destroy server (option 1)

3. **Run full orchestration**
   ```bash
   cd ~/Documents/Personal-Projects/tide/testing
   ./orchestrate-tests.sh
   ```

### For Production Migration

1. **Validate reliability**
   - Run tests over 3-6 months
   - Monitor success rate
   - Evaluate performance

2. **Plan Tide Gateway production deployment**
   - Choose CPX21 or CAX11
   - Document production setup
   - Configure WireGuard (v1.3.0+)

3. **Plan Car Flipper migration**
   - Test Car Flipper on CX32
   - Create migration checklist
   - Schedule maintenance window
   - Migrate with minimal downtime

---

## Additional Resources

**Official Docs:**
- Hetzner Cloud: https://docs.hetzner.com/cloud/
- Hetzner CLI: https://github.com/hetznercloud/cli
- Hetzner API: https://docs.hetzner.cloud/

**Tide Gateway Docs:**
- Testing Guide: `testing/GETTING-STARTED.md`
- Orchestration: `testing/ORCHESTRATION.md`
- Platform Comparison: `testing/PLATFORM-COMPARISON.md`

**Support:**
- Hetzner Support: https://console.hetzner.cloud/support
- Tide Gateway Issues: https://github.com/bodegga/tide/issues

---

**Created:** December 10, 2025  
**Version:** 1.0  
**Author:** Anthony Biasi  
**Status:** Active - Hetzner is PRIMARY platform

🌊 **Ride the Tide on Hetzner!**
