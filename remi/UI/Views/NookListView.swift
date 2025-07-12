import SwiftUI

struct NookListView: View {
    @StateObject private var viewModel = NookListViewModel()
    @FocusState private var isSearchFocused: Bool
    @State private var navigationPath = NavigationPath()
    @State private var nookToNavigate: Nook?
    @State private var isSettingsPresented = false

    var body: some View {
        Themed { theme in
            NavigationStack(path: $navigationPath) {
                VStack(spacing: 0) {
                    HeaderView(theme: theme, onSettingsTap: { isSettingsPresented.toggle() })
                    
                    SearchBarView(searchText: $viewModel.searchText, isFocused: $isSearchFocused, theme: theme)
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.vertical, AppTheme.Spacing.medium)

                    Divider()

                    if viewModel.filteredNooks.isEmpty && !viewModel.searchText.isEmpty {
                        createNookSuggestionView(theme: theme)
                    } else if viewModel.filteredNooks.isEmpty {
                        emptyStateView(theme: theme)
                    } else {
                        nookScrollView
                    }
                }
                .background(theme.background)
                .navigationDestination(for: Nook.self) { nook in
                    TaskEditorView(nook: nook)
                }
                .onAppear {
                    viewModel.fetchNooks()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // Slightly longer delay
                        isSearchFocused = true
                    }
                }
                .onChange(of: nookToNavigate) {
                    if let nook = nookToNavigate {
                        navigationPath.append(nook)
                        nookToNavigate = nil
                    }
                }
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView()
                }
            }
        }
    }

    private var nookScrollView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.medium) {
                ForEach(viewModel.filteredNooks) {
                    nook in
                    NavigationLink(value: nook) {
                        NookCardView(nook: nook, isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteNook(nook)
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
                .font(.system(size: 50))
                .foregroundColor(theme.accent)
            Text("A Quiet Place for Your Thoughts")
                .font(.title2.weight(.bold))
                .foregroundColor(theme.textPrimary)
            Text("Search for a Nook to get started, or type a new name and press Enter to create one.")
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 350)
            Spacer()
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
    
    private func createNookSuggestionView(theme: Theme) -> some View {
        VStack {
            Spacer()
            Text("No nooks found for \"\(viewModel.searchText)\"")
                .font(.title2.weight(.semibold))
                .foregroundColor(theme.textPrimary)
            Button(action: {
                let newNook = viewModel.createNook(named: viewModel.searchText)
                nookToNavigate = newNook
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Nook: \"\(viewModel.searchText)\"")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.plain)
            .padding()
            .background(theme.accent.opacity(0.2))
            .cornerRadius(AppTheme.CornerRadius.medium)
            Spacer()
        }
    }
    
    private func handleSearchSubmit() {
        if !viewModel.searchText.isEmpty && viewModel.filteredNooks.isEmpty {
            let newNook = viewModel.createNook(named: viewModel.searchText)
            nookToNavigate = newNook
        } else if let firstResult = viewModel.filteredNooks.first {
            nookToNavigate = firstResult
        }
    }
}

// MARK: - Subviews

private struct HeaderView: View {
    let theme: Theme
    var onSettingsTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "r.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.accent)
            Text("Remi")
                .font(.title2.weight(.bold))
                .foregroundColor(theme.textPrimary)
            Spacer()
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.large)
        .background(theme.background) // Match the main background
    }
}

private struct SearchBarView: View {
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding
    let theme: Theme

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textSecondary)
            
            TextField("Search or create a Nook...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused(isFocused)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(theme.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

struct NookListView_Previews: PreviewProvider {
    static var previews: some View {
        NookListView()
    }
}

