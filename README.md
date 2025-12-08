# Tide

**Privacy gateway for Apple Silicon**

Your invisible connection to the internet. Free, open-source, untraceable.

---

## What is Tide?

Tide is a transparent Tor proxy gateway that routes all your internet traffic through the Tor network, protecting your identity and location. Built for Apple Silicon Macs (M1/M2/M3/M4).

**From Bodegga. Built in Petaluma, CA.** 🌊

---

## Features

- ✅ **Tor transparent proxy** - All traffic automatically routed through Tor
- ✅ **DNS leak prevention** - No DNS queries leak to your ISP
- ✅ **.onion support** - Access hidden services built-in
- ✅ **Fail-closed firewall** - Secure by default, no accidental leaks
- ✅ **Apple Silicon optimized** - Native ARM64 for M1/M2/M3/M4
- ✅ **Multi-hypervisor** - Works with Parallels, UTM, VMware, VirtualBox

---

## Quick Start

### Requirements
- Apple Silicon Mac (M1/M2/M3/M4)
- Parallels Desktop or UTM (free alternative)
- 1GB RAM (for gateway VM)
- 3GB disk space

### Installation (2 minutes)

1. **Download** the latest release:
   ```bash
   curl -LO https://github.com/bodegga/tide/releases/download/v1.0.0/tide-gateway-v1.0-arm64.tar.gz
   ```

2. **Extract** to Parallels directory:
   ```bash
   tar -xzf tide-gateway-v1.0-arm64.tar.gz -C ~/Parallels/
   ```

3. **Register** with Parallels:
   ```bash
   prlctl register ~/Parallels/Tor-Gateway.pvm
   ```

4. **Start** the gateway:
   ```bash
   prlctl start Tor-Gateway
   ```

5. **Configure** your workstation VM to use `10.152.152.10` as gateway

Done! Your traffic now flows through Tor.

---

## Workstation Setup

Configure your secure workstation VM to route through Tide:

```bash
# Edit network config
sudo nano /etc/network/interfaces
```

Add:
```
auto eth0
iface eth0 inet static
    address 10.152.152.11
    netmask 255.255.255.0
    gateway 10.152.152.10
    dns-nameservers 10.152.152.10
```

Restart networking:
```bash
sudo systemctl restart networking
```

Test:
```bash
curl https://check.torproject.org/api/ip
# Should return: {"IsTor":true}
```

---

## Architecture

```
Internet
   ↑
   | (Tor encrypted)
   |
[Tide Gateway VM]
   | 10.152.152.10
   |
[Your Workstation VM]
   | 10.152.152.11
   |
Your applications
```

- All workstation traffic → Gateway → Tor network → Internet
- DNS requests → Tor (no leaks)
- Transparent proxy (no app configuration needed)
- Fail-closed firewall (secure by default)

---

## Verification

**Check your IP is hidden:**
```bash
curl https://api.ipify.org
# Should show Tor exit node IP, NOT your real IP
```

**Verify Tor is working:**
```bash
curl https://check.torproject.org/api/ip
# Should return: {"IsTor":true}
```

**Test DNS:**
```bash
nslookup google.com
# Server should be 10.152.152.10 (the gateway)
```

---

## Security Notes

### What Tide Protects
✅ Hides your real IP address  
✅ Prevents ISP monitoring  
✅ Encrypts all traffic through Tor  
✅ Prevents DNS leaks  
✅ Blocks accidental clearnet connections  

### What Tide Doesn't Protect
⚠️ Browser fingerprinting (use Tor Browser for max anonymity)  
⚠️ Malware on your workstation  
⚠️ Physical access to your Mac  
⚠️ State-level adversaries with advanced capabilities  

### Best Practices
- Use Tor Browser on workstation for sensitive browsing
- Keep both VMs updated
- Create VM snapshots before updates
- Review firewall logs periodically

---

## Troubleshooting

**Gateway won't start:**
```bash
prlctl start Tor-Gateway
prlctl status Tor-Gateway
```

**Workstation not routing:**
- Verify gateway is set to `10.152.152.10`
- Ping gateway: `ping 10.152.152.10`
- Check DNS: `cat /etc/resolv.conf`

**Check Tor status on gateway:**
```bash
# (Requires Parallels Tools installed)
prlctl exec Tor-Gateway sudo systemctl status tor
```

---

## Configuration

**Gateway:**
- IP: `10.152.152.10`
- SOCKS Port: `9050` (localhost only)
- DNS Port: `53`
- TransPort: `9040`

**Workstation:**
- IP: `10.152.152.11`
- Gateway: `10.152.152.10`
- DNS: `10.152.152.10`

---

## Building From Source

Want to build your own gateway? See [BUILD.md](BUILD.md) for instructions.

---

## About

**Tide** is built by [Bodegga](https://tide.bodegga.net), a Petaluma, California-based software company.

Like the Petaluma River's tide that ebbs and flows—revealing and concealing the riverbed—Tide protects your digital footprint, leaving no trace behind.

**Privacy flows naturally.** 🌊

---

## License

MIT License - See [LICENSE](LICENSE) for details

---

## Support

- **Issues:** [GitHub Issues](https://github.com/bodegga/tide/issues)
- **Discussions:** [GitHub Discussions](https://github.com/bodegga/tide/discussions)
- **Security:** Report vulnerabilities via GitHub Security Advisories

---

**Built in Petaluma, CA**  
**A Bodegga product**

Privacy for everyone. Free forever.

## Quick Install

**One-liner:**
```bash
curl -sSL https://tide.bodegga.net/install.sh | bash
```

Or manual:
```bash
curl -LO https://github.com/bodegga/tide/releases/download/v1.0.0/tide-gateway-v1.0-arm64.tar.gz
tar -xzf tide-gateway-v1.0-arm64.tar.gz -C ~/Parallels/
prlctl register ~/Parallels/Tor-Gateway.pvm
prlctl start Tor-Gateway
```

---

**Website:** https://tide.bodegga.net  
**GitHub:** https://github.com/bodegga/tide  
**Download:** https://github.com/bodegga/tide/releases/latest
