#!/bin/bash
# Build script for Tide Client Linux
# ====================================
# Creates a standalone Linux executable with PyInstaller

set -e

echo "🌊 Building Tide Client for Linux..."

cd "$(dirname "$0")"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    exit 1
fi

# Check/install dependencies
echo "📦 Installing dependencies..."
python3 -m pip install -q -r requirements.txt || {
    echo "❌ Failed to install dependencies"
    exit 1
}

# Build directory
BUILD_DIR="build/linux"
mkdir -p "$BUILD_DIR"

# Build with PyInstaller
echo "📦 Building executable with PyInstaller..."
python3 -m PyInstaller \
    --name TideClient \
    --onefile \
    --windowed \
    --icon=assets/tide-icon.png 2>/dev/null || \
    --clean \
    --distpath "$BUILD_DIR/dist" \
    --workpath "$BUILD_DIR/build" \
    --specpath "$BUILD_DIR" \
    --hidden-import PyQt6 \
    --hidden-import PyQt6.QtCore \
    --hidden-import PyQt6.QtGui \
    --hidden-import PyQt6.QtWidgets \
    --add-data "shared:shared" \
    linux/tide-client-qt.py

if [ -f "$BUILD_DIR/dist/TideClient" ]; then
    echo "✅ Build complete!"
    echo "📦 Executable: $BUILD_DIR/dist/TideClient"
    echo ""
    echo "To run:"
    echo "  $BUILD_DIR/dist/TideClient"
    echo ""
    echo "To install:"
    echo "  sudo cp $BUILD_DIR/dist/TideClient /usr/local/bin/tide-client"
    echo "  sudo chmod +x /usr/local/bin/tide-client"
    echo ""
    
    # Create .desktop file
    DESKTOP_FILE="$BUILD_DIR/tide-client.desktop"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Tide Client
Comment=Tor Gateway Client
Exec=/usr/local/bin/tide-client
Icon=network-vpn
Terminal=false
Type=Application
Categories=Network;Security;
Keywords=tor;proxy;privacy;
EOF
    
    echo "📝 Desktop file: $DESKTOP_FILE"
    echo "   Install to: ~/.local/share/applications/"
    echo ""
    
    # Optional: Create AppImage
    if command -v appimagetool &> /dev/null; then
        echo "📦 Creating AppImage..."
        
        APPDIR="$BUILD_DIR/TideClient.AppDir"
        mkdir -p "$APPDIR/usr/bin"
        mkdir -p "$APPDIR/usr/share/applications"
        mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
        
        cp "$BUILD_DIR/dist/TideClient" "$APPDIR/usr/bin/"
        cp "$DESKTOP_FILE" "$APPDIR/usr/share/applications/"
        cp "$DESKTOP_FILE" "$APPDIR/"
        
        # Create AppRun
        cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
exec "${HERE}/usr/bin/TideClient" "$@"
APPRUN
        chmod +x "$APPDIR/AppRun"
        
        # Build AppImage
        appimagetool "$APPDIR" "$BUILD_DIR/TideClient.AppImage"
        
        if [ -f "$BUILD_DIR/TideClient.AppImage" ]; then
            echo "✅ AppImage created: $BUILD_DIR/TideClient.AppImage"
        fi
    else
        echo "ℹ️  Install appimagetool for AppImage packaging"
    fi
    
    # Optional: Create .deb package
    if command -v dpkg-deb &> /dev/null; then
        echo "📦 Creating .deb package..."
        
        DEB_DIR="$BUILD_DIR/tide-client_1.2.0_amd64"
        mkdir -p "$DEB_DIR/DEBIAN"
        mkdir -p "$DEB_DIR/usr/local/bin"
        mkdir -p "$DEB_DIR/usr/share/applications"
        
        # Copy files
        cp "$BUILD_DIR/dist/TideClient" "$DEB_DIR/usr/local/bin/tide-client"
        chmod +x "$DEB_DIR/usr/local/bin/tide-client"
        cp "$DESKTOP_FILE" "$DEB_DIR/usr/share/applications/"
        
        # Create control file
        cat > "$DEB_DIR/DEBIAN/control" << CONTROL
Package: tide-client
Version: 1.2.0
Section: net
Priority: optional
Architecture: amd64
Maintainer: Tide Project <tide@bodegga.net>
Description: Tide Gateway Client
 Native client for connecting to Tide Tor gateway.
 Provides system tray integration and one-click proxy configuration.
CONTROL
        
        # Build .deb
        dpkg-deb --build "$DEB_DIR"
        
        if [ -f "$BUILD_DIR/tide-client_1.2.0_amd64.deb" ]; then
            echo "✅ .deb package created: $BUILD_DIR/tide-client_1.2.0_amd64.deb"
            echo ""
            echo "To install:"
            echo "  sudo dpkg -i $BUILD_DIR/tide-client_1.2.0_amd64.deb"
        fi
    fi
else
    echo "❌ Build failed"
    exit 1
fi
