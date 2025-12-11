#!/bin/bash
# Tide Gateway - Matrix Testing System
# Tests all hardware/OS combinations on Hetzner Cloud
# Compatible with Bash 3.2 (macOS default)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TIDE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
TESTING_DIR="$TIDE_ROOT/testing"
CLOUD_DIR="$TESTING_DIR/cloud"
RESULTS_DIR="$TESTING_DIR/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SESSION_DIR="$RESULTS_DIR/matrix-$TIMESTAMP"

# Create session directory
mkdir -p "$SESSION_DIR"
mkdir -p "$SESSION_DIR/logs"

# Test matrix definitions
# Server types: CPX (shared ARM), CX (x86), CAX (dedicated ARM)
declare -a HIGH_PRIORITY_SERVERS=("cpx11" "cx22" "cax11")
declare -a MEDIUM_PRIORITY_SERVERS=("cpx21" "cx32")
declare -a ALL_SERVERS=("cpx11" "cpx21" "cx22" "cx32" "cax11" "cax21")

# OS images
declare -a HIGH_PRIORITY_IMAGES=("ubuntu-22.04" "ubuntu-24.04" "debian-12")
declare -a MEDIUM_PRIORITY_IMAGES=("debian-11" "fedora-40")
declare -a ALL_IMAGES=("ubuntu-22.04" "ubuntu-24.04" "debian-12" "debian-11" "fedora-40")

# Server info functions (Bash 3.2 compatible - no associative arrays)
get_server_cost() {
    case "$1" in
        cpx11) echo "0.0054" ;;
        cpx21) echo "0.0108" ;;
        cx22) echo "0.0072" ;;
        cx32) echo "0.0144" ;;
        cax11) echo "0.0072" ;;
        cax21) echo "0.0144" ;;
        *) echo "0.01" ;;
    esac
}

get_server_specs() {
    case "$1" in
        cpx11) echo "ARM,2vCPU,2GB" ;;
        cpx21) echo "ARM,3vCPU,4GB" ;;
        cx22) echo "x86,2vCPU,4GB" ;;
        cx32) echo "x86,4vCPU,8GB" ;;
        cax11) echo "ARM-Dedicated,2vCPU,4GB" ;;
        cax21) echo "ARM-Dedicated,4vCPU,8GB" ;;
        *) echo "Unknown,?,?" ;;
    esac
}

# Maximum concurrent tests (cost control)
MAX_CONCURRENT=3

# Functions
banner() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌊 TIDE GATEWAY - MATRIX TESTING"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${CYAN}Session:${NC} matrix-$TIMESTAMP"
    echo -e "${CYAN}Results:${NC} $SESSION_DIR"
    echo ""
}

show_usage() {
    cat << EOF
Tide Gateway Matrix Testing

Usage: $0 [mode] [options]

Modes:
  --dry-run     Show what would be tested (no actual tests)
  --quick       Test high-priority configurations (3 tests)
  --medium      Test high + medium priority (8 tests)
  --full        Test all combinations (30 tests)
  --custom      Specify server and images to test

Options:
  --no-confirm  Skip confirmation prompt
  --keep        Keep servers running after tests
  --max N       Maximum concurrent tests (default: 3)

Examples:
  $0 --dry-run              # See test matrix
  $0 --quick                # Fast validation (recommended)
  $0 --full --no-confirm    # Full matrix without prompt
  $0 --custom cpx11 "ubuntu-22.04 ubuntu-24.04"

Matrix Definitions:
  High Priority:  CPX11, CX22, CAX11 × Ubuntu 22.04/24.04, Debian 12
  Medium Priority: CPX21, CX32 × Debian 11, Fedora 40
  Full Matrix:    All server types × All OS images

Cost Estimates:
  --quick:  ~$0.03 (3 tests × $0.01)
  --medium: ~$0.08 (8 tests × $0.01)
  --full:   ~$0.30 (30 tests × $0.01)

EOF
}

# Calculate estimated cost (Bash 3.2 compatible - no bc)
calculate_cost() {
    local servers=("$@")
    local test_count=0
    
    for server in "${servers[@]}"; do
        for image in "${IMAGES[@]}"; do
            test_count=$((test_count + 1))
        done
    done
    
    # Rough estimate: $0.01 per test
    local total_cents=$((test_count * 1))
    local dollars=$((total_cents / 100))
    local cents=$((total_cents % 100))
    
    echo "$test_count tests, ~\$${dollars}.$(printf "%02d" $cents) USD"
}

