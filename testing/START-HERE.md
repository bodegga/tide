# 🌊 Tide Gateway - Testing Infrastructure

**START HERE** for automated testing across multiple platforms.

---

## ⚡️ Fastest Test (2 minutes)

```bash
cd /Users/abiasi/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh
```

**That's it.** Fully automated Docker testing in under 3 minutes.

---

## 📚 Documentation Index

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **START-HERE.md** | You are here - Quick overview | 2 min |
| **QUICKSTART.md** | Get testing in 5 minutes | 3 min |
| **README.md** | Complete testing documentation | 10 min |
| **PLATFORM-COMPARISON.md** | Platform analysis & recommendations | 8 min |
| **IMPLEMENTATION-SUMMARY.md** | Technical implementation details | 12 min |

---

## 🎯 What's Available

### Fully Automated ✅
- **Docker** - `./containers/test-docker.sh` (2-3 min, free)
- **Hetzner Cloud** - `./cloud/test-hetzner.sh` (5 min, ~$0.01)

### Semi-Automated ⚠️
- **QEMU** - `./hypervisors/test-qemu.sh` (requires manual Alpine setup)
- **VirtualBox** - `./hypervisors/test-virtualbox.sh` (requires VirtualBox install)

---

## 🚀 Quick Decision Tree

```
What do you need?

├─ Fast dev testing → Docker (test-docker.sh)
├─ Production validation → Hetzner (test-hetzner.sh)
├─ Offline ARM testing → QEMU (test-qemu.sh)
└─ Visual debugging → VirtualBox (test-virtualbox.sh)
```

---

## ✅ What Gets Tested

Every platform validates:

1. ✅ **CLI Commands** - `tide status` works
2. ✅ **Configuration** - `/etc/tide/mode` and `/etc/tide/security` exist
3. ✅ **Services** - Tor, API server, dnsmasq running
4. ✅ **Tor Connectivity** - SOCKS5 proxy works, exit IP validated
5. ✅ **Mode Switching** - Can switch between proxy/router/killa-whale
6. ✅ **API Endpoints** - REST API responds with valid JSON

---

## 📊 Platform Comparison

| Platform | Time | Cost | Automation | Killa Whale |
|----------|------|------|------------|-------------|
| Docker | 2-3 min | Free | 100% | ❌ No |
| Hetzner | 5 min | $0.01 | 100% | ✅ Yes |
| QEMU | 15 min | Free | 40% | ✅ Yes |
| VirtualBox | 15 min | Free | 40% | ✅ Yes |

---

## 🎓 First Time? Start Here

### Step 1: Run Docker Test
```bash
cd /Users/abiasi/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh
```

**Why:** Fastest, free, fully automated. Proves the test framework works.

### Step 2: Read the Output
The script will:
- Build Docker image
- Start container
- Wait for Tor bootstrap
- Run 5 test categories
- Show ✅ for passed tests
- Auto-cleanup

### Step 3: If Successful
You now have a working test framework! Use it on every commit.

### Step 4: Before Releases
Run Hetzner test for production validation:
```bash
cd /Users/abiasi/Documents/Personal-Projects/tide/testing/cloud
./test-hetzner.sh
```

---

## 🔧 Prerequisites

### Docker Testing (Ready Now)
```bash
docker info  # Should work
```

### Hetzner Testing (Requires Setup)
```bash
# 1. Install hcloud CLI
brew install hcloud

# 2. Get API token from: https://console.hetzner.cloud/
# 3. Save token
mkdir -p ~/.config/tide
echo 'export HETZNER_TIDE_TOKEN="your-token"' > ~/.config/tide/hetzner.env
```

### QEMU Testing (Already Installed)
```bash
which qemu-system-aarch64  # Should show: /opt/homebrew/bin/qemu-system-aarch64
ls alpine-virt-3.21.0-aarch64.iso  # Should exist in tide/ directory
```

### VirtualBox Testing (Not Installed)
```bash
brew install --cask virtualbox  # If you want VirtualBox testing
```

---

## 📁 Directory Structure

```
testing/
├── START-HERE.md                    ← You are here
├── QUICKSTART.md                    ← 5-minute guide
├── README.md                        ← Complete docs
├── PLATFORM-COMPARISON.md           ← Platform analysis
├── IMPLEMENTATION-SUMMARY.md        ← Technical details
│
├── containers/
│   ├── test-docker.sh               ← Fastest test (start here)
│   └── docker-compose-test.yml      ← Multi-mode testing
│
├── cloud/
│   └── test-hetzner.sh              ← Production validation
│
└── hypervisors/
    ├── test-qemu.sh                 ← Local ARM testing
    └── test-virtualbox.sh           ← GUI debugging
```

