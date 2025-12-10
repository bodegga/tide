#!/bin/bash
# Deploy Tide Gateway from template (instant deployment)

TEMPLATE="Tide-Gateway-TEMPLATE"
NEW_NAME="Killa-Whale-$(date +%Y%m%d-%H%M%S)"

echo "🌊 Deploying Tide Gateway from template..."
echo "Template: $TEMPLATE"
echo "New VM: $NEW_NAME"
echo ""

if ! prlctl list -a | grep -q "$TEMPLATE"; then
    echo "❌ Template not found: $TEMPLATE"
    echo "Run ./deploy-vm.sh first to create the template"
    exit 1
fi

prlctl clone "$TEMPLATE" --name "$NEW_NAME"
prlctl start "$NEW_NAME"

echo ""
echo "========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "VM Name: $NEW_NAME"
echo "Gateway IP: 10.101.101.10"
echo "DHCP Range: 10.101.101.100-200"
echo ""
echo "Connect devices to the host-only network"
echo "and they'll automatically route through Tor!"
echo ""

