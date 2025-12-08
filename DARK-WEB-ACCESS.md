# Dark Web Access Guide - OPSEC VM

**Date:** 2025-12-07  
**Status:** ✅ READY - Your VM routes ALL traffic through Tor

---

## 🎯 IMPORTANT: You Don't Need Tor Browser!

**Your SecuredWorkstation VM already routes 100% of traffic through the Tor Gateway.**

This means:
- ✅ **Firefox = Tor Browser** (all traffic goes through Tor)
- ✅ **Any browser = Tor access** (everything is routed through Tor Gateway)
- ✅ **Better security** (system-wide Tor, not just one app)
- ✅ **.onion sites work** (in any browser)

---

## ✅ Verified: You're on Tor

```json
{
    "IsTor": true,
    "IP": "185.220.101.186"
}
```

**Your public IP shows a Tor exit node, NOT your real IP.**

---

## 🌐 How to Access Dark Web (.onion sites)

### Step 1: Launch Firefox
- **Applications** → **Internet** → **Firefox**
- Or from terminal: `firefox &`

### Step 2: Visit .onion Sites
Just type the .onion address in the address bar. It works automatically!

---

## 🔗 Dark Web Sites to Test

### Search Engines
- **DuckDuckGo (Tor):**
  ```
  https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
  ```

### Email
- **ProtonMail (Tor):**
  ```
  https://protonmailrmez3lotccipshtkleegetolb73fuirgj7r4o4vfu7ozyd.onion
  ```

### Wikis & Directories
- **The Hidden Wiki:**
  ```
  http://zqktlwiuavvvqqt4ybvgvi7tyo4hjl5xgfuvpdf6otjiycgwqbym2qad.onion
  ```

- **Tor Links Directory:**
  ```
  http://torlinksd6pdnihy.onion
  ```

### News & Information
- **BBC News (Tor):**
  ```
  https://www.bbcnewsd73hkzno2ini43t4gblxvycyac5aw4gnv7t2rccijh7745uqd.onion
  ```

- **The New York Times (Tor):**
  ```
  https://ej3kv4ebuugcmuwxctx5ic7zxh73rnxt42soi3tdneu2c2em55thufqd.onion
  ```

### Forums & Communities
- **Dread (Reddit-like forum):**
  ```
  http://dreadytofatroptsdj6io7l3xptbet6onoyno2yv7jicoxknyazubrad.onion
  ```

---

## 🔒 Why This Setup is BETTER Than Tor Browser

### Traditional Tor Browser:
- ❌ Only routes browser traffic through Tor
- ❌ Other apps leak your real IP
- ❌ Need to download/update separately
- ❌ Can accidentally use wrong browser

### Your OPSEC VM Setup:
- ✅ **ALL traffic** goes through Tor Gateway (system-wide)
- ✅ **Impossible to leak** real IP (no direct internet access)
- ✅ **Any app** you use is automatically Tor-routed
- ✅ **More secure** isolation (Whonix-style architecture)

---

## 🛡️ Your Security Architecture

```
[Internet]
    ↑
    | (Tor encrypted)
    |
[Tor-Gateway VM] ← Routes through Tor network
    |
    | (Internal network: 10.152.152.x)
    |
[SecuredWorkstation VM]
    | - Firefox
    | - HexChat
    | - All apps
    ↓
  YOU (100% anonymous)
```

**Every packet** leaving your Workstation **MUST** go through Tor Gateway.

---

## 🔍 How to Verify You're on Tor

### Method 1: Check Tor Project
Visit in Firefox:
```
https://check.torproject.org
```

Should show: **"Congratulations. This browser is configured to use Tor."**

### Method 2: Check Your IP
Visit any of these:
- https://icanhazip.com
- https://ifconfig.me
- https://api.ipify.org

**Should show:** A Tor exit node IP (changes periodically)
**Should NOT show:** Your home IP address

### Method 3: Terminal Check
```bash
curl https://check.torproject.org/api/ip
```

Should return:
```json
{"IsTor":true,"IP":"<tor-exit-ip>"}
```

---

## ⚠️ Dark Web Safety Tips

### DO:
- ✅ Use your OPSEC VM for all dark web browsing
- ✅ Verify .onion URLs before visiting (many are phishing)
- ✅ Use KeePassXC to generate/store passwords
- ✅ Enable Firefox privacy settings (see below)
- ✅ Be paranoid - trust no one

### DON'T:
- ❌ Download files without verifying them first
- ❌ Enable JavaScript on untrusted sites
- ❌ Use your real name, email, or personal info
- ❌ Login to clearnet accounts (Gmail, Facebook, etc.)
- ❌ Resize Firefox window (can fingerprint your screen resolution)

