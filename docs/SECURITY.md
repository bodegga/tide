# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | ✅ Active support  |
| < 1.0   | ❌ No longer supported |

## Reporting a Vulnerability

**Please DO NOT open public issues for security vulnerabilities.**

### How to Report

Send security reports to: **a@biasi.co**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to Expect

- **Acknowledgment:** Within 48 hours
- **Investigation:** Within 7 days
- **Fix & Disclosure:** Coordinated timeline (typically 30-90 days)

We'll work with you to understand the issue and develop a fix before public disclosure.

## Security Model

Tide's security guarantees:

### ✅ What We Protect Against
- **Traffic leaks** - All traffic routed through Tor or blocked
- **DNS leaks** - DNS queries go through Tor DNSPort
- **IPv6 leaks** - IPv6 disabled entirely
- **Clearnet fallback** - Gateway itself cannot reach clearnet
- **Tor failures** - If Tor dies, traffic is blocked (fail-closed)

### ⚠️ What We Don't Protect Against
- **Local network attacks** - Tide doesn't encrypt local traffic
- **Browser fingerprinting** - Use Tor Browser for anonymity
- **Malware on client** - Tide is a network gateway, not endpoint security
- **Physical access** - Assume attacker with VM/host access can see traffic
- **Zero-day exploits** - We use Tor/Alpine/iptables; vulnerabilities there affect Tide

### 🔒 Security Features

1. **Immutable Config** - Critical files locked with `chattr +i`
2. **Fail-Closed Firewall** - Default DROP policy on OUTPUT
3. **No IPv6** - Completely disabled to prevent leaks
4. **Minimal Attack Surface** - Alpine Linux, minimal packages
5. **No Logging** - Tor doesn't log, gateway doesn't log

## Known Limitations

### Docker Mode
- Docker's NAT can be bypassed if container has `CAP_NET_ADMIN` + bad config
- Host network mode (`--network host`) defeats isolation
- Container escape vulnerabilities affect Tide's isolation

### VM Mode
- Hypervisor bugs could leak traffic
- Shared clipboard/drag-drop can leak data
- VM snapshots may contain sensitive state

### Takeover Mode (Planned)
- ARP hijacking is detectable on the local network
- Could be disrupted by legitimate ARP traffic
- Requires physical network access to deploy

## Best Practices

### For Users
1. **Verify no leaks:** Test with `curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip`
2. **Use Tor Browser:** For anonymity, not just privacy
3. **Isolate sensitive VMs:** Don't mix clearnet and Tide on same host
4. **Keep updated:** Run `docker pull bodegga/tide:latest` regularly

### For Developers
1. **Never log traffic:** No packet captures, connection logs, etc.
2. **Fail closed:** If in doubt, block traffic
3. **Audit iptables rules:** Ensure no clearnet bypass
4. **Test leak scenarios:** Tor stopped, network down, etc.

## Responsible Disclosure

We follow coordinated vulnerability disclosure:
1. Reporter privately notifies us
2. We confirm and develop a fix
3. We release the fix
4. Public disclosure after fix is available

**Timeline:** Typically 30-90 days, negotiable based on severity.

## Security Updates

Critical security updates will be:
- Released immediately
- Announced in GitHub Releases
- Noted in CHANGELOG.md
- Tagged with `[SECURITY]` prefix

## Questions?

For non-sensitive security questions, open a GitHub Discussion.

For vulnerabilities, email **a@biasi.co**.

---

**Thank you for helping keep Tide secure!** 🔒
