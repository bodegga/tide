# Tide - Dead Simple Tor Gateway

**One command. Your laptop routes through Tor. Done.**

## Install (30 seconds)

```bash
# Download and run
curl -fsSL https://raw.githubusercontent.com/bodegga/tide/main/install.sh | sh

# That's it. Everything goes through Tor now.
```

## Verify It Works

```bash
# Check your IP is coming from Tor
curl https://check.torproject.org/api/ip
```

Should show: `{"IsTor":true,"IP":"<some-tor-exit>"}`

## What Just Happened?

Tide installed a tiny Docker container that:
- ✅ Routes all traffic through Tor automatically
- ✅ Blocks non-Tor traffic (fail-closed)
- ✅ Starts on boot
- ✅ Updates itself

## Uninstall

```bash
tide uninstall
```

---

## Advanced: Docker Only (No Install Script)

```bash
# Clone repo
git clone https://github.com/bodegga/tide
cd tide

# Start
docker-compose up -d

# Verify
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip
```

**Note:** This is SOCKS proxy mode - you configure apps manually. Not transparent routing.

---

**That's the vision. One command = Tor gateway.**
