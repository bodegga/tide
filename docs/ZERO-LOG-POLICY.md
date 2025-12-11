# Tide Gateway - Zero-Log Security Policy

**Version:** 1.0  
**Status:** MANDATORY  
**Last Updated:** December 10, 2025

---

## Core Principle

**Tide Gateway is a privacy appliance. We NEVER log user traffic, client IPs, requests, or any identifying information.**

If you can't verify it didn't happen, you can't prove it didn't happen. Zero logs = zero evidence.

---

## What We NEVER Log

### ❌ Absolutely Forbidden

1. **Client IP addresses** - Not even in memory beyond the active connection
2. **DNS queries** - No record of what sites users visit
3. **HTTP/HTTPS requests** - No URLs, no headers, no nothing
4. **Tor circuit information** - No exit nodes, no entry guards
5. **Timestamps of user activity** - Only system uptime (not per-user)
6. **API token usage** - No record of who called what endpoint
7. **Web dashboard access** - No visitor tracking
8. **Traffic volumes per user** - Only aggregate system stats
9. **Mode switches** - When user changes security/mode settings
10. **Configuration changes** - What settings were changed and when

### What This Means in Practice

**HTTP Server Logs:**
```python
def log_message(self, format, *args):
    """ZERO-LOG POLICY: No request logging for privacy"""
    pass  # Literally do nothing
```

**Systemd Services:**
```ini
StandardOutput=null  # No stdout logging
StandardError=null   # No stderr logging
```

**No Journal Entries:**
- Services configured to not write to systemd journal
- No syslog entries for user activity
- No debug output that could reveal usage patterns

---

## What We CAN Log (System Health Only)

### ✅ Permitted (Non-Identifying Information Only)

1. **Service start/stop** - "Tor started" (not "User connected")
2. **System errors** - "Tor failed to start" (not "Request from 192.168.1.5 failed")
3. **Version information** - Current Tide version
4. **Mode at boot** - What mode/security level is configured (not when it changed)
5. **Aggregate stats** - "5 connections active" (not who they are)

**Example of permitted logging:**
```
[SYSTEM] Tide Gateway started in killa-whale mode
[SYSTEM] Tor bootstrap complete
[ERROR] Failed to start dnsmasq (system-level error)
```

**Example of FORBIDDEN logging:**
```
❌ [REQUEST] 192.168.1.105 accessed http://tide.bodegga.net/
❌ [DNS] Client 192.168.1.105 queried facebook.com
❌ [TOR] Exit node: 123.45.67.89
❌ [API] 192.168.1.105 called /status at 14:35:22
```

---

## Implementation Checklist

### Python Services

**tide-web-dashboard.py:**
- [x] Override `log_message()` to do nothing
- [x] No `print()` statements with client data
- [x] No file writing with request info
- [x] Connection state only in memory (not persisted)

**tide-api.py:**
- [x] Override `log_message()` to do nothing
- [x] Don't print API tokens
- [x] Don't log API calls
- [x] No Bearer token logging

### Systemd Services

**tide-web.service:**
- [x] `StandardOutput=null`
- [x] `StandardError=null`
- [x] No journal logging

**tide-api.service:**
- [x] `StandardOutput=null`
- [x] `StandardError=null`
- [x] No journal logging

### System Configuration

**Tor:**
```
# torrc - already zero-log by default
# SafeLogging 1 (default) strips IP addresses from logs
# Log notice stdout (only for debugging, disabled in production)
```

**dnsmasq:**
```
# No query logging
# No DHCP lease logging with client IDs
log-queries=0  # MUST be off
log-dhcp=0     # MUST be off
```

**iptables:**
```
# No packet logging rules
# No LOG targets in production
```

---

## Testing Zero-Log Compliance

### Manual Verification

Run these commands on a Tide Gateway to verify zero-log compliance:

```bash
# 1. Check for recent journal entries (should be minimal/system only)
journalctl -u tide-web -u tide-api --since "1 hour ago"

# 2. Check for log files (should not exist)
find /var/log -name "*tide*" -o -name "*dns*" -o -name "*http*"

# 3. Check Python processes aren't logging
ps aux | grep tide-web-dashboard
# Should show: StandardOutput=null, StandardError=null

# 4. Make a request and verify no logs
curl http://localhost/
journalctl -u tide-web -n 10  # Should show no new entries

# 5. Check Tor logs (should be minimal)
journalctl -u tor -n 20 | grep -i "client\|request\|IP"  # Should be empty
```

