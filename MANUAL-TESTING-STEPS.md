# Tide Gateway Manual Testing Steps

## Current Status

✅ **Gateway VM**: Running  
✅ **Test Client VM**: Running  
⚠️ **Automation**: Not possible (Parallels Tools not installed in VMs)

---

## Testing Checklist

### Step 1: Access Gateway Console

```bash
# Open gateway console
prlctl enter Tide-Gateway
```

**In the gateway console:**
1. Login (credentials should be `root` / `tide` or just `root` no password)
2. Run these commands:

```bash
# Check what's running
ps aux | grep -E "tor|dnsmasq|tide-web|gateway-start" | head -20

# Check if config files exist
ls -la /etc/tide/
cat /etc/tide/mode 2>/dev/null
cat /etc/tide/security 2>/dev/null

# Check network interfaces
ip addr show

# Check if tide CLI works
which tide
tide status 2>/dev/null || echo "tide command not found"

# Check if web dashboard is running
netstat -tulpn | grep :80 || ss -tulpn | grep :80

# Check dnsmasq config for DNS hijacking
cat /etc/dnsmasq.conf | grep tide.bodegga.net
```

**Expected Results:**
- `/etc/tide/mode` should exist (may be empty or contain a mode)
- `/etc/tide/security` should exist (may be empty or contain a profile)
- Should see `tor` process running
- Should see `dnsmasq` running (if mode is router/killa-whale)
- Should see `python3` process for web dashboard
- Port 80 should be listening
- dnsmasq.conf should have `address=/tide.bodegga.net/10.101.101.10`

---

### Step 2: Configure Gateway (If Needed)

**If tide CLI is available:**
```bash
# Check if tide-config.sh exists
ls -la /usr/local/bin/tide*

# If tide command works:
tide mode killa-whale
tide security standard

# Or use config tool directly:
/usr/local/bin/tide-config.sh mode killa-whale
```

**If tide CLI is NOT available (old gateway):**
```bash
# Manually set mode
mkdir -p /etc/tide
echo "killa-whale" > /etc/tide/mode
echo "standard" > /etc/tide/security

# Check if gateway-start.sh exists
ls -la /usr/local/bin/gateway-start.sh

# If it doesn't exist, this is an old gateway that needs UPDATE-TO-V1.2.sh
```

---

### Step 3: Update Gateway to v1.2.0 (If Needed)

**If the gateway doesn't have the new tools:**

```bash
# Download update script (if internet access works)
wget -O /tmp/update.sh https://raw.githubusercontent.com/bodegga/tide/main/UPDATE-TO-V1.2.sh

# Run it
sh /tmp/update.sh

# Or manually install files:
# (This requires copying files from the repo to the VM)
```

**Note:** This gateway might be from v1.1.1 or earlier and won't have:
- `tide` CLI command
- `tide-config.sh`
- `tide-web-dashboard.py`
- DNS hijacking for tide.bodegga.net

---

### Step 4: Access Test Client Console

```bash
# Open client console (from your Mac terminal)
prlctl enter Tide-Test-Client-1
```

**In the client console (after Alpine boots):**

1. Login as `root` (no password on fresh Alpine)

2. Configure network for DHCP:

```bash
# Setup network interfaces
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Start networking
rc-service networking start

# Wait a few seconds, then check IP
ip addr show eth0

# Should get 10.101.101.xxx if gateway DHCP is working
```

3. Install testing tools:

```bash
# Add packages
apk add curl lynx bind-tools

# Test DNS resolution
nslookup tide.bodegga.net

# Should resolve to 10.101.101.10 if DNS hijacking works
```

4. Test web dashboard:

```bash
# Test with curl
curl http://tide.bodegga.net

# Should return HTML if web dashboard is running

# Test API endpoint
curl http://10.101.101.10:9051/status

# Test in text browser
lynx http://tide.bodegga.net
```

---

### Step 5: Test Results Documentation

**Record your findings:**

#### Gateway Status
- [ ] Gateway booted successfully
- [ ] Tor is running
- [ ] dnsmasq is running (if not in proxy mode)
- [ ] Web dashboard server is running (port 80)
- [ ] tide CLI is available
- [ ] Config files exist in /etc/tide/

#### Client Network
- [ ] Client got DHCP IP (10.101.101.xxx)
- [ ] Client can ping gateway (10.101.101.10)
- [ ] DNS resolution works
- [ ] tide.bodegga.net resolves to 10.101.101.10

#### Web Dashboard
- [ ] http://tide.bodegga.net loads
- [ ] Dashboard shows Tor status
- [ ] Dashboard shows correct mode
- [ ] Dashboard shows connected clients
- [ ] API endpoint works (http://10.101.101.10:9051/status)

#### Mode Switching
- [ ] Can run `tide config`
- [ ] Can switch modes with `tide mode <mode>`
- [ ] Services restart after mode change
- [ ] Dashboard reflects new mode after change

---

## Issues Found & Fixes

### Issue: Gateway doesn't have v1.2.0 features

**Cause:** Gateway was created before v1.2.0 changes were pushed

**Fix Options:**

1. **Update existing gateway:**
   - Get internet access in gateway VM
   - Run UPDATE-TO-V1.2.sh script

2. **Deploy new gateway from template:**
   - Use DEPLOY-TEMPLATE.sh with latest code
   - Or manually install new scripts

3. **Clone and update:**
   - Clone existing gateway
   - Mount repo files and copy scripts manually

### Issue: No Parallels Tools (automation doesn't work)

**Cause:** Alpine Linux VMs don't have Parallels Tools installed

**Fix:** Add to future builds:
```bash
# In Alpine VM
apk add parallels-tools
rc-update add parallels-tools boot
rc-service parallels-tools start
```

### Issue: Client can't get DHCP

**Cause:** Gateway is in proxy mode (no DHCP server)

**Fix:**
```bash
# In gateway
tide mode router
# or
tide mode killa-whale
```

### Issue: DNS hijacking not working

**Cause:** dnsmasq.conf doesn't have the address= line

**Fix:**
```bash
# In gateway
echo "address=/tide.bodegga.net/10.101.101.10" >> /etc/dnsmasq.conf
killall -HUP dnsmasq
```

---

## Observations for Anthony

After testing, note:

1. **Which gateway version is running:** v1.1.1 or earlier?
2. **Do the new features work:** tide CLI, web dashboard, mode switching?
3. **Does DNS hijacking work:** tide.bodegga.net resolution?
4. **Performance:** How fast does dashboard load?
5. **Any errors:** Note any error messages or issues

---

## Next Steps After Manual Testing

1. Document which gateway needs updating
2. Test mode switching if available
3. Test with second client VM
4. Consider adding Parallels Tools to gateway build for automation
5. Create updated gateway template with all v1.2.0 features

---

## Automation Note

For future testing automation, we need to either:

**Option A:** Install Parallels Tools in gateway VMs
- Enables `prlctl exec` commands
- Allows scripted testing
- Requires rebuilding gateway template

**Option B:** Use cloud-init or other automation
- Pre-configure everything in cloud-init
- No manual console access needed
- Already partially implemented

**Option C:** Accept manual testing
- VMs are lightweight
- Testing is quick via console
- Good for development/debugging

---

**Current Status:** VMs are running, ready for manual console testing via `prlctl enter`
