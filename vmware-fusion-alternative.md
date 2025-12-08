# VMware Fusion Player - Free Alternative to Parallels

## Download
https://www.vmware.com/products/fusion/fusion-evaluation.html

- Free for personal use
- ARM64 support (Tech Preview)
- Should support clipboard with Linux VMs

## Setup Same Architecture

1. Create two VMs with Debian 12 ARM64
2. Configure networking:
   - Gateway: NAT + Host-Only
   - Workstation: Host-Only only
3. Apply same Tor configs we already have

## Migration Path

All our scripts should work identically:
- fix-tor-gateway.sh
- make-gateway-permanent.sh  
- install-xfce.sh
- fix-workstation-network.sh

Just need to recreate the VMs in VMware instead of Parallels.

## Test First

Install VMware Fusion, create ONE test VM, install Parallels Tools equivalent (VMware Tools), and test if clipboard works with Linux before migrating everything.
