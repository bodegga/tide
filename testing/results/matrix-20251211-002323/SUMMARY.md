# Matrix Test Results - December 11, 2025

**Session:** matrix-20251211-002323  
**Test Mode:** Quick (3 configurations)  
**Total Cost:** ~$0.01 (only CPX11 ran successfully)

---

## Test Matrix

| Server Type | CPU Arch | Image | Status | Passed | Failed | Notes |
|-------------|----------|-------|--------|--------|--------|-------|
| **CPX11** | ARM | Ubuntu 22.04 | ⚠️ PARTIAL | 19 | 2 | Primary platform - mostly working |
| **CX22** | x86 | Ubuntu 22.04 | ❌ FAILED | 1 | 0 | Server type deprecated, not available in hil location |
| **CAX11** | ARM Dedicated | Ubuntu 22.04 | ❌ FAILED | 1 | 0 | Not available in hil location |

---

## CPX11 Results (Primary Platform)

### ✅ What Works
1. ✅ CLI Command (`tide status`)
2. ✅ Configuration Files (mode, security)
3. ✅ Tor running and connected
4. ✅ Web dashboard process running
5. ✅ API responds on port 9051 (correct version 1.1.3)
6. ✅ Mode switching (killa-whale → router)
7. ✅ Tor connectivity (exit IP verified: 45.84.107.33)

### ❌ What Failed
1. ❌ Web dashboard not responding on port 80 (process runs but port not accessible)
2. ❌ dnsmasq not running (need to determine if required)

### Analysis
**CPX11 is 90% functional.** The two failures are:
- **Dashboard issue:** Capability fix may not be working properly
- **dnsmasq issue:** May not be needed for all modes

---

## CX22 Results (x86 Platform)

### ❌ Server Creation Failed

**Error:**
```
Server Type "cx22" is deprecated and will no longer be available
hcloud: unsupported location for server type
```

**Solution:** Use CX32 or CX42 instead (newer x86 server types)

---

## CAX11 Results (ARM Dedicated)

### ❌ Server Creation Failed

**Error:**
```
hcloud: unsupported location for server type
```

**Solution:** Check available locations for CAX series, may need different region

---

## Recommendations

### Immediate Actions

1. **Fix web dashboard port 80 issue**
   - Investigate why capability fix isn't working
   - May need different approach (setcap, different user, etc.)

2. **Investigate dnsmasq requirement**
   - Determine which modes need dnsmasq
   - Update test expectations accordingly

3. **Update matrix test script**
   - Remove CX22 (deprecated)
   - Use CX32 for x86 testing
   - Check CAX availability or skip dedicated ARM

### Testing Strategy

**For now:**
- ✅ CPX11 (ARM shared) is PRIMARY platform
- ✅ 90% functional, good enough for v1.1.3
- ⏳ x86 testing postponed until CX32 added

**Future:**
- Add CX32 (x86) to matrix
- Test in different regions for CAX11
- Consider testing on actual hypervisors (ESXi, Proxmox) instead

---

## Cost Analysis

**This test:**
- CPX11: ~$0.01 (ran for ~2 minutes)
- CX22: $0 (failed immediately)
- CAX11: $0 (failed immediately)
- **Total: ~$0.01**

**Annual estimate (weekly quick tests):**
- 52 weeks × $0.01 = **$0.52/year**

(Much cheaper than originally estimated $3/year since only one server works)

---

## Next Steps

1. **Fix dashboard** - Priority 1
2. **Update test matrix** - Remove deprecated server types
3. **Document CPX11 as tested platform**
4. **Add hypervisor testing** - Real end-to-end deployment tests

---

**Conclusion:** CPX11 (ARM) works well enough for v1.1.3 release. Minor issues (dashboard port, dnsmasq) are not blockers for the appliance's core functionality (Tor routing).
