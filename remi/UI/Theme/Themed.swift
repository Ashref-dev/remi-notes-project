import SwiftUI

struct Themed<Content: View>: View {
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) private var colorScheme
    
    private let content: (Theme) -> Content
    
    init(@ViewBuilder content: @escaping (Theme) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(themeManager.currentTheme)
            .onChange(of: colorScheme) { newColorScheme in
                themeManager.applyTheme(for: newColorScheme)
            }
            .onAppear {
                themeManager.applyTheme(for: colorScheme)
            }
    }
}
