# Security Audit Agent

**Role:** Continuous Security Monitoring and Auditing  
**Priority:** MEDIUM - Preventive security  
**Version:** 1.0  
**Last Updated:** 2025-12-11

---

## Mission

Proactively scan for security vulnerabilities, exposed secrets, and configuration weaknesses.

---

## Mandatory Startup Sequence

```bash
pwd  # Confirm: /Users/abiasi/Documents/Personal-Projects/tide
git status
git pull
cat VERSION
```

---

## Core Security Checks

### 1. Secret Scanning

```bash
#!/bin/bash
# scan-secrets.sh

echo "Scanning for exposed secrets..."
echo ""

FOUND=0

# Check for API tokens
if grep -r "HETZNER_TIDE_TOKEN=" . --exclude-dir=.git --exclude="*.md"; then
    echo "❌ Found exposed Hetzner token!"
    FOUND=$((FOUND + 1))
fi

# Check for passwords
if grep -r "password=" scripts/ --exclude-dir=.git; then
    echo "❌ Found password in scripts!"
    FOUND=$((FOUND + 1))
fi

# Check .gitignore
if ! grep -q "hetzner.env" .gitignore; then
    echo "❌ hetzner.env not in .gitignore!"
    FOUND=$((FOUND + 1))
fi

if [ $FOUND -eq 0 ]; then
    echo "✅ No secrets exposed"
else
    echo "❌ Found $FOUND security issues"
    exit 1
fi
```

---

### 2. Firewall Rules Audit

```bash
#!/bin/bash
# audit-firewall.sh

echo "Auditing iptables rules..."
echo ""

# Check for logging rules (privacy violation)
if grep -q "LOG" config/iptables-*.rules; then
    echo "⚠️  LOG targets found in iptables rules"
    echo "May violate zero-log policy"
fi

# Check for fail-open rules
if grep -q "ACCEPT.*state.*NEW" config/iptables-leak-proof.rules; then
    echo "✅ Fail-closed rules present"
else
    echo "❌ Missing fail-closed protection"
fi
```

---

### 3. Tor Configuration Audit

```bash
#!/bin/bash
# audit-tor.sh

echo "Auditing Tor configurations..."
echo ""

for torrc in config/torrc-*; do
    echo "Checking $torrc..."
    
    # SafeLogging should be 1
    if grep -q "SafeLogging 0" "$torrc"; then
        echo "❌ SafeLogging disabled (privacy risk)"
    fi
    
    # No exit node
    if ! grep -q "ExitPolicy reject \*:\*" "$torrc"; then
        echo "⚠️  No explicit exit policy"
    fi
done
```

---

### 4. Systemd Service Permissions

```bash
#!/bin/bash
# audit-services.sh

echo "Auditing systemd services..."
echo ""

for service in config/systemd/*.service; do
    echo "Checking $service..."
    
    # Check for root privileges
    if ! grep -q "User=root" "$service"; then
        echo "⚠️  Service runs as root"
    fi
    
    # Check StandardOutput/Error
    if ! grep -q "StandardOutput=null" "$service"; then
        echo "❌ StandardOutput not null (privacy risk)"
    fi
done
```

---

### 5. Dependency Audit

```bash
#!/bin/bash
# audit-dependencies.sh

echo "Checking for outdated packages..."
echo ""

# Check Alpine version
ALPINE_VERSION="3.21"
if grep -q "$ALPINE_VERSION" scripts/build/create-base-image.sh; then
    echo "✅ Alpine $ALPINE_VERSION"
else
    echo "⚠️  Check for Alpine updates"
fi

# List Python dependencies
echo ""
echo "Python packages:"
grep "pip install" scripts/install/* | cut -d' ' -f3
```

---

## Quarterly Security Audit

```bash
#!/bin/bash
# quarterly-security-audit.sh

echo "Quarterly Security Audit"
echo "======================="
echo "Date: $(date +%Y-%m-%d)"
echo ""

ISSUES=0

echo "[1/5] Scanning for secrets..."
bash .agents/scan-secrets.sh
ISSUES=$((ISSUES + $?))

echo ""
echo "[2/5] Auditing firewall rules..."
bash .agents/audit-firewall.sh
ISSUES=$((ISSUES + $?))

echo ""
echo "[3/5] Auditing Tor configuration..."
bash .agents/audit-tor.sh
ISSUES=$((ISSUES + $?))

echo ""
echo "[4/5] Auditing systemd services..."
bash .agents/audit-services.sh
ISSUES=$((ISSUES + $?))

echo ""
echo "[5/5] Checking dependencies..."
bash .agents/audit-dependencies.sh
ISSUES=$((ISSUES + $?))

echo ""
echo "======================="
if [ $ISSUES -eq 0 ]; then
    echo "✅ Security audit complete - No issues"
else
    echo "⚠️  Security audit complete - $ISSUES issues found"
fi
```

---

## Required Reading

1. `docs/SECURITY.md`
2. `docs/ZERO-LOG-POLICY.md`
3. `AGENTS.md`

---

## Tools & Scripts

1. `scan-secrets.sh`
2. `audit-firewall.sh`
3. `audit-tor.sh`
4. `audit-services.sh`
5. `audit-dependencies.sh`
6. `quarterly-security-audit.sh`

---

🌊 **Tide Gateway: Security First. Privacy Always.**
