# Manual Firefox .onion Fix - Step by Step

**Date:** 2025-12-07  
**For:** Immediate fix when .onion sites won't load

---

## 🚀 Quick Fix (Do This NOW in Firefox)

### Step 1: Open Firefox Configuration

1. **Open Firefox** in your SecuredWorkstation VM

2. **Type in the address bar:**
   ```
   about:config
   ```

3. **Click:** "Accept the Risk and Continue"

---

### Step 2: Enable .onion Domains

1. **In the search box, type:**
   ```
   network.dns.blockDotOnion
   ```

2. **You'll see the setting appear**
   - If it says `true` → Click the toggle button to change it to `false`
   - If it says `false` → Good, it's already set correctly

3. **The setting should now show:**
   ```
   network.dns.blockDotOnion = false
   ```

---

### Step 3: Disable WebRTC (Privacy)

1. **In the search box, type:**
   ```
   media.peerconnection.enabled
   ```

2. **Click the toggle to set it to `false`**

---

### Step 4: Enable Privacy Protection

1. **In the search box, type:**
   ```
   privacy.resistFingerprinting
   ```

2. **Click the toggle to set it to `true`**

---

### Step 5: Test .onion Site

1. **Open a new tab**

2. **Type this .onion address:**
   ```
   https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
   ```

3. **Press Enter**

4. **Wait 10-30 seconds** (.onion sites are slower)

5. **DuckDuckGo dark web version should load!** ✅

---

## 🎯 What You Just Did

You told Firefox:
- ✅ **Allow .onion domains** (removed the block)
- ✅ **Disable WebRTC** (prevents IP leaks)
- ✅ **Enable fingerprint protection** (more privacy)

---

## 🧪 Test More .onion Sites

Try these to confirm it's working:

**BBC News (Tor):**
```
https://www.bbcnewsd73hkzno2ini43t4gblxvycyac5aw4gnv7t2rccijh7745uqd.onion
```

**ProtonMail (Tor):**
```
https://protonmailrmez3lotccipshtkleegetolb73fuirgj7r4o4vfu7ozyd.onion
```

**The Hidden Wiki:**
```
http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion
```

---

## ⚠️ Important Notes

### .onion sites are SLOW
- Wait 10-30 seconds for pages to load
- This is normal - Tor routes through multiple relays worldwide
- Be patient!

### Some sites might be down
- .onion sites go up and down
- If one doesn't work, try another
- DuckDuckGo and BBC are usually reliable

### No extra software needed
- You DON'T need Tor Browser
- Your VM already routes through Tor Gateway
- Firefox with this config is enough!

---

## 🔍 Verify It's Working

### Method 1: Check Tor Status
Visit in Firefox:
```
https://check.torproject.org
```

Should say: **"Congratulations. This browser is configured to use Tor."**

### Method 2: Check Your IP
Visit:
```
https://icanhazip.com
```

Should show a **Tor exit node IP** (NOT your home IP)

### Method 3: Terminal Test
In terminal:
```bash
curl https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

Should return HTML (proves .onion routing works)

---

## 🚨 Still Not Working?

### Check 1: Gateway Running?
```bash
# From Mac terminal
prlctl list | grep Tor-Gateway
```

Should show `running`. If not:
```bash
prlctl start Tor-Gateway
```

### Check 2: Correct Setting?
- Go back to `about:config`
- Search: `network.dns.blockDotOnion`
- Should be: `false` (not true)

### Check 3: Try Desktop Script
There's a script on your Desktop: `fix-firefox-onion.sh`
- Double-click it
- Follow the prompts
- Restart Firefox

### Check 4: What Error Do You See?

**"Unable to connect"**
- Wait longer (30-60 seconds)
- .onion sites are slow

**"Server not found"**
- Check Gateway is running
- Restart Gateway: `prlctl restart Tor-Gateway`

**"Connection refused"**
- The specific .onion site might be down
- Try a different one (DuckDuckGo, BBC)

**Page loads but looks broken**
- Some .onion sites have display issues
- Try disabling uBlock/privacy extensions
- Or try different .onion site

---

## 📸 Screenshot Guide

### What about:config Should Look Like

```
Search: network.dns.blockDotOnion
Result: network.dns.blockDotOnion = false  [Boolean] [Modified]
```

### What Working .onion Looks Like

Address bar should show:
```
🔒 https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

Page should load DuckDuckGo search page.

---

## ✅ Success Checklist

After following these steps, you should have:

- ✅ `network.dns.blockDotOnion` set to `false`
- ✅ `media.peerconnection.enabled` set to `false`
- ✅ `privacy.resistFingerprinting` set to `true`
- ✅ .onion sites loading in Firefox
- ✅ Tor routing verified at check.torproject.org

---

## 🎓 Understanding the Settings

### network.dns.blockDotOnion
**What it does:** Blocks access to .onion addresses  
**Why we change it:** We WANT to access .onion sites  
**Safe to change?** YES - your VM routes through Tor Gateway

### media.peerconnection.enabled
**What it does:** Enables WebRTC for video calls  
**Why we disable it:** WebRTC can leak your real IP  
**Safe to disable?** YES - prevents IP leaks

### privacy.resistFingerprinting
**What it does:** Makes your browser harder to track  
**Why we enable it:** Extra privacy protection  
**Safe to enable?** YES - standard privacy practice

---

## 💡 Alternative: Just Use Terminal

If Firefox keeps giving you trouble, you can access .onion content via terminal:

```bash
# Download .onion page
curl https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion > page.html

# View in browser
firefox page.html
```

Not ideal, but proves the routing works!

---

**Follow the steps above in Firefox right now. It should work immediately!** 🚀

---

*Created: 2025-12-07 by OpenCode*
*Quick fix for Firefox .onion access*
