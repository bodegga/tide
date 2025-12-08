# OPSEC VM Templates - Clone Guide

**Date:** 2025-12-07  
**Status:** ✅ Templates Ready

---

## 📦 Available Templates

You now have reusable templates that include ALL your apps and configurations:

### 1. Tor-Gateway-TEMPLATE
**Location:** `~/Parallels/Tor-Gateway-TEMPLATE.pvm/`  
**Includes:**
- ✅ Debian 12 ARM64
- ✅ Tor daemon configured (TransPort 9040, DNSPort 53)
- ✅ nftables firewall rules (persistent)
- ✅ Dual network adapters (Shared + Host-Only)
- ✅ IP forwarding enabled
- ✅ All configurations survive reboots

### 2. SecuredWorkstation-TEMPLATE
**Location:** `~/Parallels/SecuredWorkstation-TEMPLATE.pvm/`  
**Includes:**
- ✅ Debian 12 ARM64
- ✅ XFCE desktop environment
- ✅ Parallels Tools installed
- ✅ Tor Browser
- ✅ Firefox ESR
- ✅ All OPSEC tools (KeePassXC, HexChat, Pidgin, GPG, etc.)
- ✅ Text editors (vim, nano, gedit, mousepad)
- ✅ Development tools (git, curl, wget)
- ✅ Office & media apps (LibreOffice, VLC, GIMP)
- ✅ Network isolated to Tor Gateway

---

## 🚀 How to Spin Up Fresh VMs

### Quick Clone (Command Line)

**Clone fresh Gateway:**
```bash
prlctl clone Tor-Gateway-TEMPLATE --name "Tor-Gateway-test" \
  --dst ~/Parallels/
```

**Clone fresh Workstation:**
```bash
prlctl clone SecuredWorkstation-TEMPLATE --name "SecuredWorkstation-test" \
  --dst ~/Parallels/
```

**Start the cloned VMs:**
```bash
prlctl start Tor-Gateway-test
prlctl start SecuredWorkstation-test
```

### GUI Method (Parallels Desktop)

1. **Open Parallels Desktop**
2. **Right-click** on `Tor-Gateway-TEMPLATE` → **Clone**
3. **Name** the new VM (e.g., "Tor-Gateway-experimental")
4. **Choose location:** ~/Parallels/
5. Click **Clone**
6. Repeat for `SecuredWorkstation-TEMPLATE`

---

## 📋 Common Use Cases

### Use Case 1: Testing Risky Tools
```bash
# Clone from templates
prlctl clone Tor-Gateway-TEMPLATE --name "Gateway-test" --dst ~/Parallels/
prlctl clone SecuredWorkstation-TEMPLATE --name "Workstation-test" --dst ~/Parallels/

# Start and use them
prlctl start Gateway-test
prlctl start Workstation-test

# Install risky tools, test exploits, whatever...

# When done, DELETE the test VMs
prlctl stop Workstation-test --kill
prlctl stop Gateway-test --kill
prlctl delete Workstation-test
prlctl delete Gateway-test

# Clone fresh ones next time
```

### Use Case 2: Multiple Isolated Environments
```bash
# Create separate environments for different projects
prlctl clone SecuredWorkstation-TEMPLATE --name "Work-Project-A" --dst ~/Parallels/
prlctl clone SecuredWorkstation-TEMPLATE --name "Work-Project-B" --dst ~/Parallels/

# Each uses the same Gateway, but has isolated workspaces
```

### Use Case 3: Quick Recovery from Compromise
```bash
# If you suspect compromise:
prlctl stop SecuredWorkstation --kill
prlctl delete SecuredWorkstation

# Spin up fresh from template
prlctl clone SecuredWorkstation-TEMPLATE --name "SecuredWorkstation" \
  --dst ~/Parallels/
prlctl start SecuredWorkstation

# Back to clean state in ~2 minutes
```

---

## 🗂 VM Inventory

### Production VMs (Current Working Instances)
| Name | Status | Purpose |
|------|--------|---------|
| **Tor-Gateway** | Original | Your main Gateway (keep this) |
| **SecuredWorkstation** | Original | Your main Workstation (keep this) |

### Template VMs (Master Copies - Don't Modify)
| Name | Status | Purpose |
|------|--------|---------|
| **Tor-Gateway-TEMPLATE** | Template | Clone fresh Gateways from this |
| **SecuredWorkstation-TEMPLATE** | Template | Clone fresh Workstations from this |

---

## ⚙️ Template Management

### View All Templates
```bash
prlctl list -a --template
```

### View All VMs (Including Templates)
```bash
prlctl list -a
```

### Delete a Cloned VM (Not the Template!)
```bash
prlctl stop VM-name --kill
prlctl delete VM-name
```

### Update Templates (When You Add New Apps)

**If you install new apps and want to update the template:**

