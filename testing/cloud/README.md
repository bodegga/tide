# Cloud Testing for Killa-Whale Mode

## 🚀 Quick Start (30 seconds!)

### First Time Setup (one-time, ~3 minutes):
```bash
# Create pre-configured VM snapshots
./create-golden-images.sh
```

### Run Tests (30 seconds):
```bash
# Use pre-baked snapshots for blazing fast tests
./test-killa-whale-snapshot.sh
```

That's it! Your test will complete in ~30 seconds instead of 6 minutes.

---

## 📊 Test Options

| Script | Time | Cost | When to Use |
|--------|------|------|-------------|
| `test-killa-whale-snapshot.sh` | **30s** | €0.10/mo | **Daily testing (RECOMMENDED)** |
| `test-killa-whale-cloudinit.sh` | 90s | €0 | One-off tests without setup |
| `test-killa-whale-v2.sh` | 6min | €0 | Legacy/debug purposes |

## 🏗️ How Snapshots Work

### The Problem:
Traditional cloud tests are SLOW because:
1. Create fresh VMs (30s)
2. Wait for SSH (10s)
3. **Install packages via apt-get (5 minutes)** ⬅️ BOTTLENECK
4. Configure services (1min)
5. Run test (10s)

**Total: 6-7 minutes** 😢

### The Solution:
Pre-bake VM images (snapshots) with everything installed:
1. Boot from pre-configured snapshots (20s)
2. VMs are ready immediately (no apt-get needed!)
3. Run test (10s)

**Total: 30 seconds** 🚀

---

## 🛠️ Snapshot Management

### Create/Update Golden Images
```bash
# First time setup
./create-golden-images.sh

# Monthly updates (or run when packages need updating)
./create-golden-images.sh
```

**This creates 3 snapshots:**
- `tide-golden-gateway` - Real gateway with NAT/routing
- `tide-golden-tide` - Tide with Tor/arping pre-installed
- `tide-golden-victim` - Minimal victim device

**Cost:** ~€0.10/month for storage (€1.20/year total)

### Automatic Updates (GitHub Actions)
Snapshots are automatically refreshed monthly via GitHub Actions:
- Workflow: `.github/workflows/update-golden-images.yml`
- Schedule: 1st of every month at 3 AM
- Manual trigger: Available in Actions tab

### Manual Snapshot Deletion
```bash
# List snapshots
hcloud image list | grep tide-golden

# Delete specific snapshot
hcloud image delete <snapshot-id>

# Or delete all
source ~/.config/tide/golden-images.env
hcloud image delete $GOLDEN_GATEWAY_ID $GOLDEN_TIDE_ID $GOLDEN_VICTIM_ID
rm ~/.config/tide/golden-images.env
```

---

## 💰 Cost Breakdown

### What Costs Money:
- ✅ **Running VMs:** €0.0052/hour (CX23)
  - Test duration: 30 seconds
  - Test cost: ~€0.0001 (basically free)
- ✅ **Snapshots:** €0.0119/GB/month
  - 3 snapshots × ~3GB each = ~€0.10/month
  - Annual cost: **€1.20/year**
- ❌ **Networks:** FREE
- ❌ **Stopped VMs:** Same as running (no savings)

### Total Cost for Fast Testing:
- **Setup:** €0 (just time)
- **Per test:** ~€0.0001 (negligible)
- **Storage:** €0.10/month (€1.20/year)

**Worth it?** Absolutely! Save 5.5 minutes per test = hundreds of hours saved per year.

---

## 🔧 Configuration

### Snapshot IDs
Located in: `~/.config/tide/golden-images.env`

```bash
GOLDEN_GATEWAY_ID=12345678
GOLDEN_TIDE_ID=12345679
GOLDEN_VICTIM_ID=12345680
```

### Hetzner API Token
Located in: `~/.config/tide/hetzner.env`

```bash
HETZNER_TIDE_TOKEN=your_token_here
```

---

## 📝 Test Workflow

### 1. Create Golden Images (Monthly)
```bash
./create-golden-images.sh
```
- Creates 3 temporary VMs
- Installs all packages via cloud-init (~2-3 min)
- Creates snapshots from configured VMs
- Deletes temporary VMs
- Saves snapshot IDs to `~/.config/tide/golden-images.env`

### 2. Run Fast Tests (Anytime)
```bash
./test-killa-whale-snapshot.sh
```
- Creates network
- Boots 3 VMs from snapshots (~20s)
- VMs are pre-configured, ready immediately
- Runs ARP poisoning test (~10s)
- Validates results
- Cleans up

---

## 🐛 Troubleshooting

### "Golden images not found"
```bash
# Run this first
./create-golden-images.sh
```

### "Hetzner token not found"
```bash
# Setup token
mkdir -p ~/.config/tide
echo "HETZNER_TIDE_TOKEN=your_token" > ~/.config/tide/hetzner.env
```

### "Resource limit exceeded"
```bash
# You hit Hetzner's free tier limits (3 servers max)
# Clean up old servers:
hcloud server list
hcloud server delete <server-name>
```

### Test is slow
```bash
# Check if using correct script
./test-killa-whale-snapshot.sh  # ✅ Fast (30s)
./test-killa-whale-cloudinit.sh # ⚠️ Slower (90s)
./test-killa-whale-v2.sh         # ❌ Very slow (6min)
```

### Snapshots need updates
```bash
# Refresh monthly or when packages need updating
./create-golden-images.sh <<< "y"
```

---

## 📚 More Information

- **Snapshot strategy:** See `FAST-TESTING-STRATEGY.md`
- **Performance analysis:** See `FAST-TEST-SUMMARY.md`
- **Cloud-init docs:** https://community.hetzner.com/tutorials/basic-cloud-config

---

## 🎯 Best Practices

1. **Use snapshots for daily testing** (30s)
2. **Refresh snapshots monthly** (auto via GitHub Actions)
3. **Always clean up test VMs** (avoid costs)
4. **Keep networks** (they're free and save time)
5. **Document snapshot IDs** (in git-ignored config)

---

## ✅ Success Metrics

With snapshot-based testing:
- **Test time:** 30 seconds (vs 6 minutes)
- **12x faster** than traditional approach
- **Cost:** Basically free (<€2/year)
- **Maintenance:** Automated via GitHub Actions
- **Developer happiness:** 📈 (tests don't interrupt flow!)
