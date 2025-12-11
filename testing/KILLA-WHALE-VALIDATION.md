# Killa Whale Mode - Validation Testing

**Purpose:** Confirm that killa-whale mode actually works as advertised

**Last Updated:** December 11, 2025

---

## The Problem

We've been testing if killa-whale **mode is enabled**, but NOT if it **actually functions**.

**What we WERE testing:**
- ✅ Mode file says "killa-whale"
- ✅ Services are running

**What we WEREN'T testing:**
- ❌ Does ARP poisoning actually work?
- ❌ Is traffic actually intercepted?
- ❌ Are victims forced through Tor?
- ❌ Can victims bypass it?

---

## What Killa Whale Mode Claims To Do

From `scripts/runtime/gateway-start.sh`:

```bash
echo "🐋 Mode: KILLA WHALE - AGGRESSIVE NETWORK TAKEOVER"
echo "   ⚠️  MAXIMUM AGGRESSION: All subnet traffic WILL be intercepted"
echo "   ⚠️  ARP poisoning, IP hijacking, fail-closed enforcement"
echo "   ⚠️  NOTHING escapes without going through Tor"
```

**Specific tactics:**
1. **ARP Poisoning** - Spoof as default gateway
2. **Promiscuous Mode** - Capture all packets on network
3. **IP Forwarding** - Route intercepted traffic
4. **Transparent Proxy** - Force TCP through Tor port 9040
5. **DNS Hijacking** - Force DNS through Tor port 5353
6. **Fail-Closed Firewall** - Block ALL non-Tor traffic
7. **Continuous Monitoring** - Detect and poison new devices

---

## Comprehensive Test Suite

### Test Setup

**Infrastructure:**
- 2 Hetzner Cloud servers (CPX11 ARM)
- Private network (10.101.101.0/24) simulating LAN
- Tide Gateway: Running killa-whale mode
- Victim Device: Standard Ubuntu, no Tor config

**Cost:** ~$0.02 per test (2 servers × 5 minutes × $0.01/hr)

**Location:** Hillsboro, OR (real ARM hardware)

### TEST 1: ARP Poisoning Detection ⭐ CRITICAL

**What it tests:**
- Does Tide successfully poison victim's ARP cache?
- Does victim think Tide is the default gateway?

**Method:**
```bash
# On victim:
arp -a  # Check ARP table

# Compare:
TIDE_MAC=$(get MAC from Tide's eth1)
GATEWAY_MAC=$(get MAC from victim's ARP entry for 10.101.101.1)

# Should match if poisoning works
```

**Pass criteria:**
- ✅ Victim's ARP table shows Tide's MAC for gateway IP
- ✅ Gateway IP (10.101.101.1) resolves to Tide's MAC address

**Failure indicates:**
- ARP spoofing not sending packets
- ARP packets being filtered
- Network doesn't support ARP spoofing
- arp-takeover.sh script not running

---

### TEST 2: Default Gateway (Routing Table) ⭐ CRITICAL

**What it tests:**
- Is Tide set as the victim's default gateway?
- Will victim send all traffic to Tide?

**Method:**
```bash
# On victim:
route -n
# Check if default route (0.0.0.0) points to 10.101.101.1
```

**Pass criteria:**
- ✅ Default gateway is 10.101.101.1
- ✅ All non-local traffic routes to gateway

**Failure indicates:**
- DHCP not configuring gateway correctly
- Static routes interfering
- Network configuration issue

---

### TEST 3: DNS Hijacking

**What it tests:**
- Does tide.bodegga.net resolve to Tide's IP?
- Is dnsmasq DNS hijacking working?

**Method:**
```bash
# On victim:
nslookup tide.bodegga.net
# Should return 10.101.101.10 (Tide's IP)
```

**Pass criteria:**
- ✅ tide.bodegga.net → 10.101.101.10
- ✅ DNS server is Tide Gateway

**Failure indicates:**
- dnsmasq not running
- DNS hijacking rules not configured
- Victim using hardcoded DNS (8.8.8.8)

---

### TEST 4: Transparent HTTP Interception ⭐⭐⭐ MOST CRITICAL

**What it tests:**
- Can victim reach internet WITHOUT configuring SOCKS proxy?
- Is traffic transparently routed through Tor?

**Method:**
```bash
# On victim (NO SOCKS configuration):
curl http://check.torproject.org/api/ip

# Should return:
# {"IsTor": true, "IP": "<tor-exit-ip>"}
```

**Pass criteria:**
- ✅ HTTP request succeeds
- ✅ Response shows `"IsTor": true`
- ✅ Exit IP is a Tor exit node (not Hetzner IP)

**Failure indicates:**
- **CRITICAL FAILURE** - Transparent proxy not working
- iptables REDIRECT rules not applied
- Tor TransPort (9040) not listening
- Traffic bypassing Tide entirely

**This is THE most important test** - if this fails, killa-whale doesn't work.

---

### TEST 5: Fail-Closed (Block Direct Access) ⭐ CRITICAL

**What it tests:**
- Can victim bypass Tor and reach internet directly?
- Is fail-closed firewall actually blocking leaks?

**Method:**
```bash
# Try multiple endpoints:
curl http://example.com          # Should fail
curl https://google.com          # Should fail
curl http://1.1.1.1             # Should fail
curl http://api.ipify.org       # Should fail

# All should timeout or be blocked
```

**Pass criteria:**
- ✅ ALL direct internet access attempts fail
- ✅ Victim cannot bypass Tor
- ✅ No DNS leaks, no IP leaks

**Failure indicates:**
- **SECURITY FAILURE** - Traffic can escape without Tor
- iptables rules not applied
- Firewall has gaps
- User can bypass privacy protection

---

### TEST 6: DNS Leak Prevention

