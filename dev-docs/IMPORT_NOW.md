# IMPORT TIDE GATEWAY INTO PARALLELS - 60 SECONDS

## The VMDK is ready at:
/Users/abiasi/Documents/Personal-Projects/opsec-vm/tide-flat.vmdk

## Do this NOW in Parallels (it's opening):

1. **File → New** (or Cmd+N)
2. Click **"Install Windows or another OS from a DVD or image file"**
3. Click **"select a file..."**
4. Navigate to: `/Users/abiasi/Documents/Personal-Projects/opsec-vm`
5. Select: **tide-flat.vmdk**
6. Click **Continue**
7. Select OS: **Other Linux**
8. Name: **Tide-Gateway**
9. **Before clicking Create**, uncheck "Customize settings before use"
10. Click **Create**

## If it boots:
- You'll see Alpine Linux boot
- Wait 30 seconds
- Try: `ssh root@<ip-from-parallels>` password: unknown (cloud image has no default)

## If it doesn't boot:
- The VMDK boots perfectly in QEMU
- Parallels is just being difficult with the disk format
- We can use UTM instead (5 minute setup)

## What you're importing:
- ✅ Alpine Linux 3.19 (168MB)
- ✅ ARM64 UEFI bootable
- ✅ Tested and working in QEMU
- ❌ NOT yet configured with Tor (needs post-install script)

The automation will come AFTER we prove we can boot it in Parallels.
