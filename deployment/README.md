# Tide Gateway Deployment

## Recommended: Hetzner Cloud

**Cost:** ~$0.003 per test  
**Speed:** Server ready in 30 seconds  
**Perfect for:** Automated testing, CI/CD, production

```bash
cd hetzner/
./test-on-hetzner.sh
```

[→ Hetzner Deployment Guide](hetzner/)

---

## Parallels Desktop (macOS)

**Cost:** Free (runs on your Mac)  
**Speed:** 5 minutes to deploy  
**Perfect for:** Development, testing on macOS

```bash
cd parallels/
./ONE-COMMAND-DEPLOY.sh
```

[→ Parallels Deployment Guide](parallels/)

---

## QEMU/KVM (Linux)

**Cost:** Free (runs on your server)  
**Speed:** Manual setup required  
**Perfect for:** Linux servers, bare metal

```bash
cd qemu/
./build-qemu-image.sh
```

[→ QEMU Deployment Guide](qemu/)

---

**[← Back to Main README](../README.md)**
