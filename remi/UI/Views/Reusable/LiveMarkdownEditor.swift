import SwiftUI
import AppKit

struct LiveMarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    let theme: Theme // Use the theme passed from the parent
    var isEditable: Bool = true
    var isMarkdownPreviewEnabled: Bool = true
    var font: NSFont = .systemFont(ofSize: 16, weight: .regular)

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 28, height: 28) // More spacious padding
        
        // UNDO FIX: Simplified undo system configuration - basic functionality only
        if let undoManager = textView.undoManager {
            // Basic undo configuration - let NSTextView handle its own undo naturally
            undoManager.levelsOfUndo = 50  // Reasonable default
            // Remove complex grouping that interferes with native undo
        }
        
        textView.importsGraphics = false
        textView.drawsBackground = true
        
        // Improve scroll behavior
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        
        // Configure scroll view for better performance
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        // Style the background and insertion point with modern colors
        textView.backgroundColor = NSColor(theme.background)
        textView.insertionPointColor = NSColor(theme.accent)
        
        // Better line height and spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 8
        textView.defaultParagraphStyle = paragraphStyle

        // Enable smart substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        // Update colors from the theme
        textView.backgroundColor = NSColor(theme.background)
        textView.textColor = NSColor(theme.textPrimary)
        textView.insertionPointColor = NSColor(theme.accent)
        
        // Always reapply styling when the view updates (important for toggle responsiveness)
        let selectedRange = textView.selectedRange
        
        if textView.string != text {
            textView.string = text
        }
        
        // Apply styling based on current mode
        if isMarkdownPreviewEnabled {
            applyMarkdownStyling(to: textView, theme: theme)
        } else {
            applyPlainTextStyling(to: textView, theme: theme)
        }
        
        textView.setSelectedRange(selectedRange)
        textView.isEditable = isEditable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LiveMarkdownEditor
        var textView: NSTextView?
        
        // Smart debouncing and typing state tracking
        private var stylingTimer: Timer?
        private var isActivelyTyping: Bool = false
        private var lastTextChangeTime: Date = Date()
        private let stylingDebounceInterval: TimeInterval = 0.2 // 200ms
        
        // Smart undo grouping properties
        private var lastUndoGroupTime: Date = Date()
        private var lastCursorPosition: Int = 0
        private var undoGroupingTimer: Timer?
        private let undoGroupingInterval: TimeInterval = 2.0 // Group typing within 2 seconds
        private let cursorMovementThreshold: Int = 10 // Group if cursor moved less than 10 characters
        
        // Advanced undo configuration
        private var lastCharacterType: CharacterType = .other
        private var consecutiveTypeCount: Int = 0
        private let maxConsecutiveCharsBeforeGroup: Int = 20
        
        // Character classification for smart grouping
        private enum CharacterType {
            case letter
            case digit
            case whitespace
            case punctuation
            case newline
            case other
        }
        
        // Position preservation
        private var preservedScrollPosition: NSPoint = .zero
        private var preservedCursorPosition: NSRange = NSRange(location: 0, length: 0)
        private var shouldPreservePosition: Bool = false
        
        // Performance optimization
        private var lastStyledRange: NSRange = NSRange(location: 0, length: 0)
        private var stylingQueue: DispatchQueue = DispatchQueue(label: "markdown.styling", qos: .userInteractive)
        
        // Performance monitoring and validation
        private var stylingStartTime: Date = Date()
        private var totalStylingOperations: Int = 0

        init(_ parent: LiveMarkdownEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // UNDO FIX: Simplified text change handling to preserve native undo
            if textView.string != parent.text {
                // Update SwiftUI binding (this doesn't interfere with undo if done correctly)
                parent.text = textView.string
                
                // Minimal styling update with debouncing
                stylingTimer?.invalidate()
                stylingTimer = Timer.scheduledTimer(withTimeInterval: stylingDebounceInterval, repeats: false) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.performDeferredStyling(textView: textView)
                    }
                }
            }
        }
        
        // UNDO FIX: Completely disable selection-based undo grouping
        func textViewDidChangeSelection(_ notification: Notification) {
            // All custom undo grouping logic disabled to allow NSTextView's native undo to work
            return
        }
        
        // MARK: - Smart Undo Grouping - CRASH FIX
        
        private func handleSmartUndoGrouping(textView: NSTextView) {
            guard let undoManager = textView.undoManager else { return }
            
            let currentTime = Date()
            let currentCursorPosition = textView.selectedRange().location
            let timeSinceLastGroup = currentTime.timeIntervalSince(lastUndoGroupTime)
            let cursorMovement = abs(currentCursorPosition - lastCursorPosition)
            
            // Analyze current character type for intelligent grouping
            let currentCharType = getCurrentCharacterType(textView: textView, position: currentCursorPosition)
            let characterTypeChanged = currentCharType != lastCharacterType
            
            // Advanced grouping logic
            let shouldStartNewGroup = 
                timeSinceLastGroup > undoGroupingInterval ||
                cursorMovement > cursorMovementThreshold ||
                characterTypeChanged ||
                consecutiveTypeCount > maxConsecutiveCharsBeforeGroup ||
                isAtSentenceBoundary(textView: textView) ||
                isAtWordBoundary(textView: textView)
            
            if shouldStartNewGroup {
                // CRASH FIX: Only end grouping if we're currently grouping
                if undoManager.groupingLevel > 0 {
                    undoManager.endUndoGrouping()
                }
                undoManager.beginUndoGrouping()
                lastUndoGroupTime = currentTime
                consecutiveTypeCount = 1
            } else {
                consecutiveTypeCount += 1
            }
            
            lastCharacterType = currentCharType
            lastCursorPosition = currentCursorPosition
            
            // Cancel existing grouping timer
            undoGroupingTimer?.invalidate()
            
            // Set timer to end current group after inactivity - CRASH FIX
            undoGroupingTimer = Timer.scheduledTimer(withTimeInterval: undoGroupingInterval, repeats: false) { [weak self] _ in
                // CRASH FIX: Only end grouping if we're currently grouping
                if undoManager.groupingLevel > 0 {
                    undoManager.endUndoGrouping()
                }
                self?.lastUndoGroupTime = Date.distantPast
                self?.consecutiveTypeCount = 0
            }
        }
        
        private func getCurrentCharacterType(textView: NSTextView, position: Int) -> CharacterType {
            guard position > 0 else { return .other }
            
            let text = textView.string
            let index = text.index(text.startIndex, offsetBy: position - 1)
            let character = text[index]
            
            if character.isLetter { return .letter }
            if character.isNumber { return .digit }
            if character.isWhitespace { return .whitespace }
            if character.isPunctuation { return .punctuation }
            if character.isNewline { return .newline }
            return .other
        }
        
        private func isAtSentenceBoundary(textView: NSTextView) -> Bool {
            let selectedRange = textView.selectedRange()
            guard selectedRange.location > 0 else { return false }
            
            let text = textView.string
            let index = text.index(text.startIndex, offsetBy: selectedRange.location - 1)
            let previousChar = text[index]
            
            // Consider sentence boundaries: period, exclamation, question mark followed by space
            return (previousChar == "." || previousChar == "!" || previousChar == "?") &&
                   selectedRange.location < text.count &&
                   text[text.index(text.startIndex, offsetBy: selectedRange.location)].isWhitespace
        }
        
        private func isAtWordBoundary(textView: NSTextView) -> Bool {
            let selectedRange = textView.selectedRange()
            guard selectedRange.location > 0 else { return false }
            
            let text = textView.string
            let index = text.index(text.startIndex, offsetBy: selectedRange.location - 1)
            let previousChar = text[index]
            
            // Enhanced word boundary detection
            let isWordBoundary = previousChar.isWhitespace || 
                               previousChar.isPunctuation || 
                               previousChar.isNewline ||
                               isMarkdownSyntax(character: previousChar)
            
            // Also check for transition from word to non-word character
            if selectedRange.location < text.count {
                let currentIndex = text.index(text.startIndex, offsetBy: selectedRange.location)
                let currentChar = text[currentIndex]
                let previousCharIsLetter = previousChar.isLetter || previousChar.isNumber
                let currentCharIsLetter = currentChar.isLetter || currentChar.isNumber
                
                return isWordBoundary || (previousCharIsLetter && !currentCharIsLetter) || (!previousCharIsLetter && currentCharIsLetter)
            }
            
            return isWordBoundary
        }
        
        private func isMarkdownSyntax(character: Character) -> Bool {
            let markdownChars: Set<Character> = ["*", "_", "`", "#", "-", "+", "=", "[", "]", "(", ")", "|", "~"]
            return markdownChars.contains(character)
        }
        
        // MARK: - Edge Case Handling
        
        private func handleTypingEdgeCases(textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            
            // Handle end-of-document typing
            if isTypingAtEndOfDocument(textView: textView, selectedRange: selectedRange) {
                handleEndOfDocumentTyping(textView: textView)
            }
            
            // Handle new line insertion
            if isNewLineInsertion(textView: textView) {
                handleNewLineInsertion(textView: textView)
            }
        }
        
        private func handleEndOfDocumentTyping(textView: NSTextView) {
            // Ensure smooth scrolling when typing at the end
            let selectedRange = textView.selectedRange()
            
            DispatchQueue.main.async {
                // Scroll to show cursor with padding
                let scrollRect = textView.layoutManager?.boundingRect(forGlyphRange: selectedRange, in: textView.textContainer!) ?? .zero
                let paddedRect = NSRect(
                    x: scrollRect.origin.x,
                    y: scrollRect.origin.y,
                    width: scrollRect.width,
                    height: scrollRect.height + 100 // Add padding below cursor
                )
                textView.scrollToVisible(paddedRect)
            }
        }
        
        private func handleNewLineInsertion(textView: NSTextView) {
            // Smooth handling of new line creation
            let selectedRange = textView.selectedRange()
            
            // Ensure cursor remains visible during new line creation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                textView.scrollRangeToVisible(selectedRange)
            }
        }
        
        private func isNewLineInsertion(textView: NSTextView) -> Bool {
            // Detect if user just inserted a new line
            let text = textView.string
            let selectedRange = textView.selectedRange()
            
            guard selectedRange.location > 0 else { return false }
            
            let previousChar = text[text.index(text.startIndex, offsetBy: selectedRange.location - 1)]
            return previousChar == "\n"
        }
        
        private func isRapidTyping() -> Bool {
            // Detect rapid typing to prevent styling queue backup
            let timeSinceLastChange = Date().timeIntervalSince(lastTextChangeTime)
            return timeSinceLastChange < 0.1 // Less than 100ms between keystrokes
        }
        
        private func isTypingAtEndOfDocument(textView: NSTextView, selectedRange: NSRange) -> Bool {
            let documentLength = textView.string.count
            return selectedRange.location >= documentLength - 10 // Within last 10 characters
        }
        
        // MARK: - Validation and Testing Methods
        
        private func validateScrollPosition(textView: NSTextView, expectedRange: NSRange) -> Bool {
            let visibleRange = getVisibleTextRange(textView: textView)
            let isVisible = NSLocationInRange(expectedRange.location, visibleRange)
            
            if !isVisible {
                print("⚠️ Scroll position validation failed - cursor not visible after styling")
            }
            
            return isVisible
        }
        
        private func logPerformanceMetrics(operation: String, duration: TimeInterval, documentLength: Int) {
            if duration > 0.05 { // Log operations taking more than 50ms
                print("📊 \(operation): \(String(format: "%.3f", duration))s for \(documentLength) chars")
            }
        }
        
        // MARK: - Smart Debouncing Methods
        
        private func storeCurrentPosition(textView: NSTextView) {
            guard let scrollView = textView.enclosingScrollView else { return }
            
            // Store scroll position using contentView bounds for reliability
            preservedScrollPosition = scrollView.contentView.bounds.origin
            preservedCursorPosition = textView.selectedRange()
            shouldPreservePosition = true
        }
        
        private func performDeferredStyling(textView: NSTextView) {
            // Only apply styling if user has stopped typing
            let timeSinceLastChange = Date().timeIntervalSince(lastTextChangeTime)
            
            if timeSinceLastChange >= stylingDebounceInterval {
                // Performance monitoring
                stylingStartTime = Date()
                totalStylingOperations += 1
                
                // Performance optimization: only style visible content for long documents
                let documentLength = textView.string.count
                
                if documentLength > 5000 {
                    // For long documents, use lazy styling - only style visible portions
                    applyLazyStyling(textView: textView)
                } else {
                    // For shorter documents, use full styling with background processing
                    applyBackgroundStyling(textView: textView)
                }
                
                // Log performance metrics for validation
                let stylingDuration = Date().timeIntervalSince(stylingStartTime)
                if stylingDuration > 0.1 { // Log if styling takes longer than 100ms
                    print("⚠️ Styling operation took \(stylingDuration)s for document length: \(documentLength)")
                }
                
                shouldPreservePosition = false
            }
        }
        
        // MARK: - Performance Optimization Methods
        
        private func applyLazyStyling(textView: NSTextView) {
            // Calculate visible range for styling
            let visibleRange = getVisibleTextRange(textView: textView)
            
            // Only style visible content + small buffer
            let bufferSize = 500
            let expandedRange = NSRange(
                location: max(0, visibleRange.location - bufferSize),
                length: min(textView.string.count - max(0, visibleRange.location - bufferSize), visibleRange.length + (2 * bufferSize))
            )
            
            // Apply styling to visible range only
            if parent.isMarkdownPreviewEnabled {
                parent.applyIncrementalMarkdownStyling(
                    to: textView,
                    range: expandedRange,
                    theme: parent.theme,
                    preservingPosition: shouldPreservePosition ? (preservedScrollPosition, preservedCursorPosition) : nil
                )
            } else {
                parent.applyPlainTextStyling(
                    to: textView,
                    theme: parent.theme,
                    preservingPosition: shouldPreservePosition ? (preservedScrollPosition, preservedCursorPosition) : nil
                )
            }
        }
        
        private func applyBackgroundStyling(textView: NSTextView) {
            // Process styling in background for better performance
            stylingQueue.async { [weak self] in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if self.parent.isMarkdownPreviewEnabled {
                        self.parent.applyMarkdownStyling(
                            to: textView,
                            theme: self.parent.theme,
                            preservingPosition: self.shouldPreservePosition ? (self.preservedScrollPosition, self.preservedCursorPosition) : nil
                        )
                    } else {
                        self.parent.applyPlainTextStyling(
                            to: textView,
                            theme: self.parent.theme,
                            preservingPosition: self.shouldPreservePosition ? (self.preservedScrollPosition, self.preservedCursorPosition) : nil
                        )
                    }
                }
            }
        }
        
        private func getVisibleTextRange(textView: NSTextView) -> NSRange {
            let visibleRect = textView.visibleRect
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return NSRange(location: 0, length: 0)
            }
            
            let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
            return layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        }
    }
    
    // MARK: - Incremental Markdown Styling for Performance
    
    private func applyIncrementalMarkdownStyling(to textView: NSTextView, range: NSRange, theme: Theme, preservingPosition: (NSPoint, NSRange)? = nil) {
        guard let textStorage = textView.textStorage else { return }
        
        // Enhanced position preservation
        let (scrollOrigin, selectedRange) = preservingPosition ?? getCurrentPosition(textView: textView)
        let cursorRelativePosition = getCursorRelativePosition(textView: textView, selectedRange: selectedRange)
        
        // Apply base styling to the specified range only
        let baseFont = NSFont.systemFont(ofSize: 16, weight: .regular)
        textStorage.addAttribute(.font, value: baseFont, range: range)
        textStorage.addAttribute(.foregroundColor, value: NSColor(theme.textPrimary), range: range)
        
        // Apply markdown patterns only to the specified range
        let rangeString = (textView.string as NSString).substring(with: range)
        let attributedString = NSMutableAttributedString(string: rangeString)
        
        // Define hidden attributes for markdown syntax
        let hiddenAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .ultraLight),
            .foregroundColor: NSColor(theme.textSecondary).withAlphaComponent(0.4)
        ]
        
        // Apply patterns to the range
        applyMarkdownPatterns(
            to: attributedString, 
            theme: theme, 
            hiddenAttributes: hiddenAttributes, 
            fullRange: NSRange(location: 0, length: rangeString.count)
        )
        
        // Update the text storage with incremental changes
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: range, with: attributedString)
        textStorage.endEditing()
        
        // Restore position with layout completion awareness
        DispatchQueue.main.async {
            self.restorePositionAfterLayout(
                textView: textView,
                scrollOrigin: scrollOrigin,
                selectedRange: selectedRange,
                cursorRelativePosition: cursorRelativePosition
            )
        }
    }
    
    // MARK: - Enhanced Plain Text Styling with Robust Position Preservation
    private func applyPlainTextStyling(to textView: NSTextView, theme: Theme, preservingPosition: (NSPoint, NSRange)? = nil) {
        guard let textStorage = textView.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        // Enhanced position preservation
        let (scrollOrigin, selectedRange) = preservingPosition ?? getCurrentPosition(textView: textView)
        
        // Calculate cursor position relative to visible text for more reliable restoration
        let cursorRelativePosition = getCursorRelativePosition(textView: textView, selectedRange: selectedRange)
        
        // Remove ALL formatting attributes to ensure clean plain text
        let attributesToRemove: [NSAttributedString.Key] = [
            .font, .foregroundColor, .backgroundColor, .underlineStyle, 
            .strikethroughStyle, .kern, .paragraphStyle, .baselineOffset
        ]
        
        textStorage.beginEditing()
        
        for attribute in attributesToRemove {
            textStorage.removeAttribute(attribute, range: fullRange)
        }
        
        // Apply clean, modern plain text styling
        let plainFont = NSFont.systemFont(ofSize: 16, weight: .regular)
        textStorage.addAttribute(.font, value: plainFont, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor(theme.textPrimary), range: fullRange)
        
        // Apply subtle paragraph styling for readability
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 6
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        textStorage.endEditing()
        
        // Restore position with layout completion awareness
        DispatchQueue.main.async {
            self.restorePositionAfterLayout(
                textView: textView, 
                scrollOrigin: scrollOrigin, 
                selectedRange: selectedRange,
                cursorRelativePosition: cursorRelativePosition
            )
        }
    }
    
    // MARK: - Enhanced Markdown Styling with Robust Position Preservation
    private func applyMarkdownStyling(to textView: NSTextView, theme: Theme, preservingPosition: (NSPoint, NSRange)? = nil) {
        guard let textStorage = textView.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        // Enhanced position preservation
        let (scrollOrigin, selectedRange) = preservingPosition ?? getCurrentPosition(textView: textView)
        
        // Calculate cursor position relative to visible text for more reliable restoration
        let cursorRelativePosition = getCursorRelativePosition(textView: textView, selectedRange: selectedRange)
        
        let attributedString = NSMutableAttributedString(attributedString: textStorage)
        
        // 1. Reset styles with better base formatting
        attributedString.removeAttribute(.font, range: fullRange)
        attributedString.removeAttribute(.foregroundColor, range: fullRange)
        attributedString.removeAttribute(.backgroundColor, range: fullRange)
        
        // Apply base font with better typography
        let baseFont = NSFont.systemFont(ofSize: 16, weight: .regular)
        attributedString.addAttribute(.font, value: baseFont, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor(theme.textPrimary), range: fullRange)
        
        // Better paragraph styling
        let baseParagraphStyle = NSMutableParagraphStyle()
        baseParagraphStyle.lineSpacing = 4
        baseParagraphStyle.paragraphSpacing = 8
        attributedString.addAttribute(.paragraphStyle, value: baseParagraphStyle, range: fullRange)

        // Define a more subtle "hidden" style for Markdown syntax characters
        let hiddenAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .ultraLight),
            .foregroundColor: NSColor(theme.textSecondary).withAlphaComponent(0.4)
        ]

        // 2. Apply enhanced styles with better typography (only if document is not too long for performance)
        if textStorage.length < 10000 { // Performance optimization for long documents
            applyMarkdownPatterns(to: attributedString, theme: theme, hiddenAttributes: hiddenAttributes, fullRange: fullRange)
        }
        
        // 3. Apply the final attributed string with smooth transition
        textStorage.beginEditing()
        textStorage.setAttributedString(attributedString)
        textStorage.endEditing()
        
        // Restore position with layout completion awareness
        DispatchQueue.main.async {
            self.restorePositionAfterLayout(
                textView: textView, 
                scrollOrigin: scrollOrigin, 
                selectedRange: selectedRange,
                cursorRelativePosition: cursorRelativePosition
            )
        }
    }
    
    // MARK: - Position Preservation Helper Methods
    
    private func getCurrentPosition(textView: NSTextView) -> (NSPoint, NSRange) {
        guard let scrollView = textView.enclosingScrollView else {
            return (.zero, textView.selectedRange())
        }
        
        return (scrollView.contentView.bounds.origin, textView.selectedRange())
    }
    
    private func getCursorRelativePosition(textView: NSTextView, selectedRange: NSRange) -> CGFloat {
        // Calculate cursor position relative to visible area for more reliable restoration
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return 0.0
        }
        
        let cursorRect = layoutManager.boundingRect(forGlyphRange: selectedRange, in: textContainer)
        let visibleRect = textView.visibleRect
        
        return cursorRect.origin.y - visibleRect.origin.y
    }
    
    private func restorePositionAfterLayout(textView: NSTextView, scrollOrigin: NSPoint, selectedRange: NSRange, cursorRelativePosition: CGFloat) {
        // Wait for layout to complete before restoring position
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        
        // Restore cursor position first
        let clampedRange = NSRange(
            location: min(selectedRange.location, textView.string.count),
            length: min(selectedRange.length, textView.string.count - min(selectedRange.location, textView.string.count))
        )
        textView.setSelectedRange(clampedRange)
        
        // Handle end-of-document typing special case
        if isTypingAtEndOfDocument(textView: textView, selectedRange: selectedRange) {
            textView.scrollRangeToVisible(selectedRange)
        } else {
            // Restore scroll position using contentView bounds
            textView.enclosingScrollView?.contentView.scroll(scrollOrigin)
        }
    }
    
    private func isTypingAtEndOfDocument(textView: NSTextView, selectedRange: NSRange) -> Bool {
        let documentLength = textView.string.count
        return selectedRange.location >= documentLength - 10 // Within last 10 characters
    }
    
    // MARK: - Markdown Pattern Application
    
    private func applyMarkdownPatterns(to attributedString: NSMutableAttributedString, theme: Theme, hiddenAttributes: [NSAttributedString.Key: Any], fullRange: NSRange) {
        let headingRegex = try! NSRegularExpression(pattern: "^(#+)\\s*(.*)$", options: [.anchorsMatchLines])
        headingRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            
            let syntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            let level = syntaxRange.length
            var headingFont: NSFont
            var headingColor: NSColor
            
            switch level {
            case 1: 
                headingFont = .systemFont(ofSize: 28, weight: .bold)
                headingColor = NSColor(theme.textPrimary)
            case 2: 
                headingFont = .systemFont(ofSize: 24, weight: .semibold)
                headingColor = NSColor(theme.textPrimary)
            case 3: 
                headingFont = .systemFont(ofSize: 20, weight: .medium)
                headingColor = NSColor(theme.textPrimary)
            default: 
                headingFont = .systemFont(ofSize: 18, weight: .medium)
                headingColor = NSColor(theme.textPrimary)
            }
            
            attributedString.addAttribute(.font, value: headingFont, range: contentRange)
            attributedString.addAttribute(.foregroundColor, value: headingColor, range: contentRange)
            attributedString.addAttributes(hiddenAttributes, range: syntaxRange)
            
            // Add spacing after headings
            let headingParagraphStyle = NSMutableParagraphStyle()
            headingParagraphStyle.lineSpacing = 6
            headingParagraphStyle.paragraphSpacingBefore = 16
            headingParagraphStyle.paragraphSpacing = 12
            attributedString.addAttribute(.paragraphStyle, value: headingParagraphStyle, range: match.range)
        }

        // Bold text with improved styling
        let boldRegex = try! NSRegularExpression(pattern: "(\\*\\*|__)(.*?)\\1", options: [])
        boldRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            let syntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let trailingSyntaxStart = match.range.location + match.range.length - syntaxRange.length
            let trailingSyntaxRange = NSRange(location: trailingSyntaxStart, length: syntaxRange.length)
            
            let boldFont = NSFont.systemFont(ofSize: 16, weight: .semibold)
            attributedString.addAttribute(.font, value: boldFont, range: contentRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor(theme.textPrimary), range: contentRange)
            attributedString.addAttributes(hiddenAttributes, range: syntaxRange)
            attributedString.addAttributes(hiddenAttributes, range: trailingSyntaxRange)
        }

        // Italic text with improved styling
        let italicRegex = try! NSRegularExpression(pattern: "(\\*|_)(?!\\s)(.*?)(?<!\\s)\\1", options: [])
        italicRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            let syntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let trailingSyntaxStart = match.range.location + match.range.length - syntaxRange.length
            let trailingSyntaxRange = NSRange(location: trailingSyntaxStart, length: syntaxRange.length)
            
            let italicFont = NSFont.systemFont(ofSize: 16, weight: .regular).withTraits(.italicFontMask)
            attributedString.addAttribute(.font, value: italicFont, range: contentRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor(theme.textSecondary), range: contentRange)
            attributedString.addAttributes(hiddenAttributes, range: syntaxRange)
            attributedString.addAttributes(hiddenAttributes, range: trailingSyntaxRange)
        }
        
        // Code blocks with modern styling
        let codeRegex = try! NSRegularExpression(pattern: "`([^`]+)`", options: [])
        codeRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 2 else { return }
            let fullRange = match.range(at: 0)
            let contentRange = match.range(at: 1)
            
            let codeFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            attributedString.addAttribute(.font, value: codeFont, range: contentRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor(theme.accent), range: contentRange)
            attributedString.addAttribute(.backgroundColor, value: NSColor(theme.backgroundSecondary), range: fullRange)
        }
    }
    
    // MARK: - Phase 5.1: Memory Optimization and Undo Stack Management
    
    /// Calculates optimal undo levels based on document size and system memory
    private func calculateOptimalUndoLevels(for text: String) -> Int {
        let documentLength = text.count
        
        // Base levels for different document sizes
        switch documentLength {
        case 0..<1000:        // Small documents (< 1K chars)
            return 150        // Allow more undo levels for small docs
        case 1000..<5000:     // Medium documents (1K-5K chars)
            return 100        // Standard undo levels
        case 5000..<20000:    // Large documents (5K-20K chars)
            return 75         // Reduce undo levels for performance
        case 20000..<50000:   // Very large documents (20K-50K chars)
            return 50         // Further reduction for memory efficiency
        default:              // Extremely large documents (50K+ chars)
            return 25         // Minimal undo levels for performance
        }
    }
    
    /// Sets up memory management for the undo stack
    private func setupUndoMemoryManagement(undoManager: UndoManager) {
        // Set up periodic cleanup of undo stack for large documents
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            // Clean up undo stack if it gets too large
            if undoManager.canUndo {
                let maxMemoryActions = 50
                // This is a conservative approach to memory management
                // NSUndoManager handles most memory management internally
            }
        }
        
        // Monitor when app moves to background to trim undo stack
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Trim undo stack when app goes to background
            if undoManager.levelsOfUndo > 25 {
                undoManager.levelsOfUndo = 25
            }
        }
    }
}

// MARK: - NSFont Extension for Better Typography
extension NSFont {
    func withTraits(_ traits: NSFontTraitMask) -> NSFont {
        let fontManager = NSFontManager.shared
        return fontManager.font(
            withFamily: familyName ?? "SF Pro",
            traits: traits,
            weight: 5,
            size: pointSize
        ) ?? self
    }
}
