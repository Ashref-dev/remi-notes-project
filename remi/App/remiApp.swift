import SwiftUI

@main
struct remiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showingSettings = true
    
    var body: some Scene {
        Settings {
            IntegratedSettingsView(showingSettings: $showingSettings)
        }
    }
}

