# QUICK FIX: .onion Sites Not Working

**Do this RIGHT NOW in your SecuredWorkstation VM**

---

## Step 1: Open Terminal in SecuredWorkstation

Click: **Applications** → **System** → **Terminal**

---

## Step 2: SSH into the Gateway

In the terminal, type:

```bash
ssh user@10.152.152.10
```

Enter the password you set for the Gateway when you created it.

(If `user` doesn't work, try `ssh root@10.152.152.10`)

---

## Step 3: Fix Tor Configuration

Once logged into the Gateway, copy and paste this ENTIRE block:

```bash
sudo bash << 'ENDOFSCRIPT'

# Add .onion DNS support to Tor
cat >> /etc/tor/torrc << 'EOF'

# .onion DNS resolution support
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
VirtualAddrNetworkIPv4 10.192.0.0/10
VirtualAddrNetworkIPv6 [FC00::]/7
EOF

# Restart Tor
systemctl restart tor
sleep 3

# Show status
echo ""
echo "Tor status:"
systemctl status tor | head -10

echo ""
echo "✅ Gateway fixed! Type 'exit' to return to Workstation"

ENDOFSCRIPT
```

---

## Step 4: Exit Gateway

Type:
```bash
exit
```

---

## Step 5: Test .onion Site in Firefox

Open Firefox and visit:
```
https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

**It should work now!** 🎉

---

## If SSH Password Doesn't Work

You might not remember the Gateway password. Here's what to do:

1. **On your Mac**, run:
   ```bash
   prlctl stop Tor-Gateway
   ```

2. **Double-click Tor-Gateway** in Parallels Desktop to open console

3. **Login directly** with whatever credentials you used

4. **Run the commands from Step 3** directly in the console

5. **Close the console**, then:
   ```bash
   prlctl start Tor-Gateway
   ```

---

## Why This Fix Works

Your Tor Gateway was routing traffic through Tor, but wasn't configured to handle .onion domain resolution properly.

These settings tell Tor:
- `AutomapHostsOnResolve 1` - Automatically map hostnames  
- `AutomapHostsSuffixes .onion` - Specifically handle .onion domains
- `VirtualAddrNetworkIPv4 10.192.0.0/10` - Use this IP range for mapping

Now when Firefox tries to visit a .onion site, the Gateway's Tor daemon properly resolves and routes it!

---

**That's it! Just SSH in, paste the commands, test Firefox.** 🚀
