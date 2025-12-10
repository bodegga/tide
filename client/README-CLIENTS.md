# Tide Client Applications

Production-ready native desktop clients for Tide Gateway.

## Features

- **Auto-Discovery** - Finds Tide gateway via UDP beacon, default gateway check, and common IPs
- **One-Click Connect** - Configure system proxy with a single click
- **Status Display** - View Tor connection status, exit IP, and gateway mode
- **New Circuit** - Request fresh Tor circuit on demand
- **System Tray/Menu Bar** - Minimal, always-accessible interface

## Supported Platforms

| Platform | Client | Framework | Package Format |
|----------|--------|-----------|----------------|
| **macOS** | Native Swift | Cocoa | `.app`, `.dmg` |
| **Linux** | PyQt6 | PyQt6 | `.AppImage`, `.deb`, binary |
| **Windows** | PyQt6 | PyQt6 | `.exe`, installer |

## Quick Start

### macOS

```bash
# Build
./build-macos.sh

# Run
open build/macos/TideClient.app

# Install
cp -r build/macos/TideClient.app /Applications/
```

**Features:**
- Native menu bar app
- macOS-style notifications
- Admin prompt for proxy configuration
- Copy proxy settings to clipboard

**Requirements:**
- macOS 10.15+
- Xcode Command Line Tools (for building)

### Linux

```bash
# Install dependencies
pip3 install -r requirements.txt

# Build
./build-linux.sh

# Run
./build/linux/dist/TideClient

# Install system-wide
sudo cp build/linux/dist/TideClient /usr/local/bin/tide-client
cp build/linux/tide-client.desktop ~/.local/share/applications/
```

**Features:**
- System tray integration
- GNOME proxy configuration
- Desktop file for app launcher

**Requirements:**
- Python 3.8+
- PyQt6
- GNOME desktop (for automatic proxy config)

**Packaging Options:**
- **Binary:** `build/linux/dist/TideClient`
- **AppImage:** `build/linux/TideClient.AppImage` (portable)
- **.deb:** `build/linux/tide-client_1.2.0_amd64.deb` (Debian/Ubuntu)

### Windows

```bash
# Install dependencies
pip install -r requirements.txt

# Build (in WSL2 or Windows with bash)
./build-windows.sh

# Run
build/windows/dist/TideClient.exe
```

**Features:**
- System tray integration
- Windows registry proxy configuration
- NSIS installer (optional)

**Requirements:**
- Python 3.8+
- PyQt6

**Packaging Options:**
- **Binary:** `build/windows/dist/TideClient.exe`
- **Installer:** `build/windows/TideClient-Setup.exe` (requires NSIS)

## Architecture

```
client/
├── shared/
│   └── tide_gateway.py          # Platform-agnostic API client (stdlib only)
├── macos/
│   └── TideClient/
│       └── TideClient.swift     # Native Swift menu bar app
├── linux/
│   └── tide-client-qt.py        # PyQt6 system tray app
├── windows/
│   └── tide-client-qt.py        # Same as Linux (symlink)
├── build-macos.sh               # macOS build script
├── build-linux.sh               # Linux build script
├── build-windows.sh             # Windows build script
└── requirements.txt             # Python dependencies
```

### Shared Module (`shared/tide_gateway.py`)

Platform-agnostic Python module for gateway communication:
- **Zero external dependencies** - uses stdlib only (`urllib`, `socket`, `subprocess`)
- Gateway discovery (UDP beacon + default gateway + common IPs)
- HTTP API client (status, circuit, new circuit, check)
- System proxy configuration (macOS, Linux, Windows)

Used by all Python-based clients. Swift client has native implementation.

## Discovery Protocol

Clients discover the Tide Gateway using multiple methods:

1. **UDP Beacon** - Listen for broadcasts on port 19050
   ```
   Message format: "TIDE:<gateway_ip>"
   ```

2. **Default Gateway Check** - Query system's default gateway and test for Tide API

3. **Common IPs** - Try well-known gateway addresses:
   - `10.101.101.10` (Tide default)
   - `192.168.1.1`
   - `192.168.0.1`
   - `10.0.0.1`

4. **HTTP API Validation** - Verify gateway by checking `/status` endpoint:
   ```bash
   curl http://10.101.101.10:9051/status
   # Response: {"gateway":"tide","tor":"connected",...}
   ```

## Gateway API

