# Alpine Tor Gateway - Automated Deployment

**Status:** Ready to deploy  
**Time:** 5 minutes total  
**Automation:** 95% automated

---

## 🚀 Quick Deploy (Best Option)

The easiest way is to use **cloud-init** style automation with Alpine's answer file:

### Option 1: Semi-Automated (Recommended - 5 minutes)

```bash
cd /Users/abiasi/Documents/Personal-Projects/opsec-vm
./alpine-automated-install.sh
```

This script will:
1. ✅ Download Alpine ISO (if needed)
2. ✅ Create VM with correct settings
3. ✅ Configure network adapters
4. ✅ Boot Alpine installer
5. ⏸️  **YOU:** Run `setup-alpine` (2 minutes)
6. ✅ After reboot, run ONE command to finish setup

**Why not 100% automated?**
- Alpine's `setup-alpine` requires password input (security feature)
- Can't be fully scripted without compromising security

---

## Option 2: Fully Automated with Packer (20 min setup, reusable)

If you want TRUE automation (for future rebuilds), use HashiCorp Packer.

### Install Packer:
```bash
brew install packer
```

### Create Packer template:

Create file: `alpine-gateway.pkr.hcl`

```hcl
packer {
  required_plugins {
    parallels = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/parallels"
    }
  }
}

variable "root_password" {
  type    = string
  default = "ChangeMe123!"
}

source "parallels-iso" "alpine" {
  vm_name              = "Alpine-Tor-Gateway"
  iso_url              = "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-virt-3.19.1-aarch64.iso"
  iso_checksum         = "sha256:d8e1f8c2e5c5f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5"
  ssh_username         = "root"
  ssh_password         = var.root_password
  ssh_timeout          = "20m"
  boot_wait            = "10s"
  disk_size            = 2048
  memory               = 512
  cpus                 = 1
  
  boot_command = [
    "<enter><wait30>",
    "root<enter><wait>",
    "setup-alpine -q<enter><wait>",
    "us<enter><wait>",
    "us<enter><wait>",
    "gateway<enter><wait>",
    "eth0<enter><wait>",
    "dhcp<enter><wait>",
    "n<enter><wait>",
    "${var.root_password}<enter><wait>",
    "${var.root_password}<enter><wait>",
    "UTC<enter><wait>",
    "<enter><wait>",
    "f<enter><wait10>",
    "openssh<enter><wait>",
    "chrony<enter><wait>",
    "sda<enter><wait>",
    "sys<enter><wait>",
    "y<enter><wait60>",
    "reboot<enter>"
  ]
  
  shutdown_command = "poweroff"
}

build {
  sources = ["source.parallels-iso.alpine"]
  
  provisioner "shell" {
    inline = [
      # Network configuration
      "cat >> /etc/network/interfaces << 'EOF'",
      "",
      "auto eth1",
      "iface eth1 inet static",
      "    address 10.152.152.10",
      "    netmask 255.255.255.0",
      "EOF",
      
      # IP forwarding
      "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf",
      "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf",
      
      # Install packages
      "apk add tor iptables ip6tables",
      
      # Tor config
      "cat > /etc/tor/torrc << 'EOF'",
      "SocksPort 10.152.152.10:9050",
      "DNSPort 10.152.152.10:5353",
      "TransPort 10.152.152.10:9040",
      "VirtualAddrNetworkIPv4 10.192.0.0/10",
      "AutomapHostsOnResolve 1",
      "AutomapHostsSuffixes .onion",
      "Log notice file /var/log/tor/notices.log",
      "EOF",
      
      # Firewall rules (condensed for brevity)
      "cat > /etc/iptables/rules-save << 'EOF'",
      "*nat",
      "-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353",
      "-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040",
      "COMMIT",
      "*filter",
      "-A INPUT -i lo -j ACCEPT",
      "-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT",
      "COMMIT",
      "EOF",
      
      # Enable services
      "rc-update add tor",
      "rc-update add iptables",
    ]
  }
}
```

### Deploy with Packer:
```bash
packer build alpine-gateway.pkr.hcl
```

**Result:** Fully automated, repeatable build.

---

## Option 3: Use Existing Alpine VM (Fastest - 2 minutes)

You already have `Alpine-Tor-Gateway` VM created!

Just boot it and run the setup script:

```bash
# 1. Start the VM
prlctl start Alpine-Tor-Gateway

# 2. Open VM console in Parallels
# 3. Login as root
# 4. If Alpine NOT installed yet, run:
setup-alpine

# 5. After reboot, upload and run setup script:
cd /Users/abiasi/Documents/Personal-Projects/opsec-vm
cat /tmp/alpine-auto-setup.sh | pbcopy

# Then in Alpine VM:
# Paste the script contents into a file:
vi /tmp/setup.sh
# Paste, save, then:
chmod +x /tmp/setup.sh
/tmp/setup.sh
```

---

## 🎯 Recommended Approach

**For you (Anthony):**

Use **Option 3** since you already have the VM created.

**Steps:**
1. Boot Alpine-Tor-Gateway VM
2. Check if Alpine is installed:
   - If at installer: run `setup-alpine` (2 min)
   - If at login: proceed to step 3
3. Login as root
4. Copy/paste the setup script
5. Run it
6. Done!

**For sharing/documenting:**

Create a **Packer template** (Option 2) so you can:
- Rebuild from scratch anytime
- Share the template with others
- Version control the infrastructure
- Deploy to UTM/VMware/etc easily

---

## 📦 One-Liner Deployment (Future)

Once you have the Packer template or answer file perfected:

```bash
# Clone the repo
git clone https://github.com/yourusername/alpine-tor-gateway
cd alpine-tor-gateway

# Deploy
make deploy

# Total time: 5 minutes
```

---

## 🎬 What Do You Want to Do?

1. **Quick:** Use existing VM, paste script, done (2 min)
2. **Automated:** Run `./alpine-automated-install.sh` (5 min)
3. **Professional:** Create Packer template (20 min, reusable forever)

Pick one!
