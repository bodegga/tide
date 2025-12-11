# CRITICAL: Security Audit Needed

**Status:** IN PROGRESS  
**Priority:** CRITICAL  
**Created:** 2025-12-11

---

## Problem Identified

During testing, we discovered that the web dashboard requires `StandardError=journal` to bind to port 80. This violates our zero-log policy.

**Current Issue:**
- `StandardError=null` → Dashboard fails to bind port 80
- `StandardError=journal` → Dashboard works but logs errors

This is UNACCEPTABLE for a privacy appliance.

---

## Required: Complete Security Audit

We need to audit the ENTIRE appliance to ensure we are truly logless, anonymous, and secure.

### Goal

**Users must know that Tide Gateway is simply a tunnel to internet freedom. Nothing logged. Nothing tracked. Nothing stored.**

---

## Audit Checklist

### 1. Python Services

**Files to audit:**
- [ ] `scripts/runtime/tide-web-dashboard.py`
- [ ] `scripts/runtime/tide-api.py`
- [ ] `scripts/runtime/tide-cli.sh`
- [ ] `scripts/runtime/tide-config.sh`

**Check for:**
- ❌ Any `print()` statements with user data
- ❌ Any `logging.*` calls
- ❌ Any file writes to `/var/log` or elsewhere
- ❌ Any error messages that leak client info
- ❌ Any debug output

### 2. Bash Scripts

**Files to audit:**
- [ ] `scripts/runtime/gateway-start.sh`
- [ ] All scripts in `scripts/setup/`
- [ ] All scripts in `scripts/build/`

**Check for:**
- ❌ `echo` statements with user data
- ❌ Logging to syslog
- ❌ Writing to log files
- ❌ Debug output

### 3. Systemd Services

**Files to audit:**
- [ ] `config/systemd/tide-web.service`
- [ ] `config/systemd/tide-api.service`

**Check for:**
- ❌ `StandardOutput=journal` (should be `null`)
- ❌ `StandardError=journal` (should be `null`)
- ❌ Any logging configuration
- ❌ Debug flags

**Current problem:** Port 80 binding fails with `StandardError=null`

### 4. Tor Configuration

**Files to audit:**
- [ ] `config/torrc-*` (all security profiles)

**Check for:**
- ✅ `SafeLogging 1` (strips IP addresses)
- ❌ Any `Log` directives (should be minimal or none)
- ❌ Any debugging flags
- ❌ Any telemetry

### 5. Network Configuration

**Files to audit:**
- [ ] `config/iptables-*.rules`
- [ ] Any `dnsmasq` config (if used)

**Check for:**
- ❌ iptables `LOG` targets
- ❌ Connection tracking logs
- ❌ DNS query logging
- ❌ DHCP lease logging with client IDs

### 6. Alpine Linux Base

**System-level checks:**
- [ ] Disable syslog if running
- [ ] Disable audit logs
- [ ] Check for telemetry daemons
- [ ] Verify no log aggregation

### 7. Runtime Behavior

**Test these scenarios:**
- [ ] User connects → Check `journalctl` (should be empty)
- [ ] User browses sites → Check logs (should be nothing)
- [ ] User disconnects → Check for any traces (should be none)
- [ ] Appliance reboots → Check for persistent logs (should be none)

---

## Specific Issues to Fix

### Issue 1: Web Dashboard Port 80

**Problem:** Python's HTTP server fails to bind port 80 when stderr is closed

**Potential solutions:**
1. Use a different HTTP server (nginx, lighttpd with zero-log config)
2. Investigate Python socketserver requirements
3. Run dashboard on different port (not 80)
4. Use setcap instead of systemd capabilities

**Research needed:**
- Why does Python need stderr open for port binding?
- Is this a systemd issue or Python issue?
- Can we redirect stderr to /dev/null AFTER binding?

### Issue 2: Error Handling

**Problem:** If we suppress all errors, debugging becomes impossible

**Solution options:**
1. Error codes only (no messages)
2. Generic error pages (no details)
3. Health endpoint that doesn't log
4. Development mode with logging (MUST be disabled in production)

---

## Testing Requirements

### After each fix, verify:

1. **Run appliance normally:**
   ```bash
   # Use appliance for 5 minutes
   # Then check:
   journalctl --since "5 minutes ago" | grep -v "systemd\|Started\|Stopped"
   # Should return NOTHING
   ```

2. **Check filesystem:**
   ```bash
   find /var/log -type f -mtime -1
   # Should be empty or only system files
   ```

3. **Check network logs:**
   ```bash
   iptables -L -v -n
   # Should show 0 in LOG chain
   ```

4. **Check Tor logs:**
   ```bash
   cat /var/log/tor/* 2>/dev/null
   # Should not exist or be empty
   ```

---

## Success Criteria

### Tide Gateway passes audit when:

1. ✅ **Zero user data logging**
   - No client IPs in any logs
   - No DNS queries logged
   - No HTTP requests logged
   - No Tor circuit info logged

2. ✅ **Zero persistent storage of user activity**
   - Nothing written to disk about users
   - No temporary files with user data
   - Memory only (clears on reboot)

3. ✅ **Provable privacy**
   - Code audit shows no logging
   - Runtime test shows no logs
   - Can demonstrate to users

4. ✅ **All features working**
   - Web dashboard accessible
   - API functional
   - Tor routing working
   - CLI commands working

---

## Philosophy

**"If you can't verify it didn't happen, you can't prove it didn't happen."**

- Zero logs = zero evidence
- If you don't collect it, you can't leak it
- Privacy is not a feature - it's the entire point
- Users trust us with their freedom - don't betray that

---

## Timeline

**Immediate (next session):**
1. Fix web dashboard port 80 without logging
2. Audit all Python scripts
3. Audit all systemd services

**Short-term (this week):**
4. Audit Tor configuration
5. Audit network services
6. Runtime testing

**Before v1.2.0 release:**
7. Complete security audit
8. Document findings
9. Prove zero-log compliance
10. Update ZERO-LOG-POLICY.md

---

## Documentation to Update

After audit completion:

1. **ZERO-LOG-POLICY.md** - Add audit results
2. **SECURITY.md** - Document threat model
3. **SECURITY-AUDIT.md** - Detailed audit report
4. **README.md** - Emphasize security guarantees
5. **CHANGELOG.md** - Document security fixes

---

## Notes

**This is CRITICAL.** We are building a privacy appliance. If we log user activity, we've failed our mission.

**Users' safety may depend on our zero-log policy.** Journalists, activists, and privacy-conscious individuals trust us. We cannot betray that trust.

**Priority over all features.** Web dashboard can wait. Zero logs cannot.

---

**Next Action:** Fix port 80 issue without compromising zero-log policy, then conduct full security audit.
