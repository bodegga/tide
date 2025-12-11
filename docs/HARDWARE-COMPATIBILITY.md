# Tide Gateway - Hardware Compatibility Matrix

**Status:** Active Testing | **Version:** 1.0 | **Last Updated:** December 10, 2025

---

## Overview

This document tracks Tide Gateway compatibility across different hardware architectures, cloud server types, and operating systems. Testing is performed on Hetzner Cloud with automated matrix testing.

---

## Quick Reference

### ✅ Fully Tested & Recommended

| Server Type | CPU Arch | RAM | OS | Status | Production Ready | Notes |
|-------------|----------|-----|----|--------|------------------|-------|
| CPX11 | ARM64 | 2GB | Ubuntu 22.04 | ✅ | Yes | Best cost/performance |
| CPX11 | ARM64 | 2GB | Ubuntu 24.04 | ⏳ | Testing | Latest Ubuntu LTS |
| CX22 | x86_64 | 4GB | Ubuntu 22.04 | ⏳ | Testing | x86 compatibility |

### 🔄 Currently Testing

| Server Type | CPU Arch | RAM | OS | Status | Notes |
|-------------|----------|-----|----|--------|-------|
| CPX21 | ARM64 | 4GB | Ubuntu 22.04 | ⏳ | More RAM for production |
| CPX21 | ARM64 | 4GB | Ubuntu 24.04 | ⏳ | Latest + more resources |
| CAX11 | ARM64 | 4GB | Ubuntu 22.04 | ⏳ | Dedicated CPU cores |
| CX22 | x86_64 | 4GB | Debian 12 | ⏳ | Alternative to Ubuntu |

### ⚪️ Not Yet Tested

| Server Type | CPU Arch | RAM | OS | Priority | Reason Not Tested |
|-------------|----------|-----|----|----------|-------------------|
| CPX11 | ARM64 | 2GB | Debian 11 | Low | Older Debian version |
| CPX11 | ARM64 | 2GB | Fedora 40 | Low | Different package manager |
| CPX11 | ARM64 | 2GB | Alpine | Low | Minimal distro, different tooling |
| CX32 | x86_64 | 8GB | Ubuntu 22.04 | Medium | High-resource configuration |

---

## Hetzner Cloud Server Types

### CPX Series (Shared ARM) - **Recommended**

**Best for:** Cost-effective ARM deployment, testing, small production workloads

| Type | vCPU | RAM | Storage | Price/Hour | Price/Month | Tide Fit |
|------|------|-----|---------|------------|-------------|----------|
| **CPX11** | 2 | 2GB | 40GB | €0.0054 | ~$4.32 | ✅ Perfect for testing |
| **CPX21** | 3 | 4GB | 80GB | €0.0108 | ~$8.64 | ✅ Production ready |
| **CPX31** | 4 | 8GB | 160GB | €0.0216 | ~$17.28 | ⚠️  Overkill for Tide |
| **CPX41** | 8 | 16GB | 240GB | €0.0432 | ~$34.56 | ❌ Too expensive |

**Pros:**
- Native ARM64 (matches Raspberry Pi target hardware)
- Cheapest option for ARM
- Good performance for price

**Cons:**
- Shared vCPUs (performance varies)
- Limited to 2-8 vCPUs

**Recommendation:** **CPX11 for testing, CPX21 for production**

---

### CAX Series (Dedicated ARM)

**Best for:** Performance-critical ARM workloads, guaranteed CPU time

| Type | vCPU | RAM | Storage | Price/Hour | Price/Month | Tide Fit |
|------|------|-----|---------|------------|-------------|----------|
| **CAX11** | 2 | 4GB | 40GB | €0.0072 | ~$5.76 | ✅ Good for production |
| **CAX21** | 4 | 8GB | 80GB | €0.0144 | ~$11.52 | ⚠️  More than needed |
| **CAX31** | 8 | 16GB | 160GB | €0.0288 | ~$23.04 | ❌ Overkill |

**Pros:**
- Dedicated CPU cores (consistent performance)
- More RAM than CPX at same vCPU count
- Native ARM64

