import SwiftUI

struct Themed<Content: View>: View {
    @StateObject private var themeManager = ThemeManager()
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private let content: (Theme) -> Content
    
    init(@ViewBuilder content: @escaping (Theme) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(themeManager.currentTheme)
            .onChange(of: colorScheme) { _, newColorScheme in
                updateTheme(systemScheme: newColorScheme)
            }
            .onChange(of: settings.colorSchemeOption) { _, _ in
                updateTheme(systemScheme: colorScheme)
            }
            .onAppear {
                updateTheme(systemScheme: colorScheme)
            }
            .preferredColorScheme(settings.colorSchemeOption.colorScheme)
    }
    
    private func updateTheme(systemScheme: ColorScheme) {
        let schemeToApply = settings.colorSchemeOption.colorScheme ?? systemScheme
        themeManager.applyTheme(for: schemeToApply)
    }
}
