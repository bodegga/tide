# Tide Gateway - Specialized Agents

**Version:** 1.0  
**Last Updated:** 2025-12-11

---

## Overview

This directory contains specialized agent specifications for managing different aspects of the Tide Gateway project. Each agent has specific responsibilities and can be invoked manually or as part of automated workflows.

---

## Available Agents

### 1. Privacy Guardian Agent ⭐ CRITICAL
**File:** `privacy-guardian.md`  
**Priority:** CRITICAL - Non-negotiable  
**Purpose:** Enforce zero-log policy across all code changes

**Responsibilities:**
- Scan for logging violations before commits
- Check systemd services have null output
- Verify no client IP tracking, DNS query logging
- Audit code for privacy compliance
- Block features that log user data

**When to use:**
- ✅ Before every commit
- ✅ Before every release
- ✅ When adding new features
- ✅ Quarterly code audits

**Invocation:**
```bash
# Pre-commit check
bash .agents/test-zero-log-compliance.sh

# Full audit
bash .agents/privacy-guardian-audit.sh

# Release audit
bash .agents/privacy-guardian-release-audit.sh
```

---

### 2. Testing Orchestrator Agent ⭐ HIGH PRIORITY
**File:** `testing-orchestrator.md`  
**Priority:** HIGH - Validates production readiness  
**Purpose:** Automate comprehensive testing across all platforms

**Responsibilities:**
- Run Docker tests (quick iteration, free)
- Run Hetzner tests (PRIMARY - real ARM hardware, $0.01/test)
- Execute matrix testing (hardware/OS combinations)
- Generate test dashboards and reports
- Manage test infrastructure

**When to use:**
- ✅ Before every release (Hetzner REQUIRED)
- ✅ During development (Docker for quick checks)
- ✅ Weekly/monthly matrix tests
- ✅ After build system changes

**Invocation:**
```bash
# Quick Docker test (development)
cd testing/containers && ./test-docker.sh

# Hetzner test (REQUIRED before release)
cd testing/cloud && ./test-hetzner.sh

# Full orchestration (both platforms in parallel)
cd testing && ./orchestrate-tests.sh

# Matrix testing
./orchestrate-tests.sh matrix --quick
```

---

### 3. Hetzner Cloud Manager Agent ⭐ CRITICAL
**File:** `hetzner-cloud-manager.md`  
**Priority:** CRITICAL - PRIMARY testing platform  
**Purpose:** Manage Hetzner Cloud infrastructure for real ARM hardware validation

**Responsibilities:**
- Create/destroy Hetzner test servers
- Run matrix tests across hardware types (CPX11, CX22, CAX11)
- Monitor monthly costs (target: <$5/month)
- Track test results and hardware compatibility
- Manage API tokens securely

**When to use:**
- ✅ Before every release (real hardware validation)
- ✅ Matrix testing (quarterly)
- ✅ Hardware compatibility validation
- ✅ Production deployment planning

**Invocation:**
```bash
# Create test server
bash .agents/create-test-server.sh

# List active servers
bash .agents/list-test-servers.sh

# Destroy server
bash .agents/destroy-test-server.sh <server-name>

# Matrix test
bash .agents/run-matrix-test.sh quick

# Cost tracking
bash .agents/track-hetzner-costs.sh
```

---

### 4. Documentation Sync Agent
**File:** `documentation-sync.md`  
**Priority:** HIGH - Prevents documentation drift  
**Purpose:** Keep all documentation accurate, versioned, and synchronized

**Responsibilities:**
- Sync version numbers across all files
- Update CHANGELOG.md with every feature/fix
- Validate internal and external links
- Check documentation completeness
- Generate release notes

**When to use:**
- ✅ After version bump
- ✅ Before releases
- ✅ When adding features
- ✅ Quarterly documentation audits

**Invocation:**
```bash
# Sync version across files
bash .agents/sync-version.sh

# Check CHANGELOG compliance
bash .agents/check-changelog.sh

# Validate links
bash .agents/validate-links.sh

# Generate release notes
bash .agents/generate-release-notes.sh

# Quarterly audit
bash .agents/quarterly-doc-audit.sh
```

---

