import SwiftUI
import AppKit

struct LiveMarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    let theme: Theme // Use the theme passed from the parent
    var isEditable: Bool = true
    var font: NSFont = AppTheme.Fonts.editor
    
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
        textView.textContainerInset = NSSize(width: 25, height: 25) // More spacious padding
        
        textView.importsGraphics = false
        textView.drawsBackground = true

        // Style the background and insertion point
        textView.backgroundColor = NSColor(theme.background)
        textView.insertionPointColor = NSColor(theme.accent)

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
            applyMarkdownStyling(to: textView, theme: theme)
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
                // Pass the correct theme from the parent struct
                parent.applyMarkdownStyling(to: textView, theme: parent.theme)
            }
        }
    }
    
    private func applyMarkdownStyling(to textView: NSTextView, theme: Theme) {
        guard let textStorage = textView.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let attributedString = NSMutableAttributedString(attributedString: textStorage)
        
        // 1. Reset styles
        attributedString.removeAttribute(.font, range: fullRange)
        attributedString.removeAttribute(.foregroundColor, range: fullRange)
        attributedString.addAttribute(.font, value: font, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor(theme.textPrimary), range: fullRange)

        // Define a "hidden" style for Markdown syntax characters
        let hiddenAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 0.1),
            .foregroundColor: NSColor.clear
        ]

        // 2. Apply styles
        
        // Headings
        let headingRegex = try! NSRegularExpression(pattern: "^(#+)\\s*(.*)$", options: [.anchorsMatchLines])
        headingRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            
            let syntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            let level = syntaxRange.length
            var headingFont: NSFont
            switch level {
            case 1: headingFont = .boldSystemFont(ofSize: 28)
            case 2: headingFont = .boldSystemFont(ofSize: 24)
            case 3: headingFont = .boldSystemFont(ofSize: 20)
            default: headingFont = .boldSystemFont(ofSize: 18)
            }
            
            attributedString.addAttribute(.font, value: headingFont, range: contentRange)
            attributedString.addAttributes(hiddenAttributes, range: syntaxRange)
        }

        // Bold
        let boldRegex = try! NSRegularExpression(pattern: "(\\*\\*|__)(.*?)\\1", options: [])
        boldRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            let syntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let trailingSyntaxStart = match.range.location + match.range.length - syntaxRange.length
            let trailingSyntaxRange = NSRange(location: trailingSyntaxStart, length: syntaxRange.length)
            let boldFont = NSFont.boldSystemFont(ofSize: font.pointSize)
            attributedString.addAttribute(.font, value: boldFont, range: contentRange)
            attributedString.addAttributes(hiddenAttributes, range: syntaxRange)
            attributedString.addAttributes(hiddenAttributes, range: trailingSyntaxRange)
        }

        // Italic
        let italicRegex = try! NSRegularExpression(pattern: "(\\*|_)(?!\\s)(.*?)(?<!\\s)\\1", options: [])
        italicRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            let syntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let trailingSyntaxStart = match.range.location + match.range.length - syntaxRange.length
            let trailingSyntaxRange = NSRange(location: trailingSyntaxStart, length: syntaxRange.length)
            let fontManager = NSFontManager.shared
            let italicFont = fontManager.font(withFamily: font.familyName ?? "", traits: .italicFontMask, weight: 5, size: font.pointSize) ?? font
            attributedString.addAttribute(.font, value: italicFont, range: contentRange)
            attributedString.addAttributes(hiddenAttributes, range: syntaxRange)
            attributedString.addAttributes(hiddenAttributes, range: trailingSyntaxRange)
        }
        
        // 3. Apply the final attributed string
        let selectedRange = textView.selectedRange
        textStorage.beginEditing()
        textStorage.setAttributedString(attributedString)
        textStorage.endEditing()
        textView.setSelectedRange(selectedRange)
    }
}
