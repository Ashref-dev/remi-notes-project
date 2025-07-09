import SwiftUI
import AppKit

struct LiveMarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool = true
    var font: NSFont = .monospacedSystemFont(ofSize: 16, weight: .regular)
    
    // Callback to provide the NSTextView instance
    var textViewBinding: ((NSTextView) -> Void)? = nil

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = false // We will handle rich text via attributed strings
        textView.allowsUndo = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        textView.importsGraphics = false
        textView.drawsBackground = true
        textView.backgroundColor = .clear

        // Enable automatic quote substitution and dash substitution
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticLinkDetectionEnabled = false // We don't want automatic links

        context.coordinator.textView = textView // Store reference to textView
        textViewBinding?(textView) // Provide the textView instance

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        // Prevent infinite loop when text is updated programmatically
        if textView.string != text {
            let selectedRange = textView.selectedRange
            textView.string = text
            applyMarkdownStyling(to: textView)
            textView.setSelectedRange(selectedRange)
        }
        textView.isEditable = isEditable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LiveMarkdownEditor
        var textView: NSTextView? // Reference to the NSTextView

        init(_ parent: LiveMarkdownEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Update the binding only if the text has actually changed by user input
            if textView.string != parent.text {
                parent.text = textView.string
                parent.applyMarkdownStyling(to: textView)
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }
    }
    
    private func applyMarkdownStyling(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        // Start with a mutable attributed string
        let attributedString = NSMutableAttributedString(attributedString: textStorage)
        
        // 1. Reset all styles to default
        attributedString.removeAttribute(.font, range: fullRange)
        attributedString.removeAttribute(.foregroundColor, range: fullRange)
        attributedString.addAttribute(.font, value: font, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        // Define a "hidden" style for Markdown syntax characters
        let hiddenAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 0.1),
            .foregroundColor: NSColor.clear
        ]

        // 2. Apply styles and hide syntax
        
        // Headings (#, ##, ###)
        let headingRegex = try! NSRegularExpression(pattern: "^(#+)\\s*(.*)$", options: [.anchorsMatchLines])
        headingRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match else { return }
            
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
            attributedString.addAttributes(hiddenAttributes, range: syntaxRange) // Hide the hashes
        }

        // Bold (**text** or __text__)
        let boldRegex = try! NSRegularExpression(pattern: "(\\*\\*|__)(.*?)\\1", options: [])
        boldRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            
            let leadingSyntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            // Calculate trailing syntax range
            let trailingSyntaxStart = match.range.location + match.range.length - leadingSyntaxRange.length
            let trailingSyntaxRange = NSRange(location: trailingSyntaxStart, length: leadingSyntaxRange.length)

            let boldFont = NSFont.boldSystemFont(ofSize: font.pointSize)
            attributedString.addAttribute(.font, value: boldFont, range: contentRange)
            
            attributedString.addAttributes(hiddenAttributes, range: leadingSyntaxRange)
            attributedString.addAttributes(hiddenAttributes, range: trailingSyntaxRange)
        }

        // Italic (*text* or _text_)
        let italicRegex = try! NSRegularExpression(pattern: "(\\*|_)(?!\\s)(.*?)(?<!\\s)\\1", options: [])
        italicRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }

            let leadingSyntaxRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            // Calculate trailing syntax range
            let trailingSyntaxStart = match.range.location + match.range.length - leadingSyntaxRange.length
            let trailingSyntaxRange = NSRange(location: trailingSyntaxStart, length: leadingSyntaxRange.length)

            let fontManager = NSFontManager.shared
            let italicFont = fontManager.font(withFamily: font.familyName ?? "", traits: .italicFontMask, weight: 5, size: font.pointSize) ?? font
            attributedString.addAttribute(.font, value: italicFont, range: contentRange)
            
            attributedString.addAttributes(hiddenAttributes, range: leadingSyntaxRange)
            attributedString.addAttributes(hiddenAttributes, range: trailingSyntaxRange)
        }
        
        // 3. Apply the final attributed string to the text storage
        // This must be done carefully to avoid triggering the delegate's textDidChange method unnecessarily
        let selectedRange = textView.selectedRange
        textStorage.beginEditing()
        textStorage.setAttributedString(attributedString)
        textStorage.endEditing()
        textView.setSelectedRange(selectedRange)
    }
}