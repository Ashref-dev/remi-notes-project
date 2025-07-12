import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let hotkeyManager = HotkeyManager.shared
    private let settingsManager = SettingsManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "r.circle.fill", accessibilityDescription: "Remi")
            button.action = #selector(togglePopover)
        }

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
    }

    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.becomeKey()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }
}