# Run single matrix test
run_matrix_test() {
    local server=$1
    local image=$2
    local test_name="${server}-${image}"
    local log_file="$SESSION_DIR/logs/${test_name}.log"
    local result_file="$SESSION_DIR/${test_name}.json"
    
    echo -e "${YELLOW}[START]${NC} Testing ${CYAN}${server}${NC} with ${CYAN}${image}${NC}..."
    
    local start_time=$(date +%s)
    
    # Run test-hetzner.sh with parameters
    # Redirect input to auto-destroy (option 1)
    if echo "1" | "$CLOUD_DIR/test-hetzner.sh" "$server" "$image" > "$log_file" 2>&1; then
        local status="PASS"
        local status_icon="${GREEN}✅${NC}"
    else
        local status="FAIL"
        local status_icon="${RED}❌${NC}"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Parse test results
    local passed_tests=$(grep -c "✓" "$log_file" 2>/dev/null || echo 0)
    local failed_tests=$(grep -c "✗" "$log_file" 2>/dev/null || echo 0)
    
    # Create JSON result
    cat > "$result_file" << EOF
{
  "server": "$server",
  "image": "$image",
  "timestamp": "$TIMESTAMP",
  "status": "$status",
  "duration_seconds": $duration,
  "tests": {
    "passed": $passed_tests,
    "failed": $failed_tests
  },
  "specs": "$(get_server_specs "$server")"
}
EOF
    
    echo -e "$status_icon ${server} + ${image} (${duration}s) - ${passed_tests} passed, ${failed_tests} failed"
    
    return $([ "$status" = "PASS" ] && echo 0 || echo 1)
}

