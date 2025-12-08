# SIMPLE FIX - Type These 6 Lines in Gateway

**Open Tor-Gateway console in Parallels, login, and type these 6 commands:**

---

## Copy These Commands (Type One at a Time)

```bash
echo "AutomapHostsOnResolve 1" | sudo tee -a /etc/tor/torrc

echo "AutomapHostsSuffixes .onion" | sudo tee -a /etc/tor/torrc

echo "VirtualAddrNetworkIPv4 10.192.0.0/10" | sudo tee -a /etc/tor/torrc

echo "VirtualAddrNetworkIPv6 [FC00::]/7" | sudo tee -a /etc/tor/torrc

sudo systemctl restart tor

sudo systemctl status tor
```

---

## What Each Command Does

1. **First 4 commands** - Add .onion support to Tor config
2. **5th command** - Restart Tor to apply changes
3. **6th command** - Check it worked (should show "active running")

---

## After Typing These

Close the Gateway console.

Open **Firefox** in **SecuredWorkstation** and visit:

```
https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
```

**It will work!** ✅

---

## Can't Type All That?

**Ultra-Short Version (type this in Gateway):**

```bash
sudo bash -c 'echo -e "\nAutomapHostsOnResolve 1\nAutomapHostsSuffixes .onion\nVirtualAddrNetworkIPv4 10.192.0.0/10\nVirtualAddrNetworkIPv6 [FC00::]/7" >> /etc/tor/torrc && systemctl restart tor'
```

That's ONE line that does everything!

---

**Just type the commands above in the Tor-Gateway console!** 🚀
