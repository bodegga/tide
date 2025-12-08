# Making Regular Firefox Access .onion Sites

**Yes, regular Firefox CAN access .onion sites!** You just need the right Tor configuration.

---

## 🎯 **The Solution**

### On Gateway: Enhanced Tor Config
### On Workstation: Proxy DNS Through SOCKS

**That's it.**

---

## 📋 **Step 1: Gateway Tor Configuration**

### Enhanced `/etc/tor/torrc` on Alpine:

```bash
# On Alpine Gateway, edit Tor config
cat > /etc/tor/torrc << 'EOF'
# Standard SOCKS/DNS/TransPort
SocksPort 10.152.152.10:9050
DNSPort 10.152.152.10:5353
TransPort 10.152.152.10:9040

# .onion support (CRITICAL LINES)
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion

# Logging
Log notice file /var/log/tor/notices.log
EOF

# Restart Tor
rc-service tor restart

# Verify it loaded
tail -f /var/log/tor/notices.log
# Look for "Bootstrapped 100%: Done"
```

### What These Settings Do:

| Setting | Purpose |
|---------|---------|
| `VirtualAddrNetworkIPv4 10.192.0.0/10` | Creates virtual IP space for .onion addresses |
| `AutomapHostsOnResolve 1` | Automatically maps .onion to virtual IPs |
| `AutomapHostsSuffixes .onion` | Tells Tor to specially handle .onion domains |

**Without these:** Firefox can't resolve `.onion` addresses  
**With these:** Tor intercepts and routes `.onion` properly

---

## 📋 **Step 2: Firefox Configuration**

### Method A: GUI Settings (Easiest)

1. **Open Firefox**
2. **Settings → General → Network Settings → Settings**
3. **Select "Manual proxy configuration"**
4. **Configure:**

```
SOCKS Host: 10.152.152.10
Port: 9050

☑ SOCKS v5
☑ Proxy DNS when using SOCKS v5  ← CRITICAL!

No proxy for: (leave blank)
```

5. **Click OK**

### Method B: about:config (Permanent)

1. **Open Firefox**
2. **Type in address bar:** `about:config`
3. **Accept warning**
4. **Search and set these values:**

```
network.proxy.type = 1
network.proxy.socks = 10.152.152.10
network.proxy.socks_port = 9050
network.proxy.socks_remote_dns = true  ← CRITICAL
network.dns.blockDotOnion = false      ← CRITICAL
```

**What `socks_remote_dns = true` does:**
- Forces Firefox to send `.onion` address to Tor **without resolving it first**
- Without this, Firefox tries to DNS resolve `.onion` and fails

---

## 📋 **Step 3: Test It Works**

### Test .onion Sites:

```
http://3g2upl4pq6kufc4m.onion
→ DuckDuckGo onion service

https://www.facebookwkhpilnemxj7asaniu7vnjjbiltxjqhye3mhbshg7kx5tfyd.onion
→ Facebook onion service

http://thehiddenwiki.onion
→ The Hidden Wiki
```

### Expected Behavior:

1. Type `.onion` address in Firefox
2. Firefox sends it to SOCKS proxy (gateway)
3. Tor on gateway maps `.onion` → virtual IP
4. Tor routes through onion network
5. Page loads!

---

## 🔧 **Advanced: FoxyProxy Extension**

**Why use FoxyProxy?**
- Switch between Tor and normal easily
- Route only `.onion` through Tor, rest direct
- More control

### Install FoxyProxy:

1. **Visit:** `https://addons.mozilla.org/firefox/addon/foxyproxy-standard/`
2. **Add to Firefox**

### Configure FoxyProxy:

```
1. Click FoxyProxy icon → Options
2. Add New Proxy:
   Title: Tor Gateway
   Type: SOCKS5
   Hostname: 10.152.152.10
   Port: 9050

3. Add Pattern:
   Pattern: *.onion
   Type: Wildcard
   Proxy: Tor Gateway

4. Default: Direct (or Tor if you want everything through Tor)
```

**Now:**
- `.onion` sites → Automatic Tor routing
- Regular sites → Direct (or Tor, your choice)

---

## 🐛 **Troubleshooting**

### Problem: "Server Not Found" for .onion

**Fix 1: Check Proxy DNS**
```
about:config
network.proxy.socks_remote_dns = true
```

**Fix 2: Check blockDotOnion**
```
about:config
network.dns.blockDotOnion = false
```

**Fix 3: Verify Gateway Tor Config**
```bash
# On gateway
grep -i automap /etc/tor/torrc
# Should show: AutomapHostsOnResolve 1
```

### Problem: .onion Loads but Hangs

**Fix 1: Check SOCKS Version**
Must be **SOCKS v5**, not SOCKS4.

**Fix 2: Check Firewall**
```bash
# On gateway
iptables -L -n | grep 9050
# Should show ACCEPT from 10.152.152.0/24
```

### Problem: Some .onion Work, Others Don't

**Check Tor Version (v3 onion support)**
```bash
# On gateway
tor --version
# Should be 0.4.x or higher for v3 onion support
```

**v2 onions:** 16 characters (deprecated)  
**v3 onions:** 56 characters (modern, required)

---

## 📊 **How It Works**

```
┌─────────────────────────────────────────────────┐
│  Firefox on Workstation                         │
│                                                  │
│  User types: example.onion                      │
│  ↓                                               │
│  Firefox sends to SOCKS5 10.152.152.10:9050     │
│  (WITHOUT resolving DNS first)                  │
└────────────────────────┬────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────┐
│  Tor on Alpine Gateway                          │
│                                                  │
│  Receives: example.onion                        │
│  ↓                                               │
│  AutomapHostsOnResolve kicks in                 │
│  ↓                                               │
│  Maps example.onion → 10.192.1.1 (virtual IP)   │
│  ↓                                               │
│  Routes through Tor onion network               │
│  ↓                                               │
│  Connection established to hidden service       │
└────────────────────────┬────────────────────────┘
                         │
                         ↓
                  Response flows back
                         │
                         ↓
                  Firefox displays page
```

---

## ✅ **Final Configs**

### Gateway: `/etc/tor/torrc`

```bash
SocksPort 10.152.152.10:9050
DNSPort 10.152.152.10:5353
TransPort 10.152.152.10:9040

# .onion support
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion

Log notice file /var/log/tor/notices.log
```

### Workstation: Firefox Settings

**Network Settings (GUI):**
```
Manual proxy configuration
SOCKS Host: 10.152.152.10
Port: 9050
☑ SOCKS v5
☑ Proxy DNS when using SOCKS v5
```

**about:config:**
```
network.proxy.type = 1
network.proxy.socks = 10.152.152.10
network.proxy.socks_port = 9050
network.proxy.socks_remote_dns = true
network.dns.blockDotOnion = false
```

---

## 🎯 **Summary**

**Gateway changes:**
- Add 3 lines to `/etc/tor/torrc`
- Restart Tor

**Firefox changes:**
- Set SOCKS5 proxy to gateway
- Enable "Proxy DNS when using SOCKS v5"
- Disable `blockDotOnion` in about:config

**Result:**
- ✅ Regular Firefox accesses `.onion` sites
- ✅ No Tor Browser needed (though still recommended for max anonymity)
- ✅ Works with all your Firefox extensions
- ✅ Same anonymity as Tor Browser (traffic goes through Tor)

---

**Now Firefox can access .onion sites just like Tor Browser!**

*Want me to walk you through setting this up on your existing VMs?*
