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

    init(_ text: Binding<String>,
         isEditable: Bool = true,
         isScrollable: Bool = false,
         isSelectable: Bool = true,
         lineLimit: Int = 0,
         font: UIFont,
         canHaveNewLineCharacters: Bool = true,
         foregroundColor: Color = defaultForegroundColor) {
        self._text = text
        self.isEditable = isEditable
        self.isScrollable = isScrollable
        self.isSelectable = isSelectable
        self.lineLimit = lineLimit
        self.foregroundColor = foregroundColor
        self.font = font
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
    }

    init(text: String) {
        self.init(
            Binding<String>.constant(text),
            isEditable: false,
            font: UIFont.preferredFont(forTextStyle: .body),
            foregroundColor: Self.defaultForegroundColor)
    }

    func makeUIView(context: Context) -> CustomTextView {
        let view = CustomTextView()
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: CustomTextView, context: Context) {
        view.hasDynamicHeight = !isScrollable
        if view.text != text {
            view.text = text
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
            if parent.text != textView.text {
                parent.text = textView.text
            }
            if selectedRange != textView.selectedRange {
                selectedRange = textView.selectedRange
            }
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
