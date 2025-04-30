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

    override func processEditing() {
        super.processEditing()
    }
    
    private func applyDecorationsIfNeeded() {
        guard attributionMap != appliedAttributionMap else {
            return
        }
        beginEditing()
        let fullRange = NSRange(location: 0, length: string.utf16.count)
        // Apply defaultFont
        if let defaultFont = attributionMap.defaultFont {
            addAttributes([.font: defaultFont], range: fullRange)
        }
        if let defaultForegroundColor = attributionMap.defaultForegroundColor {
            addAttributes([.foregroundColor: defaultForegroundColor], range: fullRange)
        }
        for old in appliedAttributionMap.decorations where old.range.isValid(in: string) {
            let ns = NSRange(old.range, in: string)
            for key in old.attributes.keys { removeAttribute(key, range: ns) }
        }
        for deco in attributionMap.decorations where deco.range.isValid(in: string) {
            addAttributes(deco.attributes, range: NSRange(deco.range, in: string))
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
