import SwiftUI

struct NookCardView: View {
    let nook: Nook
    let isSelected: Bool
    
    @State private var isHovering = false
    
    private func preview(for nook: Nook) -> String {
        let content = NookManager.shared.fetchTasks(for: nook)
        return content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Image(systemName: "doc.text")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 2) // Minor adjustment for alignment

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                Text(nook.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(preview(for: nook))
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackgroundColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var cardBackgroundColor: Color {
        if isSelected {
            return AppColors.cardBackgroundSelected
        } else if isHovering {
            return AppColors.cardBackgroundHover
        } else {
            return AppColors.cardBackground
        }
    }
}

struct NookCardView_Previews: PreviewProvider {
    static var previews: some View {
        let previewNook = Nook(name: "Welcome to Remi", url: URL(fileURLWithPath: "/dev/null"))
        
        VStack {
            NookCardView(nook: previewNook, isSelected: false)
            NookCardView(nook: previewNook, isSelected: true)
        }
        .padding()
        .background(AppColors.background)
    }
}
