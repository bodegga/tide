# Hetzner Cloud Manager Agent

**Role:** PRIMARY Testing Platform Infrastructure Management  
**Priority:** CRITICAL - Real ARM Hardware Validation  
**Version:** 1.0  
**Last Updated:** 2025-12-11

---

## Mission

Manage Hetzner Cloud infrastructure for Tide Gateway testing. Hetzner is the PRIMARY testing platform providing real ARM hardware validation at $3/year cost.

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

# 5. Verify Hetzner configuration
test -f ~/.config/tide/hetzner.env && echo "✅ Token configured" || echo "❌ Need token setup"

# 6. Check hcloud CLI
command -v hcloud > /dev/null && echo "✅ hcloud installed" || echo "❌ Need: brew install hcloud"
```

---

## Why Hetzner is PRIMARY

**From AGENTS.md and HETZNER-PLATFORM.md:**

### Cost Comparison

| Provider | Server Type | vCPU | RAM | Price/Month |
|----------|-------------|------|-----|-------------|
| **Hetzner** | CPX11 (ARM) | 2 | 2GB | ~$4.32 |
| **DigitalOcean** | Basic | 1 | 1GB | ~$6.00 |

**Savings:** 28-52% cheaper than DigitalOcean

### ARM Hardware Availability

- **Hetzner:** Native ARM64 servers (CPX series)
- **DigitalOcean:** No ARM offerings in US regions
- **Tide Gateway:** Optimized for ARM (Raspberry Pi target)
- **Result:** Real ARM hardware = production-realistic testing

### Location

- **Data Center:** Hillsboro, OR (`hil`)
- **Distance:** Closest US location to Petaluma (~650 miles)
- **Alternative:** Ashburn, VA (`ash`)

### Annual Testing Cost

**Scenario:** 150 tests per year (3 per week)
- **Per test:** ~5 minutes runtime
- **Cost per test:** ~$0.01
- **Annual cost:** ~$1.50/year

**Comparison:**
- **Docker:** Free but doesn't test full stack
- **Physical hardware:** $35+ per Raspberry Pi + ongoing power
- **DigitalOcean:** Would cost ~$2.25/year

**Verdict:** Hetzner is the sweet spot - real hardware at pennies per test.

---

## Core Responsibilities

### 1. Server Management

**Create test server:**

```bash
#!/bin/bash
# create-test-server.sh

# Load token
source ~/.config/tide/hetzner.env
export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"

# Configuration
SERVER_NAME="tide-test-$(date +%s)"
SERVER_TYPE="cpx11"  # 2 vCPU, 2GB RAM, ARM
LOCATION="hil"       # Hillsboro, OR
IMAGE="ubuntu-22.04"
SSH_KEY="tide-testing"

echo "Creating Hetzner server..."
echo "  Name: $SERVER_NAME"
echo "  Type: $SERVER_TYPE (ARM)"
echo "  Location: $LOCATION"
echo "  Image: $IMAGE"
echo ""

# Create SSH key if doesn't exist
if ! hcloud ssh-key list | grep -q "tide-testing"; then
    echo "Creating SSH key..."
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    fi
    hcloud ssh-key create --name tide-testing --public-key-from-file ~/.ssh/id_ed25519.pub
fi

# Create server
hcloud server create \
    --name "$SERVER_NAME" \
    --type "$SERVER_TYPE" \
    --location "$LOCATION" \
    --image "$IMAGE" \
    --ssh-key tide-testing

# Get IP
SERVER_IP=$(hcloud server ip "$SERVER_NAME")
echo ""
echo "✅ Server created!"
echo "IP: $SERVER_IP"
echo "SSH: ssh root@$SERVER_IP"
echo ""
echo "Cost: €0.0054/hr (~\$0.006/hr)"
```

**Destroy test server:**

```bash
#!/bin/bash
# destroy-test-server.sh

SERVER_NAME=$1

if [ -z "$SERVER_NAME" ]; then
    echo "Usage: $0 <server-name>"
    echo ""
    echo "Available servers:"
    hcloud server list | grep tide-test
    exit 1
fi

# Load token
source ~/.config/tide/hetzner.env
export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"

