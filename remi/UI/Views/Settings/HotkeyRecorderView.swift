import SwiftUI
import HotKey

struct HotkeyRecorderView: View {
    @Binding var hotkey: HotKey
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(hotkey.description)
                .padding(8)
                .background(isRecording ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            
            Button(isRecording ? "Stop Recording" : "Record") {
                isRecording.toggle()
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if isRecording {
                    guard let characters = event.charactersIgnoringModifiers else { return event }
                    let key = Key(string: characters.uppercased()) ?? .r
                    let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    
                    hotkey = HotKey(key: key, modifiers: modifiers)
                    isRecording = false
                    return nil
                }
                return event
            }
        }
    }
}
