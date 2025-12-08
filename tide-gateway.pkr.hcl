packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "alpine_iso" {
  type    = string
  default = "alpine-standard-3.21.2-aarch64.iso"
}

variable "alpine_checksum" {
  type    = string
  default = "sha256:8aaf23ac55a0b2576c54d3bb8ad48fe81bd14bdc4def2da2f2d9a8113c66328e"
}

source "qemu" "tide-gateway" {
  iso_url          = "${var.alpine_iso}"
  iso_checksum     = "${var.alpine_checksum}"
  output_directory = "output"
  shutdown_command = "poweroff"
  disk_size        = "2G"
  format           = "qcow2"
  accelerator      = "hvf"
  
  # ARM64 settings
  qemu_binary      = "qemu-system-aarch64"
  machine_type     = "virt"
  cpu_model        = "cortex-a72"
  
  # Headless mode
  headless = true
  
  # UEFI boot
  qemuargs = [
    ["-bios", "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"],
    ["-cpu", "cortex-a72"],
    ["-m", "1024"],
    ["-nographic"],
    ["-serial", "mon:stdio"],
  ]
  
  # Network
  net_device       = "virtio-net-device"
  
  # SSH settings (for provisioning)
  ssh_username     = "root"
  ssh_password     = "tide"
  ssh_timeout      = "20m"
  ssh_port         = 22
  
  # Boot command - types these keys at boot
  boot_wait        = "30s"
  boot_command = [
    # Login as root
    "root<enter><wait5>",
    
    # Setup network
    "ifup eth0<enter><wait3>",
    "setup-interfaces -a -r<enter><wait3>",
    
    # Enable SSH for Packer to connect
    "apk add openssh<enter><wait10>",
    "rc-service sshd start<enter><wait3>",
    "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config<enter>",
    "echo 'root:tide' | chpasswd<enter><wait>",
    "rc-service sshd restart<enter><wait5>",
  ]

  vm_name = "tide-gateway"
}

build {
  sources = ["source.qemu.tide-gateway"]

  # Install Alpine to disk
  provisioner "shell" {
    inline = [
      "export ERASE_DISKS=/dev/vda",
      "cat > /tmp/answers << 'EOF'",
      "KEYMAPOPTS='us us'",
      "HOSTNAMEOPTS='-n tide-gateway'",
      "INTERFACESOPTS='auto lo",
      "iface lo inet loopback",
      "",
      "auto eth0", 
      "iface eth0 inet dhcp'",
      "TIMEZONEOPTS='-z UTC'",
      "PROXYOPTS='none'",
      "APKREPOSOPTS='-1'",
      "SSHDOPTS='-c openssh'",
      "NTPOPTS='-c chrony'",
      "DISKOPTS='-m sys /dev/vda'",
      "EOF",
      "setup-alpine -f /tmp/answers -e << 'PASS'",
      "tide",
      "tide",
      "y",
      "PASS",
    ]
  }

  # Reboot into installed system
  provisioner "shell" {
    inline = ["reboot"]
    expect_disconnect = true
  }

  # Wait for reboot
  provisioner "shell" {
    pause_before = "30s"
    inline       = ["echo 'System rebooted'"]
  }

  # Install and configure Tor gateway
  provisioner "shell" {
    inline = [
      # Install packages
      "apk add --no-cache tor iptables ip6tables",
      
      # Configure Tor
      "cat > /etc/tor/torrc << 'EOF'",
      "User tor",
      "DataDirectory /var/lib/tor",
      "SocksPort 0.0.0.0:9050",
      "DNSPort 0.0.0.0:5353", 
      "TransPort 0.0.0.0:9040",
      "VirtualAddrNetworkIPv4 10.192.0.0/10",
      "AutomapHostsOnResolve 1",
      "Log notice syslog",
      "EOF",
      
      # Configure LAN interface
      "cat >> /etc/network/interfaces << 'EOF'",
      "",
      "auto eth1",
      "iface eth1 inet static",
      "    address 10.101.101.10",
      "    netmask 255.255.255.0",
      "EOF",
      
      # Sysctl
      "mkdir -p /etc/sysctl.d",
      "echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/tide.conf",
      "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/tide.conf",
      
      # IPTables
      "mkdir -p /etc/iptables",
      "cat > /etc/iptables/rules-save << 'EOF'",
      "*nat",
      ":PREROUTING ACCEPT [0:0]",
      ":INPUT ACCEPT [0:0]",
      ":OUTPUT ACCEPT [0:0]",
      ":POSTROUTING ACCEPT [0:0]",
      "-A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353",
      "-A PREROUTING -i eth1 -p tcp --dport 53 -j REDIRECT --to-ports 5353",
      "-A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040",
      "COMMIT",
      "*filter",
      ":INPUT DROP [0:0]",
      ":FORWARD DROP [0:0]",
      ":OUTPUT ACCEPT [0:0]",
      "-A INPUT -i lo -j ACCEPT",
      "-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT",
      "-A INPUT -i eth1 -p tcp --dport 9050 -j ACCEPT",
      "-A INPUT -i eth1 -p tcp --dport 9040 -j ACCEPT",
      "-A INPUT -i eth1 -p udp --dport 5353 -j ACCEPT",
      "-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT",
      "-A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT",
      "COMMIT",
      "EOF",
      
      # Enable services
      "rc-update add tor default",
      "rc-update add iptables default",
      
      # Create iptables loader
      "cat > /etc/local.d/iptables.start << 'EOF'",
      "#!/bin/sh",
      "iptables-restore < /etc/iptables/rules-save",
      "sysctl -p /etc/sysctl.d/tide.conf",
      "EOF",
      "chmod +x /etc/local.d/iptables.start",
      "rc-update add local default",
      
      # Mark complete
      "echo 'Tide Gateway $(date)' > /root/BUILD_COMPLETE",
    ]
  }
}
