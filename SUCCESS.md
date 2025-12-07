# ✅ TOR GATEWAY SUCCESSFULLY CONFIGURED

**Date:** 2025-12-07  
**Status:** 🟢 WORKING  

---

## What's Working

✅ **Tor-Gateway VM** - Routing all traffic through Tor  
✅ **SecuredWorkstation VM** - All traffic forced through Gateway  
✅ **Network isolation** - Workstation has no direct internet access  
✅ **Tor verification** - `check.torproject.org` confirms Tor usage  
✅ **IP anonymization** - Public IP checks show Tor exit node, NOT home IP  

---

## Final Configuration

### Tor-Gateway VM

**Interfaces:**
- `enp0s5`: 10.37.129.5/24 (Parallels Shared Network - internet access)
- `enp0s10`: 10.152.152.10/24 (Host-Only - internal network to Workstation)

**Tor Configuration (`/etc/tor/torrc`):**
```
TransPort 10.152.152.10:9040
DNSPort 10.152.152.10:53
SocksPort 127.0.0.1:9050
```

**Firewall (`/etc/nftables.conf`):**
- Loaded from: `https://paste.rs/Jse4z`
- Redirects all Workstation DNS to Tor DNSPort (53)
- Redirects all Workstation TCP to Tor TransPort (9040)
- NAT masquerade for traffic going to internet

**IP Forwarding:** Enabled (`net.ipv4.ip_forward=1`)

### SecuredWorkstation VM

**Network:**
- Static IP: 10.152.152.11/24
- Gateway: 10.152.152.10
- DNS: 10.152.152.10

**Isolation:** No direct internet access - all traffic routed through Tor-Gateway

---

## Testing Commands

### From Workstation - Verify Tor Usage

```bash
# Check public IP (should show Tor exit node)
curl https://icanhazip.com
curl https://api.ipify.org

# Verify Tor status
curl https://check.torproject.org/api/ip
# Should return: {"IsTor":true,"IP":"<tor-exit-ip>"}

# DNS leak test
nslookup google.com
# Should resolve through Gateway's Tor DNSPort
```

### From Gateway - Maintenance

```bash
# Check Tor status
sudo systemctl status tor
sudo journalctl -u tor | grep Bootstrapped | tail -1

# Verify Tor listening ports
sudo ss -tlnp | grep 9040
sudo ss -unlp | grep :53

# Check firewall rules
sudo nft list ruleset

# Monitor Tor logs
sudo journalctl -u tor -f
```

---

## Architecture Diagram

```
Internet
   ↑
   | (Tor encrypted)
   |
[Tor-Gateway VM]
   | enp0s5: 10.37.129.5 (Parallels Shared Network)
   |
   | Tor Daemon
   | - TransPort: 9040
   | - DNSPort: 53
   |
   | enp0s10: 10.152.152.10 (Host-Only)
   ↓
[SecuredWorkstation VM]
   | 10.152.152.11
   | Gateway: 10.152.152.10
   | DNS: 10.152.152.10
   |
   ↓ All traffic forced through Gateway
```

---

## Known Issues & Notes

### DNS Port Configuration
- Initially tried port 5353 (standard Tor DNSPort)
- Had to use port 53 instead after disabling `systemd-resolved`
- Port 53 works correctly with NAT redirect rules

### Interface Names
- Parallels uses `enp0sX` naming (not `eth0/eth1`)
- Had to create interface-agnostic firewall rules
- Used IP subnet matching instead of interface names where possible

### Firewall Evolution
- Started with strict `policy drop` - blocked Tor bootstrap
- Used permissive rules to allow Tor to connect first
- Can add stricter rules later once stable

---

## Security Considerations

### Current Threat Protection

✅ **Network surveillance** - Traffic exits via Tor, not home IP  
✅ **IP correlation** - Workstation cannot discover real IP  
✅ **DNS leaks** - All DNS goes through Tor DNSPort  
✅ **Isolation** - Workstation has no direct internet path  

### Known Limitations

⚠️ **Parallels instead of UTM** - Closed source, not recommended by Kicksecure guide  
⚠️ **No host hardening yet** - macOS swap not disabled (VM memory could leak to disk)  
⚠️ **No FileVault verification** - Host encryption status unknown  
⚠️ **Permissive firewall** - Gateway can still make direct connections (should restrict to Tor user only)  
⚠️ **No snapshot mode** - VMs writing to persistent disk  

