import SwiftUI

struct AIDiffView: View {
    let originalText: String
    let proposedText: String
    let theme: Theme
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.accent)
                
                Text("Review AI Changes")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onReject) {
                        Text("Reject (Esc)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onAccept) {
                        Text("Accept (Return)")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(theme.accent)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.top, AppTheme.Spacing.medium)
            
            // Diff Content (Side by Side or Stacked)
            HStack(spacing: 12) {
                // Original
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, 4)
                    
                    ScrollView {
                        Text(originalText)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color.red.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Proposed
                VStack(alignment: .leading, spacing: 4) {
                    Text("Proposed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, 4)
                    
                    ScrollView {
                        Text(proposedText)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color.green.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.medium)
        }
        .frame(height: 300)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.1, fallbackMaterial: .thickMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
        }
        // Invisible button to catch Esc key
        .background(
            Button("") {
                onReject()
            }
            .keyboardShortcut(.cancelAction)
            .hidden()
        )
    }
}