### Automated Test

```bash
#!/bin/bash
# Test zero-log compliance

echo "Testing Zero-Log Policy..."

# Make requests
curl -s http://localhost/ > /dev/null
curl -s http://localhost/api/status > /dev/null

# Check for leaked data
LEAKED=$(journalctl -u tide-web -u tide-api --since "1 min ago" | grep -E "192\.168\.|client|request" | wc -l)

if [ $LEAKED -eq 0 ]; then
    echo "✅ Zero-Log Policy: PASS"
else
    echo "❌ Zero-Log Policy: FAIL ($LEAKED leaked entries)"
    journalctl -u tide-web -u tide-api --since "1 min ago"
    exit 1
fi
```

---

## Audit Requirements

### Before Each Release

1. **Code Review**: Search for `print(`, `logging.`, `log.`, `logger.`
2. **Service Files**: Verify `StandardOutput=null` and `StandardError=null`
3. **Manual Testing**: Run test suite on Hetzner, check journals
4. **No Logs Remain**: `journalctl --vacuum-time=1s` before releasing VM template

### Quarterly Audit

1. Review all Python scripts for logging creep
2. Check systemd services haven't been modified
3. Verify dnsmasq config still has logging disabled
4. Test on fresh VM install

---

## Developer Guidelines

### When Writing Code

**DO:**
- Return anonymous aggregate statistics
- Use in-memory state that doesn't persist
- Log system errors (not user errors)
- Use generic error messages

**DON'T:**
- `print()` client IPs or requests
- Write files with user data
- Log to syslog/journal
- Debug with `--verbose` flags in production

### Code Review Checklist

- [ ] No `print()` statements with IP addresses
- [ ] No `logging.info()` or similar with user data
- [ ] No file writes to `/var/log` or anywhere
- [ ] No debug flags that could leak data
- [ ] Systemd service has `StandardOutput=null`

---

## Philosophy

**"If you don't collect it, you can't leak it."**

Privacy isn't about securing logs - it's about not creating them in the first place.

### Why This Matters

1. **User Trust**: Users chose Tide for privacy - we deliver
2. **Legal Protection**: No logs = no subpoenas
3. **Security**: Can't leak what doesn't exist
4. **Simplicity**: No log rotation, no storage, no cleanup

### Comparison to Others

**VPN providers who claim "no logs":**
- Often log connection times
- Often log aggregate bandwidth
- Often log authentication attempts
- "No logs" = marketing

**Tide Gateway:**
- Literally `/dev/null` for all user activity
- Open source - verify the code yourself
- No exceptions, no asterisks
- Zero logs = zero logs

---

## Exceptions (None)

There are **NO EXCEPTIONS** to the zero-log policy for user data.

If a feature requires logging user activity, the feature doesn't get built.

---

## Enforcement

### In Code

```python
# Good
class TideWebHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """ZERO-LOG POLICY: No request logging for privacy"""
        pass

# Bad (NEVER DO THIS)
class BadHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"Request from {self.client_address[0]}")  # ❌ FORBIDDEN
```

### In Services

```ini
# Good
[Service]
StandardOutput=null  # No logs
StandardError=null   # No logs

# Bad (NEVER DO THIS)
[Service]
StandardOutput=journal  # ❌ FORBIDDEN - logs to systemd
StandardError=journal   # ❌ FORBIDDEN
```

---

## Future Considerations

### If We Add Features

**Any new feature must answer:**
1. Does it log user data? → Don't build it
2. Does it persist user data? → Don't build it
3. Can it be subpoenaed? → Don't build it

**Examples:**
- Bandwidth monitoring per-user → ❌ NO
- Traffic graphs with timestamps → ❌ NO
- User activity analytics → ❌ NO
- "Recently accessed sites" → ❌ NO

**Acceptable:**
- Total system bandwidth (no per-user) → ✅ OK
- Number of active connections (no IPs) → ✅ OK
- Tor circuit count (no exit nodes) → ✅ OK

---

## Documentation

This policy must be:
1. Linked from README.md
2. Referenced in all service files
3. Included in VM template documentation
4. Mentioned in user-facing docs

---

## Version History

**v1.0 - December 10, 2025**
- Initial zero-log policy
- Implemented in v1.1.3
- Applied to web dashboard, API, and systemd services

---

**Remember: Privacy is not a feature. It's the entire point.**

🌊 **Tide Gateway: True Privacy. Provable. Verifiable. Zero Logs.**
