import SwiftUI

// MARK: - Main SidebarView

struct SidebarView: View {
    @Binding var selectedNook: Nook?
    @Binding var showingSettings: Bool
    let onCollapse: () -> Void
    @StateObject private var viewModel = NookListViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header
                SidebarHeaderView(theme: theme, onCollapse: onCollapse)
                
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
        .onChange(of: viewModel.selectedNook) { newValue in
            selectedNook = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectNookByIndex)) { notification in
            if let index = notification.object as? Int {
                viewModel.selectNookByIndex(index)
            }
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress { keyPress in
            if isSearchFocused {
                return .ignored
            }
            
            if keyPress.key == .tab {
                if keyPress.modifiers.contains(.shift) {
                    viewModel.selectPreviousNook()
                } else {
                    viewModel.selectNextNook()
                }
                return .handled
            }
            
            return .ignored
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
    let onCollapse: () -> Void
    @State private var isHoveringCollapse = false
    
    var body: some View {
        HStack {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .foregroundColor(theme.accent)
            Text("Remi")
                .font(AppTheme.Fonts.title2)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Button(action: onCollapse) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isHoveringCollapse ? theme.accent : theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isHoveringCollapse ? theme.accent.opacity(0.1) : Color.clear)
                    )
                    .scaleEffect(isHoveringCollapse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHoveringCollapse)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringCollapse = hovering
            }
            .accessibilityLabel("Collapse sidebar")
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
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHovering)
                
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
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHovering)
            }
            .padding(AppTheme.Spacing.medium)
            .scaleEffect(scale)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isHovering ? theme.backgroundSecondary.opacity(0.8) : theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(theme.accent.opacity(isHovering ? 0.3 : 0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: theme.accent.opacity(isHovering ? 0.15 : 0.05),
                        radius: isHovering ? 8 : 4,
                        x: 0,
                        y: isHovering ? 3 : 2
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.medium)
        .onHover { hovering in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
                onReorder: { from, to in
                    viewModel.moveNook(from: from, to: to)
                },
                onResetOrder: {
                    viewModel.resetToAlphabeticalOrder()
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
    let onReorder: (Int, Int) -> Void
    let onResetOrder: () -> Void
    let theme: Theme
    
    @State private var draggedItemIndex: Int? = nil
    @State private var dropTargetIndex: Int? = nil
    @State private var dragTimeoutTask: Task<Void, Never>? = nil
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(Array(nooks.enumerated()), id: \.element.id) { index, nook in
                    VStack(spacing: 0) {
                        // Drop zone above - with visual indicator
                        ZStack {
                            // Drop indicator above - full height of card
                            if dropTargetIndex == index && draggedItemIndex != index {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.accent.opacity(0.3))
                                    .stroke(theme.accent, lineWidth: 2)
                                    .frame(height: 60) // Approximate card height
                                    .padding(.horizontal, AppTheme.Spacing.medium)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 0.9).combined(with: .opacity)
                                    ))
                            }
                            
                            // Invisible drop target that covers the entire indicator area
                            if dropTargetIndex == index && draggedItemIndex != index {
                                Color.clear
                                    .frame(height: 60)
                                    .padding(.horizontal, AppTheme.Spacing.medium)
                                    .onDrop(of: [.text], delegate: NookDropDelegate(
                                        nook: nook,
                                        currentIndex: index,
                                        onDrop: { fromIndex, toIndex in
                                            // Cancel timeout since drop is successful
                                            dragTimeoutTask?.cancel()
                                            
                                            onReorder(fromIndex, toIndex)
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                draggedItemIndex = nil
                                                dropTargetIndex = nil
                                            }
                                        },
                                        onDragEnter: { 
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                dropTargetIndex = index 
                                            }
                                        },
                                        onDragEnd: { 
                                            // Cancel timeout since drag is ending properly
                                            dragTimeoutTask?.cancel()
                                            
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                draggedItemIndex = nil
                                                dropTargetIndex = nil
                                            }
                                        }
                                    ))
                            }
                        }
                        
                        DraggableNookCard(
                            nook: nook,
                            index: index,
                            isSelected: selectedNook?.id == nook.id,
                            onTap: { selectedNook = nook },
                            onEdit: onEdit,
                            onDelete: onDelete,
                            onDragStart: { 
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    draggedItemIndex = index 
                                }
                                
                                // Cancel any existing timeout
                                dragTimeoutTask?.cancel()
                                
                                // Set a timeout to cleanup state if drag gets stuck
                                dragTimeoutTask = Task {
                                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                                    if !Task.isCancelled {
                                        await MainActor.run {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                draggedItemIndex = nil
                                                dropTargetIndex = nil
                                            }
                                        }
                                    }
                                }
                            },
                            onDragEnd: { 
                                // Cancel timeout since drag is ending properly
                                dragTimeoutTask?.cancel()
                                
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    draggedItemIndex = nil
                                    dropTargetIndex = nil
                                }
                            },
                            onDragEnter: { 
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    dropTargetIndex = index 
                                }
                            },
                            onDrop: { fromIndex, toIndex in
                                // Cancel timeout since drop is successful
                                dragTimeoutTask?.cancel()
                                
                                onReorder(fromIndex, toIndex)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    draggedItemIndex = nil
                                    dropTargetIndex = nil
                                }
                            },
                            theme: theme
                        )
                        .opacity(draggedItemIndex == index ? 0.3 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: draggedItemIndex)
                        
                        // Drop zone below (for last item)
                        if index == nooks.count - 1 {
                            ZStack {
                                // Drop indicator below (for last item)
                                if dropTargetIndex == nooks.count {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.accent.opacity(0.3))
                                        .stroke(theme.accent, lineWidth: 2)
                                        .frame(height: 60) // Approximate card height
                                        .padding(.horizontal, AppTheme.Spacing.medium)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                                            removal: .scale(scale: 0.9).combined(with: .opacity)
                                        ))
                                }
                                
                                // Invisible drop target for bottom area
                                Color.clear
                                    .frame(height: dropTargetIndex == nooks.count ? 60 : 20)
                                    .padding(.horizontal, AppTheme.Spacing.medium)
                                    .onDrop(of: [.text], delegate: NookDropDelegate(
                                        nook: nook,
                                        currentIndex: nooks.count,
                                        onDrop: { fromIndex, toIndex in
                                            // Cancel timeout since drop is successful
                                            dragTimeoutTask?.cancel()
                                            
                                            onReorder(fromIndex, toIndex)
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                draggedItemIndex = nil
                                                dropTargetIndex = nil
                                            }
                                        },
                                        onDragEnter: { 
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                dropTargetIndex = nooks.count 
                                            }
                                        },
                                        onDragEnd: { 
                                            // Cancel timeout since drag is ending properly
                                            dragTimeoutTask?.cancel()
                                            
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                draggedItemIndex = nil
                                                dropTargetIndex = nil
                                            }
                                        }
                                    ))
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .contextMenu {
            Button("Reset to Alphabetical Order") {
                onResetOrder()
            }
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
            
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
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
            .frame(maxWidth: .infinity, alignment: .leading)
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
            )
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.large)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Open application settings")
    }
}

