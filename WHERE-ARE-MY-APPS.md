# Where Are My Apps? - Quick Reference

**Date:** 2025-12-07  
**Issue:** Apps installed but not showing in Applications menu  
**Solution:** Menu refreshed + this guide

---

## 🎯 Where to Find Your Apps

### 📂 Applications Menu Categories

**Click the Applications menu (top-left)** → Look in these categories:

| Category | Apps You'll Find |
|----------|------------------|
| **Internet** | Firefox, HexChat, Pidgin, Transmission |
| **Graphics** | GIMP |
| **Multimedia** | VLC Media Player |
| **Office** | LibreOffice (Writer, Calc, Impress, Base, Math, Draw) |
| **Accessories** | Text editors (gedit, mousepad), KeePassXC |
| **System** | Terminal, File Manager |
| **Settings** | Various system settings |

---

## 🚀 Launch Apps from Terminal (Always Works)

If apps still don't show in the menu, you can always launch them from terminal:

### Internet & Communication
```bash
firefox &                    # Firefox browser
hexchat &                    # IRC client
pidgin &                     # Instant messenger
transmission-gtk &           # Torrent client
remmina &                    # Remote desktop
```

### Graphics & Media
```bash
gimp &                       # Image editor
vlc &                        # Media player
```

### Office & Productivity
```bash
libreoffice --writer &       # Word processor
libreoffice --calc &         # Spreadsheet
libreoffice --impress &      # Presentations
libreoffice --draw &         # Drawing
libreoffice --base &         # Database
libreoffice &                # Start Center (shows all apps)
```

### Text Editors
```bash
gedit &                      # GNOME text editor
mousepad &                   # XFCE text editor
vim filename                 # Terminal editor (advanced)
nano filename                # Terminal editor (simple)
```

### Security & Crypto
```bash
keepassxc &                  # Password manager
kleopatra &                  # PGP key manager
```

### Development Tools
```bash
htop                         # System monitor
tmux                         # Terminal multiplexer
screen                       # Alternative multiplexer
git                          # Version control
```

---

## 🔧 If Menu Still Doesn't Show Apps

### Method 1: Manual Menu Refresh (from VM terminal)
```bash
DISPLAY=:0 xfce4-panel -r
DISPLAY=:0 xfdesktop --reload
```

### Method 2: Log Out and Back In
- Click Applications → Log Out
- Log back in
- Menu will be fully rebuilt

### Method 3: Rebuild Menu Cache
```bash
sudo update-desktop-database /usr/share/applications/
killall xfce4-panel
xfce4-panel &
```

### Method 4: Check if .desktop files exist
```bash
ls -la /usr/share/applications/ | grep -E 'hexchat|pidgin|gimp|libreoffice|vlc|keepass'
```

Should show files like:
- `hexchat.desktop`
- `pidgin.desktop`
- `gimp.desktop`
- `org.keepassxc.KeePassXC.desktop`
- `libreoffice-writer.desktop`
- `vlc.desktop`

---

## 📋 Quick Test: Are Apps Actually Installed?

Run this in terminal to verify installations:

```bash
# Check if apps are installed
dpkg -l | grep -E 'hexchat|pidgin|gimp|vlc|keepassxc|libreoffice' | awk '{print $2}'
```

Should show:
- hexchat
- pidgin
- gimp
- vlc
- keepassxc
- libreoffice (multiple packages)

---

## 🎯 My Top Recommendations

### Essential Apps to Set Up First:

1. **KeePassXC** (Password Manager)
   ```bash
   keepassxc &
   ```
   - Create database: `~/passwords.kdbx`
   - Use strong master password
   - Store ALL your passwords here

2. **Tor Browser** (Install manually)
   ```bash
   mkdir -p ~/tor-browser && cd ~/tor-browser
   wget https://www.torproject.org/dist/torbrowser/13.5.7/tor-browser-linux-arm64-13.5.7.tar.xz
   tar -xf tor-browser-linux-arm64-13.5.7.tar.xz
   ~/tor-browser/tor-browser/Browser/start-tor-browser
   ```

3. **HexChat** (IRC for secure comms)
   ```bash
   hexchat &
   ```

