# Tide - Quick Start (Default Mode)

## One Command Setup

```bash
docker-compose up -d
```

That's it! Tide Gateway is now running in **Router Mode**.

## What Just Happened?

Tide started a gateway that:
- ✅ Runs Tor with transparent proxy
- ✅ Runs DHCP server (10.101.101.100-200)
- ✅ Automatically routes all traffic through Tor

## Connect a Device

Any device that connects to the `tide_tidenet` network will:
1. Get an IP via DHCP automatically
2. Get gateway configured (10.101.101.10)
3. Get DNS configured (10.101.101.10)
4. Route ALL traffic through Tor automatically

**No SOCKS5 configuration needed. No manual setup. Just connect.**

## Test It

```bash
# Test with a client container
docker run --rm --network tide_tidenet alpine sh -c "
  apk add curl &&
  udhcpc -i eth0 -n -q &&
  curl https://check.torproject.org/api/ip
"
```

Should return: `{"IsTor":true,"IP":"<tor-exit-ip>"}`

## What If I Want Proxy Mode Instead?

If you prefer manual SOCKS5 configuration:

```bash
# Stop router mode
docker-compose down

# Start proxy mode
docker-compose -f docker-compose.proxy.yml up -d

# Configure apps
# SOCKS5: localhost:9050
# DNS: localhost:9053
```

## Why Router Mode is Default

Router Mode gives you:
- Zero client configuration
- Automatic DHCP
- Transparent routing (apps don't need to know about Tor)
- Works with any device/OS

Proxy Mode requires:
- Manual SOCKS5 configuration in every app
- Apps that support SOCKS5
- Can leak if misconfigured

**Router Mode is simpler and safer.**

---

**See also:**
- [START-HERE.md](START-HERE.md) - All modes explained
- [README-MODES.md](README-MODES.md) - Mode comparison
