//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Lays out the text of a text view with its own layout manager, so that the size for any
/// proposed width can be measured without changing the layout of the text view itself.
@MainActor
final class TextMeasurer {
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer()
    private weak var textStorage: NSTextStorage?

    init() {
        layoutManager.addTextContainer(textContainer)
    }

    struct Line: Equatable {
        var baseline: CGFloat
        var maxY: CGFloat
    }

    /// Returns the size of the laid out text as the text view shows it: the empty line after a trailing
    /// newline is omitted when the line limit is reached, and empty text is one line of `emptyLineFont`.
    func size(of textStorage: NSTextStorage, width: CGFloat?, like container: NSTextContainer, emptyLineFont: UXFont) -> CGSize {
        layOut(textStorage, width: width, like: container)

        var size = layoutManager.usedRect(for: textContainer).size
        if textStorage.length == 0 {
            size.height = lineHeight(of: emptyLineFont)
        } else if !showsExtraLine(like: container) {
            size.height -= layoutManager.extraLineFragmentUsedRect.height
        }
        return size
    }

    func lines(of textStorage: NSTextStorage, width: CGFloat?, like container: NSTextContainer, emptyLineFont: UXFont) -> [Line] {
        layOut(textStorage, width: width, like: container)

        let emptyLineMetrics = LineMetrics.of(emptyLineFont)
        guard textStorage.length > 0 else {
            return [Line(baseline: emptyLineMetrics.baseline, maxY: emptyLineMetrics.height)]
        }
        var lines: [Line] = []
        layoutManager.enumerateLineFragments(forGlyphRange: layoutManager.glyphRange(for: textContainer)) { rect, usedRect, _, glyphRange, _ in
            lines.append(Line(
                baseline: rect.minY + self.layoutManager.location(forGlyphAt: glyphRange.location).y,
                maxY: usedRect.maxY
            ))
        }
        if showsExtraLine(like: container) {
            let extraLineRect = layoutManager.extraLineFragmentUsedRect
            lines.append(Line(baseline: extraLineRect.minY + emptyLineMetrics.baseline, maxY: extraLineRect.maxY))
        }
        return lines
    }

    private func layOut(_ textStorage: NSTextStorage, width: CGFloat?, like container: NSTextContainer) {
        if self.textStorage !== textStorage {
            self.textStorage?.removeLayoutManager(layoutManager)
            textStorage.addLayoutManager(layoutManager)
            self.textStorage = textStorage
        }
        textContainer.lineFragmentPadding = container.lineFragmentPadding
        textContainer.maximumNumberOfLines = container.maximumNumberOfLines
        textContainer.lineBreakMode = container.lineBreakMode
        textContainer.size = CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)
    }

    private func showsExtraLine(like container: NSTextContainer) -> Bool {
        layoutManager.extraLineFragmentUsedRect.height > 0
            && !(container.maximumNumberOfLines > 0 && numberOfLines() >= container.maximumNumberOfLines)
    }

    private func lineHeight(of font: UXFont) -> CGFloat {
        LineMetrics.of(font).height
    }

    private func numberOfLines() -> Int {
        var count = 0
        layoutManager.enumerateLineFragments(forGlyphRange: layoutManager.glyphRange(for: textContainer)) { _, _, _, _, _ in
            count += 1
        }
        return count
    }
}

struct LineMetrics: Equatable {
    var baseline: CGFloat
    var height: CGFloat

    @MainActor private static var cache: [UXFont: LineMetrics] = [:]

    @MainActor static func of(_ font: UXFont) -> LineMetrics {
        if let metrics = cache[font] {
            return metrics
        }
        let storage = NSTextStorage(string: " ", attributes: [.font: font])
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        layoutManager.ensureLayout(for: container)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: 0, effectiveRange: nil)
        let metrics = LineMetrics(
            baseline: lineRect.minY + layoutManager.location(forGlyphAt: 0).y,
            height: layoutManager.usedRect(for: container).height
        )
        cache[font] = metrics
        return metrics
    }
}
