#!/bin/bash
# Tide Gateway - Test Dashboard Generator
# Creates HTML dashboard from test results

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

TIDE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
TESTING_DIR="$TIDE_ROOT/testing"
RESULTS_DIR="$TESTING_DIR/results"
DASHBOARD_FILE="$RESULTS_DIR/dashboard.html"

# Get latest results
LATEST=$(ls -t "$RESULTS_DIR" | grep -E '^[0-9]{8}-[0-9]{6}$' | head -1)

if [ -z "$LATEST" ]; then
    echo "No test results found. Run tests first:"
    echo "  ./orchestrate-tests.sh run"
    exit 1
fi

echo -e "${CYAN}Generating dashboard from session: $LATEST${NC}"

# Generate HTML dashboard
cat > "$DASHBOARD_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tide Gateway - Test Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #0a1929 0%, #1a2942 100%);
            color: #e0e0e0;
            padding: 2rem;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        header {
            text-align: center;
            margin-bottom: 3rem;
        }
        
        h1 {
            font-size: 3rem;
            background: linear-gradient(135deg, #4fc3f7 0%, #29b6f6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 0.5rem;
        }
        
        .subtitle {
            color: #90caf9;
            font-size: 1.2rem;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 3rem;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 12px;
            padding: 1.5rem;
            border: 1px solid rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
        }
        
        .stat-card h3 {
            font-size: 0.9rem;
            color: #90caf9;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 0.5rem;
        }
        
        .stat-card .value {
            font-size: 2.5rem;
            font-weight: bold;
            color: #fff;
        }
        
        .stat-card.success .value {
            color: #66bb6a;
        }
        
        .stat-card.failure .value {
            color: #ef5350;
        }
        
        .platform-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 2rem;
            margin-bottom: 3rem;
        }
        
        .platform-card {
            background: rgba(255, 255, 255, 0.08);
            border-radius: 12px;
            padding: 2rem;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .platform-card.pass {
            border-left: 4px solid #66bb6a;
        }
        
        .platform-card.fail {
            border-left: 4px solid #ef5350;
        }
        
        .platform-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
        }
        
        .platform-name {
            font-size: 1.5rem;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .status-badge {
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: bold;
        }
        
        .status-badge.pass {
            background: rgba(102, 187, 106, 0.2);
            color: #66bb6a;
        }
        
        .status-badge.fail {
            background: rgba(239, 83, 80, 0.2);
            color: #ef5350;
        }
        
        .test-stats {
            display: flex;
            gap: 1.5rem;
            margin-bottom: 1rem;
        }
        
        .test-stat {
            flex: 1;
        }
        
        .test-stat-label {
            font-size: 0.85rem;
            color: #90caf9;
            margin-bottom: 0.25rem;
        }
        
        .test-stat-value {
            font-size: 1.8rem;
            font-weight: bold;
        }
        
        .duration {
            color: #64b5f6;
            font-size: 0.95rem;
        }
        
        .log-preview {
            background: rgba(0, 0, 0, 0.3);
            border-radius: 8px;
            padding: 1rem;
            margin-top: 1rem;
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 0.85rem;
            overflow-x: auto;
            max-height: 200px;
            overflow-y: auto;
        }
        
        .log-preview pre {
            color: #b0bec5;
            line-height: 1.5;
        }
        
        footer {
            text-align: center;
            color: #546e7a;
            margin-top: 3rem;
            padding-top: 2rem;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .refresh-btn {
            position: fixed;
            bottom: 2rem;
            right: 2rem;
            background: linear-gradient(135deg, #4fc3f7 0%, #29b6f6 100%);
            color: white;
            border: none;
            padding: 1rem 2rem;
            border-radius: 50px;
            font-size: 1rem;
            font-weight: bold;
            cursor: pointer;
            box-shadow: 0 4px 20px rgba(79, 195, 247, 0.4);
            transition: all 0.3s ease;
        }
        
        .refresh-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 25px rgba(79, 195, 247, 0.6);
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🌊 TIDE GATEWAY</h1>
            <div class="subtitle">Test Dashboard</div>
        </header>
        
        <div class="stats-grid" id="statsGrid">
            <!-- Stats will be injected here -->
        </div>
        
        <div class="platform-grid" id="platformGrid">
            <!-- Platform cards will be injected here -->
        </div>
        
        <footer>
            <p>Last updated: <span id="lastUpdated"></span></p>
            <p>Tide Gateway Testing Infrastructure v1.0</p>
        </footer>
    </div>
    
    <button class="refresh-btn" onclick="location.reload()">🔄 Refresh</button>
    
    <script>
        // Load test data
        async function loadTestData() {
            try {
                const response = await fetch('test-data.json');
                const data = await response.json();
                renderDashboard(data);
            } catch (error) {
                console.error('Failed to load test data:', error);
            }
        }
        
        function renderDashboard(data) {
            // Render stats
            const statsGrid = document.getElementById('statsGrid');
            statsGrid.innerHTML = `
                <div class="stat-card ${data.overall.failed === 0 ? 'success' : 'failure'}">
                    <h3>Overall Status</h3>
                    <div class="value">${data.overall.failed === 0 ? '✅ PASS' : '❌ FAIL'}</div>
                </div>
                <div class="stat-card success">
                    <h3>Tests Passed</h3>
                    <div class="value">${data.overall.passed}</div>
                </div>
                <div class="stat-card ${data.overall.failed > 0 ? 'failure' : ''}">
                    <h3>Tests Failed</h3>
                    <div class="value">${data.overall.failed}</div>
                </div>
                <div class="stat-card">
                    <h3>Total Duration</h3>
                    <div class="value">${data.overall.total_duration}s</div>
                </div>
            `;
            
            // Render platforms
            const platformGrid = document.getElementById('platformGrid');
            platformGrid.innerHTML = data.platforms.map(platform => `
                <div class="platform-card ${platform.status.toLowerCase()}">
                    <div class="platform-header">
                        <div class="platform-name">${platform.name}</div>
                        <div class="status-badge ${platform.status.toLowerCase()}">${platform.status}</div>
                    </div>
                    
                    <div class="test-stats">
                        <div class="test-stat">
                            <div class="test-stat-label">Passed</div>
                            <div class="test-stat-value" style="color: #66bb6a;">${platform.tests.passed}</div>
                        </div>
                        <div class="test-stat">
                            <div class="test-stat-label">Failed</div>
                            <div class="test-stat-value" style="color: #ef5350;">${platform.tests.failed}</div>
                        </div>
                        <div class="test-stat">
                            <div class="test-stat-label">Total</div>
                            <div class="test-stat-value">${platform.tests.total}</div>
                        </div>
                    </div>
                    
                    <div class="duration">⏱️ Duration: ${platform.duration}s</div>
                    
                    <div class="log-preview">
                        <pre>${platform.log_preview}</pre>
                    </div>
                </div>
            `).join('');
            
            // Update timestamp
            document.getElementById('lastUpdated').textContent = data.timestamp;
        }
        
        // Load data on page load
        loadTestData();
    </script>
</body>
</html>
EOF

# Generate test data JSON
cat > "$RESULTS_DIR/test-data.json" << EOF
{
    "timestamp": "$(date '+%Y-%m-%d %H:%M:%S')",
    "session": "$LATEST",
    "overall": {
        "passed": 0,
        "failed": 0,
        "total_duration": 0
    },
    "platforms": []
}
EOF

# Parse results and build JSON
PLATFORMS=()
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_DURATION=0

for result_file in "$RESULTS_DIR/$LATEST"/*-results.json; do
    if [ -f "$result_file" ]; then
        PLATFORM=$(jq -r '.platform' "$result_file")
        STATUS=$(jq -r '.status' "$result_file")
        DURATION=$(jq -r '.duration_seconds' "$result_file")
        PASSED=$(jq -r '.tests.passed' "$result_file")
        FAILED=$(jq -r '.tests.failed' "$result_file")
        TOTAL=$(jq -r '.tests.total' "$result_file")
        
        # Get log preview
        LOG_FILE="$RESULTS_DIR/$LATEST/logs/${PLATFORM}.log"
        LOG_PREVIEW=$(tail -n 10 "$LOG_FILE" 2>/dev/null | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' || echo "No log available")
        
        # Update totals
        TOTAL_PASSED=$((TOTAL_PASSED + PASSED))
        TOTAL_FAILED=$((TOTAL_FAILED + FAILED))
        TOTAL_DURATION=$((TOTAL_DURATION + DURATION))
        
        # Build platform JSON
        PLATFORMS+=("{\"name\":\"$PLATFORM\",\"status\":\"$STATUS\",\"duration\":$DURATION,\"tests\":{\"passed\":$PASSED,\"failed\":$FAILED,\"total\":$TOTAL},\"log_preview\":\"$LOG_PREVIEW\"}")
    fi
done

# Build final JSON
PLATFORMS_JSON=$(IFS=,; echo "[${PLATFORMS[*]}]")

cat > "$RESULTS_DIR/test-data.json" << EOF
{
    "timestamp": "$(date '+%Y-%m-%d %H:%M:%S')",
    "session": "$LATEST",
    "overall": {
        "passed": $TOTAL_PASSED,
        "failed": $TOTAL_FAILED,
        "total_duration": $TOTAL_DURATION
    },
    "platforms": $PLATFORMS_JSON
}
EOF

echo -e "${GREEN}✅ Dashboard generated${NC}"
echo ""
echo "Open in browser:"
echo "  file://$DASHBOARD_FILE"
echo ""
echo "Or serve locally:"
echo "  cd $RESULTS_DIR && python3 -m http.server 8080"
echo "  Then visit: http://localhost:8080/dashboard.html"
