import SwiftUI

struct ModelSelectionView: View {
    @StateObject private var settings = SettingsManager.shared
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header
                headerSection(theme: theme)
                
                // Model Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(GroqModelRegistry.availableModels) { model in
                            CompactModelCard(
                                model: model,
                                isSelected: model.id == settings.selectedGroqModel,
                                theme: theme
                            ) {
                                selectModel(model)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(theme.background)
        }
    }
    
    @ViewBuilder
    private func headerSection(theme: any Theme) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Models")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Choose the perfect model for your task")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
                .opacity(0.5)
        }
    }
    
    private func selectModel(_ model: GroqModel) {
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.selectedGroqModel = model.id
        }
    }
}

// MARK: - Supporting Views

struct CompactModelCard: View {
    let model: GroqModel
    let isSelected: Bool
    let theme: any Theme
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var modelTag: String {
        switch model.category {
        case .general:
            return "Generalist"
        case .coding:
            return "Coding"
        case .reasoning:
            return "Reasoning"
        case .creative:
            return "Creative"
        case .fast:
            return "Fast"
        }
    }
    
    var tagColor: Color {
        switch model.category {
        case .general:
            return .blue
        case .coding:
            return .green
        case .reasoning:
            return .purple
        case .creative:
            return .orange
        case .fast:
            return .yellow
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with model info and selection state
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(model.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(1)
                        
                        // Model tag
                        Text(modelTag)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(tagColor.opacity(0.15))
                            .foregroundColor(tagColor)
                            .clipShape(Capsule())
                    }
                    
                    // Fixed height description area
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 28, alignment: .top) // Fixed height for consistency
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isSelected)
                }
            }
            
            // Stats row - Context and Size only
            HStack(spacing: 12) {
                StatPill(label: "Context", value: "\(model.contextLength/1000)K", theme: theme)
                
                // Extract model size from name
                if let sizeInfo = extractModelSize(from: model.name) {
                    StatPill(label: "Size", value: sizeInfo, theme: theme)
                }
                
                // Show reasoning capability if available
                if model.capabilities.contains(.highQuality) && model.category == .reasoning {
                    StatPill(label: "Capability", value: "Reasoning", theme: theme)
                }
                
                Spacer() // Push content to the left for alignment
            }
        }
        .frame(height: 120) // Fixed card height for perfect consistency
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.green : 
                            isHovered ? theme.accent.opacity(0.3) : theme.border,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : isHovered ? 1.01 : 1.0)
        .shadow(
            color: isSelected ? Color.green.opacity(0.2) : 
                   isHovered ? theme.accent.opacity(0.1) : Color.clear,
            radius: isSelected ? 8 : isHovered ? 4 : 0
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private func extractModelSize(from name: String) -> String? {
        // Extract size information from model names
        let lowercased = name.lowercased()
        
        if lowercased.contains("120b") {
            return "120B"
        } else if lowercased.contains("70b") {
            return "70B"
        } else if lowercased.contains("32b") {
            return "32B"
        } else if lowercased.contains("20b") {
            return "20B"
        } else if lowercased.contains("17b") {
            return "17B"
        } else if lowercased.contains("8b") {
            return "8B"
        } else if lowercased.contains("7b") {
            return "7B"
        }
        
        return nil
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let theme: any Theme
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(theme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