### 5. Release Manager Agent
**File:** `release-manager.md`  
**Priority:** HIGH - Ensures consistent releases  
**Purpose:** Automate semantic versioning and GitHub releases

**Responsibilities:**
- Enforce semantic versioning (MAJOR.MINOR.PATCH)
- Run comprehensive pre-release checks
- Create git tags with proper annotations
- Generate GitHub releases with artifacts
- Upload VM images to releases

**When to use:**
- ✅ When preparing releases
- ✅ After version bumps
- ✅ When tagging releases

**Invocation:**
```bash
# Determine version bump
bash .agents/determine-version-bump.sh

# Pre-release checklist
bash .agents/pre-release-checklist.sh

# Create release
bash .agents/create-release.sh

# Post-release tasks
bash .agents/post-release.sh
```

---

### 6. Build Orchestrator Agent
**File:** `build-orchestrator.md`  
**Priority:** MEDIUM - Needed for releases  
**Purpose:** Automate multi-platform VM builds

**Responsibilities:**
- Build VM templates for 6 hypervisors
- Support ARM64 and x86_64 architectures
- Verify checksums and image integrity
- Generate release artifacts
- Convert between formats (QCOW2, VMDK, VHDX, VDI, OVA)

**When to use:**
- ✅ Before releases (build VM templates)
- ✅ Testing build system changes
- ✅ Creating platform-specific images

**Invocation:**
```bash
# Build all platforms (ARM64 + x86_64)
bash .agents/build-all-platforms.sh

# Build single platform
cd scripts/build && ./build-multi-platform.sh --platform esxi

# Verify builds
bash .agents/verify-builds.sh
```

---

### 7. Security Audit Agent
**File:** `security-audit.md`  
**Priority:** MEDIUM - Preventive security  
**Purpose:** Continuous security monitoring and auditing

**Responsibilities:**
- Scan for exposed secrets/API tokens
- Audit firewall rules (iptables)
- Verify Tor configuration matches security profiles
- Check systemd service permissions
- Validate Alpine package versions

**When to use:**
- ✅ Before releases
- ✅ Quarterly security audits
- ✅ After configuration changes

**Invocation:**
```bash
# Scan for secrets
bash .agents/scan-secrets.sh

# Audit firewall rules
bash .agents/audit-firewall.sh

# Audit Tor configuration
bash .agents/audit-tor.sh

# Quarterly audit
bash .agents/quarterly-security-audit.sh
```

---

## Agent Priority Matrix

| Agent | Priority | Frequency | Cost | Automation |
|-------|----------|-----------|------|------------|
| **Privacy Guardian** | ⭐ CRITICAL | Every commit | Free | Pre-commit hook |
| **Testing Orchestrator** | ⭐ HIGH | Before releases | $0.01 | Manual/CI |
| **Hetzner Cloud Manager** | ⭐ CRITICAL | Before releases | $0.01 | Manual/CI |
| **Documentation Sync** | HIGH | Version bumps | Free | Pre-commit hook |
| **Release Manager** | HIGH | Releases | Free | Manual |
| **Build Orchestrator** | MEDIUM | Releases | Free | Manual |
| **Security Audit** | MEDIUM | Quarterly | Free | Manual |

---

## Workflow Integration

### Pre-Commit Workflow

```bash
# 1. Privacy Guardian
bash .agents/privacy-guardian-audit.sh

# 2. Documentation Sync (if VERSION changed)
bash .agents/sync-version.sh

# 3. CHANGELOG check (if code changed)
bash .agents/check-changelog.sh
```

### Pre-Release Workflow

```bash
# 1. Version bump
bash .agents/determine-version-bump.sh

# 2. Documentation sync
bash .agents/sync-version.sh

# 3. Privacy Guardian audit
bash .agents/privacy-guardian-release-audit.sh

# 4. Build VM images
bash .agents/build-all-platforms.sh

# 5. Verify builds
bash .agents/verify-builds.sh

# 6. Run tests (Docker + Hetzner)
cd testing && ./orchestrate-tests.sh

# 7. Generate release notes
bash .agents/generate-release-notes.sh

# 8. Create GitHub release
bash .agents/create-release.sh
```

### Quarterly Maintenance