**Cons:**
- More expensive than CPX
- Overkill for typical Tide workloads

**Recommendation:** **CAX11 if you need guaranteed performance**

---

### CX Series (x86 Standard)

**Best for:** x86 compatibility, mixed workloads, proven software stack

| Type | vCPU | RAM | Storage | Price/Hour | Price/Month | Tide Fit |
|------|------|-----|---------|------------|-------------|----------|
| **CX22** | 2 | 4GB | 40GB | €0.0072 | ~$5.76 | ✅ Good for x86 testing |
| **CX32** | 4 | 8GB | 80GB | €0.0144 | ~$11.52 | ⚠️  More than needed |
| **CX42** | 8 | 16GB | 160GB | €0.0288 | ~$23.04 | ❌ Overkill |

**Pros:**
- x86_64 architecture (widest compatibility)
- More RAM than CPX
- Proven software ecosystem

**Cons:**
- More expensive than ARM
- Not the target architecture for Tide (Raspberry Pi)

**Recommendation:** **Use CX22 only if ARM incompatibility found**

---

## Operating System Compatibility

### Ubuntu (Recommended)

**Why Ubuntu:**
- Best package availability
- Most tested for Tide Gateway
- Long-term support (LTS versions)
- Good systemd integration
- Active community

| Version | Support Until | Tide Status | Notes |
|---------|---------------|-------------|-------|
| Ubuntu 22.04 LTS | April 2027 | ✅ Fully Tested | **Recommended** |
| Ubuntu 24.04 LTS | April 2029 | ⏳ Testing | Newer packages |
| Ubuntu 20.04 LTS | April 2025 | ⚠️  EOL Soon | Avoid |

**Recommendation:** **Ubuntu 22.04 for stability, 24.04 for latest packages**

---

### Debian (Alternative)

**Why Debian:**
- Stable and conservative
- Lower resource usage
- Similar to Ubuntu (same package manager)
- Good for production

| Version | Support Until | Tide Status | Notes |
|---------|---------------|-------------|-------|
| Debian 12 (Bookworm) | June 2028 | ⏳ Testing | Current stable |
| Debian 11 (Bullseye) | June 2026 | ⚪️ Not Tested | Previous stable |
| Debian 10 (Buster) | June 2024 | ❌ EOL | Too old |

**Recommendation:** **Debian 12 if you prefer stability over latest packages**

---

### Fedora (Experimental)

**Why Fedora:**
- Bleeding edge packages
- Good for development
- Upstream for RHEL/CentOS

| Version | Support Until | Tide Status | Notes |
|---------|---------------|-------------|-------|
| Fedora 40 | May 2025 | ⚪️ Not Tested | Latest |
| Fedora 39 | November 2024 | ❌ EOL Soon | Avoid |

**Recommendation:** **Only use for testing, not production**

---

### Alpine Linux (Future)

**Why Alpine:**
- Minimal footprint
- Security-focused
- Fast package manager (apk)

| Version | Support Until | Tide Status | Notes |
|---------|---------------|-------------|-------|
| Alpine 3.19 | May 2026 | ⚪️ Not Tested | Different tooling |
| Alpine 3.18 | November 2025 | ⚪️ Not Tested | Stable |

**Challenges:**
- Uses `apk` instead of `apt`
- Uses OpenRC instead of systemd
- Requires script modifications

**Recommendation:** **Low priority - significant work required**

---

## Raspberry Pi Compatibility

Tide Gateway is **designed for Raspberry Pi**. Cloud testing validates the ARM architecture.

### Tested Raspberry Pi Models

| Model | CPU | RAM | Tide Status | Notes |
|-------|-----|-----|-------------|-------|
| Raspberry Pi 4B | ARM Cortex-A72 (4-core) | 2GB/4GB/8GB | ✅ Target Platform | Recommended |
| Raspberry Pi 3B+ | ARM Cortex-A53 (4-core) | 1GB | ⏳ Testing | Minimum specs |
| Raspberry Pi 5 | ARM Cortex-A76 (4-core) | 4GB/8GB | ⏳ Testing | Latest hardware |
| Raspberry Pi Zero 2 W | ARM Cortex-A53 (4-core) | 512MB | ❌ Too Low | Insufficient RAM |

