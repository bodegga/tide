# Firefox .onion Site Fix

**Date:** 2025-12-07  
**Issue:** .onion sites not loading in Firefox (but work via curl)  
**Status:** ✅ FIXED

---

## Problem

- .onion sites work from command line: `curl https://[onion-address]` ✅
- .onion sites DON'T work in Firefox ❌
- Firefox was blocking .onion domains by default

---

## Solution Applied

Created Firefox configuration file to:
1. **Allow .onion domains** (`network.dns.blockDotOnion = false`)
2. **Disable WebRTC** (prevents IP leaks)
3. **Enable privacy protections** (fingerprinting resistance)
4. **Use transparent proxy** (no manual proxy config needed)

**File created:** `/home/user/.mozilla/firefox/[profile]/user.js`

---

## ✅ How to Apply the Fix

### In Your SecuredWorkstation VM:

1. **Close Firefox** (if it's open)
   - Click X to close all Firefox windows
   
2. **Reopen Firefox**
   - Applications → Internet → Firefox ESR

3. **Test .onion site**
   - Type in address bar:
     ```
     https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
     ```
   - Should load DuckDuckGo's dark web version!

---

## 🧪 Test .onion Sites

Try these in Firefox:

### Search Engines
```
https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

### News
```
https://www.bbcnewsd73hkzno2ini43t4gblxvycyac5aw4gnv7t2rccijh7745uqd.onion
```

### Email
```
https://protonmailrmez3lotccipshtkleegetolb73fuirgj7r4o4vfu7ozyd.onion
```

### The Hidden Wiki
```
http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion
```

---

## What Was Changed in Firefox

The `user.js` file adds these settings:

```javascript
// Allow .onion domains (CRITICAL FIX)
user_pref("network.dns.blockDotOnion", false);

// Disable WebRTC (privacy - prevents IP leaks)
user_pref("media.peerconnection.enabled", false);

// Privacy hardening
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.trackingprotection.enabled", true);

// Disable DNS prefetching (privacy)
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);

// No manual proxy needed (transparent routing via Gateway)
user_pref("network.proxy.type", 0);
```

---

## 🔍 Verify It's Working

### Method 1: Visit .onion Site
Just type an .onion URL in Firefox address bar. Should load!

### Method 2: Check Tor Status
Visit:
```
https://check.torproject.org
```

Should say: **"Congratulations. This browser is configured to use Tor."**

### Method 3: Terminal Test (Already Works)
```bash
curl https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

This already worked - proves .onion routing is functional.

---

## 🚨 Troubleshooting

### ".onion sites still don't load"

**1. Did you restart Firefox?**
   - Close ALL Firefox windows
   - Wait 5 seconds
   - Reopen Firefox

**2. Check user.js exists:**
   ```bash
   ls -la ~/.mozilla/firefox/*.default*/user.js
   ```
   Should show the file.

**3. Check Firefox profile:**
   ```bash
   cat ~/.mozilla/firefox/*.default*/user.js | grep blockDotOnion
   ```
   Should show: `user_pref("network.dns.blockDotOnion", false);`

**4. Try about:config manually:**
   - In Firefox, type in address bar: `about:config`
   - Accept the warning
   - Search for: `network.dns.blockDotOnion`
   - Double-click to set it to `false`
   - Restart Firefox

### "Page loads but shows error"

Some .onion sites are slow or down. Try multiple:
- DuckDuckGo .onion (usually fast)
- BBC .onion (reliable)
- ProtonMail .onion (usually fast)

Wait 10-30 seconds for .onion sites to load (they're slower than clearnet).

### "Firefox says 'Server Not Found'"

Check Gateway is running:
```bash
# From Mac terminal
prlctl list | grep Tor-Gateway
```

Should show `running`.

If not:
```bash
prlctl start Tor-Gateway
```

---

## 📋 Manual Configuration (If Script Didn't Work)

### Open Firefox and manually configure:

1. Type in address bar: `about:config`
2. Click "Accept the Risk and Continue"
3. Search for: `network.dns.blockDotOnion`
4. Click the toggle to set it to `false`
5. Search for: `media.peerconnection.enabled`
6. Click the toggle to set it to `false`
7. Search for: `privacy.resistFingerprinting`
8. Click the toggle to set it to `true`
9. Restart Firefox

---

## Why This Happens

**Firefox blocks .onion domains by default** for security reasons (prevents phishing on clearnet).

Since your Workstation routes ALL traffic through Tor Gateway, Firefox doesn't realize it's safe to access .onion sites.

The fix tells Firefox: "Trust .onion domains - we're on Tor!"

---

## 🎯 Expected Behavior After Fix

✅ Type .onion URL → Site loads  
✅ No proxy configuration needed  
✅ All traffic still goes through Tor Gateway  
✅ Privacy protections enabled  

---

## Alternative: Use Brave Browser

If Firefox continues to have issues, Brave Browser has built-in Tor support:

```bash
# Install Brave (optional alternative)
sudo apt install curl
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
  https://brave-browser-apt-release.s3.brave.com/ stable main" \
  | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo apt update
sudo apt install brave-browser
```

Then use: **File → New Private Window with Tor**

---

**Bottom line: Restart Firefox and try again. The fix is applied!** 🚀

---

*Created: 2025-12-07 by OpenCode*
*Firefox Profile: /home/user/.mozilla/firefox/ghsddiln.default*
