import SwiftUI
import AppKit

struct QuickCapturePanelView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var draftText = ""
    @State private var route: CaptureRoute
    @State private var isSaving = false

    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        _route = State(initialValue: SettingsManager.shared.captureDefaultRoute)
    }

    var body: some View {
        Themed { theme in
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Capture")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Enter saves. Option-Enter adds a new line.")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer()

                    Menu {
                        Picker("Route", selection: $route) {
                            ForEach(CaptureRoute.allCases) { route in
                                Text(route.title).tag(route)
                            }
                        }
                    } label: {
                        Label(route.title, systemImage: "arrow.triangle.branch")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .menuStyle(.borderlessButton)

                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                QuickCaptureTextView(
                    text: $draftText,
                    onSubmit: submit,
                    onCancel: onClose
                )
                .frame(height: 140)
                .background {
                    Color.clear
                        .liquidGlassSurface(cornerRadius: 14, strokeOpacity: 0.06, interactive: true, fallbackMaterial: .thinMaterial)
                }

                HStack {
                    Text(route.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)

                    Spacer()

                    Button("Cancel") {
                        onClose()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                    Button {
                        submit()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 80)
                        } else {
                            Text("Save")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 80)
                        }
                    }
                    .liquidGlassButtonStyle(prominent: true)
                    .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .padding(16)
            .frame(width: 420)
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 18, strokeOpacity: 0.1, interactive: true, fallbackMaterial: .regularMaterial)
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
            }
            .onAppear {
                route = settings.captureDefaultRoute
            }
        }
    }

    private func submit() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSaving else { return }

        isSaving = true
        settings.captureDefaultRoute = route

        if CaptureService.shared.capture(text: trimmed, route: route, source: .quickCapture) != nil {
            HapticsService.shared.perform(.noteCreated)
        } else {
            ErrorHandlingService.shared.showWarning(message: "Could not save that capture.")
        }

        draftText = ""
        isSaving = false
        onClose()
    }
}

private struct QuickCaptureTextView: NSViewRepresentable {
    @Binding var text: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 14)
        textView.isRichText = false
        textView.backgroundColor = .clear
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.string = text

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }

        DispatchQueue.main.async {
            if let window = nsView.window, window.firstResponder !== textView {
                window.makeFirstResponder(textView)
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: QuickCaptureTextView
        weak var textView: NSTextView?

        init(_ parent: QuickCaptureTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                if NSApp.currentEvent?.modifierFlags.contains(.option) == true {
                    return false
                }
                parent.onSubmit()
                return true

            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true

            default:
                return false
            }
        }
    }
}
