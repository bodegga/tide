#!/bin/bash
# Build script for Tide Client Windows
# ======================================
# Creates a standalone Windows .exe with PyInstaller
# Run this in WSL2 or on a Windows machine with bash

set -e

echo "🌊 Building Tide Client for Windows..."

cd "$(dirname "$0")"

# Check Python
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo "❌ Python not found"
    exit 1
fi

PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
fi

# Check/install dependencies
echo "📦 Installing dependencies..."
$PYTHON_CMD -m pip install -q -r requirements.txt || {
    echo "❌ Failed to install dependencies"
    exit 1
}

# Build directory
BUILD_DIR="build/windows"
mkdir -p "$BUILD_DIR"

# Build with PyInstaller
echo "📦 Building executable with PyInstaller..."
$PYTHON_CMD -m PyInstaller \
    --name TideClient \
    --onefile \
    --windowed \
    --clean \
    --distpath "$BUILD_DIR/dist" \
    --workpath "$BUILD_DIR/build" \
    --specpath "$BUILD_DIR" \
    --hidden-import PyQt6 \
    --hidden-import PyQt6.QtCore \
    --hidden-import PyQt6.QtGui \
    --hidden-import PyQt6.QtWidgets \
    --add-data "shared:shared" \
    windows/tide-client-qt.py

if [ -f "$BUILD_DIR/dist/TideClient.exe" ]; then
    echo "✅ Build complete!"
    echo "📦 Executable: $BUILD_DIR/dist/TideClient.exe"
    echo ""
    echo "To run:"
    echo "  $BUILD_DIR/dist/TideClient.exe"
    echo ""
    
    # Optional: Create installer with NSIS
    if command -v makensis &> /dev/null; then
        echo "📦 Creating NSIS installer..."
        
        NSI_FILE="$BUILD_DIR/installer.nsi"
        cat > "$NSI_FILE" << 'EOF'
; Tide Client Windows Installer
!include "MUI2.nsh"

Name "Tide Client"
OutFile "TideClient-Setup.exe"
InstallDir "$PROGRAMFILES\Tide Client"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "Install"
    SetOutPath "$INSTDIR"
    File "dist\TideClient.exe"
    
    CreateDirectory "$SMPROGRAMS\Tide Client"
    CreateShortCut "$SMPROGRAMS\Tide Client\Tide Client.lnk" "$INSTDIR\TideClient.exe"
    CreateShortCut "$DESKTOP\Tide Client.lnk" "$INSTDIR\TideClient.exe"
    
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    CreateShortCut "$SMPROGRAMS\Tide Client\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\TideClient.exe"
    Delete "$INSTDIR\Uninstall.exe"
    Delete "$SMPROGRAMS\Tide Client\Tide Client.lnk"
    Delete "$SMPROGRAMS\Tide Client\Uninstall.lnk"
    Delete "$DESKTOP\Tide Client.lnk"
    RMDir "$SMPROGRAMS\Tide Client"
    RMDir "$INSTDIR"
SectionEnd
EOF
        
        cd "$BUILD_DIR"
        makensis installer.nsi
        cd - > /dev/null
        
        if [ -f "$BUILD_DIR/TideClient-Setup.exe" ]; then
            echo "✅ Installer created: $BUILD_DIR/TideClient-Setup.exe"
        fi
    else
        echo "ℹ️  Install NSIS for installer packaging"
        echo "   Windows: Download from https://nsis.sourceforge.io/"
        echo "   Linux: sudo apt install nsis"
    fi
else
    echo "❌ Build failed"
    exit 1
fi
