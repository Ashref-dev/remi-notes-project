import SwiftUI

struct AIInputView: View {
    @Binding var isVisible: Bool
    @State private var userInput: String = ""
    
    var onSend: (String) -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            TextField("Ask Remi to edit your tasks...", text: $userInput)
                .textFieldStyle(.plain)
                .onSubmit(handleSend)
            
            Button(action: handleSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.accent)
            }
            .buttonStyle(.plain)
            .disabled(userInput.isEmpty)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(radius: 10)
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onChange(of: isVisible) { newValue in
            if !newValue {
                userInput = ""
            }
        }
    }
    
    private func handleSend() {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        onSend(input)
        isVisible = false
    }
}
