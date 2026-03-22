import SwiftUI

struct TodayOverlay: View {
    @ObservedObject var viewModel: NookListViewModel
    @Binding var selectedNook: Nook?
    let isPresented: Bool
    let onQuickCapture: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sections: [TodaySection] {
        TodayWorkspaceService.shared.sections(from: viewModel.filteredNooks)
    }

    var body: some View {
        Themed { theme in
            ZStack {
                if isPresented {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .onTapGesture(perform: onClose)
                        .transition(.opacity)

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Today")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(theme.textPrimary)
                                Text("Pinned, recent, inbox, and pending AI work")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.textSecondary)
                            }

                            Spacer()

                            Button {
                                onQuickCapture()
                            } label: {
                                Label("Capture", systemImage: "square.and.pencil")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .liquidGlassButtonStyle()

                            Button(action: onClose) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)

                        Divider().opacity(0.1)

                        if sections.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(theme.textSecondary)
                                Text("Nothing for Today yet")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(theme.textPrimary)
                                Text("Capture a note or pin one to make it show up here.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(24)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 18) {
                                    ForEach(sections) { section in
                                        sectionView(section, theme: theme)
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }
                    .frame(width: 430, height: 520)
                    .background {
                        Color.clear
                            .liquidGlassSurface(cornerRadius: 16, strokeOpacity: 0.1, fallbackMaterial: .thickMaterial)
                    }
                    .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 10)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85), value: isPresented)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: TodaySection, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(section.title, systemImage: section.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(section.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.textSecondary)
            }

            VStack(spacing: 6) {
                ForEach(section.nooks) { nook in
                    Button {
                        viewModel.select(nook)
                        selectedNook = viewModel.selectedNook
                        onClose()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: nook.iconName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(nook.iconColor.color)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(nook.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.textPrimary)
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    if nook.isInbox {
                                        badge(text: "Inbox", tint: theme.accent)
                                    }
                                    if nook.isPinned {
                                        badge(text: "Pinned", tint: .orange)
                                    }
                                    if nook.hasPendingAIWork {
                                        badge(text: "Pending AI", tint: .blue)
                                    }
                                }
                            }

                            Spacer()

                            if let timestamp = nook.lastOpenedAt ?? Optional(nook.updatedAt) {
                                Text(timestamp, style: .relative)
                                    .font(.system(size: 10))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background {
                            Color.clear
                                .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.05, fallbackMaterial: .thinMaterial)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(tint.opacity(0.12))
            }
    }
}
