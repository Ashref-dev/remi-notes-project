import SwiftUI
import AppIntents

@main
struct remiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showingSettings = false
    
    var body: some Scene {
        // Settings scene for menu bar app
        Settings {
            IntegratedSettingsView(showingSettings: $showingSettings)
                .frame(width: 760, height: 620)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Remove default File menu items that don't make sense for a menu bar app
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .importExport) { }
            // Keep default Undo/Redo and Pasteboard groups so standard shortcuts (⌘Z, ⌘⇧Z, ⌘C, etc.) work
            
            // Add custom menu items
            CommandGroup(after: .appInfo) {
                Button("Show Remi") {
                    // Trigger the popover through notification
                    NotificationCenter.default.post(name: .showRemiPopover, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Open Focus Window") {
                    NotificationCenter.default.post(name: .openFocusWindow, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
            }
        }
    }
}
