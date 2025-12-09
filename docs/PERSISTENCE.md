# Tide Gateway Persistence Guide
## Saving State Between Reboots

The Tide Gateway can maintain state between reboots in several ways, depending on your deployment method.

### VM Deployments (QEMU/UTM/Parallels)

#### Option 1: Persistent Disk Image (Recommended)
- The `tide-gateway.qcow2` image is persistent by default
- All configuration changes, Tor state, and logs are saved automatically
- Simply shut down and restart the VM - state is preserved

#### Option 2: Cloud-init with Persistent Data
If you need to rebuild the image but keep data:

```bash
# Create a separate data disk
qemu-img create -f qcow2 tide-data.qcow2 1G

# Attach it to VM and mount at /var/lib/tor-data
# Tor data directory can be moved to persistent storage
```

#### Option 3: Export/Import VM State
```bash
# Export current state
qemu-img convert -O qcow2 tide-gateway.qcow2 tide-gateway-backup.qcow2

# Restore later
cp tide-gateway-backup.qcow2 tide-gateway.qcow2
```

### Docker Deployments

#### Persistent Tor State
```bash
# Mount host directory for Tor data
docker run -d \
  --name tide \
  -p 9050:9050 \
  -p 5353:5353/udp \
  -v /host/tor-data:/var/lib/tor \
  bodegga/tide
```

#### Persistent Configuration
```bash
# Mount config directory
docker run -d \
  --name tide \
  -v /host/tide-config:/etc/tide \
  bodegga/tide
```

### Alpine ISO Installations

#### Persistent System Changes
- Install to disk for full persistence
- Use `lbu` (Local Backup) for config persistence:

```bash
# Commit changes to APK cache
lbu commit

# Include in future ISOs
lbu package - | gzip > alpine-tide.apkovl.tar.gz
```

#### Tor State Persistence
```bash
# Tor data is in /var/lib/tor by default
# Ensure /var is on persistent storage

# Check current data directory
grep DataDirectory /etc/tor/torrc
```

### Backup Strategies

#### Automated Backups
```bash
#!/bin/bash
# Daily backup script
DATE=$(date +%Y%m%d)
qemu-img convert -O qcow2 tide-gateway.qcow2 "backups/tide-gateway-$DATE.qcow2"

# Keep last 7 days
ls backups/tide-gateway-*.qcow2 | head -n -7 | xargs rm -f
```

#### Configuration Backup
```bash
# Backup all config files
tar czf tide-config-backup.tar.gz \
  /etc/tor/torrc \
  /etc/iptables/rules-save \
  /etc/network/interfaces \
  /etc/sysctl.d/tide.conf
```

### State Recovery

#### From Backup
```bash
# Restore VM image
cp backups/tide-gateway-20241207.qcow2 tide-gateway.qcow2

# Restore configs
tar xzf tide-config-backup.tar.gz -C /
```

#### Emergency Recovery
If the gateway becomes unresponsive:

1. Boot from backup image
2. Check system logs: `dmesg | tail`
3. Verify Tor: `rc-service tor status`
4. Test connectivity: `curl --socks5 127.0.0.1:9050 https://check.torproject.org`

### Best Practices

- **Regular Backups**: Backup weekly during low-usage periods
- **Test Restores**: Verify backups work before relying on them
- **Monitor Disk Space**: Tor data can grow over time
- **Document Changes**: Keep notes on configuration modifications
- **Version Control**: Use git for configuration files when possible

### Troubleshooting Persistence Issues

#### Tor State Not Persisting
```bash
# Check if /var/lib/tor is on persistent storage
df /var/lib/tor

# Verify permissions
ls -la /var/lib/tor
```

#### Configuration Not Applied
```bash
# Check if files are immutable
lsattr /etc/tor/torrc

# Remove immutability if needed
chattr -i /etc/tor/torrc
```

#### Network Config Reset
```bash
# Reapply network config
ifup eth1
sysctl -p /etc/sysctl.d/tide.conf
iptables-restore < /etc/iptables/rules-save
```</content>
<parameter name="filePath">/Users/abiasi/Documents/Personal-Projects/tide/docs/PERSISTENCE.md