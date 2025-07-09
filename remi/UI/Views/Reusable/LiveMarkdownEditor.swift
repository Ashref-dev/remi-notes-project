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
        let attributedString = NSMutableAttributedString(string: textView.string)
        let fullRange = NSRange(location: 0, length: attributedString.length)
        
        // Reset all attributes first
        attributedString.removeAttribute(.font, range: fullRange)
        attributedString.removeAttribute(.foregroundColor, range: fullRange)
        
        // Apply default font
        attributedString.addAttribute(.font, value: font, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        // Headings (simplified: #, ##, ###)
        let headingRegex = try! NSRegularExpression(pattern: "^(#+)\s*(.*)$", options: [.anchorsMatchLines])
        headingRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match else { return }
            let hashRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            let level = hashRange.length
            var headingFont: NSFont
            switch level {
            case 1: headingFont = .boldSystemFont(ofSize: 28)
            case 2: headingFont = .boldSystemFont(ofSize: 24)
            case 3: headingFont = .boldSystemFont(ofSize: 20)
            default: headingFont = .boldSystemFont(ofSize: 18)
            }
            attributedString.addAttribute(.font, value: headingFont, range: contentRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: contentRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: hashRange)
        }

        // Bold (**text** or __text__)
        let boldRegex = try! NSRegularExpression(pattern: "(\*\*|__)(.*?)\1", options: [])
        boldRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match else { return }
            let contentRange = match.range(at: 2)
            attributedString.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: font.pointSize), range: contentRange)
        }

        // Italic (*text* or _text_)
        let italicRegex = try! NSRegularExpression(pattern: "(\*|_)(.*?)\1", options: [])
        italicRegex.enumerateMatches(in: attributedString.string, options: [], range: fullRange) { match, _, _ in
            guard let match = match else { return }
            let contentRange = match.range(at: 2)
            attributedString.addAttribute(.font, value: NSFont.italicSystemFont(ofSize: font.pointSize), range: contentRange)
        }
        
        // Apply the attributed string to the text view
        textView.textStorage?.setAttributedString(attributedString)
    }
}
