//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit

@MainActor
final class TextViewMeasurer {
    private static let maxCachedWidthCount = 8

    private lazy var measurer = TextMeasurer()
    private weak var textView: NSTextView?
    private var emptyLineFont: NSFont?
    private var linesByWidth: [CGFloat: [TextMeasurer.Line]] = [:]
    private var observation: NSObjectProtocol?

    func attach(to textView: NSTextView) {
        guard self.textView !== textView else {
            return
        }
        self.textView = textView
        if let observation {
            NotificationCenter.default.removeObserver(observation)
        }
        observation = NotificationCenter.default.addObserver(
            forName: NSTextStorage.didProcessEditingNotification,
            object: textView.textStorage,
            queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.textDidChange()
            }
        }
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
        linesByWidth.removeAll()
    }

    private func textDidChange() {
        invalidate()
        textView?.enclosingScrollView?.invalidateIntrinsicContentSize()
    }

    func size(width: CGFloat?) -> CGSize? {
        guard let textView, let textStorage = textView.textStorage, let textContainer = textView.textContainer, let emptyLineFont else {
            return nil
        }
        return measurer.size(of: textStorage, width: width, like: textContainer, emptyLineFont: emptyLineFont)
    }

    func lines(width: CGFloat) -> [TextMeasurer.Line]? {
        if let lines = linesByWidth[width] {
            return lines
        }
        guard let textView, let textStorage = textView.textStorage, let textContainer = textView.textContainer, let emptyLineFont else {
            return nil
        }
        if linesByWidth.count >= Self.maxCachedWidthCount {
            linesByWidth.removeAll()
        }
        let lines = measurer.lines(of: textStorage, width: width, like: textContainer, emptyLineFont: emptyLineFont)
        linesByWidth[width] = lines
        return lines
    }
}
#endif
