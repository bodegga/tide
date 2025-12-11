#!/usr/bin/env python3
"""
Tide API Server
===============
Simple HTTP API server for Tide Gateway discovery and control.
Runs on port 9051.

Security:
- Read-only endpoints (/status, /circuit, /check) are open
- Write endpoints (/newcircuit) require Bearer token authentication
"""

import http.server
import socketserver
import json
import subprocess
import os
import secrets
from urllib.parse import urlparse

PORT = 9051

# Generate or load API token
# Set TIDE_API_TOKEN env var for custom token, otherwise auto-generate
API_TOKEN = os.getenv('TIDE_API_TOKEN')
if not API_TOKEN:
    # Generate a random token and save it
    API_TOKEN = secrets.token_urlsafe(32)
    token_file = '/etc/tide/api_token'
    try:
        os.makedirs('/etc/tide', exist_ok=True)
        if not os.path.exists(token_file):
            with open(token_file, 'w') as f:
                f.write(API_TOKEN)
            os.chmod(token_file, 0o600)
            # ZERO-LOG: Don't print tokens or paths
        else:
            with open(token_file, 'r') as f:
                API_TOKEN = f.read().strip()
    except:
        # ZERO-LOG: No warnings that could reveal system state
        pass

# ZERO-LOG: Never print API tokens


class TideAPIHandler(http.server.BaseHTTPRequestHandler):
    """Handle Tide API requests"""
    
    def log_message(self, format, *args):
        """ZERO-LOG POLICY: No request logging for privacy"""
        # Tide Gateway is a privacy appliance - we NEVER log client IPs or requests
        pass
    
    def _send_json(self, code, data):
        """Send JSON response"""
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Connection', 'close')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def _tor_status(self):
        """Check if Tor is running and connected"""
        try:
            # Check if Tor process is running
            result = subprocess.run(['pgrep', '-x', 'tor'], 
                                  capture_output=True, timeout=2)
            if result.returncode != 0:
                return "offline"
            
            # Check if SOCKS port is listening
            result = subprocess.run(['nc', '-z', '127.0.0.1', '9050'],
                                  capture_output=True, timeout=2)
            return "connected" if result.returncode == 0 else "bootstrapping"
        except:
            return "unknown"
    
    def _get_uptime(self):
        """Get system uptime in seconds"""
        try:
            with open('/proc/uptime', 'r') as f:
                return int(float(f.read().split()[0]))
        except:
            return 0
    
    def _get_mode(self):
        """Get Tide mode"""
        try:
            with open('/etc/tide/mode', 'r') as f:
                return f.read().strip()
        except:
            return "unknown"
    
    def _get_security(self):
        """Get Tide security profile"""
        try:
            with open('/etc/tide/security', 'r') as f:
                return f.read().strip()
        except:
            return "standard"
    
    def _get_version(self):
        """Get Tide version"""
        try:
            with open('/opt/tide/VERSION', 'r') as f:
                return f.read().strip()
        except:
            return "unknown"
    
    def _get_circuit_info(self):
        """Get current Tor exit IP info"""
        try:
            result = subprocess.run([
                'curl', '-s', '--socks5', '127.0.0.1:9050',
                '--max-time', '10',
                'https://check.torproject.org/api/ip'
            ], capture_output=True, text=True, timeout=15)
            
            if result.returncode == 0 and result.stdout:
                return json.loads(result.stdout)
            return {"error": "timeout"}
        except:
            return {"error": "failed"}
    
    def _new_circuit(self):
        """Request new Tor circuit"""
        try:
            subprocess.run(['killall', '-HUP', 'tor'], timeout=2)
            return True
        except:
            return False
    
    def _check_auth(self):
        """Check if request has valid Bearer token"""
        auth = self.headers.get('Authorization', '')
        if auth == f'Bearer {API_TOKEN}':
            return True
        return False
    
    def do_GET(self):
        """Handle GET requests"""
        path = urlparse(self.path).path
        
        if path == '/status':
            self._send_json(200, {
                "gateway": "tide",
                "version": self._get_version(),
                "mode": self._get_mode(),
                "security": self._get_security(),
                "tor": self._tor_status(),
                "uptime": self._get_uptime(),
                "ip": "10.101.101.10",
                "ports": {
                    "socks": 9050,
                    "dns": 5353,
                    "api": PORT
                }
            })
        
        elif path == '/circuit':
            self._send_json(200, self._get_circuit_info())
        
        elif path == '/newcircuit':
            # Requires authentication
            if not self._check_auth():
                self._send_json(401, {
                    "error": "unauthorized",
                    "message": "Bearer token required for circuit control"
                })
                return
            
            success = self._new_circuit()
            self._send_json(200, {"success": success})
        
        elif path == '/check':
            # Quick health check endpoint
            self._send_json(200, {
                "status": "ok",
                "version": self._get_version()
            })
        
        elif path in ['/discover', '/']:
            self._send_json(200, {
                "service": "tide",
                "version": self._get_version()
            })
        
        else:
            self._send_json(404, {"error": "not found"})


def main():
    """Start the API server"""
    # Allow port reuse
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.TCPServer(("", PORT), TideAPIHandler) as httpd:
        print(f"🌊 Tide API server running on port {PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n✋ Stopping API server...")


if __name__ == "__main__":
    main()
