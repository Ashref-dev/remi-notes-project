import Foundation
import SwiftUI
import Combine
import AppKit

@MainActor
class TaskEditorViewModel: ObservableObject {
    @Published var nook: Nook
    @Published var taskContent: String = ""
    @Published var isProcessingAI: Bool = false
    @Published var showSaveConfirmation: Bool = false
    
    private let nookManager = NookManager.shared
    private let groqService = GroqService.shared
    private var cancellables = Set<AnyCancellable>()
    private var saveQueue = DispatchQueue(label: "save-queue", qos: .utility)
    
    // Reference to NSTextView's undoManager for app-level undo operations
    var textViewUndoManager: UndoManager?
    weak var textView: NSTextView?
    
    // Note: Removed UndoManager - using NSTextView's native undo system instead

    init(nook: Nook) {
        self.nook = nook
        self.taskContent = nookManager.fetchTasks(for: nook)
        
        // STEP 2.3: Create initial backup
        createContentBackup()
        
        // Improved debounced saving with faster response
        $taskContent
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .dropFirst() // Don't save on initial load
            .sink { [weak self] content in
                self?.saveContent(content)
            }
            .store(in: &cancellables)
        
        // Listen for app termination to force save
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.forceSave()
            }
            .store(in: &cancellables)
        
