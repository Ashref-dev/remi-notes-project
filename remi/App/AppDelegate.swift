import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var hotkeyManager = HotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "r.circle", accessibilityDescription: "Remi")
            button.action = #selector(togglePopover)
        }

        // Create the popover
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 600, height: 700)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: ContentView())

        // Register the global hotkey
        hotkeyManager.register { [weak self] in
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