1. **Install apps on your production VM** (e.g., SecuredWorkstation)
2. **Stop the VM:**
   ```bash
   prlctl stop SecuredWorkstation
   ```
3. **Delete old template:**
   ```bash
   prlctl delete SecuredWorkstation-TEMPLATE
   ```
4. **Create new template:**
   ```bash
   prlctl clone SecuredWorkstation --name "SecuredWorkstation-TEMPLATE" \
     --template --dst ~/Parallels/
   ```
5. **Restart production VM:**
   ```bash
   prlctl start SecuredWorkstation
   ```

---

## 💾 Snapshots vs Templates vs Clones

### Snapshots (What You Already Have)
- **Purpose:** Revert to previous state
- **Use:** Roll back changes within same VM
- **Storage:** Delta files (efficient)
- **Example:** `GOLDEN-IMAGE-baseline-20251207`

### Templates (What We Just Created)
- **Purpose:** Master copy to clone from
- **Use:** Spin up multiple fresh VMs
- **Storage:** Full VM copy (takes more space)
- **Example:** `Tor-Gateway-TEMPLATE`

### Clones (What You'll Create)
- **Purpose:** New VM from template
- **Use:** Isolated instances for different tasks
- **Storage:** Independent VM (doesn't affect template)
- **Example:** `Tor-Gateway-test`, `Workstation-experimental`

---

## 📊 Snapshot History

### Tor-Gateway Snapshots
- **{9e012d7c-9ef7-4d17-a0e9-c2e8f61b485a}** - `GOLDEN-IMAGE-baseline-20251207` (clean baseline)
- **{75163c4f-e762-4436-ace5-54c6d22b8f48}** - `WITH-APPS-20251207` (with all apps)

### SecuredWorkstation Snapshots
- **{67c48cbb-6915-4a70-a0a5-507e410b88ff}** - `GOLDEN-IMAGE-baseline-20251207` (clean baseline)
- **{074cd372-8c14-47c8-ac9c-69ebe1087e68}** - `WITH-APPS-20251207` (with all apps)

**To revert to snapshot:**
```bash
prlctl snapshot-switch SecuredWorkstation --id {snapshot-id}
```

---

## 🎯 Recommended Workflow

### For Daily OPSEC Work
1. **Use production VMs:** Tor-Gateway + SecuredWorkstation
2. **Create snapshots before major changes**
3. **Keep templates untouched**

### For Experimentation
1. **Clone from templates** → Create test VMs
2. **Use test VMs freely**
3. **Delete test VMs when done**
4. **Clone fresh next time**

### For Major Updates
1. **Update production VMs** with new apps/configs
2. **Test thoroughly**
3. **Update templates** to match production
4. **Create new snapshot** with descriptive name

---

## 🚨 Important Notes

### DO NOT Delete Templates
- **Tor-Gateway-TEMPLATE** - Keep this!
- **SecuredWorkstation-TEMPLATE** - Keep this!

These are your master copies. If you delete them, you'll need to manually recreate the entire setup.

### Storage Considerations
Each template is ~10-15GB. Each clone is another full copy.

**Check disk space:**
```bash
du -sh ~/Parallels/*.pvm/
df -h ~/Parallels/
```

**Clean up old clones:**
```bash
# List all VMs
prlctl list -a

# Delete ones you don't need
prlctl delete VM-name
```

---

## 📚 Quick Reference Commands

### Clone from Template
```bash
prlctl clone TEMPLATE-NAME --name "NEW-VM-NAME" --dst ~/Parallels/
```

### Start Cloned VM
```bash
prlctl start NEW-VM-NAME
```

### Stop VM
```bash
prlctl stop VM-NAME              # Graceful shutdown
prlctl stop VM-NAME --kill       # Force stop
```

### Delete VM
```bash
prlctl delete VM-NAME
```

### List All VMs
```bash
prlctl list -a                   # All VMs
prlctl list -a --template        # Only templates
prlctl list                      # Only running VMs
```

### Create New Template from Existing VM
```bash
prlctl stop VM-NAME
prlctl clone VM-NAME --name "VM-NAME-TEMPLATE" --template --dst ~/Parallels/
prlctl start VM-NAME
```

---

## ✅ You're All Set!

You now have:
- ✅ **2 Production VMs** (Tor-Gateway + SecuredWorkstation)
- ✅ **2 Templates** (ready to clone fresh instances)
- ✅ **4 Snapshots** (2 golden baseline + 2 with-apps)
- ✅ **Complete OPSEC stack** with all tools installed

**Next time you need a fresh VM:**
```bash
prlctl clone SecuredWorkstation-TEMPLATE --name "fresh-workspace" --dst ~/Parallels/
prlctl start fresh-workspace
```

**That's it. You're ready to go wild.**

---

*Created: 2025-12-07 by OpenCode*
*Templates Location: ~/Parallels/*
