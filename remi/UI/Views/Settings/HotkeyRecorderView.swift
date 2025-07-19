import SwiftUI
import HotKey

struct HotkeyRecorderView: View {
    @Binding var key: Key
    @Binding var modifiers: NSEvent.ModifierFlags
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        Themed { theme in
            HStack(spacing: 8) {
                // Display current hotkey
                Text(verbatim: "\(modifiers.description) \(key.description)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isRecording ? theme.accent.opacity(0.2) : theme.backgroundSecondary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? theme.accent : theme.border, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                // Record button
                Button(action: toggleRecording) {
                    HStack(spacing: 4) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "keyboard")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(isRecording ? "Recording..." : "Change")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isRecording ? Color.red : theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isRecording ? Color.red.opacity(0.1) : theme.accent.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear(perform: setupEventMonitor)
        .onDisappear(perform: removeEventMonitor)
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            setupEventMonitor()
        } else {
            removeEventMonitor()
        }
    }
    
    private func setupEventMonitor() {
        removeEventMonitor()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if isRecording {
                if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
                    self.key = key
                    self.modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                }
                isRecording = false
                removeEventMonitor()
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
