# Golden Image Snapshots Created

**Date:** 2025-12-07  
**Status:** ✅ Baseline snapshots ready

---

## What Are Golden Images?

Clean, working base configurations that you can instantly revert to if anything breaks or gets compromised.

---

## Created Snapshots

### Workstation Golden Image
**Snapshot ID:** `{67c48cbb-6915-4a70-a0a5-507e410b88ff}`  
**Name:** `GOLDEN-IMAGE-baseline-20251207`

**Includes:**
- ✅ Debian 12 ARM64 base
- ✅ XFCE desktop environment
- ✅ Network configured (10.152.152.11, isolated to Tor Gateway)
- ✅ Parallels Tools installed
- ✅ Clipboard working (GUI and terminal via xclip)
- ✅ Firefox ESR
- ✅ Basic utilities installed
- ✅ All traffic routes through Tor Gateway

**What's NOT included (install after restoring):**
- OPSEC tools (Tor Browser, IRC clients, crypto tools, etc.)
- Custom configurations
- User data

### Gateway Golden Image
**Snapshot ID:** `{9e012d7c-9ef7-4d17-a0e9-c2e8f61b485a}`  
**Name:** `GOLDEN-IMAGE-baseline-20251207`

**Includes:**
- ✅ Debian 12 ARM64 base
- ✅ Tor daemon configured and running
- ✅ nftables firewall (persistent across reboots)
- ✅ IP forwarding enabled
- ✅ TransPort 9040 and DNSPort 53
- ✅ Dual network interfaces (Shared + Host-Only)
- ✅ All config survives reboots

---

## How to Restore Golden Images

### Option 1: Revert to Snapshot (keeps current VM, rolls back state)

```bash
# Revert Workstation to golden image
prlctl snapshot-list SecuredWorkstation
prlctl snapshot-switch SecuredWorkstation --id {67c48cbb-6915-4a70-a0a5-507e410b88ff}

# Revert Gateway to golden image  
prlctl snapshot-list Tor-Gateway
prlctl snapshot-switch Tor-Gateway --id {9e012d7c-9ef7-4d17-a0e9-c2e8f61b485a}
```

### Option 2: Clone from Snapshot (creates new VM from golden image)

```bash
# Clone a fresh Workstation from golden image
prlctl clone SecuredWorkstation --name "SecuredWorkstation-experimental" \
  --template --dst /Users/abiasi/Parallels/

# Clone a fresh Gateway from golden image
prlctl clone Tor-Gateway --name "Tor-Gateway-experimental" \
  --template --dst /Users/abiasi/Parallels/
```

### Option 3: GUI Method

1. **Parallels Desktop** → Right-click VM → **Manage Snapshots**
2. Select `GOLDEN-IMAGE-baseline-20251207`
3. Click **Go to** (reverts) or **Clone** (creates new VM)

---

## Recommended Workflow

### For Testing/Experimenting

1. **Clone the golden images** to create experimental VMs
2. Install risky tools, test exploits, whatever
3. If compromised or broken → **delete experimental VMs**
4. Clone fresh from golden image again

### For Daily Use

1. **Use the main VMs** (SecuredWorkstation + Tor-Gateway)
2. **Create incremental snapshots** before major changes:
   ```bash
   prlctl snapshot SecuredWorkstation --name "before-installing-X"
   ```
3. If something breaks → **revert to golden image** or recent snapshot
4. Reinstall your tools from the installation script

---

## Snapshot Management Commands

### List all snapshots
```bash
prlctl snapshot-list SecuredWorkstation
prlctl snapshot-list Tor-Gateway
```

### Create new snapshot
```bash
prlctl snapshot SecuredWorkstation --name "before-risky-stuff" \
  --description "About to test exploit code"
```

### Delete old snapshots
```bash
prlctl snapshot-delete SecuredWorkstation --id {snapshot-id}
```

---

## When to Create New Golden Images

**Update the golden image baseline when:**
- ✅ Major Debian security updates applied
- ✅ Parallels Tools updated
- ✅ Core networking/Tor config improved
- ✅ Base system hardening changes

**DON'T update golden image for:**
- ❌ Installing tools (do this per session)
- ❌ User data/configs (keep separate)
- ❌ Experimental changes

**To create new golden image:**
```bash
# After cleaning up VM to desired baseline state
prlctl snapshot SecuredWorkstation --name "GOLDEN-IMAGE-baseline-$(date +%Y%m%d)" \
  --description "Updated baseline with XYZ improvements"

# Delete old golden image snapshots to save space
prlctl snapshot-delete SecuredWorkstation --id {old-snapshot-id}
```

---

## Storage Considerations

**Snapshots take disk space:**
- Each snapshot = delta from current state
- Multiple snapshots = chain of deltas
- Golden images are typically 2-5GB each

**Check snapshot sizes:**
```bash
ls -lh ~/Parallels/SecuredWorkstation.pvm/*.sav
ls -lh ~/Parallels/Tor-Gateway.pvm/*.sav
```

**To save space:**
- Delete old snapshots you don't need
- Only keep golden image + recent snapshots
- Consider exporting VMs as templates instead

---

## Best Practices

### 1. Test Before Golden Image
Don't snapshot until you've verified:
- Tor routing works
- Clipboard works
- Network isolation intact
- No errors on boot

### 2. Document What Changed
When creating snapshots, use descriptive names and descriptions

### 3. Regular Cleanup
Delete old snapshots monthly to avoid bloat

### 4. Backup Golden Images
Copy the entire `.pvm` folder after creating golden image:
```bash
cp -R ~/Parallels/SecuredWorkstation.pvm ~/Backups/
cp -R ~/Parallels/Tor-Gateway.pvm ~/Backups/
```

---

## Next Steps

Now that you have golden images:

1. **Install OPSEC tools** on current VMs (Tor Browser, IRC, crypto tools)
2. **Use them normally**
3. **If compromised or broken** → Revert to golden image
4. **Reinstall tools** from saved scripts

This gives you the best of both worlds:
- Clean baseline to revert to
- Ability to experiment freely
- Quick recovery from mistakes/compromise

---

**Your VMs are now production-ready with safety nets. Go wild.**
