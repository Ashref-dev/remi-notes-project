import SwiftUI
import HotKey

struct HotkeyRecorderView: View {
    @Binding var key: Key
    @Binding var modifiers: NSEvent.ModifierFlags
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(verbatim: "\(modifiers.description) \(key.description)")
                .padding(8)
                .background(isRecording ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            
            Button(isRecording ? "Recording..." : "Record New Hotkey") {
                isRecording.toggle()
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if isRecording {
                    if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
                        self.key = key
                        self.modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    }
                    isRecording = false
                    return nil // Consume the event
                }
                return event
            }
        }
    }
}