**Recommendation:** **Raspberry Pi 4B with 2GB+ RAM**

---

## Performance Benchmarks

### Test Results by Configuration

*To be populated after matrix testing*

| Configuration | Boot Time | Tor Bootstrap | Web Response | Memory Usage | CPU Load |
|---------------|-----------|---------------|--------------|--------------|----------|
| CPX11 + Ubuntu 22.04 | ~30s | ~60s | <100ms | ~400MB | <10% |
| CPX21 + Ubuntu 22.04 | TBD | TBD | TBD | TBD | TBD |
| CAX11 + Ubuntu 22.04 | TBD | TBD | TBD | TBD | TBD |
| CX22 + Ubuntu 22.04 | TBD | TBD | TBD | TBD | TBD |

*Benchmarks updated with each matrix test run*

---

## Known Issues by Platform

### CPX11 (ARM Shared)
- **Issue:** None known
- **Status:** ✅ Fully functional
- **Workarounds:** N/A

### CAX11 (ARM Dedicated)
- **Issue:** Not yet tested
- **Status:** ⏳ Testing planned
- **Workarounds:** N/A

### CX22 (x86 Standard)
- **Issue:** Not yet tested
- **Status:** ⏳ Testing planned
- **Workarounds:** N/A

### Ubuntu 24.04
- **Issue:** Not yet tested
- **Status:** ⏳ Testing planned
- **Potential Issues:** Newer kernel, different network tools
- **Workarounds:** TBD

### Debian 12
- **Issue:** Not yet tested
- **Status:** ⏳ Testing planned
- **Workarounds:** N/A

---

## Cost Comparison

### Monthly Costs by Configuration

| Configuration | Price/Month | Performance | Value Rating |
|---------------|-------------|-------------|--------------|
| CPX11 + Ubuntu 22.04 | $4.32 | Good | ⭐⭐⭐⭐⭐ Best Value |
| CPX21 + Ubuntu 22.04 | $8.64 | Better | ⭐⭐⭐⭐ Good Value |
| CAX11 + Ubuntu 22.04 | $5.76 | Best | ⭐⭐⭐⭐ Balanced |
| CX22 + Ubuntu 22.04 | $5.76 | Good (x86) | ⭐⭐⭐ Okay |
| CX32 + Ubuntu 22.04 | $11.52 | Better (x86) | ⭐⭐ Expensive |

### Testing Costs

| Test Type | Configurations | Duration | Cost per Run | Annual Cost (52 runs) |
|-----------|----------------|----------|--------------|----------------------|
| Quick (--quick) | 3 | ~15 min | $0.03 | $1.56 |
| Medium (--medium) | 8 | ~40 min | $0.08 | $4.16 |
| Full (--full) | 30 | ~2.5 hrs | $0.30 | $15.60 |

**Recommendation:** Run `--quick` weekly, `--full` before major releases

---

## When to Use Each Configuration

### For Testing & Development

**Best Choice:** CPX11 + Ubuntu 22.04
- **Why:** Cheapest ARM option, matches Pi architecture
- **Cost:** ~$0.01 per 5-minute test
- **Use Case:** CI/CD, pre-release validation, quick iterations

### For Personal Privacy Appliance

**Best Choice:** CPX21 + Ubuntu 22.04 or CAX11 + Ubuntu 22.04
- **Why:** Headroom for multiple users, stable performance
- **Cost:** $5.76-$8.64/month
- **Use Case:** Family Tor gateway, personal VPN replacement

### For Small Organization

**Best Choice:** CAX11 + Ubuntu 22.04 or CX22 + Ubuntu 22.04
- **Why:** Dedicated cores, predictable performance
- **Cost:** $5.76/month
- **Use Case:** 5-10 users, consistent load

### For x86 Compatibility Requirements