```bash
# 1. Documentation audit
bash .agents/quarterly-doc-audit.sh

# 2. Security audit
bash .agents/quarterly-security-audit.sh

# 3. Matrix testing
cd testing && ./orchestrate-tests.sh matrix --medium

# 4. Cost review
bash .agents/track-hetzner-costs.sh
```

---

## Creating New Agents

**Template structure:**

```markdown
# [Agent Name] Agent

**Role:** [Brief description]  
**Priority:** [CRITICAL/HIGH/MEDIUM/LOW]  
**Version:** 1.0  
**Last Updated:** YYYY-MM-DD

---

## Mission

[What this agent does and why]

---

## Mandatory Startup Sequence

[Commands that MUST run first]

---

## Core Responsibilities

[Detailed responsibilities]

---

## Required Reading

[Documentation to read before using]

---

## Tools & Scripts

[Scripts this agent uses]
```

---

## Implementation Checklist

**Phase 1: Foundation (Week 1)**
- [x] Privacy Guardian specification
- [x] Testing Orchestrator specification
- [x] Hetzner Cloud Manager specification
- [ ] Create actual shell scripts in `.agents/`
- [ ] Test Privacy Guardian audit
- [ ] Test Testing Orchestrator workflows

**Phase 2: Automation (Week 2-3)**
- [x] Documentation Sync specification
- [x] Release Manager specification
- [x] Build Orchestrator specification
- [ ] Create automation scripts
- [ ] Set up git hooks (pre-commit)
- [ ] Test full release workflow

**Phase 3: Polish (Week 4+)**
- [x] Security Audit specification
- [ ] Create quarterly audit scripts
- [ ] Document agent usage in README
- [ ] Create video walkthrough (optional)

---

## Git Hooks Integration

**`.git/hooks/pre-commit`:**

```bash
#!/bin/bash
# Tide Gateway - Pre-commit checks

echo "🌊 Tide Gateway Pre-Commit Checks"
echo ""

# 1. Privacy Guardian
echo "[1/3] Privacy Guardian..."
bash .agents/test-zero-log-compliance.sh || exit 1

# 2. Documentation Sync (if VERSION changed)
if git diff --cached --name-only | grep -q "^VERSION$"; then
    echo "[2/3] Documentation Sync..."
    bash .agents/sync-version.sh || exit 1
    git add README.md AGENTS.md
fi

# 3. CHANGELOG check (if code changed)
echo "[3/3] CHANGELOG check..."
bash .agents/check-changelog.sh || exit 1

echo ""
echo "✅ All pre-commit checks passed"
```

**Install hook:**

```bash
cp .agents/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

---

## GitHub Actions Integration (Future)

**`.github/workflows/agents.yml`:**

```yaml
name: Tide Gateway Agents

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  privacy-guardian:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Privacy Guardian Audit
        run: bash .agents/test-zero-log-compliance.sh

  testing:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Docker Tests
        run: cd testing/containers && ./test-docker.sh
      
  hetzner-test:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Hetzner Test
        env:
          HETZNER_TIDE_TOKEN: ${{ secrets.HETZNER_TIDE_TOKEN }}
        run: cd testing/cloud && ./test-hetzner.sh

  documentation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Documentation Sync
        run: bash .agents/check-documentation.sh
```

---

## Troubleshooting

**Issue:** Agent script not found

**Solution:**
```bash
# Ensure you're in project root
pwd  # Should be: /Users/abiasi/Documents/Personal-Projects/tide

# Check .agents directory exists
ls -la .agents/
```

**Issue:** Permission denied

**Solution:**
```bash
# Make scripts executable
chmod +x .agents/*.sh
```

**Issue:** Agent fails with missing dependencies

**Solution:**
```bash
# Check dependencies
command -v hcloud  # Hetzner CLI
command -v qemu-img  # QEMU tools
docker info  # Docker daemon
```

---

## Support & Maintenance

**Questions:** Open an issue on GitHub  
**Bug reports:** Tag with `agents` label  
**Improvements:** Submit PR with updated agent spec

---

## Version History

**v1.0 - 2025-12-11**
- Initial agent specifications
- All 7 agents documented
- Workflow integration defined
- Implementation checklist created

---

**Remember: Agents are here to help maintain quality, privacy, and consistency. Use them!**

🌊 **Tide Gateway: Automated. Maintained. Professional.**