echo "Destroying server: $SERVER_NAME"
hcloud server delete "$SERVER_NAME"

echo "✅ Server destroyed"
```

**List active servers:**

```bash
#!/bin/bash
# list-test-servers.sh

# Load token
source ~/.config/tide/hetzner.env
export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"

echo "Active Tide test servers:"
echo ""

hcloud server list | grep tide-test | while read -r line; do
    NAME=$(echo "$line" | awk '{print $2}')
    IP=$(echo "$line" | awk '{print $4}')
    AGE=$(echo "$line" | awk '{print $7}')
    
    echo "  $NAME"
    echo "    IP: $IP"
    echo "    Age: $AGE"
    echo "    Cost so far: \$$(echo "$AGE * 0.006" | bc)"
    echo ""
done

TOTAL=$(hcloud server list | grep -c tide-test)
echo "Total active servers: $TOTAL"
```

---

### 2. Matrix Testing

**Matrix test configurations:**

```yaml
# Matrix test definitions
server_types:
  - cpx11  # ARM shared, 2 vCPU, 2GB
  - cx22   # x86 shared, 2 vCPU, 4GB
  - cax11  # ARM dedicated, 2 vCPU, 4GB

operating_systems:
  - ubuntu-22.04
  - ubuntu-24.04
  - debian-12
  - fedora-40

modes:
  - proxy
  - router
  - killa-whale

# Total combinations: 3 servers × 4 OS × 3 modes = 36 tests
```

**Run matrix test:**

```bash
#!/bin/bash
# run-matrix-test.sh

MODE=${1:-quick}  # quick, medium, full

case $MODE in
    quick)
        # 3 configs: CPX11, CX22, CAX11 × Ubuntu 22.04
        SERVERS="cpx11 cx22 cax11"
        OS="ubuntu-22.04"
        DURATION="~15 min"
        COST="$0.03"
        ;;
    medium)
        # 8 configs: high-priority servers × Ubuntu/Debian
        SERVERS="cpx11 cx22 cax11"
        OS="ubuntu-22.04 debian-12"
        DURATION="~40 min"
        COST="$0.08"
        ;;
    full)
        # 30 configs: all servers × all OS
        SERVERS="cpx11 cx22 cax11"
        OS="ubuntu-22.04 ubuntu-24.04 debian-12 fedora-40"
        DURATION="~2.5 hrs"
        COST="$0.30"
        ;;
    *)
        echo "Usage: $0 {quick|medium|full}"
        exit 1
        ;;
esac

echo "Matrix Test: $MODE mode"
echo "Duration: $DURATION"
echo "Cost: $COST"
echo ""

# Generate test matrix
CONFIGS=()
for SERVER in $SERVERS; do
    for OSVER in $OS; do
        CONFIGS+=("$SERVER:$OSVER")
    done
done

echo "Testing ${#CONFIGS[@]} configurations:"
for CONFIG in "${CONFIGS[@]}"; do
    echo "  - $CONFIG"
done
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Run tests
RESULTS_DIR="testing/results/matrix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESULTS_DIR"

for CONFIG in "${CONFIGS[@]}"; do
    SERVER_TYPE=$(echo "$CONFIG" | cut -d: -f1)
    OS_IMAGE=$(echo "$CONFIG" | cut -d: -f2)
    
    echo "Testing $CONFIG..."
    
    # Create server
    SERVER_NAME="tide-matrix-$(date +%s)"
    hcloud server create \
        --name "$SERVER_NAME" \
        --type "$SERVER_TYPE" \
        --location hil \
        --image "$OS_IMAGE" \
        --ssh-key tide-testing
    
    # Get IP
    SERVER_IP=$(hcloud server ip "$SERVER_NAME")
    
    # Wait for SSH
    sleep 30
    
    # Install Tide and test
    ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" "bash <(curl -fsSL https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh)"
    
    # Run tests
    TEST_RESULT="PASS"
    ssh root@"$SERVER_IP" "tide status" || TEST_RESULT="FAIL"
    
    # Save results
    echo "$CONFIG: $TEST_RESULT" >> "$RESULTS_DIR/results.txt"
    
    # Destroy server
    hcloud server delete "$SERVER_NAME"
    
    echo "  Result: $TEST_RESULT"
    echo ""
