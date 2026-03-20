import SwiftUI

struct VersionHistoryView: View {
    let revisions: [NoteRevision]
    let onRestore: (NoteRevision) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version History")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Automatic snapshots and recovery points")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.textSecondary)
                }
                .padding(16)

                Divider().opacity(0.1)

                if revisions.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.textSecondary)
                        Text("No saved revisions yet")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Remi will start creating local history snapshots as you keep editing.")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(revisions) { revision in
                                revisionCard(revision, theme: theme)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .frame(width: 520, height: 460)
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 16, strokeOpacity: 0.08, fallbackMaterial: .regularMaterial)
            }
        }
    }

    @ViewBuilder
    private func revisionCard(_ revision: NoteRevision, theme: Theme) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon(for: revision.source))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(revision.summary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                Text(revision.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)

                Text(label(for: revision.source))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Button("Restore") {
                onRestore(revision)
                if reduceMotion {
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        dismiss()
                    }
                }
            }
            .liquidGlassButtonStyle(prominent: true)
        }
        .padding(12)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.06, fallbackMaterial: .thinMaterial)
        }
    }

    private func icon(for source: NoteRevisionSource) -> String {
        switch source {
        case .automatic:
            return "clock.arrow.circlepath"
        case .aiProposal:
            return "sparkles"
        case .contentReplacement:
            return "wand.and.stars"
        case .restore:
            return "arrow.uturn.backward.circle.fill"
        }
    }

    private func label(for source: NoteRevisionSource) -> String {
        switch source {
        case .automatic:
            return "Automatic snapshot"
        case .aiProposal:
            return "Before AI apply"
        case .contentReplacement:
            return "Before content replacement"
        case .restore:
            return "Before restore"
        }
    }
}
