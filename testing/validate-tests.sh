#!/bin/bash
# Tide Gateway - Test Validation Script
# Checks if test scripts match TEST-SPEC.yml

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TESTING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TESTING_DIR/.." && pwd)"
SPEC_FILE="$TESTING_DIR/TEST-SPEC.yml"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Tide Gateway - Test Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if spec file exists
if [ ! -f "$SPEC_FILE" ]; then
    echo -e "${RED}Error: TEST-SPEC.yml not found${NC}"
    exit 1
fi

echo -e "${CYAN}Checking test coverage against specification...${NC}"
echo ""

# Extract version from spec
SPEC_VERSION=$(grep "^version:" "$SPEC_FILE" | cut -d'"' -f2)
echo -e "${CYAN}Spec Version:${NC} $SPEC_VERSION"

# Check VERSION file
PROJECT_VERSION=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n' | tr -d ' ')
echo -e "${CYAN}Project Version:${NC} $PROJECT_VERSION"

if [ "$SPEC_VERSION" != "$PROJECT_VERSION" ]; then
    echo -e "${YELLOW}⚠️  Warning: Spec version ($SPEC_VERSION) != Project version ($PROJECT_VERSION)${NC}"
    echo "   Update TEST-SPEC.yml version to match"
else
    echo -e "${GREEN}✓ Versions match${NC}"
fi
echo ""

# Check test script versions
echo -e "${CYAN}Checking test script versions...${NC}"

DOCKER_TEST="$TESTING_DIR/containers/test-docker.sh"
HETZNER_TEST="$TESTING_DIR/cloud/test-hetzner.sh"

if [ -f "$DOCKER_TEST" ]; then
    DOCKER_VERSION=$(grep "TIDE_VERSION=" "$DOCKER_TEST" | head -1 | cut -d'"' -f2)
    if [ "$DOCKER_VERSION" = "$SPEC_VERSION" ]; then
        echo -e "${GREEN}✓ Docker test version matches: $DOCKER_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker test version ($DOCKER_VERSION) != Spec version ($SPEC_VERSION)${NC}"
    fi
fi

echo ""

# Check core features are tested
echo -e "${CYAN}Checking core feature coverage...${NC}"

# Features that MUST be tested
CORE_FEATURES=(
    "CLI Command"
    "Configuration Files"
    "Tor Service"
    "Tor Connectivity"
)

# Check Docker test
echo ""
echo -e "${CYAN}Docker Test Coverage:${NC}"
for feature in "${CORE_FEATURES[@]}"; do
    case "$feature" in
        "CLI Command")
            if grep -q "tide" "$DOCKER_TEST" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $feature"
            else
                echo -e "  ${RED}✗${NC} $feature - NOT TESTED"
            fi
            ;;
        "Configuration Files")
            if grep -q "/etc/tide" "$DOCKER_TEST" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $feature"
            else
                echo -e "  ${RED}✗${NC} $feature - NOT TESTED"
            fi
            ;;
        "Tor Service")
            if grep -q "tor" "$DOCKER_TEST" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $feature"
            else
                echo -e "  ${RED}✗${NC} $feature - NOT TESTED"
            fi
            ;;
        "Tor Connectivity")
            if grep -q "check.torproject.org" "$DOCKER_TEST" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $feature"
            else
                echo -e "  ${RED}✗${NC} $feature - NOT TESTED"
            fi
            ;;
    esac
done

# Check v1.2.0 features
echo ""
echo -e "${CYAN}v1.2.0 Feature Coverage:${NC}"

V1_2_FEATURES=(
    "API Endpoints"
    "Enhanced CLI"
)

for feature in "${V1_2_FEATURES[@]}"; do
    case "$feature" in
        "API Endpoints")
            if grep -q "9051" "$DOCKER_TEST" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $feature"
            else
                echo -e "  ${RED}✗${NC} $feature - NOT TESTED"
            fi
            ;;
        "Enhanced CLI")
            if grep -q "tide status\|tide check" "$DOCKER_TEST" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $feature"
            else
                echo -e "  ${YELLOW}⚠${NC} $feature - PARTIAL"
            fi
            ;;
    esac
done

# Check CHANGELOG alignment
echo ""
echo -e "${CYAN}Checking CHANGELOG alignment...${NC}"

CHANGELOG="$PROJECT_ROOT/docs/CHANGELOG.md"
if [ -f "$CHANGELOG" ]; then
    # Check if CHANGELOG mentions current version
    if grep -q "\[$PROJECT_VERSION\]" "$CHANGELOG"; then
        echo -e "${GREEN}✓ CHANGELOG has entry for v$PROJECT_VERSION${NC}"
        
        # Extract features from CHANGELOG for current version
        echo ""
        echo -e "${CYAN}Features listed in CHANGELOG v$PROJECT_VERSION:${NC}"
        
        # This is a simple check - looks for "Added" section items
        awk "/\[$PROJECT_VERSION\]/,/^## \[/ {print}" "$CHANGELOG" | \
            grep "^- " | head -5 | \
            sed 's/^/  /'
        
    else
        echo -e "${YELLOW}⚠️  CHANGELOG missing entry for v$PROJECT_VERSION${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  CHANGELOG.md not found${NC}"
fi

# Check for undocumented features in tests
echo ""
echo -e "${CYAN}Checking for undocumented test features...${NC}"

# Features tested but not in spec should be flagged
if grep -q "WebSocket\|bandwidth" "$DOCKER_TEST" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Tests include future features not in current spec${NC}"
else
    echo -e "${GREEN}✓ No future features tested prematurely${NC}"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}VALIDATION SUMMARY${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Simple pass/fail
ISSUES=0

if [ "$SPEC_VERSION" != "$PROJECT_VERSION" ]; then
    echo -e "${YELLOW}⚠️  Version mismatch between spec and project${NC}"
    ((ISSUES++))
fi

if ! grep -q "check.torproject.org" "$DOCKER_TEST" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Core Tor connectivity test missing${NC}"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ All validations passed!${NC}"
    echo ""
    echo "Your tests appear to match the specification."
    echo "Test coverage is appropriate for v$PROJECT_VERSION"
else
    echo -e "${YELLOW}⚠️  Found $ISSUES issue(s)${NC}"
    echo ""
    echo "Review warnings above and update:"
    echo "  - TEST-SPEC.yml if adding/removing features"
    echo "  - Test scripts if spec changed"
    echo "  - VERSION file and CHANGELOG.md for releases"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
