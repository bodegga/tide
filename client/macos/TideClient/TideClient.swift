#!/usr/bin/env swift
// Tide Client for macOS
// ======================
// Native macOS menu bar app for Tide Gateway
//
// Build: swift TideClient.swift
// Or: swiftc -o TideClient TideClient.swift -framework Cocoa -framework Network

import Cocoa
import Network

// MARK: - Tide Gateway API Client

class TideGateway: ObservableObject {
    static let shared = TideGateway()
    
    @Published var isConnected = false
    @Published var gatewayIP: String?
    @Published var torStatus: String = "searching..."
    @Published var exitIP: String?
    @Published var mode: String?
    @Published var security: String?
    
    private var discoveryTimer: Timer?
    private let apiPort = 9051
    private let socksPort = 9050
    private let dnsPort = 5353
    
    // MARK: - Discovery
    
    func startDiscovery() {
        // Try common gateway IPs immediately
        let commonIPs = ["10.101.101.10", "192.168.1.1", "192.168.0.1", "10.0.0.1"]
        
        for ip in commonIPs {
            checkGateway(ip: ip)
            if gatewayIP != nil { break }
        }
        
        // Also try default gateway
        if let defaultGW = getDefaultGateway() {
            checkGateway(ip: defaultGW)
        }
        
        // Listen for UDP beacon
        listenForBeacon()
        
        // Periodic re-check (every 10 seconds)
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            if self?.gatewayIP == nil {
                // Still searching
                for ip in commonIPs {
                    self?.checkGateway(ip: ip)
                    if self?.gatewayIP != nil { break }
                }
            } else {
                // Refresh status
                self?.refreshStatus()
            }
        }
    }
    
    func getDefaultGateway() -> String? {
        let task = Process()
        task.launchPath = "/usr/sbin/route"
        task.arguments = ["-n", "get", "default"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            for line in output.split(separator: "\n") {
                if line.contains("gateway:") {
                    let parts = line.split(separator: ":")
                    if parts.count >= 2 {
                        return parts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        return nil
    }
    
    func checkGateway(ip: String) {
        guard let url = URL(string: "http://\(ip):\(apiPort)/status") else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["gateway"] as? String == "tide" else {
                return
            }
            
            DispatchQueue.main.async {
                self?.gatewayIP = ip
                self?.torStatus = json["tor"] as? String ?? "unknown"
                self?.mode = json["mode"] as? String
                self?.security = json["security"] as? String
                self?.refreshCircuit()
            }
        }.resume()
    }
    
    func listenForBeacon() {
        // Listen for UDP broadcast on port 19050
        let listener = try? NWListener(using: .udp, on: 19050)
        listener?.newConnectionHandler = { [weak self] connection in
            connection.start(queue: .main)
            connection.receiveMessage { data, _, _, _ in
                if let data = data,
                   let message = String(data: data, encoding: .utf8),
                   message.hasPrefix("TIDE:") {
                    let parts = message.split(separator: ":")
                    if parts.count >= 2 {
                        let ip = String(parts[1])
                        self?.checkGateway(ip: ip)
                    }
                }
            }
        }
        listener?.start(queue: .main)
    }
    
    // MARK: - Status & Control
    
    func refreshStatus() {
        guard let ip = gatewayIP else { return }
        checkGateway(ip: ip)
    }
    
    func refreshCircuit() {
        guard let ip = gatewayIP,
              let url = URL(string: "http://\(ip):\(apiPort)/circuit") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            DispatchQueue.main.async {
                self?.exitIP = json["IP"] as? String
            }
        }.resume()
    }
    
    func requestNewCircuit() {
        guard let ip = gatewayIP,
              let url = URL(string: "http://\(ip):\(apiPort)/newcircuit") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] _, _, _ in
            // Wait a moment then refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.refreshCircuit()
            }
        }.resume()
    }
    
    // MARK: - System Proxy Configuration
    
    func enableProxy() {
        guard let ip = gatewayIP else { return }
        
        // Get active network services
        let services = getNetworkServices()
        
        for service in services {
            let script = """
            do shell script "networksetup -setsocksfirewallproxy '\(service)' \(ip) \(socksPort)" with administrator privileges
            do shell script "networksetup -setsocksfirewallproxystate '\(service)' on" with administrator privileges
            """
            
            runAppleScript(script)
        }
        
        isConnected = true
    }
    
    func disableProxy() {
        let services = getNetworkServices()
        
        for service in services {
            let script = """
            do shell script "networksetup -setsocksfirewallproxystate '\(service)' off" with administrator privileges
            """
            
            runAppleScript(script)
        }
        
        isConnected = false
    }
    
    private func getNetworkServices() -> [String] {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listallnetworkservices"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            var services: [String] = []
            for line in output.split(separator: "\n") {
                let service = line.trimmingCharacters(in: .whitespaces)
                if !service.isEmpty && !service.hasPrefix("*") {
                    services.append(service)
                }
            }
            return services
        }
        
        return ["Wi-Fi", "Ethernet"]  // Fallback
    }
    
    private func runAppleScript(_ script: String) {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }
}

