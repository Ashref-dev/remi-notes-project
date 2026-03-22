import SwiftUI

struct CommandPaletteView: View {
    @ObservedObject var nookListViewModel: NookListViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    let theme: Theme
    let commandContext: CommandContext

    private var commandMatches: [RemiCommand] {
        CommandRouter.shared.commands(matching: searchText, context: commandContext)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                TextField("Search notes or commands...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .foregroundStyle(theme.textPrimary)
                    .focused($isSearchFocused)
                    .onSubmit {
                        executeFirstMatch()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.05))

            Divider().background(theme.textSecondary.opacity(0.2))

            ScrollView {
                VStack(spacing: 6) {
                    if commandMatches.isEmpty {
                        Text("No results found")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.textSecondary)
                            .padding(.top, 32)
                    } else {
                        ForEach(commandMatches) { match in
                            CommandRowView(
                                item: match,
                                theme: theme,
                                iconColor: iconColor(for: match)
                            ) {
                                execute(match)
                            }
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 320)
        }
        .frame(width: 520)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.1, fallbackMaterial: .thickMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
        }
        .onAppear {
            isSearchFocused = true
        }
        .background(
            Button("") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)
            .hidden()
        )
    }

    private func executeFirstMatch() {
        guard let match = commandMatches.first else { return }
        execute(match)
    }

    private func execute(_ match: RemiCommand) {
        CommandRouter.shared.perform(match, context: commandContext)
        isPresented = false
    }

    private func iconColor(for command: RemiCommand) -> Color? {
        guard case .note(let noteID) = command.target,
              let nook = commandContext.nooks.first(where: { $0.id == noteID }) else {
            return nil
        }
        return nook.iconColor.color
    }
}

private struct CommandRowView: View {
    let item: RemiCommand
    let theme: Theme
    let iconColor: Color?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor ?? theme.textSecondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isHovered ? theme.accent : theme.textPrimary)

                    if let subtitle = item.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let shortcutHint = item.shortcutHint {
                    Text(shortcutHint)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                } else if case .action = item.target {
                    Text("Action")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovered ? theme.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
