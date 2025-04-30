//  Copyright © 2025 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit

@MainActor
final class DecoratableTextStorage: NSTextStorage {
    struct AttributionMap: Equatable {
        var defaultFont: NSFont?
        var defaultForegroundColor: NSColor?
        var decorations: [TextDecoration] = []
    }
    
    var attributionMap = AttributionMap() {
        didSet { applyDecorationsIfNeeded() }
    }
        
    private let backing = NSMutableAttributedString()
    private var appliedAttributionMap = AttributionMap()

    override var string: String {
        backing.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backing.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backing.replaceCharacters(in: range, with: str)
        appliedAttributionMap = .init()
        edited([.editedCharacters, .editedAttributes],
               range: range,
               changeInLength: (str as NSString).length - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backing.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    private func applyDecorationsIfNeeded() {
        guard attributionMap != appliedAttributionMap else {
            return
        }
        beginEditing()
        for old in appliedAttributionMap.decorations where old.range.isValid(in: string) {
            let nsRange = NSRange(old.range, in: string)
            for key in old.attributes.keys {
                removeAttribute(key, range: nsRange)
            }
        }
        if let font = attributionMap.defaultFont {
            addAttribute(.font, value: font, range: NSRange(location: 0, length: string.utf16.count))
        }
        if let color = attributionMap.defaultForegroundColor {
            addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: string.utf16.count))
        }
        for new in attributionMap.decorations where new.range.isValid(in: string) {
            addAttributes(new.attributes, range: NSRange(new.range, in: string))
        }
        appliedAttributionMap = attributionMap
        endEditing()
    }
}

extension Range where Bound == String.Index {
    func isValid(in string: String) -> Bool {
        lowerBound >= string.startIndex && upperBound <= string.endIndex
    }
}
#endif
