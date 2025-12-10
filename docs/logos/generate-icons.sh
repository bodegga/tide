#!/bin/bash
# Generate PNG icon assets from Tide wave SVG
# Run from: tide/docs/logos/

set -e

SOURCE_SVG="tide-icon-wave-minimal.svg"
ICON_DIR="../../client/icons"

echo "🌊 Generating Tide icon assets..."

# Create output directory
mkdir -p "$ICON_DIR"

# Standard PNG sizes
echo "📐 Generating standard PNG sizes..."
convert "$SOURCE_SVG" -resize 1024x1024 "$ICON_DIR/tide-icon-1024.png"
convert "$SOURCE_SVG" -resize 512x512 "$ICON_DIR/tide-icon-512.png"
convert "$SOURCE_SVG" -resize 256x256 "$ICON_DIR/tide-icon-256.png"
convert "$SOURCE_SVG" -resize 128x128 "$ICON_DIR/tide-icon-128.png"
convert "$SOURCE_SVG" -resize 64x64 "$ICON_DIR/tide-icon-64.png"
convert "$SOURCE_SVG" -resize 32x32 "$ICON_DIR/tide-icon-32.png"
convert "$SOURCE_SVG" -resize 16x16 "$ICON_DIR/tide-icon-16.png"

# macOS .icns (requires iconutil)
if command -v iconutil &> /dev/null; then
    echo "🍎 Generating macOS .icns..."
    rm -rf tide-icon.iconset
    mkdir -p tide-icon.iconset
    
    convert "$SOURCE_SVG" -resize 16x16 tide-icon.iconset/icon_16x16.png
    convert "$SOURCE_SVG" -resize 32x32 tide-icon.iconset/icon_16x16@2x.png
    convert "$SOURCE_SVG" -resize 32x32 tide-icon.iconset/icon_32x32.png
    convert "$SOURCE_SVG" -resize 64x64 tide-icon.iconset/icon_32x32@2x.png
    convert "$SOURCE_SVG" -resize 128x128 tide-icon.iconset/icon_128x128.png
    convert "$SOURCE_SVG" -resize 256x256 tide-icon.iconset/icon_128x128@2x.png
    convert "$SOURCE_SVG" -resize 256x256 tide-icon.iconset/icon_256x256.png
    convert "$SOURCE_SVG" -resize 512x512 tide-icon.iconset/icon_256x256@2x.png
    convert "$SOURCE_SVG" -resize 512x512 tide-icon.iconset/icon_512x512.png
    convert "$SOURCE_SVG" -resize 1024x1024 tide-icon.iconset/icon_512x512@2x.png
    
    iconutil -c icns tide-icon.iconset -o "$ICON_DIR/tide-icon.icns"
    rm -rf tide-icon.iconset
    echo "✅ Created: $ICON_DIR/tide-icon.icns"
else
    echo "⚠️  iconutil not found (macOS only)"
fi

# Windows .ico (multi-resolution)
echo "🪟 Generating Windows .ico..."
convert "$SOURCE_SVG" -define icon:auto-resize=256,128,64,48,32,16 "$ICON_DIR/tide-icon.ico"

# Linux/System Tray (various sizes)
echo "🐧 Generating Linux system tray icons..."
convert "$SOURCE_SVG" -resize 48x48 "$ICON_DIR/tide-tray-48.png"
convert "$SOURCE_SVG" -resize 32x32 "$ICON_DIR/tide-tray-32.png"
convert "$SOURCE_SVG" -resize 24x24 "$ICON_DIR/tide-tray-24.png"
convert "$SOURCE_SVG" -resize 22x22 "$ICON_DIR/tide-tray-22.png"

echo "✅ Icon generation complete!"
echo ""
echo "📂 Output directory: $ICON_DIR"
ls -lh "$ICON_DIR"
