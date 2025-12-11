#!/usr/bin/env python3
"""
Tide Web Dashboard
==================
Serves web-based status dashboard on port 8080 (internal).
Nginx reverse proxy serves port 80 (external).
Accessible at http://tide.bodegga.net or http://10.101.101.10

Aggressive Killa Whale mode: DNS hijacking forces tide.bodegga.net → 10.101.101.10
"""

import http.server
import socketserver
import json
import subprocess
import os
import time
from urllib.parse import urlparse

PORT = 8080  # Internal port (nginx proxies 80 → 8080)

def get_version():
    """Get Tide version from VERSION file"""
    try:
        with open('/opt/tide/VERSION', 'r') as f:
            return f.read().strip()
    except:
        return "unknown"

VERSION = get_version()


class TideWebHandler(http.server.BaseHTTPRequestHandler):
    """Handle web dashboard requests"""
    
    def log_message(self, format, *args):
        """ZERO-LOG POLICY: No request logging for privacy"""
        # Tide Gateway is a privacy appliance - we NEVER log client IPs or requests
        # This maintains user anonymity and security
        pass
    
    def _send_html(self, code, html):
        """Send HTML response"""
        self.send_response(code)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Connection', 'close')
        self.end_headers()
        self.wfile.write(html.encode())
    
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
            result = subprocess.run(['pgrep', '-x', 'tor'], 
                                  capture_output=True, timeout=2)
            if result.returncode != 0:
                return "offline"
            
            result = subprocess.run(['nc', '-z', '127.0.0.1', '9050'],
                                  capture_output=True, timeout=2)
            return "connected" if result.returncode == 0 else "bootstrapping"
        except:
            return "unknown"
    
    def _get_uptime(self):
        """Get system uptime"""
        try:
            with open('/proc/uptime', 'r') as f:
                seconds = int(float(f.read().split()[0]))
                hours = seconds // 3600
                minutes = (seconds % 3600) // 60
                return f"{hours}h {minutes}m"
        except:
            return "unknown"
    
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
    
    def _get_circuit_info(self):
        """Get current Tor exit IP info"""
        try:
            result = subprocess.run([
                'curl', '-s', '--socks5', '127.0.0.1:9050',
                '--max-time', '5',
                'https://check.torproject.org/api/ip'
            ], capture_output=True, text=True, timeout=8)
            
            if result.returncode == 0 and result.stdout:
                data = json.loads(result.stdout)
                return data
            return None
        except:
            return None
    
    def _get_network_stats(self):
        """Get network interface stats"""
        stats = {}
        try:
            # Get connected clients (DHCP leases)
            clients = 0
            if os.path.exists('/var/lib/misc/dnsmasq.leases'):
                with open('/var/lib/misc/dnsmasq.leases', 'r') as f:
                    clients = len(f.readlines())
            stats['clients'] = clients
            
            # Get ARP poisoning status (if running)
            result = subprocess.run(['pgrep', '-f', 'arp-poison'], 
                                  capture_output=True, timeout=1)
            stats['arp_active'] = (result.returncode == 0)
            
            # Check if network scanner is running
            result = subprocess.run(['pgrep', '-f', 'network-scanner'], 
                                  capture_output=True, timeout=1)
            stats['scanner_active'] = (result.returncode == 0)
            
        except:
            pass
        
        return stats
    
    def _get_dashboard_html(self):
        """Generate dashboard HTML"""
        tor_status = self._tor_status()
        mode = self._get_mode()
        security = self._get_security()
        uptime = self._get_uptime()
        circuit = self._get_circuit_info()
        net_stats = self._get_network_stats()
        
        # Status emoji and color
        if tor_status == "connected":
            status_emoji = "🟢"
            status_color = "#00ff00"
            status_text = "CONNECTED"
        elif tor_status == "bootstrapping":
            status_emoji = "🟡"
            status_color = "#ffff00"
            status_text = "BOOTSTRAPPING"
        else:
            status_emoji = "🔴"
            status_color = "#ff0000"
            status_text = "OFFLINE"
        
        # Mode emoji
        mode_emoji = {
            'proxy': '🔌',
            'router': '🌐',
            'killa-whale': '🐋',
            'takeover': '☠️'
        }.get(mode, '❓')
        
        # Security emoji
        sec_emoji = {
            'standard': '🔐',
            'hardened': '🛡️',
            'paranoid': '🔒',
            'bridges': '🌉'
        }.get(security, '🔐')
        
        # Exit IP display
        if circuit and circuit.get('IsTor'):
            exit_ip = circuit.get('IP', 'unknown')
            exit_country = circuit.get('Country', '??')
        else:
            exit_ip = "checking..."
            exit_country = "??"
        
        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌊 Tide Gateway</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Monaco', 'Courier New', monospace;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 100%);
            color: #00ff00;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }}
        
        .container {{
            max-width: 900px;
            width: 100%;
        }}
        
        .header {{
            text-align: center;
            margin-bottom: 40px;
        }}
        
        .header h1 {{
            font-size: 3em;
            margin-bottom: 10px;
            text-shadow: 0 0 20px {status_color};
        }}
        
        .header .tagline {{
            color: #666;
            font-size: 0.9em;
            font-style: italic;
        }}
        
        .status-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        
        .card {{
            background: rgba(0, 255, 0, 0.05);
            border: 1px solid rgba(0, 255, 0, 0.2);
            border-radius: 8px;
            padding: 20px;
            transition: all 0.3s;
        }}
        
        .card:hover {{
            border-color: rgba(0, 255, 0, 0.5);
            box-shadow: 0 0 20px rgba(0, 255, 0, 0.2);
        }}
        
        .card-title {{
            font-size: 0.8em;
            color: #666;
            text-transform: uppercase;
            margin-bottom: 10px;
            letter-spacing: 2px;
        }}
        
        .card-value {{
            font-size: 1.8em;
            margin-bottom: 5px;
        }}
        
        .card-subtitle {{
            font-size: 0.9em;
            color: #888;
        }}
        
        .big-status {{
            background: rgba(0, 255, 0, 0.1);
            border: 2px solid {status_color};
            text-align: center;
            padding: 30px;
            margin-bottom: 30px;
            border-radius: 12px;
            box-shadow: 0 0 30px rgba(0, 255, 0, 0.2);
        }}
        
        .big-status .emoji {{
            font-size: 4em;
            margin-bottom: 10px;
        }}
        
        .big-status .text {{
            font-size: 2em;
            color: {status_color};
            font-weight: bold;
            text-shadow: 0 0 10px {status_color};
        }}
        
        .network-stats {{
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 30px;
        }}
        
        .network-stats h3 {{
            color: #00aaff;
            margin-bottom: 15px;
            font-size: 1.2em;
        }}
        
        .stat-row {{
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }}
        
        .stat-row:last-child {{
            border-bottom: none;
        }}
        
        .stat-label {{
            color: #888;
        }}
        
        .stat-value {{
            color: #00ff00;
            font-weight: bold;
        }}
        
        .footer {{
            text-align: center;
            color: #444;
            font-size: 0.8em;
            margin-top: 40px;
        }}
        
        .refresh-btn {{
            background: rgba(0, 255, 0, 0.2);
            border: 1px solid rgba(0, 255, 0, 0.5);
            color: #00ff00;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-family: inherit;
            font-size: 1em;
            transition: all 0.3s;
        }}
        
        .refresh-btn:hover {{
            background: rgba(0, 255, 0, 0.3);
            box-shadow: 0 0 15px rgba(0, 255, 0, 0.3);
        }}
        
        @media (max-width: 600px) {{
            .header h1 {{
                font-size: 2em;
            }}
            .status-grid {{
                grid-template-columns: 1fr;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌊 TIDE</h1>
            <div class="tagline">Transparent Internet Defense Engine</div>
            <div class="tagline" style="margin-top: 5px;">freedom within the shell</div>
        </div>
        
        <div class="big-status">
            <div class="emoji">{status_emoji}</div>
            <div class="text">{status_text}</div>
        </div>
        
        <div class="status-grid">
            <div class="card">
                <div class="card-title">Mode</div>
                <div class="card-value">{mode_emoji} {mode.upper()}</div>
                <div class="card-subtitle">Deployment mode</div>
            </div>
            
            <div class="card">
                <div class="card-title">Security</div>
                <div class="card-value">{sec_emoji} {security.upper()}</div>
                <div class="card-subtitle">Tor profile</div>
            </div>
            
            <div class="card">
                <div class="card-title">Exit IP</div>
                <div class="card-value">{exit_ip}</div>
                <div class="card-subtitle">{exit_country}</div>
            </div>
            
            <div class="card">
                <div class="card-title">Uptime</div>
                <div class="card-value">{uptime}</div>
                <div class="card-subtitle">Gateway runtime</div>
            </div>
        </div>
        
        <div class="network-stats">
            <h3>🌐 Network Status</h3>
            <div class="stat-row">
                <span class="stat-label">Gateway IP</span>
                <span class="stat-value">10.101.101.10</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">SOCKS5 Port</span>
                <span class="stat-value">9050</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">DNS Port</span>
                <span class="stat-value">5353</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">Connected Clients</span>
                <span class="stat-value">{net_stats.get('clients', 0)}</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">ARP Poisoning</span>
                <span class="stat-value">{'ACTIVE 🔥' if net_stats.get('arp_active') else 'Inactive'}</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">Network Scanner</span>
                <span class="stat-value">{'ACTIVE 👁️' if net_stats.get('scanner_active') else 'Inactive'}</span>
            </div>
        </div>
        
        <div style="text-align: center;">
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh Status</button>
        </div>
        
        <div class="footer">
            <p>Tide Gateway v{VERSION} • <a href="https://github.com/bodegga/tide" style="color: #666;">github.com/bodegga/tide</a></p>
            <p style="margin-top: 5px;">Access this dashboard at <strong>http://tide.bodegga.net</strong> or <strong>http://10.101.101.10</strong></p>
        </div>
    </div>
    
    <script>
        // Auto-refresh every 30 seconds
        setTimeout(() => location.reload(), 30000);
    </script>
</body>
</html>
"""
        return html
    
    def do_GET(self):
        """Handle GET requests"""
        path = urlparse(self.path).path
        
        if path == '/' or path == '/index.html':
            # Serve dashboard
            html = self._get_dashboard_html()
            self._send_html(200, html)
        
        elif path == '/api/status':
            # JSON API endpoint
            tor_status = self._tor_status()
            circuit = self._get_circuit_info()
            
            self._send_json(200, {
                "gateway": "tide",
                "version": VERSION,
                "mode": self._get_mode(),
                "security": self._get_security(),
                "tor": tor_status,
                "uptime": self._get_uptime(),
                "circuit": circuit,
                "network": self._get_network_stats()
            })
        
        elif path == '/health':
            # Simple health check
            self._send_json(200, {"status": "ok"})
        
        else:
            self._send_html(404, "<h1>404 Not Found</h1>")


def main():
    """Start the web dashboard server"""
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.TCPServer(("", PORT), TideWebHandler) as httpd:
        # ZERO-LOG: No startup messages
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass  # ZERO-LOG: No shutdown messages


if __name__ == "__main__":
    main()
