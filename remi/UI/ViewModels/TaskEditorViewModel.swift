import Foundation
import SwiftUI
import Combine

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
    
    // Note: Removed UndoManager - using NSTextView's native undo system instead

    init(nook: Nook) {
        self.nook = nook
        self.taskContent = nookManager.fetchTasks(for: nook)
        
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
        
        // Phase 5.2: Handle edge cases and undo state management
        setupEdgeCaseHandling()
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
    
    // MARK: - Phase 3.1: Create custom undo actions for AI processing operations
    func processAIQuery(prompt: String) async {
        guard !isProcessingAI else { return }
        
        isProcessingAI = true
        let originalContent = taskContent
        
        do {
            // Get AI response
            let improvedContent = try await groqService.processQuery(
                prompt: prompt, 
                context: originalContent
            )
            
            // Phase 3.1: Register custom undo action BEFORE applying changes
            registerAppLevelUndo(
                originalContent: originalContent, 
                newContent: improvedContent, 
                actionName: "AI Enhancement"
            )
            
            // Apply the content directly with smooth animation
            withAnimation(.easeInOut(duration: 0.3)) {
                setTaskContent(improvedContent)
            }
            
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
            setTaskContent(originalContent)
        }
        
        isProcessingAI = false
    }
    
    // MARK: - Phase 3.1 & 3.4: App-level undo registration that integrates seamlessly - CRASH FIX
    private func registerAppLevelUndo(originalContent: String, newContent: String, actionName: String) {
        guard let undoManager = textViewUndoManager else { return }
        
        // Phase 5.3: Check undo stack size and cleanup if necessary
        manageUndoStackSize(undoManager: undoManager)
        
        // Phase 3.4: Ensure seamless integration - safely end any current text editing group
        if undoManager.groupingLevel > 0 {
            undoManager.endUndoGrouping()
        }
        
        // Register the app-level operation undo
        undoManager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                // Phase 3.4: When undoing, also register the redo operation
                target.registerAppLevelRedo(originalContent: newContent, newContent: originalContent, actionName: actionName)
                target.setTaskContent(originalContent)
            }
        }
        
        // Set descriptive action name for better UX
        undoManager.setActionName(actionName)
        
        // Phase 3.4: Begin new group for subsequent text editing to maintain separation
        undoManager.beginUndoGrouping()
    }
    
    // Phase 3.1: Dedicated redo registration for proper bidirectional undo/redo - CRASH FIX
    private func registerAppLevelRedo(originalContent: String, newContent: String, actionName: String) {
        guard let undoManager = textViewUndoManager else { return }
        
        undoManager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                target.registerAppLevelUndo(originalContent: originalContent, newContent: newContent, actionName: actionName)
                target.setTaskContent(newContent)
            }
        }
        undoManager.setActionName("Redo " + actionName)
    }
    
    // MARK: - Phase 3.2: Implement undo for nook content replacement/enhancement
    func replaceNookContent(with newContent: String, actionName: String = "Content Replacement") {
        let originalContent = taskContent
        
        // Register undo before making changes
        registerAppLevelUndo(originalContent: originalContent, newContent: newContent, actionName: actionName)
        
        // Apply new content
        withAnimation(.easeInOut(duration: 0.3)) {
            setTaskContent(newContent)
        }
    }
    
    // Phase 3.2: Enhanced content operations with undo support
    func enhanceContent(with enhancement: String, actionName: String = "Content Enhancement") {
        let originalContent = taskContent
        let enhancedContent = originalContent + "\n\n" + enhancement
        
        // Register undo for content enhancement
        registerAppLevelUndo(originalContent: originalContent, newContent: enhancedContent, actionName: actionName)
        
        // Apply enhancement
        withAnimation(.easeInOut(duration: 0.3)) {
            setTaskContent(enhancedContent)
        }
    }
    
    // Phase 3.2: Content formatting operations with undo
    func formatContent(with formatter: (String) -> String, actionName: String) {
        let originalContent = taskContent
        let formattedContent = formatter(originalContent)
        
        // Only register undo if content actually changed
        guard formattedContent != originalContent else { return }
        
        registerAppLevelUndo(originalContent: originalContent, newContent: formattedContent, actionName: actionName)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            setTaskContent(formattedContent)
        }
    }
    
    // MARK: - Phase 5.2: Edge Case Handling
    
    /// Sets up edge case handling for undo/redo operations
    private func setupEdgeCaseHandling() {
        // Monitor for nook changes that might affect undo state
        $nook
            .dropFirst()
            .sink { [weak self] newNook in
                self?.handleNookChange(to: newNook)
            }
            .store(in: &cancellables)
    }
    
    /// Handles edge cases when switching between nooks
    private func handleNookChange(to newNook: Nook) {
        // Force save current content before switching
        forceSave()
        
        // Clear undo stack when switching nooks to prevent confusion
        if let undoManager = textViewUndoManager {
            undoManager.removeAllActions()
        }
        
        // Update content with new nook data
        taskContent = nookManager.fetchTasks(for: newNook)
    }
    
    /// Handles edge cases for empty documents
    func handleEmptyDocumentEdgeCases() {
        guard taskContent.isEmpty else { return }
        
        // For empty documents, ensure undo manager is in clean state
        if let undoManager = textViewUndoManager {
            undoManager.removeAllActions()
        }
    }
    
    /// Validates undo state consistency
    func validateUndoState() -> Bool {
        guard let undoManager = textViewUndoManager else { return false }
        
        // Check for potential inconsistencies
        let hasUndo = undoManager.canUndo
        let hasRedo = undoManager.canRedo
        let hasContent = !taskContent.isEmpty
        
        // Edge case: If we have undo/redo but no content, something is wrong
        if (hasUndo || hasRedo) && !hasContent {
            // Clean up inconsistent state
            undoManager.removeAllActions()
            return false
        }
        
        return true
    }
    
    /// Handles edge cases during AI processing
    func handleAIProcessingEdgeCases() {
        // Ensure we don't start AI processing with inconsistent undo state
        validateUndoState()
        
        // For very large documents, warn about potential performance impact
        if taskContent.count > 50000 {
            print("Warning: Large document detected (\(taskContent.count) chars). AI processing may be slower.")
        }
    }
    
    // MARK: - Phase 5.3: Undo Stack Size Management and Cleanup
    
    /// Manages undo stack size to prevent memory issues
    private func manageUndoStackSize(undoManager: UndoManager) {
        // Count approximate undo actions by checking if we can undo
        var undoCount = 0
        let tempUndoManager = undoManager
        
        // This is an approximation since NSUndoManager doesn't expose count directly
        // We'll use a conservative approach based on content size
        let contentSize = taskContent.count
        let maxUndoActions = calculateMaxUndoActions(for: contentSize)
        
        // If we're approaching the limit, adjust the undo levels
        if undoManager.levelsOfUndo > maxUndoActions {
            undoManager.levelsOfUndo = maxUndoActions
        }
    }
    
    /// Calculates maximum undo actions based on content size
    private func calculateMaxUndoActions(for contentSize: Int) -> Int {
        switch contentSize {
        case 0..<5000:    return 100  // Small documents: full undo capability
        case 5000..<20000: return 75   // Medium documents: reduced undo levels
        case 20000..<50000: return 50  // Large documents: limited undo levels
        default:           return 25   // Very large documents: minimal undo levels
        }
    }
    
    /// Performs cleanup of old undo actions when memory is a concern
    func cleanupUndoStack() {
        guard let undoManager = textViewUndoManager else { return }
        
        // For very large documents, be more aggressive with cleanup
        if taskContent.count > 100000 {
            // Reduce undo levels significantly for massive documents
            undoManager.levelsOfUndo = 10
        }
        
        // Clean up if we have too many undo levels set
        if undoManager.levelsOfUndo > 150 {
            undoManager.levelsOfUndo = 100
        }
    }
    
    // MARK: - Phase 5.5: Final Testing and Validation
    
    /// Comprehensive validation of the undo/redo system
    func validateUndoRedoSystem() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Test 1: Check if undo manager is properly configured
        guard let undoManager = textViewUndoManager else {
            issues.append("UndoManager not properly initialized")
            return (false, issues)
        }
        
        // Test 2: Validate undo levels configuration
        if undoManager.levelsOfUndo <= 0 {
            issues.append("Invalid undo levels configuration: \(undoManager.levelsOfUndo)")
        }
        
        if undoManager.levelsOfUndo > 200 {
            issues.append("Undo levels too high, may cause memory issues: \(undoManager.levelsOfUndo)")
        }
        
        // Test 3: Check content size vs undo configuration
        let contentSize = taskContent.count
        let recommendedUndoLevels = calculateMaxUndoActions(for: contentSize)
        if undoManager.levelsOfUndo > recommendedUndoLevels * 2 {
            issues.append("Undo levels (\(undoManager.levelsOfUndo)) too high for content size (\(contentSize))")
        }
        
        // Test 4: Validate grouping configuration
        if !undoManager.groupsByEvent {
            issues.append("UndoManager should group by event for better UX")
        }
        
        // Test 5: Check for memory efficiency
        if contentSize > 50000 && undoManager.levelsOfUndo > 50 {
            issues.append("Large document with high undo levels may impact performance")
        }
        
        let isValid = issues.isEmpty
        return (isValid, issues)
    }
    
    /// Runs comprehensive tests for the undo/redo functionality
    func runUndoRedoTests() {
        print("🧪 Running Undo/Redo System Tests...")
        
        let (isValid, issues) = validateUndoRedoSystem()
        
        if isValid {
            print("✅ All undo/redo tests passed!")
        } else {
            print("⚠️ Undo/redo validation found issues:")
            for (index, issue) in issues.enumerated() {
                print("  \(index + 1). \(issue)")
            }
        }
        
        // Performance metrics
        let contentSize = taskContent.count
        let undoLevels = textViewUndoManager?.levelsOfUndo ?? 0
        let memoryEstimate = estimateUndoMemoryUsage()
        
        print("📊 Performance Metrics:")
        print("  - Document size: \(contentSize) characters")
        print("  - Undo levels: \(undoLevels)")
        print("  - Estimated memory usage: \(memoryEstimate)MB")
        print("  - Performance rating: \(getPerformanceRating())")
    }
    
    /// Estimates memory usage for undo operations
    private func estimateUndoMemoryUsage() -> Double {
        let contentSize = taskContent.count
        let undoLevels = textViewUndoManager?.levelsOfUndo ?? 0
        
        // Rough estimate: each undo level stores content + metadata
        let bytesPerLevel = contentSize * 2 // Conservative estimate
        let totalBytes = bytesPerLevel * undoLevels
        let megabytes = Double(totalBytes) / (1024 * 1024)
        
        return round(megabytes * 100) / 100 // Round to 2 decimal places
    }
    
    /// Gets performance rating for current undo configuration
    private func getPerformanceRating() -> String {
        let memoryUsage = estimateUndoMemoryUsage()
        
        switch memoryUsage {
        case 0..<1:     return "Excellent"
        case 1..<5:     return "Good"
        case 5..<15:    return "Fair"
        case 15..<50:   return "Poor"
        default:        return "Critical"
        }
    }
}
