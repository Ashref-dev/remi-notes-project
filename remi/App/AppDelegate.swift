import SwiftUI
import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let hotkeyManager = HotkeyManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "r.circle", accessibilityDescription: "Remi")
            button.action = #selector(togglePopover)
        }

        // Create the popover
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: AppTheme.Popover.width, height: AppTheme.Popover.height)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: ContentView())

        // Register the global hotkey
        // Load saved hotkey or use default
        if let savedKey = UserDefaults.standard.string(forKey: "globalHotkeyKey"),
           let savedModifiers = UserDefaults.standard.object(forKey: "globalHotkeyModifiers") as? UInt,
           let key = Key(string: savedKey) {
            let hotkey = HotKey(key: key, modifiers: NSEvent.ModifierFlags(rawValue: savedModifiers))
            hotkeyManager.register(hotkey: hotkey) { [weak self] in
                self?.togglePopover()
            }
        } else {
            hotkeyManager.registerDefaultHotkey { [weak self] in
                self?.togglePopover()
            }
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
        hotkeyManager.unregisterAllHotKeys()
    }
}
