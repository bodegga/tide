# ⚠️ FORCED MODE - AGGRESSIVE NETWORK TAKEOVER

## WARNING: MAXIMUM AGGRESSION

**Forced Mode** is designed to be **ABSOLUTELY RUTHLESS** in intercepting network traffic. 

### What It Does

When you enable `TIDE_MODE=forced`, the gateway becomes a **network tyrant**:

1. **ARP Poisoning**: Continuously broadcasts fake ARP packets claiming to be the default gateway
2. **Proxy ARP**: Responds to ARP requests for ANY IP address on the subnet
3. **Promiscuous Mode**: Captures ALL packets on the network segment
4. **Fail-Closed Firewall**: If Tor dies, ALL traffic is BLOCKED (not leaked)
5. **Aggressive DHCP**: Authoritative DHCP server overrides other DHCP servers
6. **Network Scanning**: Actively scans for new devices and poisons them immediately
7. **Traffic Hijacking**: Redirects ALL TCP traffic through Tor TransPort
8. **DNS Interception**: Forces ALL DNS queries through Tor

---

## The Attack Vector

### ARP Poisoning
```
🎯 Target Device (192.168.1.100)
   "Who has 192.168.1.1?" (ARP Request for gateway)
   
💉 Tide Gateway (10.101.101.10)
   "I am 192.168.1.1!" (Gratuitous ARP - LIE)
   
🎯 Target Device
   Updates ARP table: 192.168.1.1 → [Tide's MAC]
   Now sends ALL traffic to Tide instead of real gateway
```

### Techniques Used

1. **Gratuitous ARP Broadcasting**
   - Sends unsolicited ARP replies every 2 seconds
   - Claims to be the default gateway (`.1`)
   - Broadcasts to entire subnet

2. **Targeted ARP Poisoning**
   - Discovers active hosts via nmap
   - Sends targeted ARP replies to each device
   - Maintains individual poisoning loops

3. **Proxy ARP**
   - Kernel responds to ARP requests for ANY IP
   - Makes gateway appear to be every possible address
   - Intercepts traffic meant for other devices

4. **Network Monitoring**
   - Continuously scans subnet every 10 seconds
   - Detects new devices joining network
   - Immediately poisons new targets

5. **Promiscuous Mode**
   - NIC accepts all packets (not just addressed to it)
   - Allows packet inspection and interception
   - Works in conjunction with iptables redirection

---

## Firewall Rules (Fail-Closed)

### Policy: DEFAULT DROP
```bash
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

**Translation**: NOTHING is allowed unless explicitly permitted.

### OUTPUT Chain (Gateway Can't Leak)
```bash
# ONLY the Tor process (UID 101) can connect to internet
iptables -A OUTPUT -m owner --uid-owner tor -p tcp -j ACCEPT

# Everything else is LOGGED and DROPPED
iptables -A OUTPUT -j LOG --log-prefix "TIDE-BLOCKED-OUTPUT: "
iptables -A OUTPUT -j DROP
```

**Result**: Even if someone gets root on the gateway, they CANNOT bypass Tor.

### FORWARD Chain (No Routing)
```bash
# We don't route, we PROXY
iptables -A FORWARD -j LOG --log-prefix "TIDE-BLOCKED-FORWARD: "
iptables -A FORWARD -j DROP
```

**Translation**: Any attempt to route through the gateway is BLOCKED and LOGGED.

---

## DHCP Aggression

```
dhcp-authoritative    # Override other DHCP servers
dhcp-option=3,10.101.101.10  # Force gateway to Tide
dhcp-option=6,10.101.101.10  # Force DNS to Tide
```

**Result**: Devices that request DHCP get Tide as their gateway, even if another DHCP server exists.

---

## Network Topology

### Before Tide (Normal Network)
```
Device → Real Gateway (192.168.1.1) → ISP → Internet
```

### After Tide FORCED Mode
```
Device → [ARP POISON] → Tide Gateway → Tor → Internet
              ↓
       (thinks Tide IS the gateway)
```

**The real gateway becomes irrelevant** - all traffic is intercepted before it even reaches it.

---

## Use Cases

### ✅ **Appropriate Use:**
- **VM Lab**: Forcing all VMs through Tor for security testing
- **Home Network**: Protecting all devices on your own network
- **Pentesting**: Testing network security posture
- **Privacy Network**: Family network where all devices must use Tor

### ❌ **DO NOT USE:**
- **Corporate Networks**: You'll get fired (and possibly arrested)
- **Public WiFi**: Illegal in most jurisdictions
- **Someone else's network**: That's called hacking
- **Production environments**: Without explicit authorization

---

## Legal Warnings

### ⚠️ United States
- **Computer Fraud and Abuse Act (CFAA)**: Unauthorized network access is a federal crime
- **Wire Fraud**: Intercepting network communications without consent
- **Penalty**: Up to 10 years in prison

### ⚠️ European Union  
- **GDPR**: Intercepting personal data without consent
- **Computer Misuse Act** (UK): Unauthorized network modification
- **Penalty**: Heavy fines and imprisonment

### ⚠️ International
- Most countries have similar laws against unauthorized network interference

---

## Technical Risks

### Network Instability
- **ARP Cache Corruption**: Devices may lose connectivity
- **Duplicate IP Detection**: May trigger network alarms
- **DHCP Conflicts**: Other DHCP servers may fight back
- **Switch Confusion**: Managed switches may detect attack

### Detection
- **IDS/IPS**: Intrusion detection systems will flag ARP poisoning
- **Network Monitoring**: Tools like Wireshark will see gratuitous ARP
- **Smart Devices**: Some devices detect and block ARP attacks
- **Enterprise Switches**: May have ARP protection features

---

## Stopping FORCED Mode

### Graceful Shutdown
```bash
# Stop the gateway
docker-compose down

# OR send SIGTERM
docker kill -s SIGTERM tide-gateway-router
```

### Emergency Stop
```bash
# Nuclear option
docker kill tide-gateway-router

# Then manually fix ARP on affected devices
# Most devices will recover in 1-2 minutes
```

### ARP Cache Recovery
Devices will eventually recover as their ARP caches timeout (typically 60-120 seconds), but you can speed it up:

**Windows:**
```cmd
arp -d
ipconfig /flushdns
```

**macOS/Linux:**
```bash
sudo ip -s -s neigh flush all
sudo arp -d -a
```

---

## Monitoring FORCED Mode

### Check if ARP poisoning is active
```bash
docker exec tide-gateway-router ps aux | grep arping
```

### Watch firewall blocks
```bash
docker logs -f tide-gateway-router | grep BLOCKED
```

### Check poisoned devices
```bash
docker exec tide-gateway-router cat /tmp/tide-seen-hosts
```

---

## Comparison: Router vs FORCED

| Feature | Router Mode | FORCED Mode |
|---------|-------------|-------------|
| **DHCP** | Polite | Authoritative |
| **ARP** | Normal | POISONED |
| **Firewall** | Basic | Fail-Closed |
| **Aggression** | Low | **MAXIMUM** |
| **Interception** | Clients must configure | **ALL traffic captured** |
| **Legal Risk** | Low | **HIGH if misused** |
| **Escape Prevention** | Optional | **ABSOLUTE** |

---

## Bottom Line

**FORCED Mode** is designed for scenarios where you need **ABSOLUTE CERTAINTY** that ALL traffic on a subnet goes through Tor, with NO exceptions, NO escapes, and NO bypasses.

It is **intentionally aggressive** and will **actively fight** to control the network.

**Use responsibly. You have been warned.**

---

*"Route through Tor or NOTHING." - Tide Gateway Philosophy*
