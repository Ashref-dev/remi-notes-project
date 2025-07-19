import SwiftUI
import AppKit

struct LiveMarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    let theme: Theme // Use the theme passed from the parent
    var isEditable: Bool = true
    var isMarkdownPreviewEnabled: Bool = true
    var font: NSFont = .systemFont(ofSize: 16, weight: .regular)
    
    // Callback to provide the NSTextView instance
    var textViewBinding: ((NSTextView) -> Void)? = nil

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 28, height: 28) // More spacious padding
        
        textView.importsGraphics = false
        textView.drawsBackground = true

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
        textViewBinding?(textView)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        // Update colors from the theme
        textView.backgroundColor = NSColor(theme.background)
        textView.textColor = NSColor(theme.textPrimary)
        textView.insertionPointColor = NSColor(theme.accent)
        
        if textView.string != text {
            let selectedRange = textView.selectedRange
            textView.string = text
            
            // Only apply markdown styling if preview is enabled
            if isMarkdownPreviewEnabled {
                applyMarkdownStyling(to: textView, theme: theme)
            } else {
                applyPlainTextStyling(to: textView, theme: theme)
            }
            
            textView.setSelectedRange(selectedRange)
        }
        textView.isEditable = isEditable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LiveMarkdownEditor
        var textView: NSTextView?

        init(_ parent: LiveMarkdownEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            if textView.string != parent.text {
                parent.text = textView.string
                
                // Only apply styling if preview is enabled
                if parent.isMarkdownPreviewEnabled {
                    parent.applyMarkdownStyling(to: textView, theme: parent.theme)
                } else {
                    parent.applyPlainTextStyling(to: textView, theme: parent.theme)
                }
            }
        }
    }
    
    // MARK: - Plain Text Styling
    private func applyPlainTextStyling(to textView: NSTextView, theme: Theme) {
        guard let textStorage = textView.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let attributedString = NSMutableAttributedString(attributedString: textStorage)
        
        // Reset all formatting and apply clean, modern plain text style
        attributedString.removeAttribute(.font, range: fullRange)
        attributedString.removeAttribute(.foregroundColor, range: fullRange)
        attributedString.removeAttribute(.backgroundColor, range: fullRange)
        
        // Apply consistent, beautiful font
        let plainFont = NSFont.systemFont(ofSize: 16, weight: .regular)
        attributedString.addAttribute(.font, value: plainFont, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor(theme.textPrimary), range: fullRange)
        
        // Apply paragraph styling for better readability
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 8
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        // Apply the plain text styling
        let selectedRange = textView.selectedRange
        textStorage.beginEditing()
        textStorage.setAttributedString(attributedString)
        textStorage.endEditing()
        textView.setSelectedRange(selectedRange)
    }
    
    // MARK: - Enhanced Markdown Styling
    // MARK: - Enhanced Markdown Styling
    private func applyMarkdownStyling(to textView: NSTextView, theme: Theme) {
        guard let textStorage = textView.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
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

        // 2. Apply enhanced styles with better typography
        
        // Headings with improved hierarchy
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
        
        // 3. Apply the final attributed string with smooth transition
        let selectedRange = textView.selectedRange
        textStorage.beginEditing()
        textStorage.setAttributedString(attributedString)
        textStorage.endEditing()
        textView.setSelectedRange(selectedRange)
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