---

## Next Steps (Optional Hardening)

### 1. Restrict Gateway Firewall (High Priority)

Currently the Gateway can make direct internet connections. Should only allow `debian-tor` user:

```bash
# Add to firewall output chain
meta skuid debian-tor accept
# Remove blanket accept rules
```

### 2. macOS Host Hardening

**Disable swap (prevents VM memory leaks):**
```bash
# Boot to Recovery Mode
csrutil disable
# After reboot
sudo nvram boot-args="vm_compressor=2"
sudo pmset -a hibernatemode 0
sudo rm /private/var/vm/sleepimage
```

**Verify FileVault enabled:**
```bash
# System Settings → Privacy & Security → FileVault
```

**Disable Spotlight for VMs:**
```bash
sudo mdutil -i off ~/Parallels/
```

### 3. Enable Snapshot Mode (Anti-Forensics)

Configure VMs to run in snapshot mode - all changes discarded on shutdown.

### 4. Consider Migrating to UTM

For better security posture (open source, better anti-forensics):
- Export current VM configurations
- Recreate in UTM with same network setup
- Use QEMU backend for better isolation

### 5. Install Kicksecure Hardening

On both VMs:
```bash
# Add Kicksecure repository
sudo apt-key --keyring /etc/apt/trusted.gpg.d/derivative.gpg adv \
  --keyserver keyserver.ubuntu.com \
  --recv-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA

echo "deb [signed-by=/etc/apt/trusted.gpg.d/derivative.gpg] \
  https://deb.kicksecure.com bookworm main contrib non-free" \
  | sudo tee /etc/apt/sources.list.d/derivative.list

sudo apt update
sudo apt install kicksecure-cli
```

---

## Files & Resources

### Project Directory
`/Users/abiasi/Documents/Personal-Projects/opsec-vm/`

### Key Files
- `SESSION_RECOVERY_2025-12-07.md` - Initial setup documentation
- `TOR_GATEWAY_FIX.md` - Detailed Tor configuration guide
- `gateway-firewall-fixed.nft` - Working firewall configuration
- `fix-tor-gateway.sh` - Automated setup script (for reference)

### VMs
- `~/Parallels/Tor-Gateway.pvm/`
- `~/Parallels/SecuredWorkstation.pvm/`

### Reference Documentation
- `~/Downloads/compass_artifact_wf-56d85f30-4eb1-4e22-8139-35d05d727838_text_markdown.md`
  - Complete Kicksecure/Whonix guide for Apple Silicon

### Paste.rs Links
- Final firewall config: `https://paste.rs/Jse4z`

---

## Troubleshooting

### Workstation shows home IP
```bash
# On Gateway, check Tor bootstrap
sudo journalctl -u tor | grep Bootstrapped | tail -1

# Should show 100%
# If not, wait or restart Tor
sudo systemctl restart tor
```

### Workstation has no internet
```bash
# On Workstation, verify network config
ip addr show
ip route
cat /etc/resolv.conf

# Gateway should be 10.152.152.10
# DNS should be 10.152.152.10
```

### Gateway can't reach internet
```bash
# Check if firewall blocking everything
sudo nft list ruleset | grep "policy drop"

# Verify default route exists
ip route

# Should show route via Parallels network (10.37.129.1)
```

### Tor won't bootstrap
```bash
# Check Tor logs for errors
sudo journalctl -u tor -n 50

# Verify Tor can reach internet
# (Temporarily flush firewall if needed)
sudo nft flush ruleset
sudo systemctl restart tor
```

---

## Success Metrics

**This setup is considered successful if:**

1. ✅ Workstation public IP checks show Tor exit node (not home IP)
2. ✅ `check.torproject.org` returns `{"IsTor":true}`
3. ✅ DNS queries resolve through Tor (no leaks to ISP DNS)
4. ✅ Workstation cannot ping real internet IPs directly (only through Gateway)
5. ✅ Tor circuit remains stable (no disconnects)
6. ✅ Gateway Tor bootstrap stays at 100%

**All criteria met as of 2025-12-07 15:30 PST** ✅

---

**🎉 Congratulations! You have a working Whonix-style Tor Gateway on Apple Silicon. 🎉**
