# Tide Client - Quick Start Guide

Get connected to your Tide Gateway in under 60 seconds.

## 🚀 macOS (Fastest)

```bash
cd client
./build-macos.sh
open build/macos/TideClient.app
```

Click the wave icon 🌊 in your menu bar → Connect

**That's it.** Your traffic is now routed through Tor.

---

## 🐧 Linux (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt install python3-pip
pip3 install PyQt6

# Run client
cd client
python3 linux/tide-client-qt.py
```

Right-click the tray icon → Connect

---

## 🪟 Windows

```bash
# Install dependencies
pip install PyQt6

# Run client
cd client
python windows/tide-client-qt.py
```

Right-click the tray icon → Connect

---

## What Just Happened?

1. **Discovery:** Client auto-found your Tide Gateway on the network
2. **Connection:** System proxy configured to route through Tide
3. **Verification:** Check your IP: `curl ifconfig.me` (should show Tor exit)

## Next Steps

- **New Circuit:** Click "New Circuit" to get a fresh Tor exit
- **Status:** Click "Show Status" to see gateway info
- **Disconnect:** Click "Disconnect" to return to normal browsing

## Troubleshooting

**Gateway not found?**
```bash
# Check gateway is reachable
ping 10.101.101.10
curl http://10.101.101.10:9051/status
```

**Proxy not working?**
```bash
# macOS: Check proxy settings
networksetup -getsocksfirewallproxy Wi-Fi

# Linux: Check GNOME settings
gsettings get org.gnome.system.proxy mode

# Windows: Check registry
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable
```

**Need help?** See [README-CLIENTS.md](README-CLIENTS.md) for detailed documentation.

---

**Tide Gateway:** Transparent Tor routing for your entire system.  
**[bodegga/tide](https://github.com/bodegga/tide)** | *Freedom within the shell.* 🌊
