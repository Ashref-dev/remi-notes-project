import Social
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
    private let appGroupIdentifier = "group.ashref.tn.remi"
    private let queueDirectoryName = "SharedCaptureQueue"

    override func isContentValid() -> Bool {
        let composeText = contentText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let hasAttachments = items.contains { !($0.attachments ?? []).isEmpty }
        return !composeText.isEmpty || hasAttachments
    }

    override func didSelectPost() {
        Task {
            do {
                let sharedText = try await collectedText()
                try enqueueCapture(text: sharedText)
                extensionContext?.completeRequest(returningItems: nil)
            } catch {
                extensionContext?.cancelRequest(withError: error)
            }
        }
    }

    private func collectedText() async throws -> String {
        var parts: [String] = []

        let composeText = contentText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !composeText.isEmpty {
            parts.append(composeText)
        }

        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        for item in items {
            for provider in item.attachments ?? [] {
                if let loaded = try await loadText(from: provider) {
                    parts.append(loaded)
                }
            }
        }

        let merged = parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        guard !merged.isEmpty else {
            throw CocoaError(.fileReadUnknown)
        }

        return merged
    }

    private func loadText(from provider: NSItemProvider) async throws -> String? {
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            return try await loadItem(provider, typeIdentifier: UTType.plainText.identifier)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            return try await loadItem(provider, typeIdentifier: UTType.text.identifier)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            return try await loadItem(provider, typeIdentifier: UTType.url.identifier)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            return try await loadItem(provider, typeIdentifier: UTType.fileURL.identifier)
        }

        return nil
    }

    private func loadItem(_ provider: NSItemProvider, typeIdentifier: String) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let text = item as? String {
                    continuation.resume(returning: text)
                    return
                }

                if let url = item as? URL {
                    continuation.resume(returning: url.absoluteString)
                    return
                }

                if let data = item as? Data,
                   let string = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: string)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    private func enqueueCapture(text: String) throws {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let queueDirectory = root.appendingPathComponent(queueDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: queueDirectory.path) {
            try FileManager.default.createDirectory(at: queueDirectory, withIntermediateDirectories: true)
        }

        let payload = ShareCapturePayload(
            id: UUID(),
            text: text,
            route: "createInboxNote",
            source: "shareExtension",
            createdAt: Date()
        )
        let fileURL = queueDirectory.appendingPathComponent("\(payload.id.uuidString).json")
        let data = try JSONEncoder().encode(payload)
        try data.write(to: fileURL, options: .atomic)
    }
}

private struct ShareCapturePayload: Codable {
    let id: UUID
    let text: String
    let route: String
    let source: String
    let createdAt: Date
}