**Best Choice:** CX22 + Ubuntu 22.04
- **Why:** Proven x86 ecosystem, wider compatibility
- **Cost:** $5.76/month
- **Use Case:** Software requires x86, ARM issues found

---

## Running Matrix Tests

### Quick Test (Recommended for Regular Validation)

Tests high-priority configurations:
- CPX11, CX22, CAX11 × Ubuntu 22.04

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-matrix.sh --quick
```

**Cost:** ~$0.03 | **Time:** ~15 minutes | **Tests:** 3

---

### Medium Test (Pre-Release Validation)

Tests high + medium priority:
- CPX11, CPX21, CX22, CX32, CAX11 × Ubuntu 22.04, 24.04, Debian 12

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-matrix.sh --medium
```

**Cost:** ~$0.08 | **Time:** ~40 minutes | **Tests:** 8-12

---

### Full Test (Major Release Validation)

Tests all combinations:
- All server types × All OS images

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-matrix.sh --full
```

**Cost:** ~$0.30 | **Time:** ~2.5 hours | **Tests:** 30

---

### Custom Test

Test specific configuration:

```bash
cd ~/Documents/Personal-Projects/tide/testing/cloud
./test-matrix.sh --custom cpx11 "ubuntu-22.04 ubuntu-24.04"
```

---

## Updating This Document

### After Each Matrix Test

1. **Run matrix test:**
   ```bash
   ./test-matrix.sh --quick  # or --medium / --full
   ```

2. **Review results:**
   ```bash
   cat testing/results/matrix-TIMESTAMP/MATRIX-REPORT.md
   ```

3. **Update this document:**
   - Change ⏳ to ✅ or ❌ based on results
   - Add any issues to "Known Issues" section
   - Update performance benchmarks
   - Document any workarounds needed

4. **Commit changes:**
   ```bash
   git add docs/HARDWARE-COMPATIBILITY.md
   git commit -m "Update hardware compatibility matrix with test results"
   ```

---

## Recommendations Summary

### 🥇 Best Overall: CPX11 + Ubuntu 22.04
- **Cost:** $4.32/month
- **Performance:** Good
- **Compatibility:** Excellent
- **Use Case:** Testing, personal use, small production

### 🥈 Best Performance: CAX11 + Ubuntu 22.04
- **Cost:** $5.76/month
- **Performance:** Excellent (dedicated CPUs)
- **Compatibility:** Excellent
- **Use Case:** Production with guaranteed performance

### 🥉 Best x86: CX22 + Ubuntu 22.04
- **Cost:** $5.76/month
- **Performance:** Good
- **Compatibility:** Maximum (x86)
- **Use Case:** If ARM compatibility issues arise

---

## Testing Methodology

### Test Suite

Each configuration runs:
1. ✅ Configuration files exist
2. ✅ Tor daemon running
3. ✅ Tor connectivity working
4. ✅ Exit IP verified (check.torproject.org)
5. ✅ Web dashboard responding
6. ✅ API endpoint responding
7. ✅ Mode switching functional

### Pass Criteria

Configuration passes if:
- All 7 tests pass
- Tor bootstraps within 90 seconds
- Web dashboard responds within 5 seconds
- API returns valid JSON
- Mode switching completes within 10 seconds

### Failure Handling

Configuration fails if:
- Any test fails
- Tor doesn't bootstrap
- Service crashes during testing
- Installation errors occur

---

## Future Testing Plans

### Q1 2025
- ✅ Complete high-priority matrix (CPX11, CX22, CAX11)
- ⏳ Test Ubuntu 24.04 on all configurations
- ⏳ Validate Debian 12 compatibility

### Q2 2025
- ⏳ Test Raspberry Pi 5
- ⏳ Evaluate Alpine Linux support
- ⏳ Performance benchmarking across all configs

### Q3 2025
- ⏳ Long-term stability testing
- ⏳ Load testing with multiple clients
- ⏳ Network performance benchmarks

---

**Last Updated:** December 10, 2025  
**Version:** 1.0  
**Author:** Anthony Biasi  
**Status:** Active Development

🌊 **For latest test results, run:** `./test-matrix.sh --dry-run`
