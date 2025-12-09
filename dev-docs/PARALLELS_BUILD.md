# Build Tide Gateway in Parallels - The Easy Way

## Files Ready:
- `alpine.raw` - Alpine Linux bootable disk (168MB)
- `cloud-init.iso` - Auto-configuration ISO
- Gateway IP: **10.101.101.10**

## Step-by-Step in Parallels Desktop GUI:

### 1. Create New VM
```
1. Open Parallels Desktop
2. File → New
3. Choose "Install Windows or another OS from a DVD or image file"
4. Click "Select a file..."
5. Navigate to: /Users/abiasi/Documents/Personal-Projects/tide
6. Select: cloud-init.iso
7. Click "Continue"
8. Uncheck "Express Installation"
9. Select "More Linux" → "Other Linux"
10. Click "Continue"
11. Name: "Tide-Gateway"
12. Click "Create"
```

### 2. Replace Boot Disk BEFORE First Boot
```
1. DON'T start the VM yet!
2. Right-click VM → Configure
3. Go to "Hardware" tab
4. Select "Hard Disk 1"
5. Click the "-" button to remove it
6. Click "+" → Add Device → Hard Disk
7. Source: "Image file..."
8. Browse to: /Users/abiasi/Documents/Personal-Projects/tide/alpine.raw
9. Location: External
10. Apply
11. **IMPORTANT**: Drag the new "Hard Disk" above "CD/DVD"  in boot order
```

### 3. Keep Cloud-Init ISO
```
The cloud-init.iso is already attached as CD/DVD - perfect!
```

### 4. Add Second Network Adapter
```
1. Still in Configure → Hardware
2. Click "+" → Network
3. Source: "Host-Only Network"
4. Click "OK"
```

### 5. Enable EFI Boot
```
1. In Configure → Hardware
2. Click "Boot Order"
3. Click "Advanced..."
4. Select "EFI" as BIOS type
5. Click "OK"
```

### 6. Start and Watch Magic Happen
```
1. Close configuration
2. Start the VM
3. Watch cloud-init auto-configure everything:
   - Install Tor
   - Configure firewall
   - Set up networking on 10.101.101.10
4. Wait for: "Tide Gateway is ready!" (2-3 minutes)
```

### 7. Test It
```bash
# From your Mac:
ssh alpine@10.101.101.10
# Password: tide

# Inside VM:
rc-service tor status
cat /root/SETUP_COMPLETE
```

### 8. Export for Distribution
```
1. Shut down VM
2. File → Export to OVF
3. Save as: tide-gateway-v1.1.0-alpine-arm64.ova
```

## Troubleshooting:
- **Can't boot**: Make sure EFI is enabled and alpine.raw is first in boot order
- **No 10.101.101.10 IP**: Check that second network adapter is Host-Only
- **Cloud-init didn't run**: Make sure cloud-init.iso is attached

## What You Get:
- ✅ 168MB Alpine Linux (vs 3GB Debian!)
- ✅ Auto-configured Tor gateway
- ✅ Supports multiple client VMs
- ✅ Ready to distribute!
