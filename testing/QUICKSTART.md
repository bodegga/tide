# Tide Gateway - Testing Quick Start

**Get testing in under 5 minutes.**

---

## 🚀 Fastest Path: Docker

**Time:** 2-3 minutes  
**Cost:** Free  
**Automation:** 100%

```bash
cd /Users/abiasi/Documents/Personal-Projects/tide/testing/containers
./test-docker.sh
```

**That's it.** Script handles everything:
- Builds Docker image
- Starts container
- Waits for Tor bootstrap
- Runs full test suite
- Cleans up automatically

---

## ✅ What Gets Tested

Every test script validates:

1. **Installation** - CLI commands, config files, scripts in place
2. **Services** - Tor daemon, API server, dnsmasq (router mode)
3. **Tor Connectivity** - SOCKS5 proxy, exit IP validation
4. **Mode Switching** - Proxy, router, killa-whale modes
5. **API Endpoints** - REST API responds with valid JSON

---

## 📋 All Test Scripts

### Docker (Recommended First)
```bash
cd testing/containers
./test-docker.sh                    # Single container test
docker-compose -f docker-compose-test.yml up -d  # Multi-mode test
```

### Hetzner Cloud (Production Validation)
```bash
cd testing/cloud
./test-hetzner.sh                   # Requires: Hetzner API token
```

### QEMU (Advanced - Manual Setup)
```bash
cd testing/hypervisors
./test-qemu.sh                      # Requires: manual Alpine install
```

### VirtualBox (When Available)
```bash
cd testing/hypervisors
./test-virtualbox.sh                # Requires: VirtualBox installed
```

---

## 🎯 Recommended Workflow

### Daily Development
```bash
# Quick validation (2-3 min)
cd testing/containers && ./test-docker.sh
```

### Before Release
```bash
# Production validation (5 min, ~$0.01)
cd testing/cloud && ./test-hetzner.sh
```

### Full Multi-Mode Test
```bash
# All Docker modes simultaneously
cd testing/containers
docker-compose -f docker-compose-test.yml up -d

# Test each mode
curl --socks5 localhost:9050 https://check.torproject.org/api/ip  # Proxy
curl --socks5 localhost:9052 https://check.torproject.org/api/ip  # Hardened
curl --socks5 localhost:9054 https://check.torproject.org/api/ip  # Paranoid

# Cleanup
docker-compose -f docker-compose-test.yml down
```

---

## 📊 Platform Comparison

| Platform | Time | Cost | Automation | Use Case |
|----------|------|------|------------|----------|
| Docker | 2-3 min | Free | 100% | Daily development |
| Hetzner | 5 min | $0.01 | 100% | Pre-release validation |
| QEMU | 15 min | Free | 40% | Offline ARM testing |
| VirtualBox | 15 min | Free | 40% | GUI debugging |

**Start with Docker. Validate with Hetzner.**

---

## 🔧 Prerequisites

### Docker Testing
```bash
# Check Docker is running
docker info

# That's all you need
```

### Hetzner Testing
```bash
# 1. Install hcloud CLI
brew install hcloud

# 2. Create API token at: https://console.hetzner.cloud/
# 3. Save to config file
mkdir -p ~/.config/tide
echo 'export HETZNER_TIDE_TOKEN="your-token-here"' > ~/.config/tide/hetzner.env
```

### QEMU Testing
```bash
# Install QEMU
brew install qemu

# Verify Alpine ISO exists
ls -lh /Users/abiasi/Documents/Personal-Projects/tide/alpine-virt-3.21.0-aarch64.iso
```

### VirtualBox Testing
```bash
# Install VirtualBox
brew install --cask virtualbox

# Or download from: https://www.virtualbox.org/wiki/Downloads
```

---

## 🐛 Troubleshooting

### Docker Test Fails
```bash
# Check Docker daemon
docker info

# Check for port conflicts
lsof -i :9050

# Clean up stuck containers
docker ps -a | grep tide-test | awk '{print $1}' | xargs docker rm -f
```

### Hetzner Test Fails
```bash
# Verify token
cat ~/.config/tide/hetzner.env

# Test hcloud CLI
hcloud server list

# Manual cleanup if needed
hcloud server list | grep tide-test
hcloud server delete <server-name>
```

### Tests Pass but Tor Not Working
```bash
# Tor needs 30-60 seconds to bootstrap
# Tests wait automatically, but you can check manually:

# Inside container
docker exec <container-id> sh -c "pgrep -x tor && echo 'Tor running'"

# Test SOCKS5 manually
curl --socks5 localhost:9050 https://check.torproject.org/api/ip
```

---

## 📚 More Info

- **Full documentation:** `testing/README.md`
- **Platform comparison:** `testing/PLATFORM-COMPARISON.md`
- **Detailed matrix:** `testing/PLATFORM-TEST-MATRIX.md`

---

## 🎯 One-Command Testing

```bash
# From project root
cd /Users/abiasi/Documents/Personal-Projects/tide

# Run Docker tests
./testing/containers/test-docker.sh

# Run Hetzner tests (if configured)
./testing/cloud/test-hetzner.sh
```

---

**Estimated time to first test:** < 5 minutes  
**Recommended for new users:** Docker  
**Recommended for production:** Hetzner

**Questions?** See `testing/README.md` for complete documentation.
