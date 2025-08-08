import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var statusBarMenu: NSMenu!
    private let hotkeyManager = HotkeyManager.shared
    private let settingsManager = SettingsManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "MenubarIcon")
            button.image?.isTemplate = true // Enables automatic dark/light mode tinting
            button.action = #selector(handleStatusBarClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create the status bar menu
        setupStatusBarMenu()

        // Create the popover
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: AppTheme.Popover.width, height: AppTheme.Popover.height)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: ContentView())

        // Register the global hotkey from SettingsManager
        let hotkey = HotKey(key: settingsManager.hotkeyKey, modifiers: settingsManager.hotkeyModifiers)
        hotkeyManager.register(hotkey: hotkey) { [weak self] in
            self?.togglePopover()
        }
        
        // Hide the app from dock and app switcher (backup to Info.plist setting)
        NSApp.setActivationPolicy(.accessory)
        
        // Listen for show popover notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showPopover),
            name: .showRemiPopover,
            object: nil
        )
    }

    private func setupStatusBarMenu() {
        let menu = NSMenu()
        
        // Open Remi
        let openItem = NSMenuItem(title: "Open Remi", action: #selector(showPopover), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About Remi
        let aboutItem = NSMenuItem(title: "About Remi", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit Remi
        let quitItem = NSMenuItem(title: "Quit Remi", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Store the menu but don't assign it by default
        statusBarMenu = menu
    }

    @objc func handleStatusBarClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == NSEvent.EventType.rightMouseUp {
            // Right-click: show menu
            statusItem.menu = statusBarMenu
            statusItem.button?.performClick(nil)
        } else {
            // Left-click: show popover immediately
            statusItem.menu = nil
            showPopover()
        }
    }

        @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // Make the app active to ensure popover appears properly
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    @objc func showPopover() {
        // Ensure menu is cleared when showing popover
        statusItem.menu = nil
        
        if let button = statusItem.button {
            if !popover.isShown {
                // Make the app active to ensure popover appears properly
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.becomeKey()
            }
        }
    }
    
    @objc private func showAbout() {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow.title = "About Remi"
        aboutWindow.isReleasedWhenClosed = true
        
        // Create the about view
        let aboutView = VStack(spacing: 20) {
            // App Icon
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
            }
            
            // App Name and Version
            VStack(spacing: 8) {
                Text("Remi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.1.1")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text("Your AI-powered note-taking companion")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Credits
            VStack(spacing: 4) {
                Text("Made with ❤️ by")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("ashref.tn")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .padding(40)
        .frame(width: 400, height: 300)
        
        aboutWindow.contentViewController = NSHostingController(rootView: aboutView)
        aboutWindow.center()
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        // Clean up before quitting
        hotkeyManager.unregister()
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when windows are closed - we're a menu bar app
        return false
    }
}
