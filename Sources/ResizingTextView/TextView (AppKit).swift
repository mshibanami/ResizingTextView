//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

#if os(macOS)
import SwiftUI

struct TextView: NSViewRepresentable {
    static let defaultForegroundColor = Color(NSColor.textColor)

    @Binding var text: String
    var placeholder: String?
    var isEditable: Bool
    var isScrollable: Bool
    var lineLimit: Int
    var lineBreakMode: NSLineBreakMode
    var font: NSFont
    var canHaveNewLineCharacters: Bool
    var focusesNextKeyViewByTabKey: Bool
    var foregroundColor: Color
    var onFocusChanged: ((Bool) -> Void)?
    var onInsertNewline: (() -> Bool)?

    init(_ text: Binding<String>,
         placeholder: String? = nil,
         isEditable: Bool = true,
         isScrollable: Bool = true,
         lineLimit: Int = 0,
         lineBreakMode: NSLineBreakMode? = nil,
         font: NSFont,
         canHaveNewLineCharacters: Bool = true,
         focusesNextKeyViewByTabKey: Bool = true,
         foregroundColor: Color = defaultForegroundColor,
         onFocusChanged: ((Bool) -> Void)? = nil,
         onInsertNewline: (() -> Bool)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.isScrollable = isScrollable
        self.lineLimit = lineLimit
        self.lineBreakMode = lineBreakMode ?? .byCharWrapping
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
        self.focusesNextKeyViewByTabKey = focusesNextKeyViewByTabKey
        self.foregroundColor = foregroundColor
        self.font = font
        self.onFocusChanged = onFocusChanged
        self.onInsertNewline = onInsertNewline
    }

    init(text: String) {
        self.init(
            Binding<String>.constant(text),
            isEditable: false,
            font: NSFont.preferredFont(forTextStyle: .body),
            foregroundColor: Self.defaultForegroundColor)
    }

    func makeNSView(context: Context) -> TextEnclosingScrollView {
        let textView = CustomTextView()
        textView.textContainerInset = .init(width: -5, height: 0)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.onFocusChanged = onFocusChanged

        let scrollView = TextEnclosingScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ view: TextEnclosingScrollView, context: Context) {
        guard let textView = view.documentView as? CustomTextView else {
            assertionFailure()
            return
        }

        if view.isScrollable != isScrollable || view.hasVerticalScroller != isScrollable {
            view.isScrollable = isScrollable
            view.hasVerticalScroller = isScrollable
        }

        let documentHeightIsChanged = (view.documentView?.bounds.height ?? 0) > view.bounds.height
        let scrollerStyle = (isScrollable && documentHeightIsChanged) ? NSScroller.preferredScrollerStyle : .overlay
        if view.scrollerStyle != scrollerStyle {
            view.scrollerStyle = scrollerStyle
        }
        
        if let placeholder {
            textView.placeholderAttributedString = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: NSColor.placeholderTextColor,
                    .font: font
                ])
        } else {
            textView.placeholderAttributedString = nil
        }
        if textView.string != text {
            textView.string = text
        }
        if textView.font != font {
            textView.font = font
        }
        if textView.textColor != NSColor(foregroundColor) {
            textView.textColor = NSColor(foregroundColor)
        }
        let newBackgroundColor: NSColor = isEditable ? .textBackgroundColor : .clear
        if textView.backgroundColor != newBackgroundColor {
            textView.backgroundColor = newBackgroundColor
        }
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }
        if textView.textContainer?.maximumNumberOfLines != lineLimit {
            textView.textContainer?.maximumNumberOfLines = lineLimit
        }
        if textView.textContainer?.lineBreakMode != lineBreakMode {
            textView.textContainer?.lineBreakMode = lineBreakMode
        }
        if lineLimit > 0 {
            if textView.textContainer?.lineBreakMode != .byTruncatingTail {
                textView.textContainer?.lineBreakMode = .byTruncatingTail
            }
        }
        if !context.coordinator.selectedRanges.isEmpty {
            if textView.selectedRanges != context.coordinator.selectedRanges {
                textView.selectedRanges = context.coordinator.selectedRanges
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextView
        var selectedRanges = [NSValue]()

        init(_ parent: TextView) {
            self.parent = parent
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertTab(_:)):
                guard parent.focusesNextKeyViewByTabKey else {
                    return false
                }
                textView.window?.selectNextKeyView(nil)
                return true
            case #selector(NSResponder.insertBacktab(_:)):
                guard parent.focusesNextKeyViewByTabKey else {
                    return false
                }
                textView.window?.selectPreviousKeyView(nil)
                return true
            case #selector(NSResponder.insertNewline(_:)):
                return parent.onInsertNewline?() ?? false
            default:
                return false
            }
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            if (replacementString == "\n") && !parent.canHaveNewLineCharacters {
                return false
            }
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? CustomTextView else {
                return
            }
            if !parent.canHaveNewLineCharacters,
               textView.string.contains("\n") {
                textView.string.removeAll(where: { $0 == "\n" })
            }
            if parent.text != textView.string {
                parent.text = textView.string
            }
            if selectedRanges != textView.selectedRanges {
                selectedRanges = textView.selectedRanges
            }
        }
    }
}

class TextEnclosingScrollView: NSScrollView {
    var isScrollable = true

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func scrollWheel(with event: NSEvent) {
        if !isScrollable {
            self.nextResponder?.scrollWheel(with: event)
        } else {
            super.scrollWheel(with: event)
        }
    }
}

private class CustomTextView: NSTextView {
    var onFocusChanged: ((Bool) -> Void)?

    /// https://stackoverflow.com/a/43028577/4366470
    @objc var placeholderAttributedString: NSAttributedString?

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            onFocusChanged?(true)
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            onFocusChanged?(false)
        }
        return result
    }
}
#endif
