#!/bin/bash
# Run THIS script INSIDE the Tide VM after Alpine is installed

set -e

echo "🐋 Killa Whale - In-VM Setup Script"
echo "===================================="
echo ""

# Check we're in Alpine
if ! command -v apk &> /dev/null; then
    echo "❌ Error: This must run inside Alpine Linux"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
apk update
apk add git bash curl

# Clone Tide
echo "📥 Cloning Tide repository..."
cd /root
if [ -d "tide" ]; then
    echo "   Tide directory exists, pulling latest..."
    cd tide
    git pull
else
    git clone https://github.com/bodegga/tide.git
    cd tide
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next: Run the Tide installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ./tide-install.sh"
echo ""
echo "  Select: 3) killa-whale"
echo ""
echo "Then start it:"
echo "  rc-service tide-gateway start"
echo ""
echo "🐋🎤 Let's go!"
