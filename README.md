# 🌊 Tide Gateway

**Dead-simple Tor gateway.** Two deployment options:

## Option 1: Docker Container (Easiest)

```bash
# Run Tide as a container
docker run -d --name tide -p 9050:9050 -p 5353:5353 bodegga/tide

# Or with docker-compose
git clone https://github.com/bodegga/tide.git && cd tide
docker-compose up -d
```

Configure your apps:
- **SOCKS5 Proxy:** `localhost:9050`
- **DNS:** `localhost:5353`

Test it:
```bash
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip
```

## Option 2: VM Gateway (Full Transparency)

Routes ALL traffic from client VMs through Tor automatically.

### UTM / QEMU (Mac/Linux)

Download from [Releases](https://github.com/bodegga/tide/releases):
- `tide-gateway.qcow2`
- `cloud-init.iso`

1. Create VM → Import qcow2 as boot disk
2. Attach cloud-init.iso as CD
3. Add 2 NICs: Shared + Host-Only  
4. Boot (auto-configures in ~2 min)

### VMware / VirtualBox / Hyper-V

```bash
# Boot Alpine ISO, login as root, run:
wget -qO- https://raw.githubusercontent.com/bodegga/tide/main/tide-install.sh | sh
```

### After VM Setup

**Login:** `root` / `tide`  
**Gateway IP:** `10.101.101.10`

Configure client VMs:
| Setting | Value |
|---------|-------|
| IP | `10.101.101.x` (11-99) |
| Gateway | `10.101.101.10` |
| DNS | `10.101.101.10` |

Test: Visit https://check.torproject.org in client browser.

---

## How It Works

**Docker mode:** Apps connect to Tor via SOCKS5 proxy.

**VM mode:** All traffic is transparently redirected through Tor:
```
Client VM → Tide Gateway (iptables) → Tor Network → Internet
```

---

## Building

```bash
# Build Docker image
docker build -t tide .

# Build VM images (requires QEMU)
./build-release.sh
```

---

## Security Notes

- Default password is `tide` - change it in production
- IPv6 disabled to prevent leaks
- All DNS queries go through Tor

---

**[bodegga/tide](https://github.com/bodegga/tide)** | Alpine Linux + Tor