# Run tests with concurrency control
run_tests() {
    local servers=("$@")
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local running_jobs=0
    
    echo -e "${CYAN}Starting matrix test execution...${NC}"
    echo -e "${CYAN}Max concurrent: $MAX_CONCURRENT${NC}"
    echo ""
    
    for server in "${servers[@]}"; do
        for image in "${IMAGES[@]}"; do
            # Wait if we've hit max concurrent
            while [ $running_jobs -ge $MAX_CONCURRENT ]; do
                sleep 5
                # Count running background jobs
                running_jobs=$(jobs -r | wc -l | tr -d ' ')
            done
            
            # Start test in background
            run_matrix_test "$server" "$image" &
            running_jobs=$((running_jobs + 1))
            total_tests=$((total_tests + 1))
            
            # Small delay to avoid race conditions
            sleep 1
        done
    done
    
    # Wait for all tests to complete
    echo ""
    echo -e "${CYAN}Waiting for all tests to complete...${NC}"
    wait
    
    # Count results
    for json_file in "$SESSION_DIR"/*.json; do
        if [ -f "$json_file" ]; then
            if grep -q '"status": "PASS"' "$json_file"; then
                passed_tests=$((passed_tests + 1))
            else
                failed_tests=$((failed_tests + 1))
            fi
        fi
    done
    
    echo ""
    echo -e "${CYAN}Matrix tests complete:${NC} $passed_tests passed, $failed_tests failed"
    
    return $([ $failed_tests -eq 0 ] && echo 0 || echo 1)
}

# Generate matrix report
generate_matrix_report() {
    local summary_file="$SESSION_DIR/MATRIX-REPORT.md"
    
    cat > "$summary_file" << 'EOF'
# Tide Gateway - Hardware Compatibility Matrix

**Test Session:** TIMESTAMP_PLACEHOLDER  
**Test Directory:** `SESSION_DIR_PLACEHOLDER`

---

## Test Matrix Results

| Server Type | CPU Arch | vCPUs | RAM | OS | Status | Duration | Passed | Failed | Notes |
|-------------|----------|-------|-----|----|--------|----------|--------|--------|-------|
EOF

    # Add results for each combination
    for json_file in "$SESSION_DIR"/*.json; do
        if [ -f "$json_file" ]; then
            local server=$(grep '"server"' "$json_file" | cut -d'"' -f4)
            local image=$(grep '"image"' "$json_file" | cut -d'"' -f4)
            local status=$(grep '"status"' "$json_file" | cut -d'"' -f4)
            local duration=$(grep '"duration_seconds"' "$json_file" | grep -o '[0-9]*')
            local passed=$(grep '"passed"' "$json_file" | grep -o '[0-9]*' | head -1)
            local failed=$(grep '"failed"' "$json_file" | grep -o '[0-9]*' | tail -1)
            local specs=$(get_server_specs "$server")
            
            # Parse specs
            IFS=',' read -r arch vcpu ram <<< "$specs"
            
            # Status icon
            local status_icon="⏳"
            if [ "$status" = "PASS" ]; then
                status_icon="✅"
            elif [ "$status" = "FAIL" ]; then
                status_icon="❌"
            fi
            
            # Add row
            echo "| $server | $arch | $vcpu | $ram | $image | $status_icon | ${duration}s | $passed | $failed | - |" >> "$summary_file"
        fi
    done
    
    # Add summary section
    cat >> "$summary_file" << 'EOF'

---

## Summary

EOF

    # Count by status
    local total=$(ls "$SESSION_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local passed=$(grep -l '"status": "PASS"' "$SESSION_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local failed=$(grep -l '"status": "FAIL"' "$SESSION_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    
    cat >> "$summary_file" << EOF
- **Total Configurations Tested:** $total
- **Passed:** $passed
- **Failed:** $failed
- **Success Rate:** $(echo "scale=1; $passed * 100 / $total" | bc 2>/dev/null || echo "N/A")%

---

## Recommendations

Based on test results:

1. **Production ARM Deployment:** Use CPX11 or CAX11 with Ubuntu 22.04 or 24.04
2. **Production x86 Deployment:** Use CX22 or CX32 with Ubuntu 22.04
3. **Cost-Optimized:** CPX11 (ARM) is cheapest at €0.0054/hr (~\$4.32/month)
4. **Performance-Optimized:** CAX series for dedicated CPU cores

---

## Cost Analysis

| Server Type | Architecture | Price/Hour | Price/Month | Recommended Use |
|-------------|--------------|------------|-------------|-----------------|
| CPX11 | ARM Shared | €0.0054 | ~\$4.32 | Testing, small apps |
| CPX21 | ARM Shared | €0.0108 | ~\$8.64 | Small production |
| CX22 | x86 Shared | €0.0072 | ~\$5.76 | x86 compatibility |
| CX32 | x86 Shared | €0.0144 | ~\$11.52 | x86 production |
| CAX11 | ARM Dedicated | €0.0072 | ~\$5.76 | Dedicated performance |
| CAX21 | ARM Dedicated | €0.0144 | ~\$11.52 | Heavy workloads |

---

## Log Files

Individual test logs are available in:
\`\`\`
$SESSION_DIR/logs/
\`\`\`

View individual logs:
\`\`\`bash
cat $SESSION_DIR/logs/cpx11-ubuntu-22.04.log
\`\`\`

---

**Generated:** $(date)  
**Tide Version:** $(cat "$TIDE_ROOT/VERSION" 2>/dev/null || echo "unknown")  
**Test Duration:** Total time for all tests
EOF

    # Replace placeholders
    sed -i.bak "s|TIMESTAMP_PLACEHOLDER|$TIMESTAMP|g" "$summary_file" 2>/dev/null || \
        sed -i '' "s|TIMESTAMP_PLACEHOLDER|$TIMESTAMP|g" "$summary_file"
    sed -i.bak "s|SESSION_DIR_PLACEHOLDER|$SESSION_DIR|g" "$summary_file" 2>/dev/null || \
        sed -i '' "s|SESSION_DIR_PLACEHOLDER|$SESSION_DIR|g" "$summary_file"
    rm -f "$summary_file.bak"
    
    echo "$summary_file"
}

# Show dry run
show_dry_run() {
    local servers=("$@")
    
    echo -e "${CYAN}Matrix Test Plan (Dry Run)${NC}"
    echo ""
    echo "Server Types:"
    for server in "${servers[@]}"; do
        local specs=$(get_server_specs "$server")
        local cost=$(get_server_cost "$server")
        echo "  - $server ($specs) @ €${cost}/hr"
    done
    echo ""
    
    echo "OS Images:"
    for image in "${IMAGES[@]}"; do
        echo "  - $image"
    done
    echo ""
    
    echo "Test Combinations:"
    local count=0
    for server in "${servers[@]}"; do
        for image in "${IMAGES[@]}"; do
            count=$((count + 1))
            echo "  $count. $server × $image"
        done
    done
    echo ""
    
    local estimate=$(calculate_cost "${servers[@]}")
    echo -e "${CYAN}Estimate:${NC} $estimate"
    echo ""
}

# Main execution
MODE="${1:---help}"
NO_CONFIRM=false
KEEP_SERVERS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --dry-run)
            MODE="dry-run"
            shift
            ;;
        --quick)
            MODE="quick"
            shift
            ;;
        --medium)
            MODE="medium"
            shift
            ;;
        --full)
            MODE="full"
            shift
            ;;
        --custom)
            MODE="custom"
            CUSTOM_SERVER="$2"
            CUSTOM_IMAGES="$3"
            shift 3
            ;;
        --no-confirm)
            NO_CONFIRM=true
            shift
            ;;
        --keep)
            KEEP_SERVERS=true
            shift
            ;;
        --max)
            MAX_CONCURRENT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Select test matrix based on mode
case "$MODE" in
    quick)
        SERVERS=("${HIGH_PRIORITY_SERVERS[@]}")
        IMAGES=("ubuntu-22.04")  # Just Ubuntu 22.04 for quick test
        ;;
    medium)
        SERVERS=("${HIGH_PRIORITY_SERVERS[@]}" "${MEDIUM_PRIORITY_SERVERS[@]}")
        IMAGES=("${HIGH_PRIORITY_IMAGES[@]}")
        ;;
    full)
        SERVERS=("${ALL_SERVERS[@]}")
        IMAGES=("${ALL_IMAGES[@]}")
        ;;
    custom)
        SERVERS=("$CUSTOM_SERVER")
        IFS=' ' read -ra IMAGES <<< "$CUSTOM_IMAGES"
        ;;
    dry-run)
        banner
        echo -e "${CYAN}Quick Test (--quick):${NC}"
        SERVERS=("${HIGH_PRIORITY_SERVERS[@]}")
        IMAGES=("ubuntu-22.04")
        show_dry_run "${SERVERS[@]}"
        
        echo -e "${CYAN}Medium Test (--medium):${NC}"
        SERVERS=("${HIGH_PRIORITY_SERVERS[@]}" "${MEDIUM_PRIORITY_SERVERS[@]}")
        IMAGES=("${HIGH_PRIORITY_IMAGES[@]}")
        show_dry_run "${SERVERS[@]}"
        
        echo -e "${CYAN}Full Test (--full):${NC}"
        SERVERS=("${ALL_SERVERS[@]}")
        IMAGES=("${ALL_IMAGES[@]}")
        show_dry_run "${SERVERS[@]}"
        exit 0
        ;;
    *)
        show_usage
        exit 0
        ;;
esac

# Show banner and confirmation
banner

echo -e "${CYAN}Test Matrix:${NC}"
echo "  Servers: ${SERVERS[*]}"
echo "  Images: ${IMAGES[*]}"
echo "  Max concurrent: $MAX_CONCURRENT"
echo ""

estimate=$(calculate_cost "${SERVERS[@]}")
echo -e "${CYAN}Estimate:${NC} $estimate"
echo ""

# Confirmation prompt
if [ "$NO_CONFIRM" = false ]; then
    echo -e "${YELLOW}Proceed with matrix testing?${NC}"
    echo -n "Type 'yes' to continue: "
    read -r response
    
    if [ "$response" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi
    echo ""
fi

# Run tests
run_tests "${SERVERS[@]}"
test_result=$?

# Generate report
echo ""
echo -e "${CYAN}Generating matrix report...${NC}"
report_file=$(generate_matrix_report)
echo -e "${GREEN}✓ Report generated:${NC} $report_file"
echo ""

# Display summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}MATRIX TEST SUMMARY${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$report_file"
echo ""

if [ $test_result -eq 0 ]; then
    echo -e "${GREEN}🎉 All matrix tests passed!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Check logs for details.${NC}"
    exit 1
fi
