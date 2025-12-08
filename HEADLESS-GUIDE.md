# Tor-Gateway Headless Mode Guide

**Date:** 2025-12-07  
**Status:** ✅ Configured

---

## ✅ What Changed

Your **Tor-Gateway** VM now runs in **headless mode** - no window pops up!

- ✅ Tor-Gateway runs in background (no GUI window)
- ✅ SecuredWorkstation still has normal GUI (you'll use this one)
- ✅ Gateway keeps routing traffic through Tor silently in background

---

## 🎯 How It Works Now

### Starting VMs

**From command line:**
```bash
prlctl start Tor-Gateway          # Starts in background (no window)
prlctl start SecuredWorkstation   # Opens GUI window (normal)
```

**From Parallels Desktop:**
- Double-click Tor-Gateway → Runs in background (no window)
- Double-click SecuredWorkstation → Opens GUI window (normal)

### Checking Gateway Status

**List running VMs:**
```bash
prlctl list
```

**Check Gateway is routing traffic:**
```bash
# From SecuredWorkstation terminal:
curl https://check.torproject.org/api/ip
# Should return: {"IsTor":true,"IP":"<tor-exit-node>"}
```

### Managing Headless Gateway

**Stop the Gateway:**
```bash
prlctl stop Tor-Gateway
```

**Restart the Gateway:**
```bash
prlctl restart Tor-Gateway
```

**Access Gateway console (if needed):**
```bash
prlctl enter Tor-Gateway
# This gives you a terminal inside the Gateway VM
# Type 'exit' to leave
```

**Open Gateway GUI (temporarily):**
```bash
# If you need to see the Gateway desktop for troubleshooting:
prlctl start Tor-Gateway --startup-view window

# Or change it back to window mode permanently:
prlctl set Tor-Gateway --startup-view window
prlctl restart Tor-Gateway
```

---

## 🔧 Headless Mode Options

### Available Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **headless** | No window, runs in background | Gateways, servers |
| **window** | Normal GUI window | Workstations |
| **fullscreen** | Full screen mode | Focus work |
| **coherence** | Seamless mode (Parallels-specific) | App integration |

### Change Mode

**Set to headless:**
```bash
prlctl stop VM-NAME
prlctl set VM-NAME --startup-view headless
prlctl start VM-NAME
```

**Set to normal window:**
```bash
prlctl stop VM-NAME
prlctl set VM-NAME --startup-view window
prlctl start VM-NAME
```

---

## 💡 Why This Is Better

### Before (Window Mode)
- ❌ Gateway window always open (clutters screen)
- ❌ Accidentally clicking Gateway window
- ❌ Gateway GUI not needed (it's just routing traffic)

### After (Headless Mode)
- ✅ Gateway runs silently in background
- ✅ Only SecuredWorkstation window visible
- ✅ Cleaner workflow
- ✅ Still routing all traffic through Tor
- ✅ Can still access Gateway console if needed

---

## 🚀 Recommended Workflow

### Daily Use

**1. Start both VMs:**
```bash
prlctl start Tor-Gateway          # Runs in background
prlctl start SecuredWorkstation   # Opens GUI
```

**2. Work in SecuredWorkstation GUI**
   - All your apps are here
   - All traffic automatically routes through Gateway
   - Gateway quietly does its job in background

**3. When done, stop both:**
```bash
prlctl stop SecuredWorkstation
prlctl stop Tor-Gateway
```

### Auto-Start on Login (Optional)

**Make Gateway auto-start when you log in:**
```bash
prlctl set Tor-Gateway --autostart on --autostart-delay 0
```

**Make Workstation require manual start:**
```bash
prlctl set SecuredWorkstation --autostart off
```

Now Gateway will always be ready in background when you need it!

---

## 🛠 Troubleshooting Headless VMs

### Can't see if Gateway is running
```bash
prlctl list        # Shows running VMs
prlctl status Tor-Gateway
```

### Need to access Gateway console
```bash
prlctl enter Tor-Gateway
# You're now in the Gateway terminal
# Do what you need, then type: exit
```

### Gateway not routing traffic
```bash
# Enter Gateway console
prlctl enter Tor-Gateway

# Check Tor status
sudo systemctl status tor

# Check firewall
sudo nft list ruleset

# Exit console
exit
```

### Want to see Gateway GUI temporarily
```bash
# Open GUI window for debugging
prlctl start Tor-Gateway --startup-view window

# Or attach to running headless VM
prlctl set Tor-Gateway --startup-view window
prlctl restart Tor-Gateway
```

---

## 📋 Quick Reference

### Start Both VMs
```bash
prlctl start Tor-Gateway && prlctl start SecuredWorkstation
```

### Stop Both VMs
```bash
prlctl stop SecuredWorkstation && prlctl stop Tor-Gateway
```

### Check Status
```bash
prlctl list
```

### Access Gateway Console
```bash
prlctl enter Tor-Gateway
```

### Restart Gateway
```bash
prlctl restart Tor-Gateway
```

### Change Back to Window Mode
```bash
prlctl stop Tor-Gateway
prlctl set Tor-Gateway --startup-view window
prlctl start Tor-Gateway
```

---

## ✅ Current Configuration

### Tor-Gateway
- **Mode:** Headless (background)
- **Auto-start:** Off (manual start)
- **Purpose:** Route traffic through Tor silently

### Tor-Gateway-TEMPLATE
- **Mode:** Headless (background)
- **Note:** New clones will also be headless

### SecuredWorkstation
- **Mode:** Window (normal GUI)
- **Auto-start:** Off (manual start)
- **Purpose:** Your OPSEC workspace

### SecuredWorkstation-TEMPLATE
- **Mode:** Window (normal GUI)
- **Note:** New clones will have normal GUI

---

**Your Gateway is now a silent guardian. It runs in the shadows, protecting your traffic. 🕶️**

---

*Created: 2025-12-07 by OpenCode*
*Gateway Mode: Headless*
