# OPSEC VM - Applications Installed

**Date:** 2025-12-07  
**Status:** ✅ Apps Deployed (Tor Browser needs manual install)

---

## ✅ Successfully Installed Applications

### 📝 Text Editors
- **vim** - Powerful terminal text editor
- **nano** - Simple terminal text editor
- **gedit** - GUI text editor (GNOME)
- **mousepad** - Lightweight XFCE text editor

### 🛠 Development Tools
- **git** - Version control
- **curl** / **wget** - Download tools
- **tree** - Directory tree viewer
- **htop** - System monitor
- **tmux** / **screen** - Terminal multiplexers

### 💬 Communication Tools
- **HexChat** - IRC client for secure chats
- **Pidgin** - Multi-protocol instant messenger
  - Includes **pidgin-otr** (Off-The-Record encryption plugin)

### 🔐 Crypto & Security
- **KeePassXC** - Password manager (ESSENTIAL!)
- **GPG** / **Kleopatra** - PGP encryption & key management
- **qrencode** / **zbar-tools** - QR code generation and scanning

### 📦 Utilities
- **LibreOffice** - Full office suite (Writer, Calc, Impress)
- **VLC** - Media player
- **GIMP** - Image editor
- **Transmission** - Torrent client (GTK)
- **Remmina** - Remote desktop client

### 🌐 Web Browsers
- **Firefox ESR** - Already installed (from golden image)
- **Tor Browser** - ❌ Download failed during automated install (see manual steps below)

---

## 🔧 Manual: Install Tor Browser

The automated download failed. Here's how to install it manually:

### From SecuredWorkstation Terminal:

```bash
# Create directory
mkdir -p ~/tor-browser
cd ~/tor-browser

# Download Tor Browser for ARM64
wget https://www.torproject.org/dist/torbrowser/13.5.7/tor-browser-linux-arm64-13.5.7.tar.xz

# Extract
tar -xf tor-browser-linux-arm64-13.5.7.tar.xz

# Clean up
rm tor-browser-linux-arm64-13.5.7.tar.xz

# Launch Tor Browser
~/tor-browser/tor-browser/Browser/start-tor-browser
```

### Create Desktop Shortcut (Optional):

```bash
cat > ~/Desktop/tor-browser.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Tor Browser
Exec=/root/tor-browser/tor-browser/Browser/start-tor-browser
Icon=/root/tor-browser/tor-browser/Browser/browser/chrome/icons/default/default128.png
Terminal=false
Categories=Network;WebBrowser;
EOF

chmod +x ~/Desktop/tor-browser.desktop
```

---

## 🎯 How to Launch Applications

### From XFCE Menu (GUI):
- Click **Applications** menu (top-left)
- Navigate categories:
  - **Accessories** → Mousepad, gedit
  - **Graphics** → GIMP
  - **Internet** → Firefox, HexChat, Pidgin, Transmission
  - **Office** → LibreOffice
  - **Multimedia** → VLC
  - **Utility** → KeePassXC

### From Terminal:
```bash
# Text editors
vim filename
nano filename
gedit filename &
mousepad filename &

# Web browsers
firefox &
~/tor-browser/tor-browser/Browser/start-tor-browser &

# Communication
hexchat &
pidgin &

# Security
keepassxc &
kleopatra &

# Utilities
libreoffice &
vlc &
gimp &
transmission-gtk &
remmina &

# Development
git status
htop
tmux
```

---

## 🔐 First-Time Setup Recommendations

### 1. Set Up KeePassXC (Password Manager)

```bash
keepassxc &
```

- Create new database
- Use strong master password
- Store in `/root/keepass.kdbx`
- Store all your passwords here

### 2. Generate GPG Key (PGP Encryption)

```bash
gpg --full-generate-key
```

- Select: RSA and RSA (default)
- Key size: 4096
- Expiration: 1 year (or never)
- Enter name and email
- Use strong passphrase

**Export public key:**
```bash
gpg --armor --export your@email.com > ~/pgp-public-key.asc
```

### 3. Verify Tor Routing

```bash
# Check if traffic goes through Tor
curl https://check.torproject.org/api/ip

# Should return: {"IsTor":true,"IP":"<tor-exit-node>"}
```

### 4. Configure Pidgin with OTR

- Launch Pidgin
- Tools → Plugins → Enable "Off-the-Record Messaging"
- Configure your accounts (IRC, XMPP, etc.)
- Always use OTR for encrypted chats

---

## 📊 Disk Usage

Check how much space apps are using:

```bash
du -sh /usr/bin/* | sort -h | tail -20
df -h
```

---

## 🔄 Updating Applications

### Update all packages:
```bash
sudo apt update
sudo apt upgrade
```

### Update Tor Browser:
- Download latest from https://www.torproject.org/download/
- Extract to replace old version

---

## 🧹 Uninstalling Applications

If you need to remove apps to save space:

```bash
# Remove specific app
sudo apt remove APP_NAME

# Remove app and dependencies
sudo apt autoremove APP_NAME

# Example: Remove LibreOffice if you don't need it
sudo apt autoremove libreoffice
```

---

## 📝 Notes

### Pre-installed (from Golden Image):
- XFCE desktop environment
- Firefox ESR
- Basic system utilities
- Parallels Tools
- Network tools

### Newly Installed Today:
- All the apps listed above
- ~400MB additional disk space used
- ~173 new packages installed

### Still To-Do:
- ❌ Install Tor Browser manually
- ⏳ Set up KeePassXC database
- ⏳ Generate GPG keys
- ⏳ Configure Pidgin accounts

---

## 🚀 Quick Start Workflow

**Daily OPSEC Work Routine:**

1. **Start VMs:**
   ```bash
   prlctl start Tor-Gateway && prlctl start SecuredWorkstation
   ```

2. **Verify Tor routing:**
   ```bash
   curl https://check.torproject.org/api/ip
   ```

3. **Launch Tor Browser:**
   ```bash
   ~/tor-browser/tor-browser/Browser/start-tor-browser &
   ```

4. **Open KeePassXC for passwords:**
   ```bash
   keepassxc &
   ```

5. **Do your work securely** ✅

6. **When done, stop VMs:**
   ```bash
   prlctl stop SecuredWorkstation && prlctl stop Tor-Gateway
   ```

---

## 🎉 You're All Set!

You now have a fully-equipped OPSEC workstation with:
- ✅ Text editors for coding/writing
- ✅ Secure communication tools (IRC, IM with encryption)
- ✅ Crypto tools (GPG, password manager)
- ✅ Standard productivity apps (office, media, graphics)
- ✅ Development tools (git, terminal multiplexers)

**Just need to install Tor Browser manually and you're ready to go!**

---

*Deployed: 2025-12-07 by OpenCode*
*Total apps installed: 20+ packages*