// MARK: - Draggable Nook Card Component

private struct DraggableNookCard: View {
    let nook: Nook
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: (Nook) -> Void
    let onDelete: (Nook) -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let onDragEnter: () -> Void
    let onDrop: (Int, Int) -> Void
    let theme: Theme
    
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var showReorderHandles = false
    @State private var showingEditSheet = false
    
    var body: some View {
        ModernNookCard(
            nook: nook,
            isSelected: isSelected,
            onTap: onTap,
            onEdit: onEdit,
            showEditSheet: $showingEditSheet
        )
        .overlay(
            // Edit and drag controls positioned at top-right
            VStack {
                HStack(spacing: 6) {
                    Spacer()
                    
                    // Edit button - smaller and modern
                    Button(action: { 
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(theme.backgroundSecondary.opacity(0.9))
                                    .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit nook")
                    
                    // Drag handle - smaller and modern
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.backgroundSecondary.opacity(0.9))
                                .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 0.5)
                        )
                        .accessibilityLabel("Drag to reorder")
                }
                .padding(.trailing, 8)
                .padding(.top, 8)
                
                Spacer()
            }
            .opacity(showReorderHandles ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.15), value: showReorderHandles),
            alignment: .topTrailing
        )
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .opacity(isDragging ? 0.8 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .onHover { hovering in
            isHovering = hovering
            showReorderHandles = hovering
        }
        .onDrag {
            isDragging = true
            onDragStart()
            return NSItemProvider(object: String(index) as NSString)
        }
        .simultaneousGesture(
            DragGesture()
                .onEnded { _ in
                    // Ensure cleanup happens when drag ends, regardless of drop success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isDragging = false
                        onDragEnd()
                    }
                }
        )
        .onDrop(of: [.text], delegate: NookDropDelegate(
            nook: nook,
            currentIndex: index,
            onDrop: onDrop,
            onDragEnter: onDragEnter,
            onDragEnd: { 
                isDragging = false
                onDragEnd()
            }
        ))
        .contextMenu {
            Button("Edit") {
                showingEditSheet = true
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                onDelete(nook)
            }
        }
    }
}

// MARK: - Drop Delegate for Drag & Drop

private struct NookDropDelegate: DropDelegate {
    let nook: Nook
    let currentIndex: Int
    let onDrop: (Int, Int) -> Void
    let onDragEnter: () -> Void
    let onDragEnd: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { 
            DispatchQueue.main.async {
                onDragEnd()
            }
            return false 
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            DispatchQueue.main.async {
                if let data = data as? Data,
                   let indexString = String(data: data, encoding: .utf8),
                   let sourceIndex = Int(indexString),
                   sourceIndex != currentIndex {
                    
                    onDrop(sourceIndex, currentIndex)
                } else {
                    // Failed to process drop - ensure cleanup
                    onDragEnd()
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        onDragEnter()
    }
    
    func dropExited(info: DropInfo) {
        // Clear drop indicator when leaving this specific target
        // Note: We don't call onDragEnd here as that would end the entire drag operation
    }
}

// MARK: - Preview

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(
            selectedNook: .constant(nil),
            showingSettings: .constant(false),
            onCollapse: {}
        )
        .frame(width: 300, height: 600)
    }
}
#endif
