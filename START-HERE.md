# 🌊 Tide Gateway - Start Here

## Pick Your Mode

Tide has 2 deployment modes (4 planned):

### ✅ Router Mode (Default) ⭐ **RECOMMENDED**
**Best for:** Multiple devices, automatic setup

```bash
docker-compose up -d
```

Connect devices to `tidenet` network - they get DHCP automatically and ALL traffic routes through Tor.

### ✅ Proxy Mode (Alternative)
**Best for:** Single machine, manual control

```bash
docker-compose -f docker-compose.proxy.yml up -d
```

Then configure apps:
- SOCKS5: `localhost:9050`
- DNS: `localhost:9053`

### 🚧 Forced Mode (Coming Soon)
Router + fail-closed firewall (no leaks possible)

### 🚧 Takeover Mode (Coming Soon)
Forced + ARP hijacking (full network control)

---

## Quick Test

### Proxy Mode
```bash
docker-compose up -d
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip
```

### Router Mode
```bash
# Start gateway
docker-compose -f docker-compose.router.yml up -d

# Test with client
docker run --rm --network tide_tidenet alpine sh -c "
  apk add curl &&
  udhcpc -i eth0 -n -q &&
  curl https://check.torproject.org/api/ip
"
```

Both should return: `{"IsTor":true,"IP":"<tor-exit-ip>"}`

---

## Configuration

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
vim .env
```

Settings:
- `TIDE_MODE`: proxy, router, forced, takeover
- `TIDE_SECURITY`: standard, hardened, paranoid, bridges
- `TIDE_GATEWAY_IP`: Gateway IP (default: 10.101.101.10)
- `TIDE_SUBNET`: Network subnet (default: 10.101.101.0/24)

---

## Documentation

- **[README.md](README.md)** - Full project overview
- **[README-MODES.md](README-MODES.md)** - Mode comparison & details
- **[DOCKER-QUICKSTART.md](DOCKER-QUICKSTART.md)** - Proxy mode guide
- **[DEPLOYMENT-SIMPLE.md](DEPLOYMENT-SIMPLE.md)** - Simplified deployment guide

---

## Status

| Feature | Status |
|---------|--------|
| Proxy Mode (SOCKS5) | ✅ Working |
| Router Mode (DHCP + Transparent) | ✅ Working (Default) |
| Client GUI Application | 🚧 v1.1 - In Development |
| Takeover Mode (ARP hijack) | 🚧 v1.2 - In Development |
| Forced Mode (Fail-closed) | 📋 v1.3 - Planned |
| VM Images (qcow2/OVA) | 📋 v1.5 - Planned |

**Last tested:** Dec 9, 2025  
**Test results:** DHCP + transparent routing fully working in Docker  
**Current version:** 1.2.0  
**Next release:** 1.3 (Forced Mode - fail-closed)

See **[ROADMAP.md](ROADMAP.md)** for full development plan.

---

**Get started:** Pick a mode above and run the commands. That's it!
