# Quick Build - Do This Now

## 5-Minute Manual Build in UTM

### Step 1: Open UTM and Create VM
```
1. Open UTM app
2. Click "+" → "Virtualize"
3. Select "Linux"
4. Click "Browse" and select: 
   /Users/abiasi/Documents/Personal-Projects/opsec-vm/nocloud_alpine-3.19.6-aarch64-uefi-tiny-r0.qcow2
5. Name: "Tide-Gateway"
```

### Step 2: Configure VM
```
- Memory: 512 MB
- CPU Cores: 1
- Enable "Use UEFI Boot"
- Storage: Keep the qcow2 we selected
```

### Step 3: Add Cloud-Init ISO
```
1. Before starting, go to VM settings
2. Add new drive → CD/DVD
3. Browse and select:
   /Users/abiasi/Documents/Personal-Projects/opsec-vm/cloud-init.iso
4. Save
```

### Step 4: Configure Networks
```
1. In VM settings → Network
2. Adapter 1: Shared Network (already set)
3. Click "New..." → Add Network Adapter
4. Adapter 2: Host Only
5. Save
```

### Step 5: Boot and Wait
```
1. Start the VM
2. Wait 2-3 minutes for cloud-init to run
3. You'll see package installation, Tor setup, etc.
4. Look for "Tide Gateway is ready!" message
```

### Step 6: Test
```bash
# From your Mac terminal:
ssh alpine@10.101.101.10
# Password: tide

# Inside the VM:
rc-service tor status
cat /root/SETUP_COMPLETE
```

### Step 7: Export for Distribution
```
1. Shut down the VM
2. Right-click → Export
3. Save as: tide-gateway-v1.1.0-alpine-arm64.utm
4. OR export individual qcow2 from:
   ~/Library/Containers/com.utmapp.UTM/Data/Documents/Tide-Gateway.utm/Data/
```

## What This Creates:
- ✅ Lightweight Alpine Linux (~150MB)
- ✅ Pre-configured Tor gateway at **10.101.101.10**
- ✅ Supports **multiple client VMs** simultaneously
- ✅ Universal ARM64 format
- ✅ Ready to distribute

## Next: Upload to GitHub
Once exported, upload to GitHub releases as v1.1.0!