        // STEP 2.3: Enhanced edge case handling with crash prevention
        setupEdgeCaseHandling()
    }
    
        // MARK: - Edge Case Handling
    private func setupEdgeCaseHandling() {
        // Monitor for nook changes
        $nook
            .dropFirst()
            .sink { [weak self] newNook in
                self?.handleNookChange(to: newNook)
            }
            .store(in: &cancellables)
    }
    
    private func handleNookChange(to newNook: Nook) {
        forceSave()
        
        // Clear undo stack when switching nooks to prevent confusion
        textViewUndoManager?.removeAllActions()
        
        // Update content with new nook data
        taskContent = nookManager.fetchTasks(for: newNook)
    }
    
    private func handleTextViewChange(textView: NSTextView) {
        // Simple: just prevent undo registration during AI processing
        if isProcessingAI {
            textView.undoManager?.disableUndoRegistration()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textView.undoManager?.enableUndoRegistration()
            }
        }
    }

    private func saveContent(_ content: String) {
        saveQueue.async { [weak self] in
            guard let self = self else { return }
            self.nookManager.saveTasks(for: self.nook, content: content)
            
            // Show save confirmation on main thread
            DispatchQueue.main.async {
                self.showSaveConfirmation = true
                
                // Hide confirmation after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showSaveConfirmation = false
                }
            }
        }
    }
    
    // Force immediate save without debouncing
    func forceSave() {
        let content = taskContent
        nookManager.saveTasks(for: nook, content: content)
    }
    
    // Handle when switching to a different nook
    func prepareForNookSwitch() {
        forceSave()
    }
    
    // Set task content directly without undo registration
    // Undo operations now handled by NSTextView's native undo system
    private func setTaskContent(_ newContent: String) {
        self.taskContent = newContent
    }
    
    func deleteNook() {
        nookManager.deleteNook(nook)
    }
    
    // MARK: - Copy Functionality
    @Published var showCopySuccess: Bool = false
    
    enum CopyFormat {
        case markdown
        case plainText
    }
    
    /// Copies all content to clipboard with optional format specification
    func copyAllContent(format: CopyFormat = .markdown) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let contentToCopy: String
        switch format {
        case .markdown:
            contentToCopy = taskContent
        case .plainText:
            // Strip markdown formatting for plain text
            contentToCopy = stripMarkdownFormatting(from: taskContent)
        }
        
        pasteboard.setString(contentToCopy, forType: .string)
        
        // Show success feedback
        withAnimation(.easeInOut(duration: 0.3)) {
            showCopySuccess = true
        }
        
        // Hide feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showCopySuccess = false
            }
        }
        
        // Haptic feedback for better UX
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment, 
            performanceTime: .now
        )
    }
    
    /// Copy selected text or all content if no selection
    func copySmartSelection(format: CopyFormat = .markdown) {
        // For now, just copy all content
        // TODO: Implement actual selection detection in future iteration
        copyAllContent(format: format)
    }
    
    /// Strips basic markdown formatting to create plain text
    private func stripMarkdownFormatting(from text: String) -> String {
        var plainText = text
        
        // Remove headers (# ## ###)
        plainText = plainText.replacingOccurrences(
            of: #"^#{1,6}\s+"#, 
            with: "", 
            options: [.regularExpression]
        )
        
        // Remove bold/italic (**text** *text*)
        plainText = plainText.replacingOccurrences(
            of: #"\*{1,2}([^*]+)\*{1,2}"#, 
            with: "$1", 
            options: .regularExpression
        )
        
        // Remove inline code (`code`)
        plainText = plainText.replacingOccurrences(
            of: #"`([^`]+)`"#, 
            with: "$1", 
            options: .regularExpression
        )
        
        // Remove links [text](url)
        plainText = plainText.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^)]+\)"#, 
            with: "$1", 
            options: .regularExpression
        )
        
        // Remove task list markers (- [ ] - [x])
        plainText = plainText.replacingOccurrences(
            of: #"^[-*+]\s*\[[x\s]\]\s*"#, 
            with: "", 
            options: [.regularExpression]
        )
        
        // Remove bullet points
        plainText = plainText.replacingOccurrences(
            of: #"^[-*+]\s+"#, 
            with: "", 
            options: [.regularExpression]
        )
        
        return plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - AI Processing with Crash Prevention
    func processAIQuery(prompt: String) async {
        guard !isProcessingAI else { return }
        
        isProcessingAI = true
        let originalContent = taskContent
        
        // Create backup before AI processing
        createContentBackup()
        
        do {
            // Get AI response
            let improvedContent = try await groqService.processQuery(
                prompt: prompt, 
                context: originalContent
            )
            
            // Only proceed if content actually changed
            guard improvedContent != originalContent else {
                isProcessingAI = false
                return
            }
            
            // Apply as a single native undoable replacement
            replaceWholeDocumentUsingNativeUndo(to: improvedContent, actionName: "AI Enhancement")
            
        } catch {
            // Show error and restore original content
            let groqError = error as? GroqError
            let errorMessage = groqError?.errorDescription ?? "AI request failed"
            
            ErrorHandlingService.shared.showError(
                message: errorMessage,
                severity: .error,
                canRetry: true,
                retryAction: { [weak self] in
                    Task {
                        await self?.processAIQuery(prompt: prompt)
                    }
                }
            )
            
            // Restore original content on error
            replaceWholeDocumentUsingNativeUndo(to: originalContent, actionName: "AI Enhancement")
        }
        
        isProcessingAI = false
    }
    
    // MARK: - Safe Undo Registration
    private func registerUndoSafely(originalContent: String, newContent: String, actionName: String) {
        guard let undoManager = textViewUndoManager else { 
            // No undo manager available - AI still works, just no undo
            print("ℹ️ No undo manager available, AI processing continues without undo")
            return 
        }
        
        // Simple, safe undo registration
        undoManager.registerUndo(withTarget: self) { [weak self] _ in
            Task { @MainActor in
                self?.replaceWholeDocumentWithoutUndo(to: originalContent)
                self?.registerRedoSafely(originalContent: newContent, newContent: originalContent, actionName: actionName)
            }
        }
        undoManager.setActionName(actionName)
    }
    
    private func registerRedoSafely(originalContent: String, newContent: String, actionName: String) {
        guard let undoManager = textViewUndoManager else { return }
        
        undoManager.registerUndo(withTarget: self) { [weak self] _ in
            Task { @MainActor in
                self?.replaceWholeDocumentWithoutUndo(to: newContent)
                self?.registerUndoSafely(originalContent: originalContent, newContent: newContent, actionName: actionName)
            }
        }
        undoManager.setActionName("Redo " + actionName)
    }

    // MARK: - Document Replacement Helpers
    private func replaceWholeDocumentUsingNativeUndo(to newContent: String, actionName: String) {
        guard let textView else {
            setTaskContent(newContent)
            return
        }
        let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
        if let undoManager = textView.undoManager {
            undoManager.beginUndoGrouping()
            undoManager.setActionName(actionName)
        }
        if textView.shouldChangeText(in: fullRange, replacementString: newContent) {
            textView.textStorage?.replaceCharacters(in: fullRange, with: newContent)
            textView.didChangeText()
        }
        textView.undoManager?.endUndoGrouping()
        // Keep model in sync for saving and UI
        setTaskContent(newContent)
    }

    private func replaceWholeDocumentWithoutUndo(to newContent: String) {
        guard let textView else {
            setTaskContent(newContent)
            return
        }
        let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
        let undoManager = textView.undoManager
        let wasEnabled = undoManager?.isUndoRegistrationEnabled ?? true
        undoManager?.disableUndoRegistration()
        textView.textStorage?.replaceCharacters(in: fullRange, with: newContent)
        textView.didChangeText()
        if wasEnabled { undoManager?.enableUndoRegistration() }
        setTaskContent(newContent)
    }
    
    // MARK: - Content Backup
    private func createContentBackup() {
        let backup = taskContent
        UserDefaults.standard.set(backup, forKey: "emergencyBackup_\(nook.id.uuidString)")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "emergencyBackupTime_\(nook.id.uuidString)")
    }
    
    private func recoverFromBackup() -> String? {
        let backupKey = "emergencyBackup_\(nook.id.uuidString)"
        let timeKey = "emergencyBackupTime_\(nook.id.uuidString)"
        
        guard let backup = UserDefaults.standard.string(forKey: backupKey) else { return nil }
        let backupTime = UserDefaults.standard.double(forKey: timeKey)
        
        // Only use backup if it's less than 1 hour old
        let maxAge: TimeInterval = 3600
        if Date().timeIntervalSince1970 - backupTime < maxAge {
            return backup
        }
        
        return nil
    }
    
    // MARK: - Content Operations with Safe Undo
    func replaceNookContent(with newContent: String, actionName: String = "Content Replacement") {
        createContentBackup()
        replaceWholeDocumentUsingNativeUndo(to: newContent, actionName: actionName)
    }
    
    func enhanceContent(with enhancement: String, actionName: String = "Content Enhancement") {
        createContentBackup()
        let enhancedContent = taskContent + "\n\n" + enhancement
        replaceWholeDocumentUsingNativeUndo(to: enhancedContent, actionName: actionName)
    }
    
    func formatContent(with formatter: (String) -> String, actionName: String) {
        let formattedContent = formatter(taskContent)
        guard formattedContent != taskContent else { return }
        replaceWholeDocumentUsingNativeUndo(to: formattedContent, actionName: actionName)
    }
}
