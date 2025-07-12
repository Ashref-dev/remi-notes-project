import SwiftUI

@main
struct remiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Themed { theme in
                ContentView()
                    .background(theme.background)
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

