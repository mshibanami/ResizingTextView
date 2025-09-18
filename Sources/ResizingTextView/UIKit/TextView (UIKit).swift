//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

#if canImport(UIKit)
import SwiftUI
import UIKit

@MainActor struct TextView: UIViewRepresentable {
    static let defaultForegroundColor = Color(UIColor.label)
    
    struct Parameters {
        var text: Binding<String>
        var decorations: [TextDecoration]
#if !os(tvOS)
        var isEditable: Bool
#endif
        var isScrollable: Bool
        var isSelectable: Bool
        var lineLimit: Int
        var font: UIFont
        var canHaveNewLineCharacters: Bool
        var foregroundColor: Color
        var autocapitalizationType: UITextAutocapitalizationType
        var textContainerInset: UIEdgeInsets
        var keyboardType: UIKeyboardType
    }
    
    @Binding private var text: String
    var decorations: [TextDecoration]
#if !os(tvOS)
    private var isEditable: Bool
#endif
    private var isScrollable: Bool
    private var isSelectable: Bool
    private var lineLimit: Int
    private var foregroundColor: Color
    private var font: UIFont
    private var canHaveNewLineCharacters: Bool
    private var autocapitalizationType: UITextAutocapitalizationType
    private var textContainerInset: UIEdgeInsets
    private var keyboardType: UIKeyboardType
    
    init(parameters: Parameters) {
        _text = parameters.text
        self.decorations = parameters.decorations
        self.isScrollable = parameters.isScrollable
#if !os(tvOS)
        self.isEditable = parameters.isEditable
#endif
        self.isSelectable = parameters.isSelectable
        self.lineLimit = parameters.lineLimit
        self.foregroundColor = parameters.foregroundColor
        self.font = parameters.font
        self.canHaveNewLineCharacters = parameters.canHaveNewLineCharacters
        self.autocapitalizationType = parameters.autocapitalizationType
        self.textContainerInset = parameters.textContainerInset
        self.keyboardType = parameters.keyboardType
    }
    
    func makeUIView(context: Context) -> CustomTextView {
        let textStorage = DecoratableTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        let textView = CustomTextView(textContainer: textContainer)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        resetTypingAttributes(of: textView)
        updateUIView(textView, context: context)
        return textView
    }

    func updateUIView(_ textView: CustomTextView, context: Context) {
        var needsInvalidateIntrinsicContentSize = false

        textView.hasDynamicHeight = !isScrollable
        textView.clipsToBounds = isScrollable
        
        if textView.text != text {
            textView.text = text
        }
        
        if let textStorage = textView.textStorage as? DecoratableTextStorage {
            textStorage.attributionMap = .init(
                defaultFont: font,
                defaultForegroundColor: UIColor(foregroundColor),
                decorations: decorations
            )
        }
#if !os(tvOS)
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }
#endif
        if textView.isSelectable != isSelectable {
            textView.isSelectable = isSelectable
        }
        if textView.textContainer.maximumNumberOfLines != lineLimit {
            textView.textContainer.maximumNumberOfLines = lineLimit
        }
        if textView.autocapitalizationType != autocapitalizationType {
            textView.autocapitalizationType = autocapitalizationType
        }
        if textView.keyboardType != keyboardType {
            textView.keyboardType = keyboardType
        }
        
        let textContainerInset = textContainerInset
        if textView.textContainerInset != textContainerInset {
            textView.textContainerInset = textContainerInset
        }
        if lineLimit > 0 {
            if textView.textContainer.lineBreakMode != .byTruncatingTail {
                textView.textContainer.lineBreakMode = .byTruncatingTail
            }
        }
        if let selectedRange = context.coordinator.selectedRange {
            if textView.selectedRange != selectedRange {
                textView.selectedRange = selectedRange
            }
        }

#if !os(tvOS)
        if !isEditable {
            textView.textContainerInset = textContainerInset
            needsInvalidateIntrinsicContentSize = true
        }
#endif

        if needsInvalidateIntrinsicContentSize, !isScrollable {
            textView.invalidateIntrinsicContentSize()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func resetTypingAttributes(of textView: UITextView) {
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: UXColor(foregroundColor)
        ]
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var swiftUIView: TextView
        var selectedRange: NSRange?

        init(_ parent: TextView) {
            self.swiftUIView = parent
        }
                
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n",
               !swiftUIView.canHaveNewLineCharacters {
                return false
            }
            swiftUIView.resetTypingAttributes(of: textView)
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            if !swiftUIView.canHaveNewLineCharacters,
               textView.text.contains(where: { $0 == "\n" }) {
                textView.text.removeAll(where: { $0 == "\n" })
            }
            if textView.text != swiftUIView.text {
                swiftUIView.text = textView.text
            }
            if selectedRange != textView.selectedRange {
                selectedRange = textView.selectedRange
            }
            textView.invalidateIntrinsicContentSize()
        }
    }
}

class CustomTextView: UITextView {
    var hasDynamicHeight = true

    override var isScrollEnabled: Bool {
        didSet {
            assert(isScrollEnabled)
        }
    }

    init(textContainer: NSTextContainer? = nil) {
        super.init(frame: .zero, textContainer: textContainer)
        isScrollEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var contentSize: CGSize {
        didSet {
            if hasDynamicHeight,
               contentSize != oldValue {
                Task.detached { @MainActor [weak self] in
                    self?.invalidateIntrinsicContentSize()
                }
            }
        }
    }

    override open var intrinsicContentSize: CGSize {
        return hasDynamicHeight
            ? CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
            : super.intrinsicContentSize
    }
}
#endif
