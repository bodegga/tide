#!/bin/bash
# bump-version.sh - Helper script to update version across all files
# Part of Tide Gateway documentation system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Tide Gateway Version Bump Script${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if version provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <new-version>"
    echo ""
    echo "Examples:"
    echo "  $0 1.2.0     # New minor version"
    echo "  $0 1.1.2     # Patch version"
    echo "  $0 2.0.0     # Major version"
    echo ""
    exit 1
fi

NEW_VERSION=$1

# Validate version format (basic check)
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format: $NEW_VERSION"
    echo "Version must be in format: MAJOR.MINOR.PATCH (e.g., 1.2.0)"
    exit 1
fi

print_header

# Get current version
CURRENT_VERSION=$(cat VERSION 2>/dev/null || echo "unknown")
print_info "Current version: $CURRENT_VERSION"
print_info "New version: $NEW_VERSION"
echo ""

# Confirm with user
read -p "Proceed with version bump? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Version bump cancelled"
    exit 0
fi

echo ""
print_info "Updating version references..."
echo ""

# Update VERSION file
echo "$NEW_VERSION" > VERSION
print_success "Updated VERSION file"

# Update README.md badge
if [ -f "README.md" ]; then
    if grep -q "version-.*-green" README.md; then
        sed -i '' "s/version-[0-9.]*-green/version-$NEW_VERSION-green/" README.md
        print_success "Updated README.md badge"
    else
        print_warning "Version badge not found in README.md"
    fi
else
    print_warning "README.md not found"
fi

# Update shell scripts with embedded version
SCRIPTS_UPDATED=0
for script in setup-tide.sh tide-install.sh DEPLOY-TEMPLATE.sh ONE-COMMAND-DEPLOY.sh; do
    if [ -f "$script" ]; then
        if grep -q 'VERSION=' "$script"; then
            sed -i '' "s/VERSION=\"[0-9.]*\"/VERSION=\"$NEW_VERSION\"/" "$script"
            ((SCRIPTS_UPDATED++))
        fi
    fi
done

if [ $SCRIPTS_UPDATED -gt 0 ]; then
    print_success "Updated $SCRIPTS_UPDATED script(s) with embedded version"
else
    print_warning "No scripts found with VERSION variable"
fi

echo ""
print_info "Version bump complete!"
echo ""

# Show what changed
print_info "Changed files:"
git diff --stat 2>/dev/null || print_warning "Not a git repository or git not available"

echo ""
print_info "Next steps:"
echo "  1. Review changes: ${BLUE}git diff${NC}"
echo "  2. Update CHANGELOG.md manually with release notes"
echo "  3. Commit changes: ${BLUE}git add VERSION README.md *.sh && git commit -m \"Bump version to v$NEW_VERSION\"${NC}"
echo "  4. Create tag: ${BLUE}git tag -a v$NEW_VERSION -m \"Release v$NEW_VERSION\"${NC}"
echo "  5. Push: ${BLUE}git push && git push --tags${NC}"
echo "  6. Create GitHub release using .github/release-template.md"
echo ""

print_success "Done!"
