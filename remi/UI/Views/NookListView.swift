import SwiftUI

struct NookListView: View {
    @StateObject private var viewModel = NookListViewModel()
    @State private var showingCreateNookAlert = false
    @State private var newNookName = ""
    @State private var showingRenameAlert = false
    @State private var renamingNook: Nook?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.nooks) { nook in
                        NavigationLink(destination: TaskEditorView(nook: nook), tag: nook, selection: $viewModel.selectedNook) {
                            NookRowView(nook: nook)
                        }
                        .contextMenu {
                            Button("Rename") {
                                renamingNook = nook
                                newNookName = nook.name
                                showingRenameAlert = true
                            }
                            Button("Delete", role: .destructive) {
                                viewModel.deleteNook(nook)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)

                Divider()

                HStack {
                    Button(action: {
                        newNookName = ""
                        showingCreateNookAlert = true
                    }) {
                        Label("New Nook", systemImage: "plus")
                    }
                    .buttonStyle(.plain)
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("My Nooks")
            .background(Material.bar)
            .onAppear(perform: viewModel.fetchNooks)
            .sheet(isPresented: $showingCreateNookAlert) {
                createNookSheet
            }
            .sheet(isPresented: $showingRenameAlert, onDismiss: { renamingNook = nil }) {
                renameNookSheet
            }
            
            // Detail view
            if let selectedNook = viewModel.selectedNook {
                TaskEditorView(nook: selectedNook)
            } else {
                VStack {
                    Image(systemName: "r.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select a Nook")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var createNookSheet: some View {
        VStack(spacing: 16) {
            Text("Create New Nook")
                .font(.headline)
            TextField("Nook Name", text: $newNookName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            HStack {
                Button("Cancel") { showingCreateNookAlert = false }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Create") {
                    if !newNookName.isEmpty {
                        viewModel.createNook(named: newNookName)
                        showingCreateNookAlert = false
                    }
                }
                .disabled(newNookName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private var renameNookSheet: some View {
        VStack(spacing: 16) {
            Text("Rename Nook")
                .font(.headline)
            TextField("New Name", text: $newNookName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            HStack {
                Button("Cancel") { showingRenameAlert = false }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Rename") {
                    if let nook = renamingNook, !newNookName.isEmpty {
                        viewModel.renameNook(nook, to: newNookName)
                        showingRenameAlert = false
                    }
                }
                .disabled(newNookName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

struct NookRowView: View {
    let nook: Nook
    
    private func preview(for nook: Nook) -> String {
        let content = NookManager.shared.fetchTasks(for: nook)
        return content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(nook.name)
                .font(.headline)
            Text(preview(for: nook))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
    }
}

struct NookListView_Previews: PreviewProvider {
    static var previews: some View {
        NookListView()
    }
}
