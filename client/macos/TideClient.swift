// Tide Client for macOS
// ======================
// Auto-discovers Tide Gateway and provides one-click Tor connectivity
//
// Build: swiftc -o TideClient TideClient.swift -framework Cocoa -framework Network

import Cocoa
import Network

// MARK: - Tide Gateway Discovery & API

class TideGateway: ObservableObject {
    static let shared = TideGateway()
    
    @Published var isConnected = false
    @Published var gatewayIP: String?
    @Published var torStatus: String = "searching..."
    @Published var exitIP: String?
    @Published var exitCountry: String?
    
    private var discoveryTimer: Timer?
    private let apiPort = 9051
    private let socksPort = 9050
    private let dnsPort = 5353
    
    // MARK: - Discovery
    
    func startDiscovery() {
        // Try common gateway IPs first
        let commonIPs = ["10.101.101.10", "192.168.1.1", "10.0.0.1"]
        
        for ip in commonIPs {
            checkGateway(ip: ip)
        }
        
        // Also listen for UDP beacon
        listenForBeacon()
        
        // Periodic re-check
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            if self?.gatewayIP == nil {
                for ip in commonIPs {
                    self?.checkGateway(ip: ip)
                }
            } else {
                self?.refreshStatus()
            }
        }
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
                self?.isConnected = true
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
    
    // MARK: - Status
    
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
                // Could add GeoIP lookup here for country
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
        
        let script = """
        networksetup -setsocksfirewallproxy Wi-Fi \(ip) \(socksPort)
        networksetup -setsocksfirewallproxystate Wi-Fi on
        """
        
        runAppleScript(script)
        isConnected = true
    }
    
    func disableProxy() {
        let script = """
        networksetup -setsocksfirewallproxystate Wi-Fi off
        """
        
        runAppleScript(script)
        isConnected = false
    }
    
    private func runAppleScript(_ commands: String) {
        let script = "do shell script \"\(commands)\" with administrator privileges"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
}

// MARK: - Menu Bar App

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var gateway = TideGateway.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "wave.3.right", accessibilityDescription: "Tide")
        }
        
        // Build menu
        updateMenu()
        
        // Start discovery
        gateway.startDiscovery()
        
        // Update menu when status changes
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateMenu()
        }
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // Status header
        let statusItem = NSMenuItem(title: "🌊 Tide Gateway", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        menu.addItem(NSMenuItem.separator())
        
        if let ip = gateway.gatewayIP {
            // Connected state
            let connectedItem = NSMenuItem(title: "✓ Found: \(ip)", action: nil, keyEquivalent: "")
            connectedItem.isEnabled = false
            menu.addItem(connectedItem)
            
            let torItem = NSMenuItem(title: "  Tor: \(gateway.torStatus)", action: nil, keyEquivalent: "")
            torItem.isEnabled = false
            menu.addItem(torItem)
            
            if let exitIP = gateway.exitIP {
                let exitItem = NSMenuItem(title: "  Exit: \(exitIP)", action: nil, keyEquivalent: "")
                exitItem.isEnabled = false
                menu.addItem(exitItem)
            }
            
            menu.addItem(NSMenuItem.separator())
            
            // Actions
            if gateway.isConnected {
                menu.addItem(NSMenuItem(title: "Disconnect", action: #selector(disconnect), keyEquivalent: "d"))
            } else {
                menu.addItem(NSMenuItem(title: "Connect", action: #selector(connect), keyEquivalent: "c"))
            }
            
            menu.addItem(NSMenuItem(title: "New Circuit", action: #selector(newCircuit), keyEquivalent: "n"))
            
        } else {
            // Searching state
            let searchItem = NSMenuItem(title: "⏳ Searching for gateway...", action: nil, keyEquivalent: "")
            searchItem.isEnabled = false
            menu.addItem(searchItem)
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Retry", action: #selector(retry), keyEquivalent: "r"))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func connect() {
        gateway.enableProxy()
        updateMenu()
    }
    
    @objc func disconnect() {
        gateway.disableProxy()
        updateMenu()
    }
    
    @objc func newCircuit() {
        gateway.requestNewCircuit()
    }
    
    @objc func retry() {
        gateway.startDiscovery()
    }
    
    @objc func quit() {
        gateway.disableProxy()
        NSApp.terminate(nil)
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Menu bar only, no dock icon
app.run()