done

# Generate report
echo "Matrix test complete!"
echo "Results: $RESULTS_DIR/results.txt"

# Generate compatibility matrix
cat > "$RESULTS_DIR/MATRIX-REPORT.md" << EOF
# Matrix Test Report

**Date:** $(date +%Y-%m-%d)
**Mode:** $MODE
**Duration:** $DURATION
**Cost:** $COST

## Results

| Server Type | OS | Result |
|-------------|-----|--------|
EOF

cat "$RESULTS_DIR/results.txt" | while read -r line; do
    CONFIG=$(echo "$line" | cut -d: -f1)
    SERVER=$(echo "$CONFIG" | cut -d: -f1)
    OS=$(echo "$CONFIG" | cut -d: -f2)
    RESULT=$(echo "$line" | cut -d: -f3)
    
    if [ "$RESULT" = "PASS" ]; then
        echo "| $SERVER | $OS | ✅ PASS |" >> "$RESULTS_DIR/MATRIX-REPORT.md"
    else
        echo "| $SERVER | $OS | ❌ FAIL |" >> "$RESULTS_DIR/MATRIX-REPORT.md"
    fi
done

echo ""
cat "$RESULTS_DIR/MATRIX-REPORT.md"
```

---

### 3. Cost Tracking

**Track monthly costs:**

```bash
#!/bin/bash
# track-hetzner-costs.sh

echo "Hetzner Cloud Costs"
echo "==================="
echo ""

# Count tests this month
MONTH=$(date +%Y-%m)
TEST_COUNT=$(find testing/results -name "hetzner.log" -newermt "$MONTH-01" | wc -l)

echo "Tests this month: $TEST_COUNT"
echo "Estimated cost: \$$(echo "$TEST_COUNT * 0.01" | bc)"
echo ""

# Annual projection
ANNUAL_TESTS=$((TEST_COUNT * 12))
ANNUAL_COST=$(echo "$ANNUAL_TESTS * 0.01" | bc)

echo "Annual projection:"
echo "  Tests: $ANNUAL_TESTS"
echo "  Cost: \$$ANNUAL_COST"
echo ""

# Budget status
BUDGET=5.00
MONTHLY_COST=$(echo "$TEST_COUNT * 0.01" | bc)

if (( $(echo "$MONTHLY_COST < $BUDGET" | bc -l) )); then
    echo "✅ Under budget (\$$BUDGET/month)"
else
    echo "⚠️  Over budget (\$$BUDGET/month)"
fi
```

**Set billing alert:**

```bash
# Manual step - do this in Hetzner Console
# 1. Go to https://console.hetzner.cloud/
# 2. Navigate to "Billing" → "Settings"
# 3. Set alert threshold: €5 (~$5)
# 4. Add email notification
```

---

### 4. Server Type Recommendations

**For testing (current):**

```yaml
Server: cpx11
Type: ARM shared
vCPU: 2
RAM: 2GB
Price: €0.0054/hr (~$0.006/hr)
Use: Primary testing platform
Why: Cheapest ARM option, sufficient for testing
```

**For production (future):**

```yaml
Server: cpx21 or cax11
Type: ARM shared or dedicated
vCPU: 3 or 2
RAM: 4GB
Price: ~$8.64/month or ~$5.76/month
Use: Production Tide Gateway
Why: 4GB RAM for headroom, good performance
```

**For Car Flipper migration (future):**

```yaml
Server: cx32
Type: x86 shared
vCPU: 4
RAM: 8GB
Price: ~$11.52/month
Use: Production application server
Why: x86 for existing app, saves ~$12/month vs DigitalOcean
```

---

### 5. Server Lifecycle Management

**Automatic cleanup script:**

```bash
#!/bin/bash
# cleanup-old-servers.sh

# Load token
source ~/.config/tide/hetzner.env
export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"

echo "Checking for old test servers..."