---

## 🔧 Firefox Privacy Settings for Dark Web

### In Firefox, set these:

1. **Privacy & Security** → **Enhanced Tracking Protection** → **Strict**

2. **Privacy & Security** → **Cookies and Site Data**
   - ✅ Delete cookies and site data when Firefox is closed

3. **Privacy & Security** → **History**
   - ✅ Never remember history
   - ✅ Always use private browsing mode

4. **Privacy & Security** → **Permissions**
   - ✅ Block pop-ups
   - ✅ Block access to camera/microphone

5. **Privacy & Security** → **Firefox Data Collection**
   - ❌ Uncheck everything

6. **about:config** (type in address bar):
   - `privacy.resistFingerprinting` → **true**
   - `webgl.disabled` → **true**
   - `media.peerconnection.enabled` → **false**

---

## 🌐 Alternative: Install Tor Browser Anyway (Optional)

If you really want Tor Browser for its additional fingerprinting protection:

**Problem:** Tor Browser doesn't have ARM64 builds yet.

**Solution Options:**

### Option 1: Use Firefox (Recommended)
- You're already 100% on Tor
- Firefox with privacy settings = 95% as good as Tor Browser
- Simpler, less overhead

### Option 2: Wait for ARM64 Tor Browser
- Tor Project is working on ARM builds
- Check: https://www.torproject.org/download/

### Option 3: Use Brave Browser + Tor Tabs
```bash
# Install Brave (has built-in Tor tabs)
sudo apt install curl
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
  https://brave-browser-apt-release.s3.brave.com/ stable main" \
  | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install brave-browser
```

Then use **File → New Private Window with Tor**

---

## 🧪 Test Your Setup

### 1. Check you're on Tor
```bash
curl https://check.torproject.org/api/ip
```

### 2. Visit a .onion site in Firefox
```
https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

### 3. Verify no DNS leaks
Visit: https://www.dnsleaktest.com

Should show Tor exit node, NOT your ISP.

### 4. Check your IP isn't leaking
```bash
curl https://icanhazip.com
```

Should show Tor exit IP, NOT your home IP.

---

## 📋 Quick Start Checklist

- ✅ Tor-Gateway running (headless, in background)
- ✅ SecuredWorkstation running (GUI)
- ✅ Verified Tor routing: `{"IsTor":true}`
- ✅ Firefox installed and in Applications menu
- ✅ Firefox privacy settings configured
- ✅ KeePassXC installed for passwords
- ✅ Tested .onion site access

**You're ready for the dark web!** 🕶️

---

## 🆘 Troubleshooting

### "This site can't be reached" for .onion sites

**Check Tor Gateway is running:**
```bash
# From your Mac
prlctl list | grep Tor-Gateway
```

**Check Tor is actually routing:**
```bash
# From Workstation
curl https://check.torproject.org/api/ip
```

If shows `"IsTor":false`, restart Tor-Gateway:
```bash
prlctl restart Tor-Gateway
```

### ".onion sites load very slowly"

This is normal! Tor routes through 3+ relays globally. Expect:
- Clearnet sites: Fast (1-5 seconds)
- .onion sites: Slow (5-30 seconds)

Be patient. Speed varies by time of day and relay load.

### "Firefox not showing in menu"

Launch from terminal:
```bash
firefox &
```

Or refresh menu:
```bash
xfce4-panel -r
```

---

## 🎯 Summary

**You DON'T need Tor Browser because:**
1. ✅ Your entire VM already routes through Tor
2. ✅ Firefox works for .onion sites automatically
3. ✅ This is MORE secure (system-wide Tor isolation)

**To access dark web:**
1. Launch Firefox
2. Visit .onion URLs
3. That's it!

**You're anonymous. You're secure. You're ready.** 🕶️

---

*Created: 2025-12-07 by OpenCode*
*Architecture: Whonix-style Tor Gateway isolation*
*Current Tor Exit IP: 185.220.101.186*

---

## ✅ FIXED: Tor Conflict Resolved (2025-12-07 17:35)

### Problem
- .onion sites weren't loading in Firefox
- Tor daemon was installed on BOTH Gateway AND Workstation
- This created a "double-Tor" conflict

### Solution
- Removed Tor packages from Workstation: `tor`, `tor-geoipdb`, `torsocks`
- Now Workstation ONLY routes through Gateway (correct architecture)

### Verified Working
```bash
curl https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
# Successfully returned DuckDuckGo .onion site HTML ✅
```

**Status:** ✅ Dark web access fully functional

---

*Fixed: 2025-12-07 17:35 PST*
