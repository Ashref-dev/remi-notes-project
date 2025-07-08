import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool

    init(nook: Nook) {
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                TextEditor(text: $viewModel.taskContent)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                
                if viewModel.isSendingQuery {
                    ScrollView {
                        VStack {
                            Text(viewModel.thinkingText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(Material.ultraThick)
                    .transition(.opacity.animation(.easeInOut))
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Ask Remi to edit your tasks...", text: $userInput)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .onSubmit(handleInput)
                
                Button(action: handleInput) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(userInput.isEmpty || viewModel.isSendingQuery)
            }
            .padding()
            .background(Material.bar)
        }
        .navigationTitle(viewModel.nook.name)
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func handleInput() {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        Task {
            await viewModel.sendQuery(prompt: input)
        }
        
        userInput = ""
    }
}

struct TaskEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let previewNook = Nook(name: "Preview Nook", url: URL(fileURLWithPath: "/dev/null"))
        TaskEditorView(nook: previewNook)
    }
}
