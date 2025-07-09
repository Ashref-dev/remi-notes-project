import SwiftUI

struct NookListView: View {
    @StateObject private var viewModel = NookListViewModel()
    @State private var showingEditorSheet = false
    @State private var nookToEdit: Nook?
    
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            
            SearchBarView(searchText: $viewModel.searchText, isFocused: $isSearchFocused)
                .onSubmit(handleSearchSubmit)
            
            Divider()

            if viewModel.filteredNooks.isEmpty && !viewModel.searchText.isEmpty {
                createNookSuggestionView
            } else if viewModel.filteredNooks.isEmpty {
                emptyStateView
            } else {
                nookScrollView
            }
        }
        .background(AppColors.background)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            viewModel.fetchNooks()
            // Focus search bar on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSearchFocused = true
            }
        }
        .sheet(item: $nookToEdit) { nook in
            TaskEditorView(nook: nook)
        }
    }

    private var nookScrollView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(viewModel.filteredNooks) { nook in
                    NookCardView(nook: nook, isSelected: nookToEdit == nook)
                        .onTapGesture {
                            nookToEdit = nook
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                viewModel.deleteNook(nook)
                            }
                        }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.small)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textSecondary)
            Text("No Nooks Yet")
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            Text("Type in the search bar and press Enter to create your first Nook.")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            Spacer()
        }
    }
    
    private var createNookSuggestionView: some View {
        VStack {
            Spacer()
            Text("No nooks found for \"\(viewModel.searchText)\"")
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            Button(action: {
                viewModel.createNook(named: viewModel.searchText)
            }) {
                Text("Create New Nook: \"\(viewModel.searchText)\"")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .padding(.vertical, AppTheme.Spacing.small)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .background(AppColors.accent.opacity(0.2))
            .cornerRadius(AppTheme.CornerRadius.small)
            Spacer()
        }
    }
    
    private func handleSearchSubmit() {
        if !viewModel.searchText.isEmpty && viewModel.filteredNooks.isEmpty {
            viewModel.createNook(named: viewModel.searchText)
        } else if let firstResult = viewModel.filteredNooks.first {
            nookToEdit = firstResult
        }
    }
}

// MARK: - Subviews

private struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "r.circle.fill")
                .font(.title)
                .foregroundColor(AppColors.accent)
            Text("Remi Nooks")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppColors.backgroundSecondary)
    }
}

private struct SearchBarView: View {
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Search or create a new Nook...", text: $searchText)
                .textFieldStyle(.plain)
                .focused(isFocused)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.medium)
    }
}

struct NookListView_Previews: PreviewProvider {
    static var previews: some View {
        NookListView()
    }
}