# Tide Client

Cross-platform GUI client for connecting to Tide Gateway.

## Features

- **Auto-Discovery** - Finds Tide gateway automatically via mDNS
- **One-Click Connect** - Configures system proxy with single click
- **Status Display** - Shows Tor circuit, exit node, connection health
- **Tray Icon** - Quick access, minimal footprint

## Platforms

- macOS (native SwiftUI)
- Windows (native WPF)  
- Linux (GTK)

## Discovery Protocol

Tide Gateway announces itself via:

1. **mDNS** - `_tide._tcp.local` service
2. **DHCP Option** - Custom vendor option with gateway info
3. **Broadcast** - UDP beacon on port 19050

Client discovers gateway and displays:
- Gateway IP
- Tor status (connected/bootstrapping/offline)
- Current exit node country
- Latency

## API

Tide Gateway exposes a simple HTTP API on port 9051:

```
GET /status      - Gateway status
GET /circuit     - Current circuit info
GET /newcircuit  - Request new circuit
GET /check       - Tor connectivity check
```
