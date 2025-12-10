#!/usr/bin/env python3
"""
Tide Client for Linux (PyQt6)
==============================
Native Linux system tray application for Tide Gateway.

Requirements: PyQt6
Usage: python3 tide-client-qt.py
"""

import sys
import os
from pathlib import Path
from typing import Optional

from PyQt6.QtWidgets import (
    QApplication, QSystemTrayIcon, QMenu
)
from PyQt6.QtCore import QTimer, pyqtSlot
from PyQt6.QtGui import QIcon, QAction

# Add parent directory to path for shared module
sys.path.insert(0, str(Path(__file__).parent.parent / "shared"))
from tide_gateway import TideGateway


class TideClientApp:
    """Linux Tide Client with system tray"""
    
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.app.setQuitOnLastWindowClosed(False)
        
        self.gateway = TideGateway()
        self.tray_icon = None
        self.menu = None
        self.discovery_timer = None
        self.status_timer = None
        
        self._setup_tray()
        self._start_discovery()
    
    def _setup_tray(self):
        """Setup system tray icon and menu"""
        # Create tray icon
        icon = self._create_icon()
        self.tray_icon = QSystemTrayIcon(icon, self.app)
        self.tray_icon.setToolTip("Tide Gateway Client")
        
        # Create menu
        self.menu = QMenu()
        self._update_menu()
        
        self.tray_icon.setContextMenu(self.menu)
        self.tray_icon.show()
        
        # Click handler
        self.tray_icon.activated.connect(self._on_tray_activated)
    
    def _create_icon(self, connected: bool = False) -> QIcon:
        """Create tray icon (🌊 wave or simple colored circle)"""
        from PyQt6.QtGui import QPixmap, QPainter, QColor
        from PyQt6.QtCore import Qt
        
        pixmap = QPixmap(64, 64)
        pixmap.fill(Qt.GlobalColor.transparent)
        
        painter = QPainter(pixmap)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Draw wave-like circles
        if connected:
            color = QColor(0, 180, 100)  # Green
        elif self.gateway.gateway_ip:
            color = QColor(100, 150, 200)  # Blue
        else:
            color = QColor(150, 150, 150)  # Gray
        
        painter.setBrush(color)
        painter.setPen(Qt.PenStyle.NoPen)
        
        # Concentric circles for wave effect
        painter.setOpacity(0.8)
        painter.drawEllipse(8, 8, 48, 48)
        painter.setOpacity(0.6)
        painter.drawEllipse(16, 16, 32, 32)
        painter.setOpacity(0.4)
        painter.drawEllipse(24, 24, 16, 16)
        
        painter.end()
        
        return QIcon(pixmap)
    
    def _update_menu(self):
        """Update menu based on gateway status"""
        self.menu.clear()
        
        # Header
        if self.gateway.gateway_ip:
            header_text = f"🌊 Tide: {self.gateway.gateway_ip}"
            status_text = f"Tor: {self.gateway.status.get('tor', 'unknown')}"
        else:
            header_text = "🌊 Tide Gateway"
            status_text = "⏳ Searching..."
        
        header_action = QAction(header_text, self.menu)
        header_action.setEnabled(False)
        self.menu.addAction(header_action)
        
        status_action = QAction(status_text, self.menu)
        status_action.setEnabled(False)
        self.menu.addAction(status_action)
        
        self.menu.addSeparator()
        
        # Actions
        if self.gateway.gateway_ip:
            # Connect/Disconnect
            if self.gateway.connected:
                disconnect_action = QAction("🔴 Disconnect", self.menu)
                disconnect_action.triggered.connect(self._on_disconnect)
                self.menu.addAction(disconnect_action)
            else:
                connect_action = QAction("🟢 Connect", self.menu)
                connect_action.triggered.connect(self._on_connect)
                self.menu.addAction(connect_action)
            
            # New Circuit
            new_circuit_action = QAction("🔄 New Circuit", self.menu)
            new_circuit_action.triggered.connect(self._on_new_circuit)
            self.menu.addAction(new_circuit_action)
            
            # Status
            status_detail_action = QAction("📊 Show Status", self.menu)
            status_detail_action.triggered.connect(self._on_show_status)
            self.menu.addAction(status_detail_action)
        else:
            # Retry discovery
            retry_action = QAction("🔍 Retry Discovery", self.menu)
            retry_action.triggered.connect(self._on_retry_discovery)
            self.menu.addAction(retry_action)
        
        self.menu.addSeparator()
        
        # Quit
        quit_action = QAction("❌ Quit", self.menu)
        quit_action.triggered.connect(self._on_quit)
        self.menu.addAction(quit_action)
    
    def _start_discovery(self):
        """Start background discovery polling"""
        # Initial discovery
        self._discover()
        
        # Periodic discovery/status check
        self.discovery_timer = QTimer()
        self.discovery_timer.timeout.connect(self._discover)
        self.discovery_timer.start(10000)  # Every 10 seconds
    
    @pyqtSlot()
    def _discover(self):
        """Discover gateway or refresh status"""
        if not self.gateway.gateway_ip:
            # Search for gateway
            ip = self.gateway.discover()
            if ip:
                self.tray_icon.showMessage(
                    "Tide Gateway",
                    f"Found gateway at {ip}",
                    QSystemTrayIcon.MessageIcon.Information,
                    3000
                )
                self._update_menu()
                self._update_icon()
        else:
            # Refresh status
            self.gateway.get_status()
            self._update_menu()
    
    def _update_icon(self):
        """Update tray icon based on connection state"""
        icon = self._create_icon(self.gateway.connected)
        self.tray_icon.setIcon(icon)
    
    @pyqtSlot()
    def _on_connect(self):
        """Connect to gateway"""
        if self.gateway.connect():
            self.tray_icon.showMessage(
                "Tide Gateway",
                "Connected! Traffic routing through Tor.",
                QSystemTrayIcon.MessageIcon.Information,
                3000
            )
            self._update_menu()
            self._update_icon()
        else:
            self.tray_icon.showMessage(
                "Tide Gateway",
                "Failed to configure proxy.",
                QSystemTrayIcon.MessageIcon.Warning,
                3000
            )
    
    @pyqtSlot()
    def _on_disconnect(self):
        """Disconnect from gateway"""
        if self.gateway.disconnect():
            self.tray_icon.showMessage(
                "Tide Gateway",
                "Disconnected from Tide.",
                QSystemTrayIcon.MessageIcon.Information,
                3000
            )
            self._update_menu()
            self._update_icon()
    
    @pyqtSlot()
    def _on_new_circuit(self):
        """Request new Tor circuit"""
        if self.gateway.new_circuit():
            self.tray_icon.showMessage(
                "Tide Gateway",
                "New circuit requested.",
                QSystemTrayIcon.MessageIcon.Information,
                2000
            )
            # Refresh circuit info after a moment
            QTimer.singleShot(3000, lambda: self.gateway.get_circuit())
    
    @pyqtSlot()
    def _on_show_status(self):
        """Show detailed status"""
        status = self.gateway.get_status()
        circuit = self.gateway.get_circuit()
        
        if status:
            msg = f"Mode: {status.get('mode', '?')}\n"
            msg += f"Security: {status.get('security', '?')}\n"
            msg += f"Tor: {status.get('tor', '?')}\n"
            if circuit:
                msg += f"Exit IP: {circuit.get('IP', '?')}"
            
            self.tray_icon.showMessage(
                "Tide Gateway Status",
                msg,
                QSystemTrayIcon.MessageIcon.Information,
                5000
            )
    
    @pyqtSlot()
    def _on_retry_discovery(self):
        """Manually retry gateway discovery"""
        self.gateway.gateway_ip = None
        self._discover()
    
    @pyqtSlot()
    def _on_tray_activated(self, reason):
        """Handle tray icon activation"""
        if reason == QSystemTrayIcon.ActivationReason.Trigger:
            # Left-click: show status
            if self.gateway.gateway_ip:
                self._on_show_status()
    
    @pyqtSlot()
    def _on_quit(self):
        """Quit application"""
        # Disconnect if connected
        if self.gateway.connected:
            self.gateway.disconnect()
        
        # Stop timers
        if self.discovery_timer:
            self.discovery_timer.stop()
        
        # Quit
        self.app.quit()
    
    def run(self):
        """Run the application"""
        return self.app.exec()


def main():
    """Main entry point"""
    app = TideClientApp()
    sys.exit(app.run())


if __name__ == "__main__":
    main()
