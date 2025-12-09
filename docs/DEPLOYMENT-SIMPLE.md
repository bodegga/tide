# Tide - Simple Deployment Guide

**Tested and working: Dec 2025**

## The Simple Way

### Docker Test Network (Proof of Concept)

```bash
# Start gateway + client
docker-compose -f docker-compose-test.yml up -d

# Wait 20 seconds for Tor to bootstrap
sleep 20

# Test from client
docker exec tide-client curl https://check.torproject.org/api/ip
```

**Expected:** `{"IsTor":true,"IP":"<some-tor-exit>"}`

### How It Works

1. **Gateway container** runs Tor with SOCKS5 on `10.101.101.10:9050`
2. **Client container** has `ALL_PROXY=socks5h://10.101.101.10:9050`
3. Client routes all traffic through gateway automatically

That's it. Standard Docker networking. Standard IPv4 routing. Nothing fancy.

## Real World Deployment

### Option A: Docker Compose (Any OS with Docker)

```bash
git clone https://github.com/bodegga/tide
cd tide
docker-compose up -d
```

Configure your apps to use SOCKS5 proxy: `localhost:9050`

### Option B: VM Gateway (Full Network)

1. Import `tide-gateway.qcow2` into your hypervisor (UTM/QEMU/Parallels)
2. Configure 2 NICs:
   - **eth0:** NAT/Bridged (internet access)
   - **eth1:** Host-Only network `10.101.101.0/24`
3. Gateway auto-configures at `10.101.101.10`
4. Connect client machines to Host-Only network
5. Set gateway: `10.101.101.10`

Done. All traffic routes through Tor.

## Why This Was Confusing

We kept trying to make it "transparent" (zero client configuration) which requires:
- iptables NAT on gateway
- DHCP server
- DNS forwarding
- Fail-closed firewall

**Reality:** Just use SOCKS5 proxy. It's simpler and works everywhere.

## Current Status

✅ **Docker SOCKS5 mode** - Working perfectly  
✅ **Docker test network** - Working (gateway + client)  
🚧 **VM gateway with DHCP** - In progress (cloud-init configured, needs testing)  

---

**For most users:** Docker SOCKS5 mode is enough.  
**For paranoid users:** VM gateway with fail-closed firewall.

