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
        textContainer.widthTracksTextView = true
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        let textView = CustomTextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.textStorage?.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        resetTypingAttributes(of: textView)
        textView.onFocusChanged = { [weak textView] isFocused in
            if isFocused {
                if text.isEmpty {
                    // HACK: A workaround for the bug that the cursor is
                    // not shown when focusing an empty TextView.
                    textView?.setSelectedRange(.init())
                }
            } else {
                // Don't keep the selection
                Task.detached { [weak textView] in
                    await textView?.setSelectedRange(.init())
                }
            }
            onFocusChanged?(isFocused)
        }

        let scrollView = TextEnclosingScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        
        context.coordinator.nsView = textView

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
                    .font: font,
                ]
            )
        } else {
            textView.placeholderAttributedString = nil
        }
        
        if textView.string != text {
            textView.string = text
        }
        
        let nsForegroundColor = NSColor(foregroundColor)
        if let textStorage = textView.textStorage as? DecoratableTextStorage {
            textStorage.attributionMap = .init(
                defaultFont: font,
                defaultForegroundColor: nsForegroundColor,
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
        
        if !context.coordinator.selectedRanges.isEmpty,
           textView.selectedRanges != context.coordinator.selectedRanges {
            textView.selectedRanges = context.coordinator.selectedRanges
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(swiftUIView: self)
    }
    
    func resetTypingAttributes(of textView: NSTextView) {
        var newTypingAttributes = textView.typingAttributes
        newTypingAttributes[.font] = font
        newTypingAttributes[.foregroundColor] = NSColor(foregroundColor)
        textView.typingAttributes = newTypingAttributes
    }

    final class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        fileprivate var swiftUIView: TextView
        fileprivate weak var nsView: CustomTextView?
        fileprivate var selectedRanges = [NSValue]()

        init(swiftUIView: TextView) {
            self.swiftUIView = swiftUIView
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
            if replacementString == "\n", !swiftUIView.canHaveNewLineCharacters {
                return false
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
        
        func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
            // The `textDidChange()` delegate method is not called when the view is not focused AND the text is changed by undo/redo.
            // This code is a fallback for when it happens.
            Task { [weak self] in
                guard let self,
                      let nsView,
                      let window = await nsView.window,
                      let firstResponder = await window.firstResponder,
                      nsView != firstResponder else {
                    return
                }
                await updateTextView()
            }
        }
        
        @MainActor private func updateTextView() {
            guard let nsView else {
                return
            }
            if !swiftUIView.canHaveNewLineCharacters,
               nsView.string.contains("\n") {
                nsView.string.removeAll(where: { $0 == "\n" })
            }
            let newString = nsView.string
            if swiftUIView.text != newString {
                swiftUIView.text = newString
                swiftUIView.resetTypingAttributes(of: nsView)
            }
            let newRanges = nsView.selectedRanges
            if selectedRanges != newRanges {
                selectedRanges = newRanges
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
#endif
