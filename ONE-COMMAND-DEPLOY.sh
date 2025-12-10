#!/bin/bash
# ONE COMMAND TIDE GATEWAY DEPLOYMENT

set -e

VERSION="v1.0.0"
RELEASE_URL="https://github.com/bodegga/tide/releases/download/${VERSION}/Tide-Gateway-Template-${VERSION}.tar.gz"
VM_NAME="Killa-Whale-$(date +%Y%m%d-%H%M%S)"

echo "🌊 TIDE GATEWAY - ONE COMMAND DEPLOYMENT"
echo "=========================================="
echo ""

# Check if template already exists
if prlctl list -a | grep -q "Tide-Gateway-TEMPLATE"; then
    echo "✅ Template already exists, skipping download"
else
    echo "📥 Downloading template (192MB)..."
    curl -L -o /tmp/tide-template.tar.gz "$RELEASE_URL"
    
    echo "📦 Extracting template..."
    tar -xzf /tmp/tide-template.tar.gz -C "$HOME/Parallels/"
    rm /tmp/tide-template.tar.gz
    
    echo "✅ Template installed"
fi

echo ""
echo "🚀 Deploying new instance: $VM_NAME"
prlctl clone Tide-Gateway-TEMPLATE --name "$VM_NAME"
prlctl start "$VM_NAME"

echo ""
echo "========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "VM: $VM_NAME"
echo "Gateway IP: 10.101.101.10"
echo "DHCP: 10.101.101.100-200"
echo ""
echo "Connect devices to host-only network!"
echo ""