**What it tests:**
- Are DNS queries going through Tor?
- Is DNS information leaking to ISP?

**Method:**
```bash
# On victim:
nslookup google.com
# Check which DNS server answered

# Should be Tide Gateway (10.101.101.10)
# NOT 8.8.8.8, 1.1.1.1, or ISP DNS
```

**Pass criteria:**
- ✅ DNS server is Tide Gateway
- ✅ DNS queries routed through Tor

**Failure indicates:**
- DNS queries leaking
- Victim using hardcoded DNS
- DNS interception rules not working

---

### TEST 7: First Hop Validation (Traceroute)

**What it tests:**
- Is Tide the first hop in all routes?
- Does traffic flow through Tide before anywhere else?

**Method:**
```bash
# On victim:
traceroute 8.8.8.8

# First hop should be Tide Gateway (10.101.101.10)
```

**Pass criteria:**
- ✅ Hop 1 is Tide Gateway
- ✅ No direct routes bypass Tide

**Failure indicates:**
- Routing not configured correctly
- Traffic can bypass Tide
- Default gateway not set properly

---

### TEST 8: Explicit SOCKS Proxy (Baseline)

**What it tests:**
- Does SOCKS proxy work as expected?
- Baseline for comparison with transparent proxy

**Method:**
```bash
# On victim (explicit SOCKS config):
curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip

# Should return Tor exit IP
```

**Pass criteria:**
- ✅ SOCKS proxy functional
- ✅ Returns Tor exit IP

**Failure indicates:**
- Tor not running
- SOCKS port (9050) blocked
- Tor circuit not established

---

### TEST 9: Packet Capture (Traffic Flow)

**What it tests:**
- What does actual network traffic look like?
- Visual confirmation of interception

**Method:**
```bash
# On victim:
tcpdump -i eth1 -c 20 -n port not 22

# While generating traffic:
curl http://example.com

# Observe packet destinations
```

**Pass criteria:**
- ✅ Packets show traffic to Tide Gateway
- ✅ No packets escape directly to internet

**Failure indicates:**
- Network-level bypass detected
- Traffic not being intercepted

---

### TEST 10: ARP Poisoning Persistence

**What it tests:**
- Does ARP poisoning persist over time?
- Does Tide continuously re-poison?

**Method:**
```bash
# Check ARP table
arp -a

# Wait 15 seconds
sleep 15

# Check again
arp -a

# Tide's MAC should still be gateway
```

**Pass criteria:**
- ✅ ARP poisoning maintained after 15+ seconds
- ✅ Continuous re-poisoning working

**Failure indicates:**
- ARP poisoning script stopped
- Network caching overriding
- Continuous poisoning loop failed

---

## Success Criteria

**MINIMUM for killa-whale to be considered functional:**

1. ✅ TEST 1: ARP poisoning working
2. ✅ TEST 2: Default gateway set
3. ✅ **TEST 4: Transparent proxy working** (MOST CRITICAL)
4. ✅ **TEST 5: Fail-closed blocking leaks** (CRITICAL)

**FULL SUCCESS (all features working):**

All 10 tests passing.

---

## Known Limitations

**What killa-whale mode CANNOT do:**

1. **Hetzner private network limitations:**
   - May not support promiscuous mode
   - May filter ARP spoofing packets
   - Cloud networks often have security controls

2. **Real-world limitations:**
   - Modern switches may detect ARP poisoning
   - Enterprise networks may have 802.1X authentication
   - Some routers implement DAI (Dynamic ARP Inspection)

3. **Tor limitations:**
   - UDP not supported (only TCP + DNS)
   - Some protocols may not work (FTP, RTSP)
   - Exit nodes may block certain ports

---

## Running the Test

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-killa-whale.sh

# Cost: $0.02 (2 servers × 5 min)
# Time: ~10 minutes
# Output: Detailed validation report
```

**What you'll see:**
- 10 comprehensive tests
- ✅/❌ for each test
- Detailed failure reasons
- Summary of what's working/broken

**Cleanup:**
- Destroys both servers
- Deletes private network
- No residual costs

---

## Expected Results

### If Killa Whale Works Perfectly:

```
TEST 1: ✅ ARP poisoning successful
TEST 2: ✅ Default gateway set
TEST 3: ✅ DNS hijacking working
TEST 4: ✅ Transparent proxy working  <-- CRITICAL
TEST 5: ✅ All direct access blocked (4/4)  <-- CRITICAL
TEST 6: ✅ DNS queries through Tide
TEST 7: ✅ First hop is Tide
TEST 8: ✅ SOCKS proxy working
TEST 9: ✅ Packets intercepted
TEST 10: ✅ ARP persists over time
```

### If Killa Whale Doesn't Work:

```
TEST 1: ❌ ARP poisoning failed
TEST 4: ❌ Transparent interception not working
TEST 5: ❌ Direct access possible (0/4 blocked)

Diagnosis: Hetzner private network may not support ARP spoofing
```

---

## Why This Matters

**Without this testing, we don't know:**
- If killa-whale mode actually protects users
- If privacy claims are true
- If "fail-closed" actually prevents leaks
- If ARP poisoning works on real networks

**With this testing, we can:**
- Validate killa-whale works as advertised
- Document known limitations
- Warn users about environments where it won't work
- Provide proof of functionality

---

## Next Steps After Testing

**If tests pass:**
1. Document which networks/environments work
2. Add killa-whale to production VM templates
3. Create user guide for killa-whale deployment
4. Add continuous monitoring/validation

**If tests fail:**
1. Determine why (network restrictions, code bugs, config issues)
2. Document limitations clearly
3. Provide alternative modes (proxy, router)
4. Fix bugs if code issues found

---

**This is the difference between claiming killa-whale works and PROVING it works.**
