//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

#if os(iOS)
import UIKit
import SwiftUI

struct TextView: UIViewRepresentable {
    static let defaultForegroundColor = Color(UIColor.label)

    @Binding private var text: String
    private var isEditable: Bool
    private var isScrollable: Bool
    private var isSelectable: Bool
    private var lineLimit: Int
    private var foregroundColor: Color
    private var font: UIFont
    private var canHaveNewLineCharacters: Bool
    private var width: CGFloat?
    private var autocapitalizationType: UITextAutocapitalizationType
    private var textContainerInset: UIEdgeInsets

    init(_ text: Binding<String>,
         isEditable: Bool,
         isScrollable: Bool,
         isSelectable: Bool,
         lineLimit: Int,
         font: UIFont,
         canHaveNewLineCharacters: Bool,
         foregroundColor: Color,
         autocapitalizationType: UITextAutocapitalizationType,
         textContainerInset: UIEdgeInsets?) {
        self._text = text
        self.isEditable = isEditable
        self.isScrollable = isScrollable
        self.isSelectable = isSelectable
        self.lineLimit = lineLimit
        self.foregroundColor = foregroundColor
        self.font = font
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
        self.autocapitalizationType = autocapitalizationType
        
        // HACK: In iOS 17, the last sentence of a non-editable text may not be drawn if the textContainerInset is `.zero`. To avoid it, we add this default value to the insets.
        let defaultTextContainerInset = UIEdgeInsets(top: 0.00000001, left: 0.00000001, bottom: 0.00000001, right: 0.00000001)
        self.textContainerInset = textContainerInset ?? defaultTextContainerInset
    }

    func makeUIView(context: Context) -> CustomTextView {
        let view = CustomTextView()
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        updateUIView(view, context: context)
        return view
    }

    func updateUIView(_ view: CustomTextView, context: Context) {
        var needsInvalidateIntrinsicContentSize = false

        view.hasDynamicHeight = !isScrollable
        view.clipsToBounds = isScrollable

        if view.text != text {
            view.text = text
            needsInvalidateIntrinsicContentSize = true
        }
        if view.font != font {
            view.font = font
        }
        if view.textColor != UIColor(foregroundColor) {
            view.textColor = UIColor(foregroundColor)
        }
        if view.isEditable != isEditable {
            view.isEditable = isEditable
        }
        if view.isSelectable != isSelectable {
            view.isSelectable = isSelectable
        }
        if view.textContainer.maximumNumberOfLines != lineLimit {
            view.textContainer.maximumNumberOfLines = lineLimit
        }
        if view.autocapitalizationType != autocapitalizationType {
            view.autocapitalizationType = autocapitalizationType
        }
        if lineLimit > 0 {
            if view.textContainer.lineBreakMode != .byTruncatingTail {
                view.textContainer.lineBreakMode = .byTruncatingTail
            }
        }
        if let selectedRange = context.coordinator.selectedRange {
            if view.selectedRange != selectedRange {
                view.selectedRange = selectedRange
            }
        }

        if !isEditable {
            view.textContainerInset = textContainerInset
            needsInvalidateIntrinsicContentSize = true
        }

        if needsInvalidateIntrinsicContentSize && !isScrollable {
            view.invalidateIntrinsicContentSize()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView
        var selectedRange: NSRange?

        init(_ parent: TextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            if !parent.canHaveNewLineCharacters,
               textView.text.contains(where: { $0 == "\n" }) {
                textView.text.removeAll(where: { $0 == "\n" })
            }

            parent.text = textView.text

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

    init() {
        super.init(frame: .zero, textContainer: nil)
        isScrollEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var contentSize: CGSize {
        didSet {
            if hasDynamicHeight {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override open var intrinsicContentSize: CGSize {
        return hasDynamicHeight
        ? contentSize
        : super.intrinsicContentSize
    }
}
#endif
