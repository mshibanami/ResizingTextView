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

    /// Returns the size of the laid out text as the text view shows it: the empty line after a trailing
    /// newline is omitted when the line limit is reached, and empty text is one line of `emptyLineFont`.
    func size(of textStorage: NSTextStorage, width: CGFloat?, like container: NSTextContainer, emptyLineFont: UXFont) -> CGSize {
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

        var size = layoutManager.usedRect(for: textContainer).size
        let extraLineHeight = layoutManager.extraLineFragmentUsedRect.height
        if textStorage.length == 0 {
            size.height = lineHeight(of: emptyLineFont)
        } else if extraLineHeight > 0,
                  container.maximumNumberOfLines > 0,
                  numberOfLines() >= container.maximumNumberOfLines {
            size.height -= extraLineHeight
        }
        return size
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
