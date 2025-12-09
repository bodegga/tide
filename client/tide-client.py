#!/usr/bin/env python3
"""
Tide Client - Cross-Platform GUI
================================
Auto-discovers Tide Gateway and provides one-click Tor connectivity.

Requirements: pip install requests pystray Pillow

Usage: python tide-client.py
"""

import os
import sys
import json
import socket
import threading
import subprocess
import requests
from time import sleep

# Try to import GUI libraries
try:
    import pystray
    from PIL import Image, ImageDraw
    HAS_GUI = True
except ImportError:
    HAS_GUI = False
    print("Note: Install 'pystray' and 'Pillow' for system tray icon")


class TideClient:
    def __init__(self):
        self.gateway_ip = None
        self.api_port = 9051
        self.socks_port = 9050
        self.dns_port = 5353
        self.connected = False
        self.status = {}
        
    # ─────────────────────────────────────────────────────────────
    # Discovery
    # ─────────────────────────────────────────────────────────────
    
    def discover(self):
        """Try to find Tide gateway on the network"""
        
        # Common gateway IPs to check
        candidates = [
            "10.101.101.1",      # Default Tide IP
            "192.168.1.1",
            "192.168.0.1",
            "10.0.0.1",
        ]
        
        # Also try to find via DHCP gateway
        try:
            default_gw = self._get_default_gateway()
            if default_gw:
                candidates.insert(0, default_gw)
        except:
            pass
        
        for ip in candidates:
            if self._check_gateway(ip):
                return ip
        
        # Listen for UDP beacon
        beacon_ip = self._listen_beacon(timeout=5)
        if beacon_ip and self._check_gateway(beacon_ip):
            return beacon_ip
            
        return None
    
    def _check_gateway(self, ip):
        """Check if IP is a Tide gateway"""
        try:
            r = requests.get(f"http://{ip}:{self.api_port}/status", timeout=2)
            data = r.json()
            if data.get("gateway") == "tide":
                self.gateway_ip = ip
                self.status = data
                return True
        except:
            pass
        return False
    
    def _get_default_gateway(self):
        """Get system's default gateway IP"""
        if sys.platform == "darwin":
            result = subprocess.run(["route", "-n", "get", "default"], capture_output=True, text=True)
            for line in result.stdout.split("\n"):
                if "gateway:" in line:
                    return line.split(":")[1].strip()
        elif sys.platform == "linux":
            result = subprocess.run(["ip", "route"], capture_output=True, text=True)
            for line in result.stdout.split("\n"):
                if line.startswith("default"):
                    return line.split()[2]
        return None
    
    def _listen_beacon(self, timeout=5):
        """Listen for Tide UDP beacon"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            sock.settimeout(timeout)
            sock.bind(("", 19050))
            
            data, addr = sock.recvfrom(1024)
            message = data.decode()
            if message.startswith("TIDE:"):
                parts = message.split(":")
                return parts[1] if len(parts) >= 2 else None
        except:
            pass
        return None
    
    # ─────────────────────────────────────────────────────────────
    # Status & Control
    # ─────────────────────────────────────────────────────────────
    
    def get_status(self):
        """Get gateway status"""
        if not self.gateway_ip:
            return None
        try:
            r = requests.get(f"http://{self.gateway_ip}:{self.api_port}/status", timeout=5)
            self.status = r.json()
            return self.status
        except:
            return None
    
    def get_circuit(self):
        """Get current Tor circuit/exit info"""
        if not self.gateway_ip:
            return None
        try:
            r = requests.get(f"http://{self.gateway_ip}:{self.api_port}/circuit", timeout=10)
            return r.json()
        except:
            return None
    
    def new_circuit(self):
        """Request new Tor circuit"""
        if not self.gateway_ip:
            return False
        try:
            r = requests.get(f"http://{self.gateway_ip}:{self.api_port}/newcircuit", timeout=5)
            return r.json().get("success", False)
        except:
            return False
    
    def check_tor(self):
        """Verify Tor connectivity through gateway"""
        if not self.gateway_ip:
            return None
        try:
            r = requests.get(f"http://{self.gateway_ip}:{self.api_port}/check", timeout=15)
            return r.json()
        except:
            return None
    
    # ─────────────────────────────────────────────────────────────
    # System Proxy Configuration
    # ─────────────────────────────────────────────────────────────
    
    def connect(self):
        """Configure system to use Tide gateway"""
        if not self.gateway_ip:
            print("No gateway found")
            return False
        
        if sys.platform == "darwin":
            return self._connect_macos()
        elif sys.platform == "linux":
            return self._connect_linux()
        elif sys.platform == "win32":
            return self._connect_windows()
        
        return False
    
    def disconnect(self):
        """Remove Tide proxy configuration"""
        if sys.platform == "darwin":
            return self._disconnect_macos()
        elif sys.platform == "linux":
            return self._disconnect_linux()
        elif sys.platform == "win32":
            return self._disconnect_windows()
        
        return False
    
    def _connect_macos(self):
        """Configure macOS proxy"""
        try:
            # Get active network service
            result = subprocess.run(
                ["networksetup", "-listallnetworkservices"],
                capture_output=True, text=True
            )
            services = [s for s in result.stdout.split("\n") if s and not s.startswith("*")]
            
            for service in ["Wi-Fi", "Ethernet"] + services:
                subprocess.run([
                    "networksetup", "-setsocksfirewallproxy",
                    service, self.gateway_ip, str(self.socks_port)
                ], capture_output=True)
                subprocess.run([
                    "networksetup", "-setsocksfirewallproxystate",
                    service, "on"
                ], capture_output=True)
            
            self.connected = True
            return True
        except Exception as e:
            print(f"Error: {e}")
            return False
    
    def _disconnect_macos(self):
        """Disable macOS proxy"""
        try:
            result = subprocess.run(
                ["networksetup", "-listallnetworkservices"],
                capture_output=True, text=True
            )
            services = [s for s in result.stdout.split("\n") if s and not s.startswith("*")]
            
            for service in ["Wi-Fi", "Ethernet"] + services:
                subprocess.run([
                    "networksetup", "-setsocksfirewallproxystate",
                    service, "off"
                ], capture_output=True)
            
            self.connected = False
            return True
        except:
            return False
    
    def _connect_linux(self):
        """Configure Linux proxy (GNOME/env vars)"""
        try:
            # Set environment variables
            os.environ["ALL_PROXY"] = f"socks5://{self.gateway_ip}:{self.socks_port}"
            os.environ["all_proxy"] = f"socks5://{self.gateway_ip}:{self.socks_port}"
            
            # Try GNOME settings
            subprocess.run([
                "gsettings", "set", "org.gnome.system.proxy", "mode", "manual"
            ], capture_output=True)
            subprocess.run([
                "gsettings", "set", "org.gnome.system.proxy.socks", "host", self.gateway_ip
            ], capture_output=True)
            subprocess.run([
                "gsettings", "set", "org.gnome.system.proxy.socks", "port", str(self.socks_port)
            ], capture_output=True)
            
            self.connected = True
            return True
        except:
            return False
    
    def _disconnect_linux(self):
        """Disable Linux proxy"""
        try:
            os.environ.pop("ALL_PROXY", None)
            os.environ.pop("all_proxy", None)
            
            subprocess.run([
                "gsettings", "set", "org.gnome.system.proxy", "mode", "none"
            ], capture_output=True)
            
            self.connected = False
            return True
        except:
            return False
    
    def _connect_windows(self):
        """Configure Windows proxy"""
        try:
            import winreg
            
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
                0, winreg.KEY_SET_VALUE
            )
            
            winreg.SetValueEx(key, "ProxyEnable", 0, winreg.REG_DWORD, 1)
            winreg.SetValueEx(key, "ProxyServer", 0, winreg.REG_SZ, 
                            f"socks={self.gateway_ip}:{self.socks_port}")
            winreg.CloseKey(key)
            
            self.connected = True
            return True
        except:
            return False
    
    def _disconnect_windows(self):
        """Disable Windows proxy"""
        try:
            import winreg
            
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
                0, winreg.KEY_SET_VALUE
            )
            
            winreg.SetValueEx(key, "ProxyEnable", 0, winreg.REG_DWORD, 0)
            winreg.CloseKey(key)
            
            self.connected = False
            return True
        except:
            return False


# ─────────────────────────────────────────────────────────────
# System Tray GUI
# ─────────────────────────────────────────────────────────────

def create_icon():
    """Create the tray icon image"""
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw a wave-like icon
    draw.ellipse([8, 8, 56, 56], fill=(0, 150, 200))
    draw.ellipse([16, 16, 48, 48], fill=(0, 100, 150))
    draw.ellipse([24, 24, 40, 40], fill=(0, 50, 100))
    
    return img


def run_gui(client):
    """Run the system tray GUI"""
    if not HAS_GUI:
        print("GUI not available. Run in CLI mode.")
        return
    
    def on_connect(icon, item):
        if client.gateway_ip:
            if client.connect():
                icon.notify("Connected to Tide Gateway", "Tide")
            else:
                icon.notify("Failed to connect", "Tide")
        else:
            icon.notify("No gateway found", "Tide")
    
    def on_disconnect(icon, item):
        client.disconnect()
        icon.notify("Disconnected from Tide", "Tide")
    
    def on_new_circuit(icon, item):
        if client.new_circuit():
            icon.notify("New circuit requested", "Tide")
    
    def on_status(icon, item):
        status = client.get_status()
        circuit = client.get_circuit()
        
        if status:
            msg = f"Mode: {status.get('mode', '?')}\n"
            msg += f"Tor: {status.get('tor', '?')}\n"
            if circuit:
                msg += f"Exit: {circuit.get('IP', '?')}"
            icon.notify(msg, "Tide Status")
        else:
            icon.notify("Cannot reach gateway", "Tide")
    
    def on_quit(icon, item):
        client.disconnect()
        icon.stop()
    
    # Build menu
    menu = pystray.Menu(
        pystray.MenuItem(
            lambda text: f"🌊 {client.gateway_ip or 'Searching...'}", 
            None, 
            enabled=False
        ),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Connect", on_connect),
        pystray.MenuItem("Disconnect", on_disconnect),
        pystray.MenuItem("New Circuit", on_new_circuit),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Status", on_status),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Quit", on_quit)
    )
    
    icon = pystray.Icon("Tide", create_icon(), "Tide Client", menu)
    
    # Background discovery
    def discovery_loop():
        while True:
            if not client.gateway_ip:
                client.discover()
            else:
                client.get_status()
            sleep(10)
    
    threading.Thread(target=discovery_loop, daemon=True).start()
    
    # Start icon
    icon.run()


# ─────────────────────────────────────────────────────────────
# CLI Mode
# ─────────────────────────────────────────────────────────────

def run_cli(client):
    """Run in CLI mode"""
    print("🌊 Tide Client")
    print("=" * 40)
    
    print("Searching for gateway...")
    ip = client.discover()
    
    if ip:
        print(f"✓ Found gateway: {ip}")
        status = client.get_status()
        if status:
            print(f"  Mode: {status.get('mode', '?')}")
            print(f"  Security: {status.get('security', '?')}")
            print(f"  Tor: {status.get('tor', '?')}")
        
        circuit = client.get_circuit()
        if circuit:
            print(f"  Exit IP: {circuit.get('IP', '?')}")
        
        print()
        print("Commands:")
        print("  c - Connect (set system proxy)")
        print("  d - Disconnect")
        print("  n - New circuit")
        print("  s - Status")
        print("  q - Quit")
        print()
        
        while True:
            try:
                cmd = input("> ").strip().lower()
                
                if cmd == "c":
                    if client.connect():
                        print("✓ Connected")
                    else:
                        print("✗ Failed to connect")
                
                elif cmd == "d":
                    client.disconnect()
                    print("✓ Disconnected")
                
                elif cmd == "n":
                    if client.new_circuit():
                        print("✓ New circuit requested")
                    else:
                        print("✗ Failed")
                
                elif cmd == "s":
                    status = client.get_status()
                    circuit = client.get_circuit()
                    print(f"Tor: {status.get('tor', '?') if status else '?'}")
                    print(f"Exit: {circuit.get('IP', '?') if circuit else '?'}")
                
                elif cmd == "q":
                    client.disconnect()
                    break
                    
            except KeyboardInterrupt:
                client.disconnect()
                break
    else:
        print("✗ No Tide gateway found")
        print("Make sure you're on the same network as the Tide Gateway")


# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    client = TideClient()
    
    # Try to find gateway immediately
    client.discover()
    
    if "--cli" in sys.argv or not HAS_GUI:
        run_cli(client)
    else:
        run_gui(client)
