#!/bin/bash
# Tide Gateway - Automated Testing Orchestration
# Manages parallel testing across all platforms and aggregates results
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
TIDE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
TESTING_DIR="$TIDE_ROOT/testing"
RESULTS_DIR="$TESTING_DIR/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SESSION_DIR="$RESULTS_DIR/$TIMESTAMP"

# Create results directories
mkdir -p "$SESSION_DIR"
mkdir -p "$SESSION_DIR/logs"

# Platforms to test
PLATFORMS=("docker" "hetzner")

# Display banner
banner() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌊 TIDE GATEWAY - TEST ORCHESTRATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${CYAN}Session:${NC} $TIMESTAMP"
    echo -e "${CYAN}Results:${NC} $SESSION_DIR"
    echo ""
}

# Function: Get value from status file
get_status() {
    local platform=$1
    cat "$SESSION_DIR/.${platform}.status" 2>/dev/null || echo "UNKNOWN"
}

# Function: Set value in status file
set_status() {
    local platform=$1
    local status=$2
    echo "$status" > "$SESSION_DIR/.${platform}.status"
}

# Function: Get duration
get_duration() {
    local platform=$1
    cat "$SESSION_DIR/.${platform}.duration" 2>/dev/null || echo "0"
}

# Function: Set duration
set_duration() {
    local platform=$1
    local duration=$2
    echo "$duration" > "$SESSION_DIR/.${platform}.duration"
}

# Function: Run test on specific platform
run_test() {
    local platform=$1
    local log_file="$SESSION_DIR/logs/${platform}.log"
    
    echo -e "${YELLOW}[START]${NC} Testing on ${CYAN}${platform}${NC}..."
    
    local start_time=$(date +%s)
    
    case "$platform" in
        docker)
            "$TESTING_DIR/containers/test-docker.sh" > "$log_file" 2>&1
            ;;
        hetzner)
            echo "1" | "$TESTING_DIR/cloud/test-hetzner.sh" > "$log_file" 2>&1
            ;;
        qemu)
            "$TESTING_DIR/hypervisors/test-qemu.sh" > "$log_file" 2>&1
            ;;
        virtualbox)
            "$TESTING_DIR/hypervisors/test-virtualbox.sh" > "$log_file" 2>&1
            ;;
        *)
            echo "Unknown platform: $platform" > "$log_file"
            return 1
            ;;
    esac
    
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    set_duration "$platform" "$duration"
    
    if [ $exit_code -eq 0 ]; then
        set_status "$platform" "PASS"
        echo -e "${GREEN}[PASS]${NC} ${platform} (${duration}s)"
    else
        set_status "$platform" "FAIL"
        echo -e "${RED}[FAIL]${NC} ${platform} (${duration}s)"
    fi
    
    return $exit_code
}

# Function: Run tests in parallel
run_parallel_tests() {
    echo -e "${CYAN}Starting parallel test execution...${NC}"
    echo ""
    
    local pids=""
    
    for platform in "${PLATFORMS[@]}"; do
        run_test "$platform" &
        pids="$pids $!"
    done
    
    # Wait for all tests to complete
    local all_passed=0
    for pid in $pids; do
        wait $pid || all_passed=1
    done
    
    return $all_passed
}

# Function: Parse test results from log
parse_test_results() {
    local platform=$1
    local log_file="$SESSION_DIR/logs/${platform}.log"
    local results_file="$SESSION_DIR/${platform}-results.json"
    
    # Extract test results
    local passed_tests=$(grep -c "✓" "$log_file" 2>/dev/null || echo 0)
    local failed_tests=$(grep -c "✗" "$log_file" 2>/dev/null || echo 0)
    local total_tests=$((passed_tests + failed_tests))
    local status=$(get_status "$platform")
    local duration=$(get_duration "$platform")
    
    # Create JSON result
    cat > "$results_file" << EOF
{
  "platform": "$platform",
  "timestamp": "$TIMESTAMP",
  "status": "$status",
  "duration_seconds": $duration,
  "tests": {
    "total": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests
  }
}
EOF
}

