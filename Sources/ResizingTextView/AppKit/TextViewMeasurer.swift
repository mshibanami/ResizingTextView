//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit

@MainActor
final class TextViewMeasurer: NSObject {
    private lazy var measurer = TextMeasurer()
    private weak var textView: NSTextView?
    private var emptyLineFont: NSFont?
    private var sizesByWidth = WidthCache<CGFloat?, CGSize>()
    private var linesByWidth = WidthCache<CGFloat, [TextMeasurer.Line]>()

    func attach(to textView: NSTextView) {
        guard self.textView !== textView else {
            return
        }
        self.textView = textView
        NotificationCenter.default.removeObserver(self, name: NSTextStorage.didProcessEditingNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storageDidProcessEditing),
            name: NSTextStorage.didProcessEditingNotification,
            object: textView.textStorage
        )
        invalidate()
    }

    func setEmptyLineFont(_ font: NSFont) {
        guard emptyLineFont != font else {
            return
        }
        emptyLineFont = font
        invalidate()
    }

    func invalidate() {
        sizesByWidth.removeAll()
        linesByWidth.removeAll()
    }

    func size(width: CGFloat?) -> CGSize? {
        let scrollerWidth = verticalScrollerWidth
        let width = width.map { max(0, $0 - scrollerWidth) }
        guard var size = sizesByWidth.value(for: width, make: {
            measure { measurer.size(of: $0, width: width, like: $1, emptyLineFont: $2) }
        }) else {
            return nil
        }
        size.width += scrollerWidth
        return size
    }

    func lines(width: CGFloat) -> [TextMeasurer.Line]? {
        let width = max(0, width - verticalScrollerWidth)
        return linesByWidth.value(for: width, make: {
            measure { measurer.lines(of: $0, width: width, like: $1, emptyLineFont: $2) }
        })
    }

    private func measure<Value>(_ body: (NSTextStorage, NSTextContainer, NSFont) -> Value) -> Value? {
        guard let textStorage = textView?.textStorage,
              let textContainer = textView?.textContainer,
              let emptyLineFont else {
            return nil
        }
        return body(textStorage, textContainer, emptyLineFont)
    }

    private var verticalScrollerWidth: CGFloat {
        guard let scrollView = textView?.enclosingScrollView else {
            return 0
        }
        return max(0, scrollView.frame.width - scrollView.contentSize.width)
    }

    @objc private func storageDidProcessEditing(_ notification: Notification) {
        invalidate()
        textView?.enclosingScrollView?.invalidateIntrinsicContentSize()
    }
}

private struct WidthCache<Width: Hashable, Value> {
    private static var maxCount: Int { 8 }

    private var values: [Width: Value] = [:]

    mutating func value(for width: Width, make: () -> Value?) -> Value? {
        if let value = values[width] {
            return value
        }
        guard let value = make() else {
            return nil
        }
        if values.count >= Self.maxCount {
            values.removeAll()
        }
        values[width] = value
        return value
    }

    mutating func removeAll() {
        values.removeAll()
    }
}
#endif
