//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit

@MainActor
final class TextBaselineMeasurer {
    struct Content: Equatable {
        var text: String
        var font: NSFont
        var decorations: [TextDecoration]
        var lineLimit: Int
    }

    private static let maxCachedWidthCount = 8

    private lazy var textStorage = DecoratableTextStorage()
    private lazy var textContainer = NSTextContainer()
    private lazy var measurer = TextMeasurer()
    private var laidOutContent: Content?
    private var linesByWidth: [CGFloat: [TextMeasurer.Line]] = [:]

    var content = Content(text: "", font: .preferredFont(forTextStyle: .body), decorations: [], lineLimit: .max)

    func lines(width: CGFloat) -> [TextMeasurer.Line] {
        if laidOutContent != content {
            update()
        }
        if let lines = linesByWidth[width] {
            return lines
        }
        if linesByWidth.count >= Self.maxCachedWidthCount {
            linesByWidth.removeAll()
        }
        let lines = measurer.lines(of: textStorage, width: width, like: textContainer, emptyLineFont: content.font)
        linesByWidth[width] = lines
        return lines
    }

    private func update() {
        replaceChangedCharacters(with: content.text)
        textStorage.attributionMap = .init(
            defaultFont: content.font,
            defaultForegroundColor: nil,
            decorations: content.decorations
        )
        textContainer.maximumNumberOfLines = content.lineLimit
        if content.lineLimit > 0 {
            textContainer.lineBreakMode = .byTruncatingTail
        }
        laidOutContent = content
        linesByWidth.removeAll()
    }

    private func replaceChangedCharacters(with text: String) {
        let old = Array(textStorage.string.utf16)
        let new = Array(text.utf16)
        let maxCommonLength = min(old.count, new.count)
        var prefix = 0
        while prefix < maxCommonLength, old[prefix] == new[prefix] {
            prefix += 1
        }
        var suffix = 0
        while suffix < maxCommonLength - prefix, old[old.count - 1 - suffix] == new[new.count - 1 - suffix] {
            suffix += 1
        }
        guard prefix + suffix < old.count || prefix + suffix < new.count else {
            return
        }
        if prefix > 0, UTF16.isLeadSurrogate(new[prefix - 1]) {
            prefix -= 1
        }
        if suffix > 0, UTF16.isTrailSurrogate(new[new.count - suffix]) {
            suffix -= 1
        }
        textStorage.replaceCharacters(
            in: NSRange(location: prefix, length: old.count - prefix - suffix),
            with: String(decoding: new[prefix..<(new.count - suffix)], as: UTF16.self)
        )
    }
}
#endif