---

## 🎯 Recommended Workflow

### Daily Development
```bash
# Every commit
cd testing/containers && ./test-docker.sh
```

### Before Git Push
```bash
# Verify everything works
cd testing/containers && ./test-docker.sh
```

### Before Release
```bash
# Production validation (~$0.01)
cd testing/cloud && ./test-hetzner.sh
```

**Annual cost:** ~$1 USD (for ~100 production tests)  
**Time per release:** 5-10 minutes  
**Bugs caught:** Countless

---

## 🐛 Common Issues

### Docker Build Fails
```bash
# Check Docker is running
docker info

# Check Dockerfile exists
ls /Users/abiasi/Documents/Personal-Projects/tide/docker/Dockerfile.gateway
```

### Tor Connectivity Fails
```bash
# Tor needs 30-90 seconds to bootstrap
# Scripts wait automatically
# If still failing, check:
docker logs <container-id>
```

### Port Conflicts
```bash
# Check if port 9050 is already in use
lsof -i :9050

# Kill conflicting process or stop other Tor instances
```

---

## 📖 Next Steps

1. **Run your first test** - `./containers/test-docker.sh`
2. **Read QUICKSTART.md** - Learn all test options
3. **Read README.md** - Complete documentation
4. **Set up Hetzner** - For production validation (optional)

---

## 🎁 What You Get

✅ **4 testing platforms** ready to use  
✅ **2 fully automated** (Docker, Hetzner)  
✅ **6 test categories** per platform  
✅ **Comprehensive docs** (5 guides)  
✅ **Production-proven** (Hetzner already tested)  
✅ **Self-contained** (no dependencies)

---

## 🚦 Status Check

Run this to verify your setup:

```bash
cd /Users/abiasi/Documents/Personal-Projects/tide/testing

# Check Docker
docker info && echo "✅ Docker ready"

# Check Hetzner (if configured)
[ -f ~/.config/tide/hetzner.env ] && echo "✅ Hetzner configured" || echo "⚠️  Hetzner not configured"

# Check QEMU
which qemu-system-aarch64 && echo "✅ QEMU ready"

# Check VirtualBox
which VBoxManage && echo "✅ VirtualBox ready" || echo "⚠️  VirtualBox not installed"

# Check Alpine ISO
ls -lh /Users/abiasi/Documents/Personal-Projects/tide/alpine-virt-3.21.0-aarch64.iso && echo "✅ Alpine ISO ready"
```

---

## ⏱ Time Investment

| Task | Time | Frequency |
|------|------|-----------|
| First Docker test | 3 min | Once |
| Daily Docker tests | 2-3 min | Per commit |
| Hetzner setup | 5 min | Once |
| Hetzner tests | 5 min | Per release |
| Reading docs | 15 min | Once |

**Total first-time setup:** ~25 minutes  
**Ongoing per release:** ~5-10 minutes

---

## 💡 Pro Tips

1. **Always test with Docker first** - It's fastest and free
2. **Use Hetzner before releases** - Real hardware validation
3. **Don't skip tests** - They catch real issues
4. **Read the output** - Tests show exactly what's working
5. **Check logs if tests fail** - Docker logs are your friend

---

## 🎉 Success!

If you can run `./containers/test-docker.sh` successfully, you have:

✅ Working test framework  
✅ Automated validation  
✅ Production-ready testing  
✅ CI/CD ready infrastructure

**You're ready to test Tide Gateway like a pro.**

---

## 📞 Need Help?

1. **Read QUICKSTART.md** - Covers 90% of questions
2. **Read README.md** - Complete troubleshooting guide
3. **Check script output** - Tests show detailed error messages
4. **Review logs** - `docker logs <container-id>`

---

## 🚀 Let's Go!

```bash
# Your first test starts now:
cd /Users/abiasi/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh
```

**Expected runtime:** 2-3 minutes  
**Expected result:** All tests pass with ✅  
**What's next:** Use this on every commit

---

**Welcome to automated Tide Gateway testing!**

*Last Updated: December 10, 2024*  
*Tide Version: 1.2.0*  
*Testing Framework: 1.0*