# Function: Generate summary report
generate_summary() {
    local summary_file="$SESSION_DIR/SUMMARY.md"
    
    cat > "$summary_file" << EOF
# Tide Gateway Test Results - $TIMESTAMP

**Test Session:** $TIMESTAMP  
**Test Directory:** \`$SESSION_DIR\`

---

## Platform Results

EOF

    # Add results for each platform
    for platform in "${PLATFORMS[@]}"; do
        local status=$(get_status "$platform")
        local duration=$(get_duration "$platform")
        
        local status_icon="❓"
        if [ "$status" = "PASS" ]; then
            status_icon="✅"
        elif [ "$status" = "FAIL" ]; then
            status_icon="❌"
        fi
        
        cat >> "$summary_file" << EOF
### $status_icon $platform

- **Status:** $status
- **Duration:** ${duration}s
- **Log:** \`logs/${platform}.log\`

EOF

        # Parse and add detailed results if JSON exists
        if [ -f "$SESSION_DIR/${platform}-results.json" ]; then
            # Use grep instead of jq for bash 3.2 compatibility
            local total=$(grep '"total"' "$SESSION_DIR/${platform}-results.json" | grep -o '[0-9]*' | head -1 || echo "0")
            local passed=$(grep '"passed"' "$SESSION_DIR/${platform}-results.json" | grep -o '[0-9]*' | head -1 || echo "0")
            local failed=$(grep '"failed"' "$SESSION_DIR/${platform}-results.json" | grep -o '[0-9]*' | tail -1 || echo "0")
            
            cat >> "$summary_file" << EOF
**Test Results:**
- Total: $total
- Passed: $passed
- Failed: $failed

EOF
        fi
        
        echo "" >> "$summary_file"
    done
    
    # Add log excerpts
    cat >> "$summary_file" << EOF

---

## Log Excerpts

EOF

    for platform in "${PLATFORMS[@]}"; do
        local log_file="$SESSION_DIR/logs/${platform}.log"
        
        if [ -f "$log_file" ]; then
            cat >> "$summary_file" << EOF
### $platform

\`\`\`
$(tail -n 30 "$log_file")
\`\`\`

EOF
        fi
    done
    
    # Add footer
    cat >> "$summary_file" << EOF

---

**Generated:** $(date)  
**Tide Version:** $(cat "$TIDE_ROOT/VERSION" 2>/dev/null || echo "unknown")
EOF

    echo "$summary_file"
}

# Function: Display summary to console
display_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}TEST SUMMARY${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local total_passed=0
    local total_failed=0
    
    for platform in "${PLATFORMS[@]}"; do
        local status=$(get_status "$platform")
        local duration=$(get_duration "$platform")
        
        if [ "$status" = "PASS" ]; then
            echo -e "${GREEN}✅ ${platform}${NC} - ${duration}s"
            ((total_passed++))
        elif [ "$status" = "FAIL" ]; then
            echo -e "${RED}❌ ${platform}${NC} - ${duration}s"
            ((total_failed++))
        else
            echo -e "${YELLOW}❓ ${platform}${NC} - ${duration}s"
        fi
    done
    
    echo ""
    echo -e "${CYAN}Overall:${NC} $total_passed passed, $total_failed failed"
    echo ""
    echo -e "${CYAN}Results saved to:${NC}"
    echo "  $SESSION_DIR"
    echo ""
    
    # Generate and parse individual platform results
    for platform in "${PLATFORMS[@]}"; do
        parse_test_results "$platform"
    done
    
    # Generate markdown summary
    local summary_file=$(generate_summary)
    echo -e "${CYAN}Summary report:${NC}"
    echo "  $summary_file"
    echo ""
    
    # Cleanup temp status files
    rm -f "$SESSION_DIR"/.*.status "$SESSION_DIR"/.*.duration
    
    if [ $total_failed -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}⚠️  Some tests failed. Check logs for details.${NC}"
        return 1
    fi
}

# Function: Show latest results
show_latest() {
    local latest=$(ls -t "$RESULTS_DIR" | grep -E '^[0-9]{8}-[0-9]{6}$' | head -1)
    
    if [ -z "$latest" ]; then
        echo "No test results found."
        return 1
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 LATEST TEST RESULTS - $latest"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ -f "$RESULTS_DIR/$latest/SUMMARY.md" ]; then
        cat "$RESULTS_DIR/$latest/SUMMARY.md"
    else
        echo "Summary not found for session: $latest"
    fi
}

# Function: List all test sessions
list_sessions() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📜 TEST SESSION HISTORY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local sessions=$(ls -t "$RESULTS_DIR" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$')
    
    if [ -z "$sessions" ]; then
        echo "No test sessions found."
        return
    fi
    
    echo "Session                | Status"
    echo "-----------------------|------------------"
    
    for session in $sessions; do
        local status="Unknown"
        
        # Check if SUMMARY.md exists and parse status
        if [ -f "$RESULTS_DIR/$session/SUMMARY.md" ]; then
            if grep -q "❌" "$RESULTS_DIR/$session/SUMMARY.md"; then
                status="${RED}FAIL${NC}"
            elif grep -q "✅" "$RESULTS_DIR/$session/SUMMARY.md"; then
                status="${GREEN}PASS${NC}"
            fi
        fi
        
        echo -e "$session | $status"
    done
    
    echo ""
    echo "View details: ./orchestrate-tests.sh show <session>"
}

# Function: Show specific session
show_session() {
    local session=$1
    
    if [ ! -d "$RESULTS_DIR/$session" ]; then
        echo "Session not found: $session"
        return 1
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 TEST SESSION - $session"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ -f "$RESULTS_DIR/$session/SUMMARY.md" ]; then
        cat "$RESULTS_DIR/$session/SUMMARY.md"
    else
        echo "Summary not found for session: $session"
    fi
}

# Function: Clean old results (keep last N)
clean_results() {
    local keep=${1:-10}  # Default: keep last 10 sessions
    
    local sessions=$(ls -t "$RESULTS_DIR" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$')
    local count=$(echo "$sessions" | wc -l | tr -d ' ')
    
    if [ $count -le $keep ]; then
        echo "Only $count sessions exist. Nothing to clean."
        return
    fi
    
    local to_delete=$(echo "$sessions" | tail -n +$((keep + 1)))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗑️  CLEANING OLD TEST RESULTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Keeping last $keep sessions, deleting $((count - keep)) old sessions:"
    echo ""
    
    for session in $to_delete; do
        echo "  - $session"
        rm -rf "$RESULTS_DIR/$session"
    done
    
    echo ""
    echo "✅ Cleanup complete"
}

# Main execution
case "${1:-run}" in
    run)
        banner
        run_parallel_tests
        display_summary
        ;;
    latest)
        show_latest
        ;;
    list)
        list_sessions
        ;;
    show)
        show_session "$2"
        ;;
    clean)
        clean_results "$2"
        ;;
    *)
        echo "Tide Gateway Test Orchestration"
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  run              Run all tests in parallel (default)"
        echo "  latest           Show latest test results"
        echo "  list             List all test sessions"
        echo "  show <session>   Show specific session results"
        echo "  clean [N]        Keep last N sessions, delete older (default: 10)"
        echo ""
        echo "Examples:"
        echo "  $0                    # Run tests"
        echo "  $0 latest             # Show latest results"
        echo "  $0 list               # List all sessions"
        echo "  $0 show 20241210-153045"
        echo "  $0 clean 5            # Keep only last 5 sessions"
        ;;
esac
