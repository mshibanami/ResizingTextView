//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

#if canImport(UIKit)
import SwiftUI
import UIKit

@MainActor struct TextView: UIViewRepresentable {
    static let defaultForegroundColor = Color(UIColor.label)
    
    struct Parameters {
        var text: Binding<String>
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
#if !os(tvOS)
    private var isEditable: Bool
#endif
    private var isScrollable: Bool
    private var isSelectable: Bool
    private var lineLimit: Int
    private var foregroundColor: Color
    private var font: UIFont
    private var canHaveNewLineCharacters: Bool
    private var width: CGFloat?
    private var autocapitalizationType: UITextAutocapitalizationType
    private var textContainerInset: UIEdgeInsets
    private var keyboardType: UIKeyboardType
    
    init(parameters: Parameters) {
        _text = parameters.text
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
        let view = CustomTextView()
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        updateUIView(view, context: context)
        if isScrollable {
            Task.detached { @MainActor [weak view] in
                view?.setContentOffset(.zero, animated: false)
            }
        }
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
#if !os(tvOS)
        if view.isEditable != isEditable {
            view.isEditable = isEditable
        }
#endif
        if view.isSelectable != isSelectable {
            view.isSelectable = isSelectable
        }
        if view.textContainer.maximumNumberOfLines != lineLimit {
            view.textContainer.maximumNumberOfLines = lineLimit
        }
        if view.autocapitalizationType != autocapitalizationType {
            view.autocapitalizationType = autocapitalizationType
        }
        if view.keyboardType != keyboardType {
            view.keyboardType = keyboardType
        }
        
        let textContainerInset = textContainerInset
        if view.textContainerInset != textContainerInset {
            view.textContainerInset = textContainerInset
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

#if !os(tvOS)
        if !isEditable {
            view.textContainerInset = textContainerInset
            needsInvalidateIntrinsicContentSize = true
        }
#endif

        if needsInvalidateIntrinsicContentSize, !isScrollable {
            view.invalidateIntrinsicContentSize()
            view.layoutIfNeeded()
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
