#!/bin/bash
# Package Tide Gateway template for release

set -e

TEMPLATE_PATH="$HOME/Parallels/Tide-Gateway-TEMPLATE.pvm"
OUTPUT_DIR="$(pwd)/releases"
VERSION="v1.1.1"

echo "🌊 Packaging Tide Gateway Template"
echo "===================================="
echo ""

if [ ! -d "$TEMPLATE_PATH" ]; then
    echo "❌ Template not found: $TEMPLATE_PATH"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Compressing template..."
cd "$HOME/Parallels"
tar -czf "$OUTPUT_DIR/Tide-Gateway-Template-${VERSION}.tar.gz" Tide-Gateway-TEMPLATE.pvm

SIZE=$(du -h "$OUTPUT_DIR/Tide-Gateway-Template-${VERSION}.tar.gz" | awk '{print $1}')

echo ""
echo "========================================="
echo "✅ PACKAGE CREATED!"
echo "========================================="
echo ""
echo "File: $OUTPUT_DIR/Tide-Gateway-Template-${VERSION}.tar.gz"
echo "Size: $SIZE"
echo ""
echo "Upload to GitHub:"
echo "  gh release create $VERSION $OUTPUT_DIR/Tide-Gateway-Template-${VERSION}.tar.gz"
echo ""
echo "Or manually upload at:"
echo "  https://github.com/bodegga/tide/releases/new"
echo ""

