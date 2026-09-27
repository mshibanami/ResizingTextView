//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import SwiftUI

@MainActor struct TextView: NSViewRepresentable {
    static let defaultForegroundColor = Color(NSColor.textColor)

    @Binding var text: String
    var decorations: [TextDecoration]
    var placeholder: String?
    var isEditable: Bool
    var isScrollable: Bool
    var isSelectable: Bool
    var lineLimit: Int
    var font: NSFont
    var canHaveNewLineCharacters: Bool
    var focusesNextKeyViewByTabKey: Bool
    var foregroundColor: Color
    var onFocusChanged: ((Bool) -> Void)?
    var onInsertNewline: (() -> Bool)?
    var textContainerInset: CGSize

    init(
        _ text: Binding<String>,
        decorations: [TextDecoration],
        placeholder: String?,
        isEditable: Bool,
        isScrollable: Bool,
        isSelectable: Bool,
        lineLimit: Int,
        font: NSFont,
        canHaveNewLineCharacters: Bool,
        focusesNextKeyViewByTabKey: Bool,
        foregroundColor: Color?,
        onFocusChanged: ((Bool) -> Void)?,
        onInsertNewline: (() -> Bool)?,
        textContainerInset: CGSize
    ) {
        self._text = text
        self.decorations = decorations
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.isScrollable = isScrollable
        self.isSelectable = isSelectable
        self.lineLimit = lineLimit
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
        self.focusesNextKeyViewByTabKey = focusesNextKeyViewByTabKey
        self.foregroundColor = foregroundColor ?? Self.defaultForegroundColor
        self.font = font
        self.onFocusChanged = onFocusChanged
        self.onInsertNewline = onInsertNewline
        self.textContainerInset = textContainerInset
    }

    func makeNSView(context: Context) -> TextEnclosingScrollView {
        let textStorage = DecoratableTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        textContainer.containerSize = .greatestFiniteMagnitude
        textContainer.widthTracksTextView = true
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        let textView = CustomTextView(frame: .zero, textContainer: textContainer)
        textView.minSize = .zero
        textView.maxSize = .greatestFiniteMagnitude
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        resetTypingAttributes(of: textView)
        textView.onFocusChanged = { [weak textView, weak coordinator = context.coordinator] isFocused in
            guard let parent = coordinator?.swiftUIView else {
                return
            }
            if isFocused {
                if parent.text.isEmpty {
                    // HACK: A workaround for the bug that the cursor is
                    // not shown when focusing an empty TextView.
                    textView?.setSelectedRange(.init())
                }
            } else {
                // Don't keep the selection
                Task { @MainActor [weak textView] in
                    guard let textView,
                          textView.window?.firstResponder !== textView else {
                        return
                    }
                    textView.setSelectedRange(.init())
                }
            }
            parent.onFocusChanged?(isFocused)
        }

        let scrollView = TextEnclosingScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = isScrollable
        
        context.coordinator.nsView = textView

        return scrollView
    }

    func updateNSView(_ view: TextEnclosingScrollView, context: Context) {
        context.coordinator.swiftUIView = self

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
                    .font: font,
                ]
            )
        } else {
            textView.placeholderAttributedString = nil
        }
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.replaceStringDiscardingUndo(text)
            let length = (text as NSString).length
            textView.selectedRanges = selectedRanges.map {
                NSValue(range: $0.rangeValue.clamped(toLength: length))
            }
        }
        
        if let textStorage = textView.textStorage as? DecoratableTextStorage {
            textStorage.attributionMap = .init(
                defaultFont: font,
                defaultForegroundColor: NSColor(foregroundColor),
                decorations: decorations
            )
        }
        let newBackgroundColor: NSColor = isEditable ? .textBackgroundColor : .clear
        if textView.backgroundColor != newBackgroundColor {
            textView.backgroundColor = newBackgroundColor
        }
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }
        if textView.isSelectable != isSelectable {
            textView.isSelectable = isSelectable
        }
        if textView.textContainerInset != textContainerInset {
            textView.textContainerInset = textContainerInset
        }
        if textView.textContainer?.maximumNumberOfLines != lineLimit {
            textView.textContainer?.maximumNumberOfLines = lineLimit
        }
        if lineLimit > 0 {
            if textView.textContainer?.lineBreakMode != .byTruncatingTail {
                textView.textContainer?.lineBreakMode = .byTruncatingTail
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(swiftUIView: self)
    }
    
    func resetTypingAttributes(of textView: NSTextView) {
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: UXColor(foregroundColor),
        ]
    }

    @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
        fileprivate var swiftUIView: TextView
        fileprivate weak var nsView: CustomTextView?
        private var undoObservers: [NSObjectProtocol] = []

        init(swiftUIView: TextView) {
            self.swiftUIView = swiftUIView
            super.init()
            // `textDidChange(_:)` is not guaranteed to be called when undo/redo changes
            // a text view that is not the first responder.
            undoObservers = [NSNotification.Name.NSUndoManagerDidUndoChange, .NSUndoManagerDidRedoChange].map {
                NotificationCenter.default.addObserver(forName: $0, object: nil, queue: .main) { [weak self] notification in
                    MainActor.assumeIsolated {
                        guard let self,
                              let undoManager = notification.object as? UndoManager,
                              self.nsView?.undoManager === undoManager else {
                            return
                        }
                        self.updateTextView()
                    }
                }
            }
        }

        deinit {
            undoObservers.forEach(NotificationCenter.default.removeObserver)
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertTab(_:)):
                guard swiftUIView.focusesNextKeyViewByTabKey else {
                    return false
                }
                textView.window?.selectNextKeyView(nil)
                return true
            case #selector(NSResponder.insertBacktab(_:)):
                guard swiftUIView.focusesNextKeyViewByTabKey else {
                    return false
                }
                textView.window?.selectPreviousKeyView(nil)
                return true
            case #selector(NSResponder.insertNewline(_:)):
                return swiftUIView.onInsertNewline?() ?? false
            default:
                return false
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            if let replacementString,
               !swiftUIView.canHaveNewLineCharacters,
               replacementString.containsNewlines {
                let sanitized = replacementString.removingNewlines
                if !sanitized.isEmpty {
                    textView.insertText(sanitized, replacementRange: affectedCharRange)
                }
                return false
            }
            if let _ = replacementString, replacementString != "" {
                swiftUIView.resetTypingAttributes(of: textView)
            }
            return true
        }
        
        func textDidChange(_ notification: Notification) {
            guard let nsView,
                  (notification.object as? CustomTextView) == nsView else {
                return
            }
            updateTextView()
        }
        
        private func updateTextView() {
            guard let nsView else {
                return
            }
            if !swiftUIView.canHaveNewLineCharacters,
               nsView.string.containsNewlines {
                nsView.replaceStringDiscardingUndo(nsView.string.removingNewlines)
            }
            let newString = nsView.string
            if swiftUIView.text != newString {
                swiftUIView.text = newString
            }
        }
    }
}

class TextEnclosingScrollView: NSScrollView {
    var isScrollable = true

    init() {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
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

@MainActor
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

private extension NSTextView {
    func replaceStringDiscardingUndo(_ newString: String) {
        string = newString
        if let textStorage {
            undoManager?.removeAllActions(withTarget: textStorage)
        }
    }
}

extension NSSize {
    static let greatestFiniteMagnitude = NSSize(
        width: CGFloat.greatestFiniteMagnitude,
        height: CGFloat.greatestFiniteMagnitude
    )
}
#endif
