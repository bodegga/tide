# Tide Deployment Modes

## Quick Reference

| Mode | DHCP | Transparent | Fail-Closed | Use Case |
|------|------|-------------|-------------|----------|
| **Proxy** | ❌ | ❌ | ❌ | Single machine, manual config |
| **Router** | ✅ | ✅ | ❌ | Home lab, trusted network |
| **Forced** | ✅ | ✅ | ✅ | High security, paranoid users |
| **Takeover** | ✅ | ✅ | ✅ | Full subnet control (advanced) |

## Mode Details

### 1. Proxy Mode
**What it does:**
- Runs Tor with SOCKS5 on port 9050
- Runs Tor DNS on port 5353
- No DHCP server
- No transparent routing

**Client setup:**
- Configure each app manually
- SOCKS5: `10.101.101.10:9050`
- DNS: `10.101.101.10:5353`

**Use case:** Testing, single VM, manual control

### 2. Router Mode ⭐ (Default)
**What it does:**
- Runs DHCP server (assigns IPs automatically)
- Transparent TCP proxy (all traffic → Tor)
- DNS forwarding through Tor
- Basic firewall

**Client setup:**
- Connect to network
- Get DHCP automatically
- **That's it!** All traffic routes through Tor

**Use case:** Home lab, VM testing, trusted devices

### 3. Forced Mode
**What it does:**
- Everything from Router mode PLUS
- Fail-closed firewall (if Tor dies, traffic is BLOCKED)
- Only Tor process can reach internet
- Even root can't bypass Tor

**Client setup:**
- Same as Router (just connect)

**Use case:** Paranoid users, sensitive work, no leaks allowed

### 4. Takeover Mode ⚠️
**What it does:**
- Everything from Forced mode PLUS
- ARP hijacking to force ALL subnet traffic through gateway
- Intercepts traffic from devices that didn't configure gateway

**Client setup:**
- No setup needed - gateway hijacks traffic automatically

**Use case:** Full network control, pentesting, advanced users

**⚠️ WARNING:** May break legitimate network services. Use responsibly.

## Docker Configuration

Set mode in `.env` file:

```bash
# Copy example config
cp .env.example .env

# Edit mode
vim .env
TIDE_MODE=router  # Change to: proxy, router, forced, or takeover
```

Then start:

```bash
docker-compose -f docker-compose-test.yml up -d
```

## Current Status

✅ **Proxy mode** - Working (Docker + VM)  
✅ **Router mode** - Working (Docker, VM needs testing)  
🚧 **Forced mode** - In development  
🚧 **Takeover mode** - In development  

---

**Recommended:** Start with **Router mode** for easiest setup.
