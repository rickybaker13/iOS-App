import SwiftUI
import UIKit

enum RichTextFormatCommand: Equatable {
    case bold, italic, underline, strikethrough
    case textColor(UIColor)
    case backgroundColor(UIColor)
    case fontSize(CGFloat)
    case none
    
    static func == (lhs: RichTextFormatCommand, rhs: RichTextFormatCommand) -> Bool {
        switch (lhs, rhs) {
        case (.bold, .bold), (.italic, .italic), (.underline, .underline), 
             (.strikethrough, .strikethrough), (.none, .none):
            return true
        case (.textColor(let lhsColor), .textColor(let rhsColor)):
            return lhsColor == rhsColor
        case (.backgroundColor(let lhsColor), .backgroundColor(let rhsColor)):
            return lhsColor == rhsColor
        case (.fontSize(let lhsSize), .fontSize(let rhsSize)):
            return lhsSize == rhsSize
        default:
            return false
        }
    }
}

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    var formatCommand: RichTextFormatCommand = .none
    var onFormatCommandHandled: (() -> Void)? = nil
    var onAttributedTextChanged: ((Data?) -> Void)? = nil
    var attributedData: Data? = nil
    var onSelectionChange: ((NSRange) -> Void)? = nil
    var isScrollEnabled: Bool = true
    
    func makeUIView(context: Context) -> UITextView {
        // Use standard UITextView for scrolling (main editor) to ensure standard behavior
        // Use ProperlySizedTextView only when we need auto-expanding height (timeline)
        let textView = isScrollEnabled ? UITextView() : ProperlySizedTextView()
        
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = isScrollEnabled
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsEditingTextAttributes = true
        textView.isUserInteractionEnabled = true
        
        // Ensure proper selection highlighting
        textView.tintColor = .systemBlue
        if #available(iOS 13.0, *) {
            textView.textColor = .label
        } else {
            textView.textColor = .black
        }
        
        // Standard layout configuration
        // Note: We rely on SwiftUI padding for insets to avoid gesture/selection issues
        textView.textContainer.lineFragmentPadding = 0
        
        if isScrollEnabled {
            textView.textContainer.widthTracksTextView = true
            textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        } else {
            textView.textContainer.widthTracksTextView = false
            textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            textView.contentInsetAdjustmentBehavior = .never
        }
        
        // Load attributed data if available
        if let attributedData = attributedData {
            // Try KeyedUnarchiver first (new format)
            if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: attributedData) {
                textView.attributedText = unarchived
            }
            // Fallback to RTF (legacy format)
            else if let attributedString = try? NSAttributedString(
                data: attributedData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) {
                textView.attributedText = attributedString
            }
        } else {
            textView.text = text
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update the coordinator's parent to ensure the binding is current
        context.coordinator.parent = self
        
        // Handle formatting command FIRST - this is critical for toolbar buttons
        if formatCommand != .none {
            context.coordinator.applyFormat(formatCommand, to: uiView)
            onFormatCommandHandled?()
            return // Don't do anything else when applying format
        }
        
        // Check if text content matches to avoid unnecessary resets
        // This prevents overwriting the cursor/selection/attributes while typing
        if uiView.text == text {
            // Content matches, do nothing
            return
        }
        
        uiView.text = text
        uiView.isScrollEnabled = isScrollEnabled
        
        // Ensure text container settings are maintained
        uiView.textContainer.lineFragmentPadding = 0
        
        if isScrollEnabled {
            uiView.textContainer.widthTracksTextView = true
        } else {
            uiView.textContainer.widthTracksTextView = false
            uiView.contentInsetAdjustmentBehavior = .never
        }
        
        // Restore selection - but only if user isn't actively selecting
        if uiView.selectedRange.location != selection.location || uiView.selectedRange.length != selection.length {
            if selection.length == 0 || uiView.selectedRange.length == 0 {
                uiView.selectedRange = selection
            }
        }
        
        // Load attributed data if available and text changed
        if let attributedData = attributedData {
            if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: attributedData) {
                uiView.attributedText = unarchived
            } else if let attributedString = try? NSAttributedString(
                data: attributedData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) {
                uiView.attributedText = attributedString
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // CRITICAL: Update the text binding immediately - this ensures save works
            // Use standard async to avoid view update conflicts, but ensure it runs
            let newText = textView.text ?? ""
            let attributedString = textView.attributedText ?? NSAttributedString(string: newText)
            
            DispatchQueue.main.async {
                if self.parent.text != newText {
                    self.parent.text = newText
                }
                
                // Save attributed string data using KeyedArchiver for better fidelity
                if let attributedData = try? NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: false) {
                    self.parent.onAttributedTextChanged?(attributedData)
                }
            }
            
            // Invalidate intrinsic content size when text changes (for non-scrolling views)
            if !textView.isScrollEnabled, let properTextView = textView as? ProperlySizedTextView {
                properTextView.invalidateIntrinsicContentSize()
            }
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selection = textView.selectedRange
            parent.onSelectionChange?(textView.selectedRange)
        }
        
        func applyFormat(_ command: RichTextFormatCommand, to textView: UITextView) {
            guard textView.selectedRange.length > 0 else { return }
            let range = textView.selectedRange
            let mutableAttrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let font = UIFont.preferredFont(forTextStyle: .body)
            
            switch command {
            case .bold:
                mutableAttrString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                    let currentFont = (value as? UIFont) ?? font
                    let newFont = currentFont.isBold ? font : currentFont.bold()
                    mutableAttrString.addAttribute(.font, value: newFont, range: subrange)
                }
            case .italic:
                mutableAttrString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                    let currentFont = (value as? UIFont) ?? font
                    let newFont = currentFont.isItalic ? font : currentFont.italic()
                    mutableAttrString.addAttribute(.font, value: newFont, range: subrange)
                }
            case .underline:
                mutableAttrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            case .strikethrough:
                mutableAttrString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            case .textColor(let color):
                mutableAttrString.addAttribute(.foregroundColor, value: color, range: range)
            case .backgroundColor(let color):
                mutableAttrString.addAttribute(.backgroundColor, value: color, range: range)
            case .fontSize(let size):
                mutableAttrString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                    let currentFont = (value as? UIFont) ?? font
                    let newFont = currentFont.withSize(size)
                    mutableAttrString.addAttribute(.font, value: newFont, range: subrange)
                }
            case .none:
                break
            }
            
            textView.attributedText = mutableAttrString
            textView.selectedRange = range
            textView.scrollRangeToVisible(range)
            parent.text = mutableAttrString.string
            
            // Save attributed string data using KeyedArchiver
            if let attributedData = try? NSKeyedArchiver.archivedData(withRootObject: mutableAttrString, requiringSecureCoding: false) {
                // Update parent immediately to ensure changes are saved
                parent.onAttributedTextChanged?(attributedData)
            }
        }
    }
}