All clients communicate with the gateway via HTTP API on port `9051`:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/status` | GET | Gateway status (mode, Tor connection, uptime) |
| `/circuit` | GET | Current Tor circuit info (exit IP, country) |
| `/newcircuit` | GET | Request new Tor circuit |
| `/check` | GET | Verify Tor connectivity |

Example:
```bash
# Get status
curl http://10.101.101.10:9051/status

# Request new circuit
curl http://10.101.101.10:9051/newcircuit
```

## System Proxy Configuration

### macOS
Uses `networksetup` command to configure SOCKS proxy:
```bash
networksetup -setsocksfirewallproxy "Wi-Fi" 10.101.101.10 9050
networksetup -setsocksfirewallproxystate "Wi-Fi" on
```

### Linux
Uses `gsettings` for GNOME:
```bash
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.socks host '10.101.101.10'
gsettings set org.gnome.system.proxy.socks port 9050
```

### Windows
Uses Windows registry:
```
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings
ProxyEnable = 1
ProxyServer = "socks=10.101.101.10:9050"
```

## Development

### Building from Source

**macOS:**
```bash
swiftc -o TideClient \
    macos/TideClient/TideClient.swift \
    -framework Cocoa \
    -framework Network \
    -O
```

**Linux/Windows:**
```bash
# Run directly
python3 linux/tide-client-qt.py

# Or build with PyInstaller
pyinstaller --onefile --windowed linux/tide-client-qt.py
```

### Testing

1. Start a Tide Gateway (Docker, VM, or bare-metal)
2. Ensure gateway is accessible on the network
3. Run client - it should auto-discover the gateway
4. Test connection, circuit refresh, and status display

### Debugging

Enable debug output:
```bash
# macOS
./TideClient 2>&1 | tee tide-client.log

# Linux/Windows
python3 -u linux/tide-client-qt.py 2>&1 | tee tide-client.log
```

Check gateway API manually:
```bash
# Discover gateway
nc -u -l 19050  # Listen for UDP beacon

# Test API
curl http://10.101.101.10:9051/status
```

## Customization

### Change Gateway IP

Edit the common IPs list in `shared/tide_gateway.py`:
```python
candidates = [
    "10.101.101.10",     # Default Tide IP
    "192.168.1.10",      # Your custom IP
    "192.168.0.1",
]
```

### Change Ports

Edit port constants in `shared/tide_gateway.py`:
```python
self.api_port = 9051    # HTTP API
self.socks_port = 9050  # SOCKS5 proxy
self.dns_port = 5353    # DNS
```

### Custom Icons

- **macOS:** Edit `createWaveIcon()` function in Swift
- **Linux/Windows:** Edit `_create_icon()` function in Python

## Troubleshooting

### macOS: "Cannot be opened because the developer cannot be verified"

```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine /Applications/TideClient.app

# Or allow in System Preferences > Security & Privacy
```

### Linux: System tray icon not showing

Install tray indicator support:
```bash
# GNOME
sudo apt install gnome-shell-extension-appindicator

# KDE
sudo apt install libappindicator3-1
```

### Windows: Proxy not applying

Run as Administrator (required for registry changes):
```bash
# Right-click TideClient.exe > Run as administrator
```

### Gateway not found

1. Check network connectivity: `ping 10.101.101.10`
2. Verify gateway is running: `curl http://10.101.101.10:9051/status`
3. Check firewall rules (allow port 9051)
4. Try manual gateway IP in client code

## Dependencies

### Python (Linux/Windows)
- Python 3.8+
- PyQt6 (GUI framework)
- PyInstaller (for packaging)

Install:
```bash
pip3 install -r requirements.txt
```

### macOS (Native)
- macOS 10.15+
- Xcode Command Line Tools
- Swift compiler (included with Xcode CLT)

Install:
```bash
xcode-select --install
```

### Build Tools (Optional)

- **macOS DMG:** `brew install create-dmg`
- **Linux AppImage:** `sudo apt install appimagetool`
- **Linux .deb:** `sudo apt install dpkg-dev`
- **Windows Installer:** Install NSIS from https://nsis.sourceforge.io/

## License

MIT - Same as Tide Gateway

## Contributing

1. Test on your platform
2. Report issues with logs
3. Submit PRs for improvements
4. Add support for new platforms

---

**[bodegga/tide](https://github.com/bodegga/tide)** | *Freedom within the shell.* 🌊
