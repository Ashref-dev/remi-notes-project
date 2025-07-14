import SwiftUI

struct SidebarView: View {
    @Binding var selectedNook: Nook?
    @Binding var showingSettings: Bool
    @StateObject private var viewModel = NookListViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header
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
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textSecondary)
                        .font(.system(size: 14))
                    
                    TextField("Search or create a Nook...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .focused($isSearchFocused)
                        .onSubmit {
                            handleSearchSubmit()
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.textSecondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .background(theme.background)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.bottom, AppTheme.Spacing.medium)
                
                Divider()
                
                // Nook List
                if viewModel.filteredNooks.isEmpty && !viewModel.searchText.isEmpty {
                    createNookSuggestionView(theme: theme)
                } else if viewModel.filteredNooks.isEmpty {
                    emptyStateView(theme: theme)
                } else {
                    nookScrollView(theme: theme)
                }
                
                Spacer()
                
                Divider()
                
                // Settings Button
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingSettings = true
                    }
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                        Text("Settings")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary.opacity(0.6))
                    }
                    .foregroundColor(theme.textSecondary)
                    .padding(AppTheme.Spacing.medium)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(theme.border.opacity(0.5), lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.bottom, AppTheme.Spacing.large)
            }
        }
        .onAppear {
            viewModel.fetchNooks()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }
    
    private func nookScrollView(theme: Theme) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(viewModel.filteredNooks) { nook in
                    ModernNookCard(
                        nook: nook,
                        isSelected: selectedNook?.id == nook.id,
                        onTap: { selectedNook = nook }
                    )
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteNook(nook)
                            if selectedNook?.id == nook.id {
                                selectedNook = nil
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.large)
        }
    }
    
    private func emptyStateView(theme: Theme) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(theme.accent)
            Text("A Quiet Place for Your Thoughts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Search for a Nook to get started, or type a new name and press Enter to create one.")
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
    
    private func createNookSuggestionView(theme: Theme) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            Text("No nooks found for \"\(viewModel.searchText)\"")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
            Button(action: {
                let newNook = viewModel.createNook(named: viewModel.searchText)
                selectedNook = newNook
                viewModel.searchText = ""
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Nook: \"\(viewModel.searchText)\"")
                        .fontWeight(.medium)
                }
                .font(.system(size: 12))
                .padding(AppTheme.Spacing.medium)
                .background(theme.accent.opacity(0.2))
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
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
