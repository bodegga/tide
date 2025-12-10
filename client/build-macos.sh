#!/bin/bash
# Build script for Tide Client macOS
# ====================================
# Creates a native macOS .app bundle

set -e

echo "🌊 Building Tide Client for macOS..."

cd "$(dirname "$0")"

# Build directory
BUILD_DIR="build/macos"
APP_NAME="TideClient.app"
APP_DIR="$BUILD_DIR/$APP_NAME"

mkdir -p "$BUILD_DIR"
rm -rf "$APP_DIR"

# Compile Swift binary
echo "📦 Compiling Swift..."
swiftc -o "$BUILD_DIR/TideClient" \
    macos/TideClient/TideClient.swift \
    -framework Cocoa \
    -framework Network \
    -O

# Create app bundle structure
echo "📦 Creating .app bundle..."
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/TideClient" "$APP_DIR/Contents/MacOS/TideClient"
chmod +x "$APP_DIR/Contents/MacOS/TideClient"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>TideClient</string>
    <key>CFBundleIdentifier</key>
    <string>net.bodegga.tide-client</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Tide</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Build complete!"
echo "📦 App bundle: $APP_DIR"
echo ""
echo "To run:"
echo "  open $APP_DIR"
echo ""
echo "To install:"
echo "  cp -r $APP_DIR /Applications/"
echo ""

# Optional: Create DMG
if command -v create-dmg &> /dev/null; then
    echo "📀 Creating DMG installer..."
    create-dmg \
        --volname "Tide Client" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --app-drop-link 450 200 \
        "$BUILD_DIR/TideClient.dmg" \
        "$APP_DIR" 2>/dev/null || true
    
    if [ -f "$BUILD_DIR/TideClient.dmg" ]; then
        echo "✅ DMG created: $BUILD_DIR/TideClient.dmg"
    fi
else
    echo "ℹ️  Install create-dmg for DMG packaging: brew install create-dmg"
fi