4. **Pidgin + OTR** (Encrypted instant messaging)
   ```bash
   pidgin &
   ```
   - Enable OTR plugin: Tools → Plugins → "Off-the-Record Messaging"

---

## 🔍 Troubleshooting Menu Issues

### Issue: "I refreshed but still don't see apps"

**Try this:**
1. Open Terminal (in Applications menu or Ctrl+Alt+T)
2. Run: `ls /usr/share/applications/*.desktop | wc -l`
   - Should show 100+ .desktop files
3. Run: `echo $XDG_DATA_DIRS`
   - Should include `/usr/share`
4. Run: `xfce4-appfinder` (opens app finder GUI)
   - Search for your apps here as alternative to menu

### Issue: "Menu shows old apps but not new ones"

**Solution:**
```bash
# Clear menu cache
rm -rf ~/.cache/xfce4/
rm -rf ~/.cache/sessions/

# Restart panel
xfce4-panel -r
```

### Issue: "Apps work from terminal but not from menu"

**This is fine!** Keep using terminal to launch apps:
```bash
# Add aliases to ~/.bashrc for quick access
echo "alias keep='keepassxc &'" >> ~/.bashrc
echo "alias irc='hexchat &'" >> ~/.bashrc
echo "alias tor='~/tor-browser/tor-browser/Browser/start-tor-browser &'" >> ~/.bashrc
source ~/.bashrc

# Now you can just type:
keep     # Launches KeePassXC
irc      # Launches HexChat
tor      # Launches Tor Browser
```

---

## 📱 Create Your Own Desktop Shortcuts

If you want apps on desktop:

```bash
# Copy app launchers to desktop
cp /usr/share/applications/hexchat.desktop ~/Desktop/
cp /usr/share/applications/pidgin.desktop ~/Desktop/
cp /usr/share/applications/org.keepassxc.KeePassXC.desktop ~/Desktop/
cp /usr/share/applications/gimp.desktop ~/Desktop/

# Make them executable
chmod +x ~/Desktop/*.desktop
```

---

## ✅ Apps Currently Installed

**Confirmed installed and working:**
- ✅ Firefox ESR (pre-installed)
- ✅ HexChat (IRC)
- ✅ Pidgin + OTR (IM)
- ✅ KeePassXC (passwords)
- ✅ Kleopatra + GPG (encryption)
- ✅ GIMP (graphics)
- ✅ VLC (media)
- ✅ LibreOffice (full suite)
- ✅ Transmission (torrents)
- ✅ Remmina (remote desktop)
- ✅ gedit, mousepad (text editors)
- ✅ vim, nano (terminal editors)
- ✅ git, curl, wget, htop, tmux, screen

**Still to install:**
- ⏳ Tor Browser (manual install needed)

---

## 💡 Pro Tip: Use App Finder

**Can't find an app in the menu?**

Press **Alt+F2** or **Alt+F3** to open the XFCE Application Finder.

Type the app name (e.g., "hexchat", "gimp", "keepass") and press Enter!

This searches ALL installed apps, even if menu categories are messed up.

---

**Bottom line: Even if the menu doesn't show apps perfectly, you can ALWAYS launch them from terminal. They're installed and working!**

---

*Created: 2025-12-07 by OpenCode*
*Last menu refresh: 2025-12-07 17:30*

---

## 🆕 UPDATE: Fixed Issues (2025-12-07 17:40)

### ✅ Default Browser Fixed
Firefox is now set as the default browser. Clicking web links will open Firefox.

### ✅ GUI Text Editors Added

**Geany** - The Notepad++ alternative for Linux!
```bash
geany &              # Launch Geany
```

**Features:**
- Syntax highlighting for 50+ languages
- Code folding
- Auto-completion
- Plugin support
- Project management
- Find/Replace with regex
- Tabbed interface
- Lightweight and fast

**Also Available:**
- **gedit** - Simple text editor (like Windows Notepad but better)
  ```bash
  gedit &
  ```

- **mousepad** - XFCE lightweight editor
  ```bash
  mousepad &
  ```

**Find them in menu:**
- Applications → Accessories → Geany
- Applications → Accessories → Text Editor (gedit/mousepad)

---

*Last updated: 2025-12-07 17:40 PST*
