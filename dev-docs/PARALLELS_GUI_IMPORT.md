# Import Alpine Disk into Parallels (GUI Method)

## Files Ready:
- alpine-stream.vmdk (75MB - Alpine Linux boot disk)
- cloud-init.iso (auto-configuration)

## Steps:

### 1. Import VMDK via GUI
1. Open Parallels Desktop (already opening...)
2. File → New...
3. Select "Install Windows or another OS from a DVD or image file"
4. Click "Continue"
5. Click "select a file..." 
6. Navigate to: /Users/abiasi/Documents/Personal-Projects/opsec-vm
7. Select: **alpine-stream.vmdk**
8. Click "Continue"
9. If prompted about OS: Select "Other Linux"
10. Name: "Tide-Gateway"
11. Click "Create"

### 2. Configure Before First Boot
1. Right-click VM → Configure
2. Hardware tab:
   - CPU: 1 core
   - Memory: 512 MB
   - Boot Order → Options → Select "EFI 64-bit"
3. Add CD/DVD:
   - Click "+" → CD/DVD
   - Source: Image file
   - Browse: /Users/abiasi/Documents/Personal-Projects/opsec-vm/cloud-init.iso
4. Add Network Adapter:
   - Click "+" → Network
   - Source: Host-Only Network
5. Click "OK"

### 3. Start and Wait
1. Start the VM
2. Cloud-init will auto-configure (2-3 min)
3. Watch for packages installing, Tor starting
4. Look for "Tide Gateway is ready!"

### 4. Test
```bash
ssh alpine@10.101.101.10
# Password: tide
```

Ready to try this?
