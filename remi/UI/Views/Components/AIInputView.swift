import SwiftUI

struct AIInputView: View {
    @Binding var isVisible: Bool
    var onSend: (String) -> Void
    
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Themed { theme in
            VStack {
                Spacer()
                HStack {
                    TextField("Ask AI to edit or generate...", text: $inputText)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit { send() }
                    
                    Button(action: { send() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                }
                .padding()
                .background(theme.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .shadow(radius: 10)
                .padding()
            }
            .onAppear { isFocused = true }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func send() {
        if !inputText.isEmpty {
            onSend(inputText)
            inputText = ""
            withAnimation { isVisible = false }
        }
    }
}