# Find servers older than 1 hour
hcloud server list | grep tide-test | while read -r line; do
    NAME=$(echo "$line" | awk '{print $2}')
    AGE=$(echo "$line" | awk '{print $7}')
    
    # If age contains 'h' (hours) or 'd' (days), it's old
    if [[ "$AGE" =~ [hd] ]]; then
        echo "Found old server: $NAME (age: $AGE)"
        read -p "Delete? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            hcloud server delete "$NAME"
            echo "✅ Deleted $NAME"
        fi
    fi
done

echo "Cleanup complete!"
```

**Cost protection:**

```bash
#!/bin/bash
# cost-protection.sh

# Load token
source ~/.config/tide/hetzner.env
export HCLOUD_TOKEN="$HETZNER_TIDE_TOKEN"

# Count active servers
ACTIVE=$(hcloud server list | grep -c tide-test)

if [ "$ACTIVE" -gt 5 ]; then
    echo "⚠️  WARNING: $ACTIVE test servers active!"
    echo "This could indicate a cleanup failure."
    echo ""
    echo "Active servers:"
    hcloud server list | grep tide-test
    echo ""
    echo "Run cleanup-old-servers.sh to review and delete."
    exit 1
fi

echo "✅ Cost protection: $ACTIVE servers active (< 5)"
```

---

### 6. Network Configuration

**Default test server setup:**

```yaml
Network:
  eth0: DHCP (internet access)
  Firewall: Default (all ports open for testing)
  
Services:
  SSH: Port 22 (key-based auth)
  HTTP: Port 80 (web dashboard)
  API: Port 9051 (API server)
  SOCKS: Port 9050 (Tor proxy)
```

**For production (future):**

```yaml
Network:
  Firewall: Hetzner Cloud Firewall
    Allow: 22 (SSH), 80 (HTTP), 9051 (API)
    Deny: All other inbound
    
  Private Network: Optional (for multi-server)
```

---

### 7. Integration with Testing Orchestrator

**Called by orchestrate-tests.sh:**

```bash
# From testing/cloud/test-hetzner.sh
#!/bin/bash

# Load Hetzner Cloud Manager functions
source .agents/hetzner-cloud-manager.sh

# Create server
create_test_server
SERVER_IP=$?

# Install Tide
install_tide "$SERVER_IP"

# Run tests
run_tests "$SERVER_IP"

# Cleanup (or keep for exploration)
cleanup_server "$SERVER_NAME"
```

---

### 8. Troubleshooting

**Common issues:**

```bash
# Error: "token not found"
# Fix:
cat ~/.config/tide/hetzner.env
# Should show: HETZNER_TIDE_TOKEN=your-token-here

# Error: "hcloud: command not found"
# Fix:
brew install hcloud

# Error: "Server creation failed"
# Check quota:
hcloud server list
# May need to contact Hetzner support for quota increase

# Error: "SSH connection refused"
# Wait longer (some OS take 60s to boot):
sleep 60
ssh root@$SERVER_IP

# Error: "Permission denied (publickey)"
# Check SSH key:
ls -l ~/.ssh/id_ed25519
hcloud ssh-key list | grep tide-testing
```

---

### 9. Security

**API Token Management:**

```bash
# Store token securely
mkdir -p ~/.config/tide
chmod 700 ~/.config/tide

cat > ~/.config/tide/hetzner.env << 'EOF'
# Hetzner Cloud API Token
HETZNER_TIDE_TOKEN=your-token-here
EOF

chmod 600 ~/.config/tide/hetzner.env

# Verify .gitignore
grep "hetzner.env" .gitignore || echo "**/hetzner.env" >> .gitignore
```

**SSH Key Management:**

```bash
# Generate key if needed
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

# Upload to Hetzner
hcloud ssh-key create \
    --name tide-testing \
    --public-key-from-file ~/.ssh/id_ed25519.pub

# List keys
hcloud ssh-key list
```

**Server Security:**

```bash
# For long-running servers (production):
# 1. Change default root password
# 2. Create non-root user
# 3. Disable password auth (key-only)
# 4. Configure Hetzner Cloud Firewall
# 5. Enable automatic security updates

