import SwiftUI

// MARK: - Main SidebarView

struct SidebarView: View {
    @Binding var selectedNook: Nook?
    @Binding var showingSettings: Bool
    @StateObject private var viewModel = NookListViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header
                SidebarHeaderView(theme: theme)
                
                // Search Bar
                SidebarSearchBarView(
                    searchText: $viewModel.searchText,
                    isSearchFocused: $isSearchFocused,
                    onSubmit: handleSearchSubmit,
                    theme: theme
                )
                
                Divider()
                
                // Add Nook Button
                AddNookButtonView(
                    onAddNook: {
                        let newNook = viewModel.createNook(named: "New Nook")
                        selectedNook = newNook
                    },
                    theme: theme
                )
                
                // Nook List Content
                NookListContentView(
                    viewModel: viewModel,
                    selectedNook: $selectedNook,
                    onEditNook: { updatedNook in
                        viewModel.updateNook(updatedNook)
                    },
                    theme: theme
                )
                
                Spacer()
                
                Divider()
                
                // Settings Button
                SettingsButtonView(
                    onSettingsTap: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showingSettings = true
                        }
                    },
                    theme: theme
                )
            }
        }
        .onAppear {
            viewModel.fetchNooks()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }
    
    private func handleSearchSubmit() {
        if !viewModel.searchText.isEmpty && viewModel.filteredNooks.isEmpty {
            let newNook = viewModel.createNook(named: viewModel.searchText)
            selectedNook = newNook
            viewModel.searchText = ""
        } else if let firstResult = viewModel.filteredNooks.first {
            selectedNook = firstResult
            viewModel.searchText = ""
        }
    }
}

// MARK: - Sidebar Header Component

private struct SidebarHeaderView: View {
    let theme: Theme
    
    var body: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundColor(theme.accent)
            Text("Remi")
                .font(AppTheme.Fonts.title2)
                .foregroundColor(theme.textPrimary)
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
}

// MARK: - Search Bar Component

private struct SidebarSearchBarView: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    let onSubmit: () -> Void
    let theme: Theme
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isSearchFocused ? theme.accent : theme.textSecondary)
                .font(.system(size: 14))
                .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
            
            TextField("Search or create a Nook...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isSearchFocused)
                .onSubmit(onSubmit)
                .accessibilityLabel("Search Nooks")
                .accessibilityHint("Search existing nooks or type a new name to create one")
            
            if !searchText.isEmpty {
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textSecondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            isSearchFocused ? theme.accent.opacity(0.5) : 
                            isHovering ? theme.border.opacity(0.8) : theme.border.opacity(0.3),
                            lineWidth: 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                )
        )
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.bottom, AppTheme.Spacing.medium)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Add Nook Button Component

private struct AddNookButtonView: View {
    let onAddNook: () -> Void
    let theme: Theme
    @State private var isHovering = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: onAddNook) {
            HStack(spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(isHovering ? 0.25 : 0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accent)
                        .scaleEffect(isHovering ? 1.1 : 1.0)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add New Nook")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    Text("Create a new space for your thoughts")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(isHovering ? 0.8 : 0.6))
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
            }
            .padding(AppTheme.Spacing.medium)
            .scaleEffect(scale)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isHovering ? theme.backgroundSecondary : theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(theme.accent.opacity(isHovering ? 0.3 : 0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: theme.accent.opacity(isHovering ? 0.1 : 0),
                        radius: isHovering ? 8 : 0,
                        x: 0,
                        y: isHovering ? 2 : 0
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.medium)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
                scale = hovering ? 1.02 : 1.0
            }
        }
        .accessibilityLabel("Add New Nook")
        .accessibilityHint("Creates a new nook for organizing your thoughts")
    }
}

// MARK: - Nook List Content Component

private struct NookListContentView: View {
    @ObservedObject var viewModel: NookListViewModel
    @Binding var selectedNook: Nook?
    let onEditNook: (Nook) -> Void
    let theme: Theme
    
    var body: some View {
        if viewModel.filteredNooks.isEmpty && !viewModel.searchText.isEmpty {
            CreateNookSuggestionView(
                searchText: viewModel.searchText,
                onCreate: {
                    let newNook = viewModel.createNook(named: viewModel.searchText)
                    selectedNook = newNook
                    viewModel.searchText = ""
                },
                theme: theme
            )
        } else if viewModel.filteredNooks.isEmpty {
            EmptyStateView(theme: theme)
        } else {
            NookScrollView(
                nooks: viewModel.filteredNooks,
                selectedNook: $selectedNook,
                onEdit: onEditNook,
                onDelete: { nook in
                    viewModel.deleteNook(nook)
                    if selectedNook?.id == nook.id {
                        selectedNook = nil
                    }
                },
                theme: theme
            )
        }
    }
}

// MARK: - Nook Scroll View Component

private struct NookScrollView: View {
    let nooks: [Nook]
    @Binding var selectedNook: Nook?
    let onEdit: (Nook) -> Void
    let onDelete: (Nook) -> Void
    let theme: Theme
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(nooks) { nook in
                    ModernNookCard(
                        nook: nook,
                        isSelected: selectedNook?.id == nook.id,
                        onTap: { selectedNook = nook },
                        onEdit: onEdit
                    )
                    .contextMenu {
                        Button("Edit") {
                            // This will be handled by the edit button in the card
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            onDelete(nook)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.large)
        }
    }
}

// MARK: - Empty State Component

private struct EmptyStateView: View {
    let theme: Theme
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(theme.accent)
                .scaleEffect(iconScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        iconScale = 1.05
                    }
                }
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text("A Quiet Place for Your Thoughts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Use the \"Add New Nook\" button above, search for a Nook, or type a new name and press Enter to create one.")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
}

// MARK: - Create Nook Suggestion Component

private struct CreateNookSuggestionView: View {
    let searchText: String
    let onCreate: () -> Void
    let theme: Theme
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            
            VStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(theme.accent.opacity(0.7))
                
                Text("No nooks found for \"\(searchText)\"")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(theme.accent)
                    Text("Create New Nook: \"\(searchText)\"")
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                }
                .font(.system(size: 12))
                .padding(AppTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(theme.accent.opacity(isHovering ? 0.3 : 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(theme.accent.opacity(0.4), lineWidth: 1)
                        )
                )
                .scaleEffect(isHovering ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
            }
            .accessibilityLabel("Create new nook named \(searchText)")
            
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
}

// MARK: - Settings Button Component

private struct SettingsButtonView: View {
    let onSettingsTap: () -> Void
    let theme: Theme
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onSettingsTap) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isHovering ? theme.accent : theme.textSecondary)
                Text("Settings")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isHovering ? theme.textPrimary : theme.textSecondary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary.opacity(isHovering ? 0.8 : 0.6))
            }
            .padding(AppTheme.Spacing.medium)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(isHovering ? theme.backgroundSecondary.opacity(0.5) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            isHovering ? theme.border.opacity(0.8) : theme.border.opacity(0.5),
                            lineWidth: 1
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        )
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.bottom, AppTheme.Spacing.large)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Open application settings")
    }
}

// MARK: - Preview

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(
            selectedNook: .constant(nil),
            showingSettings: .constant(false)
        )
        .frame(width: 300, height: 600)
    }
}
#endif
