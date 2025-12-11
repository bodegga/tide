#!/bin/bash
# Fix Tide Gateway version tags
# Removes orphaned tags from deleted releases

set -e

echo "🌊 Tide Gateway - Version Cleanup"
echo ""
echo "Current state:"
echo "  Git tags: v1.0.0, v1.1.0, v1.1.1, v1.2.0, v2.0.0"
echo "  GitHub releases: v1.1.0, v1.1.1"
echo "  VERSION file: 1.1.1"
echo ""
echo "Orphaned tags to remove:"
echo "  - v1.0.0 (deleted release from Dec 7)"
echo "  - v1.2.0 (deleted Docker release from Dec 9)"
echo "  - v2.0.0 (mistake - same commit as v1.1.1)"
echo ""
echo "Tags to keep:"
echo "  - v1.1.0 (released on GitHub)"
echo "  - v1.1.1 (released on GitHub, current version)"
echo ""

read -p "Delete orphaned tags? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Deleting local tags..."
git tag -d v1.0.0
git tag -d v1.2.0
git tag -d v2.0.0

echo ""
echo "Deleting remote tags..."
git push origin :refs/tags/v1.0.0
git push origin :refs/tags/v1.2.0
git push origin :refs/tags/v2.0.0

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Remaining tags:"
git tag -l | sort -V

echo ""
echo "This matches GitHub releases and CHANGELOG."
echo ""
echo "Next steps:"
echo "  1. VERSION file is 1.1.1 ✓"
echo "  2. When ready to release web dashboard features, bump to v1.2.0"
echo "  3. Run: echo '1.2.0' > VERSION && git tag v1.2.0"
