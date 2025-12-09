# Tide Gateway - Docker Quick Start

**Status:** ✅ Working on macOS (tested Dec 2025)

## What This Does

Runs a Tor proxy in a Docker container on your laptop. Apps configure SOCKS5 proxy to route through Tor.

## Quick Start

```bash
# Start Tide
docker-compose up -d

# Verify it's running
docker ps | grep tide

# Test Tor connection
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip
```

**Expected output:** `{"IsTor":true,"IP":"<some-tor-exit-ip>"}`

## Configuration

- **SOCKS5 Proxy:** `localhost:9050`
- **DNS over Tor:** `localhost:9053` (UDP)

### Configure Apps

**Browser (Firefox):**
1. Settings → Network Settings → Manual proxy
2. SOCKS5: `localhost` Port: `9050`
3. Check "Proxy DNS when using SOCKS v5"

**Command Line:**
```bash
# One-off command
curl --socks5-hostname localhost:9050 https://example.com

# Set env vars (bash/zsh)
export ALL_PROXY=socks5h://localhost:9050
curl https://check.torproject.org/api/ip
```

**Git:**
```bash
git config --global http.proxy socks5h://localhost:9050
git config --global https.proxy socks5h://localhost:9050
```

## Container Management

```bash
# View logs
docker logs tide-gateway

# Restart container
docker-compose restart

# Stop Tide
docker-compose down

# Force new Tor circuit
docker exec tide-gateway pkill -HUP tor
```

## Verify Tor is Working

```bash
# Check your real IP
curl https://check.torproject.org/api/ip

# Check through Tor
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip

# Should show different IP and "IsTor":true
```

## Troubleshooting

**Port 9053 already in use?**

macOS uses port 5353 for mDNS. Tide maps to 9053 to avoid conflict.

**Tor won't start?**

Check logs:
```bash
docker logs tide-gateway | grep -i error
```

Restart:
```bash
docker-compose restart
```

**Slow connections?**

Tor can be slow. Wait 30-60 seconds after starting for Tor to bootstrap.

Check bootstrap status:
```bash
docker logs tide-gateway | grep Bootstrap
```

Look for: `Bootstrapped 100% (done): Done`

## macOS Specific Notes

- **Host networking doesn't work** - Use port mapping instead
- **Port 5353 is reserved** - DNS mapped to 9053
- Tested on: macOS with Docker Desktop

## Security Notes

- This is **proxy mode** - only apps you configure use Tor
- System traffic still goes direct (not leak-proof)
- For full isolation, use gateway VM mode (advanced)

---

**Project:** [bodegga/tide](https://github.com/bodegga/tide)  
**Mode:** Docker SOCKS5 Proxy  
**Status:** Production Ready ✅