// Custom UITextView that properly handles layout
class ProperlySizedTextView: UITextView {
    var swiftUIPadding: CGFloat = 40.0  // SwiftUI padding: 20pt each side
    private var lastContainerWidth: CGFloat = 0
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupSelectionGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSelectionGestures()
    }
    
    private func setupSelectionGestures() {
        // Ensure standard text interaction
        isUserInteractionEnabled = true
        isSelectable = true
        isEditable = true
        
        // Ensure selection highlighting is visible
        tintColor = .systemBlue
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Ensure text selection actions work
        return super.canPerformAction(action, withSender: sender)
    }
    
    override var intrinsicContentSize: CGSize {
        // If scrolling is enabled, let the view size itself naturally
        if isScrollEnabled {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        
        // Calculate the proper height for the text content
        let insets = textContainerInset
        let containerWidth = bounds.width > 0 ? bounds.width - insets.left - insets.right - swiftUIPadding : 0
        
        if containerWidth > 0 {
            // Temporarily set container size to calculate height
            let savedSize = textContainer.size
            textContainer.size = CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude)
            
            // Calculate the height needed for the text
            let usedRect = layoutManager.usedRect(for: textContainer)
            let height = usedRect.height + insets.top + insets.bottom
            
            // Restore container size
            textContainer.size = savedSize
            
            return CGSize(width: UIView.noIntrinsicMetric, height: height)
        }
        
        return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Only manage size manually if scrolling is disabled (for expanding views)
        if !isScrollEnabled {
            // Set text container size - subtract SwiftUI padding from bounds width
            // SwiftUI applies 20pt padding on each side outside the UITextView
            let insets = textContainerInset
            let containerWidth = bounds.width - insets.left - insets.right - swiftUIPadding
            
            if containerWidth > 0 && abs(containerWidth - lastContainerWidth) > 0.1 {
                // Only update if width actually changed
                lastContainerWidth = containerWidth
                
                // Disable width tracking to prevent UITextView from auto-managing it
                textContainer.widthTracksTextView = false
                
                // Set the size explicitly - subtract SwiftUI padding so text fits properly
                textContainer.size = CGSize(
                    width: containerWidth,
                    height: CGFloat.greatestFiniteMagnitude
                )
                
                // Use async to avoid interrupting ongoing gestures
                DispatchQueue.main.async { [weak self] in
                    self?.invalidateIntrinsicContentSize()
                }
            }
        } else {
            // For scrollable views, ensure standard behavior
            if !textContainer.widthTracksTextView {
                textContainer.widthTracksTextView = true
            }
        }
    }
    
    override var bounds: CGRect {
        didSet {
            // Only manage size manually if scrolling is disabled
            if !isScrollEnabled {
                // When bounds change (especially width), update text container size immediately
                if bounds.width != oldValue.width && bounds.width > 0 {
                    let insets = textContainerInset
                    let containerWidth = bounds.width - insets.left - insets.right - swiftUIPadding
                    
                    if containerWidth > 0 && abs(containerWidth - lastContainerWidth) > 0.1 {
                        lastContainerWidth = containerWidth
                        
                        // Disable width tracking
                        textContainer.widthTracksTextView = false
                        
                        // Force immediate update - subtract SwiftUI padding
                        textContainer.size = CGSize(
                            width: containerWidth,
                            height: CGFloat.greatestFiniteMagnitude
                        )
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.invalidateIntrinsicContentSize()
                        }
                    }
                }
            }
        }
    }
}

// UIFont helpers
extension UIFont {
    var isBold: Bool { fontDescriptor.symbolicTraits.contains(.traitBold) }
    var isItalic: Bool { fontDescriptor.symbolicTraits.contains(.traitItalic) }
    
    func bold() -> UIFont {
        let traits = fontDescriptor.symbolicTraits.union(.traitBold)
        if let desc = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: desc, size: pointSize)
        }
        return self
    }
    
    func italic() -> UIFont {
        let traits = fontDescriptor.symbolicTraits.union(.traitItalic)
        if let desc = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: desc, size: pointSize)
        }
        return self
    }
}
