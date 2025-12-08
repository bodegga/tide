# Fix Tor Gateway for .onion Sites - Manual Steps

**Date:** 2025-12-07  
**Issue:** .onion sites not resolving in browsers  
**Root Cause:** Tor Gateway DNS not configured for .onion domain mapping

---

## 🎯 The Problem

Your Tor Gateway routes traffic through Tor, but it's not properly configured to resolve .onion domain names. This is why:
- ✅ `curl` on command line works (uses direct connection)
- ❌ Firefox doesn't work (uses DNS resolution)

**We need to add .onion DNS support to the Tor Gateway.**

---

## 🔧 How to Fix (Manual Steps)

### Step 1: Open Tor-Gateway Console

**On your Mac:**

1. **Open Parallels Desktop**

2. **Find "Tor-Gateway" VM** in the list

3. **Double-click it** to open the console window
   - You'll see a login prompt
   - This VM runs headless, but we can open a console view

4. **Login:**
   - Username: `root` or `user` (depending on how you set it up)
   - Password: (whatever you set during installation)

---

### Step 2: Edit Tor Configuration

Once logged into the Gateway console:

```bash
# Edit the Tor config file
nano /etc/tor/torrc
```

**Scroll to the bottom** and add these lines:

```
# .onion DNS resolution support
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
VirtualAddrNetworkIPv4 10.192.0.0/10
VirtualAddrNetworkIPv6 [FC00::]/7
```

**Save and exit:**
- Press `Ctrl+O` (save)
- Press `Enter` (confirm)
- Press `Ctrl+X` (exit)

---

### Step 3: Restart Tor

```bash
# Restart Tor daemon
systemctl restart tor

# Wait a few seconds
sleep 5

# Check it's running
systemctl status tor
```

Should show `active (running)` in green.

---

### Step 4: Test from Workstation

Back in your SecuredWorkstation VM:

```bash
# Test .onion DNS resolution
nslookup duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

Should now resolve properly.

**Then test in Firefox:**
```
https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

Should load! 🎉

---

## 📋 Alternative: Copy-Paste Method

If nano is confusing, use this:

### In Gateway Console:

```bash
# Append the config
cat >> /etc/tor/torrc << 'EOF'

# .onion DNS resolution support
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
VirtualAddrNetworkIPv4 10.192.0.0/10
VirtualAddrNetworkIPv6 [FC00::]/7
EOF

# Restart Tor
systemctl restart tor
```

Just copy those commands and paste into the Gateway terminal.

---

## 🔍 What These Settings Do

### `AutomapHostsOnResolve 1`
Tells Tor to automatically map .onion addresses when applications try to resolve them.

### `AutomapHostsSuffixes .onion`
Specifies that .onion domains should be auto-mapped (this is the key setting!).

### `VirtualAddrNetworkIPv4 10.192.0.0/10`
Defines the IP range Tor uses for virtual addresses when mapping .onion sites.

### `VirtualAddrNetworkIPv6 [FC00::]/7`
Same as above, but for IPv6.

**Bottom line:** These tell Tor: "When you see a .onion domain, handle it properly and route it through the Tor network."

---

## ✅ Verification Steps

### 1. Check Tor Config
```bash
# On Gateway
grep -A 4 "AutomapHostsOnResolve" /etc/tor/torrc
```

Should show your new settings.

### 2. Check Tor is Running
```bash
# On Gateway
systemctl status tor
```

Should be `active (running)`.

### 3. Test DNS from Workstation
```bash
# On Workstation
host duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion 10.152.152.10
```

Should return an IP address (virtual mapping).

### 4. Test in Firefox
Visit any .onion site - should work!

---

## 🚨 Troubleshooting

### "I can't login to Tor-Gateway"

**Try these credentials:**
- Username: `root` / Password: (whatever you set)
- Username: `user` / Password: (whatever you set)
- Username: `debian` / Password: `debian` (if default install)

**Reset if forgotten:**
You may need to rebuild the Gateway VM if you forgot the password.

### "nano: command not found"

Use vi instead:
```bash
vi /etc/tor/torrc
# Press 'i' to enter insert mode
# Add the lines
# Press Esc
# Type :wq and press Enter
```

Or use echo:
```bash
echo "AutomapHostsOnResolve 1" >> /etc/tor/torrc
echo "AutomapHostsSuffixes .onion" >> /etc/tor/torrc
echo "VirtualAddrNetworkIPv4 10.192.0.0/10" >> /etc/tor/torrc
```

### "Tor won't restart"

Check for syntax errors:
```bash
# Test Tor config
tor --verify-config

# Check logs
journalctl -u tor -n 50
```

Fix any errors shown, then restart again.

### ".onion still doesn't work after fix"

1. **Restart Gateway VM completely:**
   ```bash
   # On Mac
   prlctl restart Tor-Gateway
   ```

2. **Clear Firefox cache:**
   - In Firefox: Settings → Privacy & Security
   - Click "Clear Data"
   - Restart Firefox

3. **Verify routing:**
   ```bash
   # On Workstation
   curl https://check.torproject.org/api/ip
   ```
   Should show `"IsTor":true`

---

## 📊 Expected Result

**Before fix:**
- ❌ .onion sites: DNS resolution fails
- ❌ Firefox: "Server not found"
- ✅ curl: Works (bypasses DNS)

**After fix:**
- ✅ .onion sites: DNS resolves correctly
- ✅ Firefox: Loads .onion sites
- ✅ curl: Still works

---

## 💾 Make Changes Permanent

The changes we made to `/etc/tor/torrc` are permanent. They survive reboots.

**To update your templates:**

1. **After confirming .onion works:**
   ```bash
   # On Mac
   prlctl stop Tor-Gateway
   ```

2. **Update template:**
   ```bash
   prlctl delete Tor-Gateway-TEMPLATE
   prlctl clone Tor-Gateway --name "Tor-Gateway-TEMPLATE" --template --dst ~/Parallels/
   ```

3. **Restart Gateway:**
   ```bash
   prlctl start Tor-Gateway
   ```

Now future clones will have .onion support built-in!

---

## 🎯 Quick Reference

### Commands to Run on Tor-Gateway:

```bash
# Add config
cat >> /etc/tor/torrc << 'EOF'

AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
VirtualAddrNetworkIPv4 10.192.0.0/10
VirtualAddrNetworkIPv6 [FC00::]/7
EOF

# Restart Tor
systemctl restart tor

# Verify
systemctl status tor
```

### Test from Workstation:

```bash
# Test DNS
nslookup duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion

# Test in Firefox
# Visit: https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

---

**Follow these steps and .onion sites will work in Firefox!** 🚀

---

*Created: 2025-12-07 by OpenCode*
*Fix for Tor Gateway .onion DNS resolution*
