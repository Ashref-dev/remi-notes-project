import SwiftUI

struct FloatingNookStrip: View {
    @ObservedObject var viewModel: NookListViewModel
    @Binding var selectedNook: Nook?
    let glassNamespace: Namespace.ID
    let onManageTapped: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    @State private var isHovering = false
    @State private var swipeDirection: Int = 0  // -1 left, 1 right, for transition direction

    private let haptic = NSHapticFeedbackManager.defaultPerformer
    
    private var isFirstNook: Bool {
        guard let current = selectedNook, !viewModel.filteredNooks.isEmpty else { return false }
        return viewModel.filteredNooks.first?.id == current.id
    }
    
    private var isLastNook: Bool {
        guard let current = selectedNook, !viewModel.filteredNooks.isEmpty else { return false }
        return viewModel.filteredNooks.last?.id == current.id
    }

    var body: some View {
        Themed { theme in
            HStack(spacing: 12) {

                // ─── Compact Swipe Switcher ───
                ZStack {
                    // Left chevron — appears on hover
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.textSecondary.opacity((isHovering && !isFirstNook) ? 0.65 : 0.0))
                            .padding(.leading, 10)
                        Spacer()
                    }

                    // Active nook name + icon (slot-machine animated)
                    if let nook = selectedNook {
                        HStack(spacing: 8) {
                            Image(systemName: nook.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(nook.iconColor.color)
                            Text(nook.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                                .lineLimit(1)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: swipeDirection > 0 ? .trailing : .leading).combined(with: .opacity),
                            removal:   .move(edge: swipeDirection > 0 ? .leading  : .trailing).combined(with: .opacity)
                        ))
                        .id("nookPill-\(nook.id)")
                    }

                    // Right chevron — appears on hover
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.textSecondary.opacity((isHovering && !isLastNook) ? 0.65 : 0.0))
                            .padding(.trailing, 10)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    Color.clear
                        .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.1, interactive: true, fallbackMaterial: .thinMaterial)
                }
                // ← The key fix: use an NSEvent monitor overlay that catches scroll events
                // regardless of which SwiftUI view is under the cursor.
                .overlay {
                    SwipeWheelReader { direction in
                        switchNook(direction: direction)
                    }
                    .allowsHitTesting(false)   // never intercepts clicks – only listens for scroll events
                }
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) { isHovering = hovering }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isExpanded.toggle()
                    }
                }
                .popover(isPresented: $isExpanded, arrowEdge: .top) {
                    NookGridPicker(viewModel: viewModel, selectedNook: $selectedNook, isPresented: $isExpanded)
                }
                .accessibilityLabel(selectedNook?.name ?? "No note selected")
                .accessibilityHint("Swipe left or right to switch notes. Tap to show all notes.")

                // ─── Accessory Actions ───
                HStack(spacing: 8) {
                    Button {
                        if let created = viewModel.createNook(named: "New Nook") {
                            spring { selectedNook = created }
                            HapticsService.shared.perform(.noteCreated)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .liquidGlassButtonStyle()
                    .help("Create New Note")

                    Button { onManageTapped() } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .liquidGlassButtonStyle()
                    .help("Manage Notes")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: – Helpers

    private func spring(_ updates: @escaping () -> Void) {
        if reduceMotion { updates() }
        else { withAnimation(.spring(response: 0.32, dampingFraction: 0.78), updates) }
    }

    private func switchNook(direction: Int) {
        let nooks = viewModel.filteredNooks
        guard !nooks.isEmpty,
              let current = selectedNook,
              let idx = nooks.firstIndex(where: { $0.id == current.id }) else { return }
        let next = idx + direction
        guard nooks.indices.contains(next) else {
            // Double pulse haptic feedback for reaching the edge
            haptic.perform(.generic, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                haptic.perform(.generic, performanceTime: .now)
            }
            return
        }
        swipeDirection = direction
        spring {
            viewModel.select(nooks[next])
            selectedNook = viewModel.selectedNook
        }
        haptic.perform(.levelChange, performanceTime: .now)
        HapticsService.shared.perform(.noteUpdated)
    }
}

// MARK: – SwipeWheelReader
// Uses NSEvent.addLocalMonitorForEvents so it receives scroll events even when
// the cursor is over a SwiftUI Text, Image, or other SwiftUI-rendered content —
// which would normally eat the scroll event before the background NSView sees it.
struct SwipeWheelReader: NSViewRepresentable {
    var onSwipe: (Int) -> Void

    func makeNSView(context: Context) -> SwipeTrackingView {
        let v = SwipeTrackingView()
        v.onSwipe = onSwipe
        return v
    }

    func updateNSView(_ nsView: SwipeTrackingView, context: Context) {
        nsView.onSwipe = onSwipe
    }
}

final class SwipeTrackingView: NSView {
    var onSwipe: ((Int) -> Void)?

    // All debounce state lives HERE on the NSView, which persists across SwiftUI re-renders.
    // If these were SwiftUI @State, they'd reset every time selectedNook changes (on each swipe).
    private var accumulated: CGFloat = 0
    private var lastEventTime: TimeInterval = 0
    private var isSwitching = false

    private let threshold: CGFloat = 80
    private let resetWindow: TimeInterval = 0.35
    private let switchCooldown: TimeInterval = 0.25

    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            // Install a per-application (local) monitor — no sandbox permissions needed.
            // We return the event so all other handlers also see it normally.
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handleScroll(event)
                return event
            }
        } else {
            tearDownMonitor()
        }
    }

    override func removeFromSuperview() {
        tearDownMonitor()
        super.removeFromSuperview()
    }

    private func tearDownMonitor() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    private func handleScroll(_ event: NSEvent) {
        guard isSwitching == false else { return }

        // Only respond when the mouse is actually within our visible frame.
        guard window != nil else { return }
        let locInWindow = event.locationInWindow
        let locInView = convert(locInWindow, from: nil)
        guard bounds.contains(locInView) else { return }

        let now = NSDate.timeIntervalSinceReferenceDate
        if now - lastEventTime > resetWindow { accumulated = 0 }
        lastEventTime = now

        let dx = event.scrollingDeltaX != 0 ? event.scrollingDeltaX : event.deltaX
        accumulated += dx

        if accumulated < -threshold {
            fire(direction: 1)
        } else if accumulated > threshold {
            fire(direction: -1)
        }
    }

    private func fire(direction: Int) {
        isSwitching = true
        accumulated = 0
        DispatchQueue.main.async { [weak self] in
            self?.onSwipe?(direction)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + switchCooldown) { [weak self] in
            self?.isSwitching = false
        }
    }

    deinit { tearDownMonitor() }
}

// MARK: – NookGridPicker
struct NookGridPicker: View {
    @ObservedObject var viewModel: NookListViewModel
    @Binding var selectedNook: Nook?
    @Binding var isPresented: Bool

    var body: some View {
        Themed { theme in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    ForEach(viewModel.filteredNooks) { nook in
                        let isSelected = selectedNook?.id == nook.id
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.select(nook)
                                selectedNook = viewModel.selectedNook
                                isPresented = false
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: nook.iconName)
                                    .font(.system(size: 24))
                                    .foregroundStyle(nook.iconColor.color)
                                Text(nook.name)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? nook.iconColor.color.opacity(0.15) : Color.black.opacity(0.05))
                            }
                            .overlay {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(nook.iconColor.color.opacity(0.3), lineWidth: 1)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .frame(width: 360, height: 260)
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 0, strokeOpacity: 0, interactive: false, fallbackMaterial: .thickMaterial)
            }
        }
    }
}
