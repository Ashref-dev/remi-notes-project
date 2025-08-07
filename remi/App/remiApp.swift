import SwiftUI

@main
struct remiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showingSettings = false
    
    var body: some Scene {
        // Settings scene for menu bar app
        Settings {
            IntegratedSettingsView(showingSettings: $showingSettings)
                .frame(width: 600, height: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Remove default File menu items that don't make sense for a menu bar app
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .importExport) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .pasteboard) { }
            
            // Add custom menu items
            CommandGroup(after: .appInfo) {
                Button("Show Remi") {
                    // Trigger the popover through notification
                    NotificationCenter.default.post(name: .showRemiPopover, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Divider()
            }
        }
    }
}

// Notification name for communication between app and delegate
extension Notification.Name {
    static let showRemiPopover = Notification.Name("showRemiPopover")
}

