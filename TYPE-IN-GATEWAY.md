# TYPE THESE COMMANDS IN GATEWAY CONSOLE

**Since you can't paste, type these commands manually in the Tor-Gateway console**

---

## OPTION 1: Download Fix Script (Easiest - 3 commands)

```bash
wget http://10.152.152.11:8000/tor-fix.sh
chmod +x tor-fix.sh
sudo ./tor-fix.sh
```

That's it! The script is hosted on your Workstation.

---

## OPTION 2: Type Manually (If wget doesn't work)

**Type this command by command:**

```bash
sudo nano /etc/tor/torrc
```

**Scroll to bottom (arrow keys), add these 4 lines:**

```
AutomapHostsOnResolve 1
AutomapHostsSuffixes .onion
VirtualAddrNetworkIPv4 10.192.0.0/10
VirtualAddrNetworkIPv6 [FC00::]/7
```

**Save:** Ctrl+O, Enter, Ctrl+X

**Restart Tor:**

```bash
sudo systemctl restart tor
```

---

## OPTION 3: One-Line Copy (Type this if you can)

```bash
echo "AutomapHostsOnResolve 1" | sudo tee -a /etc/tor/torrc
echo "AutomapHostsSuffixes .onion" | sudo tee -a /etc/tor/torrc  
echo "VirtualAddrNetworkIPv4 10.192.0.0/10" | sudo tee -a /etc/tor/torrc
echo "VirtualAddrNetworkIPv6 [FC00::]/7" | sudo tee -a /etc/tor/torrc
sudo systemctl restart tor
```

---

## ✅ After Running Any Option:

Check it worked:
```bash
sudo systemctl status tor
```

Should show `active (running)`.

Then test .onion in Firefox on Workstation!

---

**Try Option 1 first (wget). It's only 3 short commands to type!**
