import SwiftUI

struct CommandPaletteView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var nookListViewModel: NookListViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    let theme: Theme
    
    // Command matches
    var commandMatches: [CommandItem] {
        let text = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var matches = [CommandItem]()
        
        // Commands (Theme toggling, etc)
        if text.isEmpty || "dark".contains(text) || "theme".contains(text) {
            matches.append(CommandItem(id: "theme_dark", title: "Switch to Dark Theme", icon: "moon.fill", type: .action {
                settingsManager.colorSchemeOption = .customDark
            }))
        }
        if text.isEmpty || "light".contains(text) || "theme".contains(text) {
            matches.append(CommandItem(id: "theme_light", title: "Switch to Light Theme", icon: "sun.max.fill", type: .action {
                settingsManager.colorSchemeOption = .customLight
            }))
        }
        if text.isEmpty || "system".contains(text) || "theme".contains(text) {
            matches.append(CommandItem(id: "theme_system", title: "Use System Theme", icon: "gearshape.fill", type: .action {
                settingsManager.colorSchemeOption = .system
            }))
        }
        
        // Nook Search
        let nooks = text.isEmpty ? nookListViewModel.filteredNooks : nookListViewModel.filteredNooks.filter { $0.name.localizedCaseInsensitiveContains(text) }
        
        for nook in nooks {
            matches.append(CommandItem(id: nook.id.uuidString, title: nook.name, icon: nook.iconName, iconColor: nook.iconColor.color, type: .nook(nook)))
        }
        
        return matches
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                
                TextField("Search notes or commands...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .foregroundColor(theme.textPrimary)
                    .focused($isSearchFocused)
                    .onSubmit {
                        executeFirstMatch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.05))
            
            Divider()
                .background(theme.textSecondary.opacity(0.2))
            
            // Results List
            ScrollView {
                VStack(spacing: 4) {
                    let matches = commandMatches
                    if matches.isEmpty {
                        Text("No results found")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textSecondary)
                            .padding(.top, 32)
                    } else {
                        ForEach(matches) { match in
                            CommandRowView(item: match, theme: theme) {
                                execute(match)
                            }
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 500)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.1, fallbackMaterial: .thickMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
        }
        .onAppear {
            isSearchFocused = true
        }
        // Invisible button to catch Esc key
        .background(
            Button("") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)
            .hidden()
        )
    }
    
    private func executeFirstMatch() {
        if let match = commandMatches.first {
            execute(match)
        }
    }
    
    private func execute(_ match: CommandItem) {
        switch match.type {
        case .action(let block):
            block()
        case .nook(let nook):
            nookListViewModel.selectedNook = nook
            SettingsManager.shared.setLastViewedNook(nook)
        }
        isPresented = false
    }
}

struct CommandItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    var iconColor: Color? = nil
    let type: CommandType
    
    enum CommandType {
        case action(() -> Void)
        case nook(Nook)
    }
}

struct CommandRowView: View {
    let item: CommandItem
    let theme: Theme
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.iconColor ?? theme.textSecondary)
                    .frame(width: 20)
                
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isHovered ? theme.accent : theme.textPrimary)
                
                Spacer()
                
                if case .action = item.type {
                    Text("Action")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