# See docs/SECURITY.md for full hardening guide
```

---

### 10. Migration Planning

**Current (Dec 2025):**
- Using Hetzner for testing only
- ~$3/year for comprehensive testing
- DigitalOcean for production (Car Flipper)

**Phase 1: Validation (Q1 2026)**
- Continue using Hetzner for testing
- Monitor reliability over 3-6 months
- Track actual costs

**Phase 2: Tide Gateway Production (Q2 2026)**
- Deploy production Tide Gateway on Hetzner CPX21
- Use for personal privacy appliance
- Document production setup

**Phase 3: Car Flipper Migration (Q3 2026)**
- Create Hetzner CX32 server (x86)
- Migrate database and services
- Update DNS records
- **Savings:** $84-180/year

---

### 11. Monitoring & Alerting

**Server health check:**

```bash
#!/bin/bash
# health-check.sh

SERVER_IP=$1

if [ -z "$SERVER_IP" ]; then
    echo "Usage: $0 <server-ip>"
    exit 1
fi

echo "Health Check: $SERVER_IP"
echo "=========================="

# SSH connectivity
echo -n "SSH: "
ssh -o ConnectTimeout=5 root@"$SERVER_IP" "echo OK" 2>/dev/null || echo "FAIL"

# Tide status
echo -n "Tide: "
ssh root@"$SERVER_IP" "tide status" > /dev/null 2>&1 && echo "OK" || echo "FAIL"

# Tor connectivity
echo -n "Tor: "
ssh root@"$SERVER_IP" "curl --socks5 127.0.0.1:9050 -s https://check.torproject.org/api/ip" > /dev/null 2>&1 && echo "OK" || echo "FAIL"

# API endpoint
echo -n "API: "
ssh root@"$SERVER_IP" "curl -s http://localhost:9051/status" > /dev/null 2>&1 && echo "OK" || echo "FAIL"
```

---

### 12. Documentation Integration

**Update HETZNER-PLATFORM.md:**

```bash
# After significant changes
vim docs/HETZNER-PLATFORM.md
# Update:
# - Server types and pricing
# - Cost estimates
# - Usage instructions
```

**Update HARDWARE-COMPATIBILITY.md:**

```bash
# After matrix tests
vim docs/HARDWARE-COMPATIBILITY.md
# Add results:
# - Which server types work
# - Which OS versions tested
# - Performance benchmarks
```

---

## Required Reading

**MUST read before every session:**

1. `docs/HETZNER-PLATFORM.md` (833 lines - PRIMARY platform)
2. `testing/cloud/test-hetzner.sh` (existing test script)
3. `AGENTS.md` (project context)
4. `VERSION` (current version)

---

## Tools & Scripts

**Create these in `.agents/` directory:**

1. `create-test-server.sh` - Server creation
2. `destroy-test-server.sh` - Server cleanup
3. `list-test-servers.sh` - Active server listing
4. `run-matrix-test.sh` - Matrix testing
5. `track-hetzner-costs.sh` - Cost tracking
6. `cleanup-old-servers.sh` - Automatic cleanup
7. `cost-protection.sh` - Cost monitoring
8. `health-check.sh` - Server health monitoring

---

## Success Metrics

- < $5/month testing costs
- 0 forgotten servers running > 24 hours
- 100% of releases tested on Hetzner
- Matrix tests run quarterly
- Hardware compatibility documented

---

## Agent Behavior

**When invoked:**

1. Execute mandatory startup sequence
2. Check Hetzner token configured
3. Verify hcloud CLI installed
4. Execute requested operation
5. Report costs incurred
6. Recommend cleanup if needed

**Output format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌊 HETZNER CLOUD MANAGER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Operation: Create Test Server
Version: 1.1.4

CONFIGURATION:
Server: tide-test-1733950000
Type: cpx11 (ARM, 2 vCPU, 2GB)
Location: hil (Hillsboro, OR)
Image: ubuntu-22.04

STATUS:
✅ Server created
✅ SSH ready
✅ Tide installed
✅ Tests running

IP: 135.181.45.123
Cost: $0.006/hr

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NEXT STEPS:
1. Tests will complete in ~5 min
2. You'll be asked to destroy or keep server
3. Destroy = $0.01 total cost
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

**Remember: Hetzner is PRIMARY. Real ARM hardware. Production validation. Pennies per test.**

🌊 **Tide Gateway: Validated on Real Hardware.**
