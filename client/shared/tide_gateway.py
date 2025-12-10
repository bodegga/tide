"""
Tide Gateway API Client
========================
Shared module for discovering and communicating with Tide Gateway.
Used by all client platforms (macOS, Windows, Linux).
"""

import socket
import subprocess
import sys
import json
from typing import Optional, Dict, Any
from urllib.request import urlopen, Request
from urllib.error import URLError
from time import sleep


class TideGateway:
    """Tide Gateway Discovery and API Client"""
    
    def __init__(self):
        self.gateway_ip: Optional[str] = None
        self.api_port = 9051
        self.socks_port = 9050
        self.dns_port = 5353
        self.connected = False
        self.status: Dict[str, Any] = {}
        self.api_token: Optional[str] = None
    
    # ─────────────────────────────────────────────────────────────
    # Discovery
    # ─────────────────────────────────────────────────────────────
    
    def discover(self) -> Optional[str]:
        """
        Try to find Tide gateway on the network.
        Returns: Gateway IP if found, None otherwise
        """
        # Common gateway IPs to check
        candidates = [
            "10.101.101.10",     # Default Tide IP
            "192.168.1.1",
            "192.168.0.1",
            "10.0.0.1",
        ]
        
        # Try to find via default gateway
        try:
            default_gw = self._get_default_gateway()
            if default_gw:
                candidates.insert(0, default_gw)
        except:
            pass
        
        # Check each candidate
        for ip in candidates:
            if self._check_gateway(ip):
                return ip
        
        # Listen for UDP beacon as last resort
        beacon_ip = self._listen_beacon(timeout=3)
        if beacon_ip and self._check_gateway(beacon_ip):
            return beacon_ip
            
        return None
    
    def _check_gateway(self, ip: str) -> bool:
        """Check if IP is a Tide gateway"""
        try:
            url = f"http://{ip}:{self.api_port}/status"
            req = Request(url, headers={'User-Agent': 'TideClient/1.0'})
            
            with urlopen(req, timeout=2) as response:
                data = json.loads(response.read().decode())
                
                if data.get("gateway") == "tide":
                    self.gateway_ip = ip
                    self.status = data
                    return True
        except:
            pass
        
        return False
    
    def _get_default_gateway(self) -> Optional[str]:
        """Get system's default gateway IP"""
        try:
            if sys.platform == "darwin":
                result = subprocess.run(
                    ["route", "-n", "get", "default"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                for line in result.stdout.split("\n"):
                    if "gateway:" in line:
                        return line.split(":")[1].strip()
            
            elif sys.platform == "linux":
                result = subprocess.run(
                    ["ip", "route"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                for line in result.stdout.split("\n"):
                    if line.startswith("default"):
                        return line.split()[2]
            
            elif sys.platform == "win32":
                result = subprocess.run(
                    ["ipconfig"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                for line in result.stdout.split("\n"):
                    if "Default Gateway" in line and ":" in line:
                        gateway = line.split(":")[-1].strip()
                        if gateway and gateway != "":
                            return gateway
        except:
            pass
        
        return None
    
    def _listen_beacon(self, timeout: int = 5) -> Optional[str]:
        """Listen for Tide UDP beacon broadcast"""
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
    
    def get_status(self) -> Optional[Dict[str, Any]]:
        """Get gateway status"""
        if not self.gateway_ip:
            return None
        
        try:
            url = f"http://{self.gateway_ip}:{self.api_port}/status"
            req = Request(url, headers={'User-Agent': 'TideClient/1.0'})
            
            with urlopen(req, timeout=5) as response:
                self.status = json.loads(response.read().decode())
                return self.status
        except:
            return None
    
    def get_circuit(self) -> Optional[Dict[str, Any]]:
        """Get current Tor circuit/exit info"""
        if not self.gateway_ip:
            return None
        
        try:
            url = f"http://{self.gateway_ip}:{self.api_port}/circuit"
            req = Request(url, headers={'User-Agent': 'TideClient/1.0'})
            
            with urlopen(req, timeout=10) as response:
                return json.loads(response.read().decode())
        except:
            return None
    
    def new_circuit(self) -> bool:
        """Request new Tor circuit (requires authentication)"""
        if not self.gateway_ip:
            return False
        
        # Try to get token from gateway if we don't have it
        if not self.api_token:
            self._fetch_token()
        
        try:
            url = f"http://{self.gateway_ip}:{self.api_port}/newcircuit"
            headers = {'User-Agent': 'TideClient/1.0'}
            
            # Add Bearer token if available
            if self.api_token:
                headers['Authorization'] = f'Bearer {self.api_token}'
            
            req = Request(url, headers=headers)
            
            with urlopen(req, timeout=5) as response:
                data = json.loads(response.read().decode())
                return data.get("success", False)
        except:
            return False
    
    def _fetch_token(self):
        """Fetch API token from gateway's /token endpoint"""
        if not self.gateway_ip:
            return
        
        try:
            # First check environment variable
            import os
            token = os.getenv('TIDE_API_TOKEN')
            if token:
                self.api_token = token
                return
            
            # Otherwise fetch from gateway
            url = f"http://{self.gateway_ip}:{self.api_port}/token"
            req = Request(url, headers={'User-Agent': 'TideClient/1.0'})
            
            with urlopen(req, timeout=5) as response:
                data = json.loads(response.read().decode())
                self.api_token = data.get("token")
        except:
            pass
    
    def check_tor(self) -> Optional[Dict[str, Any]]:
        """Verify Tor connectivity through gateway"""
        if not self.gateway_ip:
            return None
        
        try:
            url = f"http://{self.gateway_ip}:{self.api_port}/check"
            req = Request(url, headers={'User-Agent': 'TideClient/1.0'})
            
            with urlopen(req, timeout=15) as response:
                return json.loads(response.read().decode())
        except:
            return None
    
    # ─────────────────────────────────────────────────────────────
    # Proxy Configuration (Platform-specific)
    # ─────────────────────────────────────────────────────────────
    
    def connect(self) -> bool:
        """Configure system to use Tide gateway proxy"""
        if not self.gateway_ip:
            return False
        
        if sys.platform == "darwin":
            return self._connect_macos()
        elif sys.platform == "linux":
            return self._connect_linux()
        elif sys.platform == "win32":
            return self._connect_windows()
        
        return False
    
    def disconnect(self) -> bool:
        """Remove Tide proxy configuration"""
        if sys.platform == "darwin":
            return self._disconnect_macos()
        elif sys.platform == "linux":
            return self._disconnect_linux()
        elif sys.platform == "win32":
            return self._disconnect_windows()
        
        return False
    
    def _connect_macos(self) -> bool:
        """Configure macOS SOCKS proxy"""
        try:
            # Get network services
            result = subprocess.run(
                ["networksetup", "-listallnetworkservices"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            services = [s for s in result.stdout.split("\n") 
                       if s and not s.startswith("*")]
            
            # Try common services first
            for service in ["Wi-Fi", "Ethernet"] + services:
                try:
                    subprocess.run([
                        "networksetup", "-setsocksfirewallproxy",
                        service, self.gateway_ip, str(self.socks_port)
                    ], capture_output=True, timeout=5, check=False)
                    
                    subprocess.run([
                        "networksetup", "-setsocksfirewallproxystate",
                        service, "on"
                    ], capture_output=True, timeout=5, check=False)
                except:
                    continue
            
            self.connected = True
            return True
        except:
            return False
    
    def _disconnect_macos(self) -> bool:
        """Disable macOS SOCKS proxy"""
        try:
            result = subprocess.run(
                ["networksetup", "-listallnetworkservices"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            services = [s for s in result.stdout.split("\n") 
                       if s and not s.startswith("*")]
            
            for service in ["Wi-Fi", "Ethernet"] + services:
                try:
                    subprocess.run([
                        "networksetup", "-setsocksfirewallproxystate",
                        service, "off"
                    ], capture_output=True, timeout=5, check=False)
                except:
                    continue
            
            self.connected = False
            return True
        except:
            return False
    
    def _connect_linux(self) -> bool:
        """Configure Linux proxy (GNOME + env vars)"""
        try:
            # Try GNOME settings
            try:
                subprocess.run([
                    "gsettings", "set", "org.gnome.system.proxy", 
                    "mode", "manual"
                ], capture_output=True, timeout=5, check=False)
                
                subprocess.run([
                    "gsettings", "set", "org.gnome.system.proxy.socks", 
                    "host", self.gateway_ip
                ], capture_output=True, timeout=5, check=False)
                
                subprocess.run([
                    "gsettings", "set", "org.gnome.system.proxy.socks", 
                    "port", str(self.socks_port)
                ], capture_output=True, timeout=5, check=False)
            except:
                pass
            
            self.connected = True
            return True
        except:
            return False
    
    def _disconnect_linux(self) -> bool:
        """Disable Linux proxy"""
        try:
            subprocess.run([
                "gsettings", "set", "org.gnome.system.proxy", 
                "mode", "none"
            ], capture_output=True, timeout=5, check=False)
            
            self.connected = False
            return True
        except:
            return False
    
    def _connect_windows(self) -> bool:
        """Configure Windows proxy"""
        try:
            import winreg
            
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
                0, winreg.KEY_SET_VALUE
            )
            
            winreg.SetValueEx(key, "ProxyEnable", 0, winreg.REG_DWORD, 1)
            winreg.SetValueEx(
                key, "ProxyServer", 0, winreg.REG_SZ, 
                f"socks={self.gateway_ip}:{self.socks_port}"
            )
            winreg.CloseKey(key)
            
            # Notify system of change
            try:
                import ctypes
                INTERNET_OPTION_SETTINGS_CHANGED = 39
                INTERNET_OPTION_REFRESH = 37
                internet_set_option = ctypes.windll.Wininet.InternetSetOptionW
                internet_set_option(0, INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
                internet_set_option(0, INTERNET_OPTION_REFRESH, 0, 0)
            except:
                pass
            
            self.connected = True
            return True
        except:
            return False
    
    def _disconnect_windows(self) -> bool:
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
            
            # Notify system
            try:
                import ctypes
                INTERNET_OPTION_SETTINGS_CHANGED = 39
                INTERNET_OPTION_REFRESH = 37
                internet_set_option = ctypes.windll.Wininet.InternetSetOptionW
                internet_set_option(0, INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
                internet_set_option(0, INTERNET_OPTION_REFRESH, 0, 0)
            except:
                pass
            
            self.connected = False
            return True
        except:
            return False
