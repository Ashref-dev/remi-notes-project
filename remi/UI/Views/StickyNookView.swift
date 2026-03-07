import SwiftUI

struct StickyNookView: View {
    let nook: Nook
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var isHovering = false
    
    // Add window dragging logic
    @State private var dragOffset: CGSize = .zero
    
    init(nook: Nook) {
        self.nook = nook
        // Re-use logic for fetching and saving markdown text
        self._viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
    }
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header (Draggable Area)
                HStack {
                    Image(systemName: nook.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(nook.iconColor.color)
                    
                    Text(nook.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Close/Toggle Control (Only visible when hovering)
                    if isHovering {
                        Button {
                            NotificationCenter.default.post(name: .toggleStickyWindow, object: nook)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.clear) // To catch window drag events properly
                .contentShape(Rectangle())
                // Native window dragging works natively if the styleMask includes .borderless 
                // and window.isMovableByWindowBackground = true, but we can explicitly allow
                // dragging via the header content area.
                
                Divider()
                    .background(theme.textSecondary.opacity(0.1))
                
                // Content area
                LiveMarkdownEditor(
                    text: $viewModel.taskContent,
                    theme: theme,
                    isMarkdownPreviewEnabled: true,
                    autoFocus: false
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                // The main background of the sticky note, uses the standard frosted glass look
                Color.clear
                    .liquidGlassSurface(cornerRadius: 16, strokeOpacity: 0.1, fallbackMaterial: .thickMaterial)
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isHovering = hovering
                }
            }
            .onDisappear {
                viewModel.forceSave()
            }
        }
    }
}