// MARK: - Menu Bar App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var gateway = TideGateway.shared
    var menuUpdateTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = createWaveIcon(color: .gray)
            button.toolTip = "Tide Gateway Client"
        }
        
        // Build initial menu
        updateMenu()
        
        // Start gateway discovery
        gateway.startDiscovery()
        
        // Update menu periodically
        menuUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateMenu()
            self?.updateIcon()
        }
    }
    
    func createWaveIcon(color: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw wave-like circles
        color.setFill()
        
        let path1 = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 14))
        path1.fill()
        
        NSColor.white.withAlphaComponent(0.3).setFill()
        let path2 = NSBezierPath(ovalIn: NSRect(x: 5, y: 5, width: 8, height: 8))
        path2.fill()
        
        NSColor.white.withAlphaComponent(0.5).setFill()
        let path3 = NSBezierPath(ovalIn: NSRect(x: 7, y: 7, width: 4, height: 4))
        path3.fill()
        
        image.unlockFocus()
        
        return image
    }
    
    func updateIcon() {
        guard let button = statusItem.button else { return }
        
        let color: NSColor
        if gateway.isConnected {
            color = .systemGreen
        } else if gateway.gatewayIP != nil {
            color = .systemBlue
        } else {
            color = .systemGray
        }
        
        button.image = createWaveIcon(color: color)
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // Header
        let headerItem = NSMenuItem(title: "🌊 Tide Gateway", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())
        
        if let ip = gateway.gatewayIP {
            // Connected state
            let ipItem = NSMenuItem(title: "✓ Found: \(ip)", action: nil, keyEquivalent: "")
            ipItem.isEnabled = false
            menu.addItem(ipItem)
            
            let statusText = "  Tor: \(gateway.torStatus)"
            let statusItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)
            
            if let mode = gateway.mode {
                let modeItem = NSMenuItem(title: "  Mode: \(mode)", action: nil, keyEquivalent: "")
                modeItem.isEnabled = false
                menu.addItem(modeItem)
            }
            
            if let exitIP = gateway.exitIP {
                let exitItem = NSMenuItem(title: "  Exit: \(exitIP)", action: nil, keyEquivalent: "")
                exitItem.isEnabled = false
                menu.addItem(exitItem)
            }
            
            menu.addItem(NSMenuItem.separator())
            
            // Actions
            if gateway.isConnected {
                menu.addItem(NSMenuItem(title: "🔴 Disconnect", action: #selector(disconnect), keyEquivalent: "d"))
            } else {
                menu.addItem(NSMenuItem(title: "🟢 Connect", action: #selector(connect), keyEquivalent: "c"))
            }
            
            menu.addItem(NSMenuItem(title: "🔄 New Circuit", action: #selector(newCircuit), keyEquivalent: "n"))
            menu.addItem(NSMenuItem(title: "📊 Copy Proxy Settings", action: #selector(copySettings), keyEquivalent: "p"))
            
        } else {
            // Searching state
            let searchItem = NSMenuItem(title: "⏳ Searching for gateway...", action: nil, keyEquivalent: "")
            searchItem.isEnabled = false
            menu.addItem(searchItem)
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "🔍 Retry", action: #selector(retry), keyEquivalent: "r"))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "❌ Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func connect() {
        gateway.enableProxy()
        showNotification(title: "Tide Gateway", message: "Connected! Traffic routing through Tor.")
        updateMenu()
        updateIcon()
    }
    
    @objc func disconnect() {
        gateway.disableProxy()
        showNotification(title: "Tide Gateway", message: "Disconnected from Tide.")
        updateMenu()
        updateIcon()
    }
    
    @objc func newCircuit() {
        gateway.requestNewCircuit()
        showNotification(title: "Tide Gateway", message: "New circuit requested.")
    }
    
    @objc func copySettings() {
        guard let ip = gateway.gatewayIP else { return }
        
        let settings = "SOCKS5: \(ip):9050\nDNS: \(ip):5353"
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(settings, forType: .string)
        
        showNotification(title: "Tide Gateway", message: "Proxy settings copied to clipboard.")
    }
    
    @objc func retry() {
        gateway.gatewayIP = nil
        gateway.startDiscovery()
        updateMenu()
    }
    
    @objc func quit() {
        if gateway.isConnected {
            gateway.disableProxy()
        }
        
        if let timer = menuUpdateTimer {
            timer.invalidate()
        }
        
        NSApp.terminate(nil)
    }
    
    func showNotification(title: String, message: String) {
        // Simple notification - could upgrade to UserNotifications framework
        print("📢 \(title): \(message)")
        
        // You can also show an alert
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            // Don't block - just log for now
        }
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // Menu bar only
app.run()
