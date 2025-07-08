import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        Form {
            Section(header: Text("API")) {
                SecureField("Groq API Key", text: $settings.groqAPIKey)
            }
            
            Section(header: Text("General")) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }
        }
        .padding()
        .frame(width: 450, height: 200)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
