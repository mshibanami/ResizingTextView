//  Copyright © 2025 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@MainActor
final class DecoratableTextStorage: NSTextStorage {
    struct AttributionMap: Equatable {
        var defaultFont: UXFont?
        var defaultForegroundColor: UXColor?
        var decorations: [TextDecoration] = []
    }
    
    var attributionMap = AttributionMap() {
        didSet {
            applyDecorations(over: string.utf16FullRange)
        }
    }
        
    private let backing = NSMutableAttributedString()
    private var appliedAttributionMap = AttributionMap()

    override var string: String {
        backing.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backing.attributes(at: location, effectiveRange: range)
    }

    override func processEditing() {
        let dirty = editedRange

        if let context = NSTextInputContext.current,
           context.client.markedRange().length > 0 {
            super.processEditing()
            return
        }

        if attributionMap != appliedAttributionMap {
            applyDecorations(over: string.utf16FullRange)
        } else if editedMask.contains(.editedCharacters),
                  dirty.length > 0 {
            applyDecorations(over: dirty)
        }

        super.processEditing()
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backing.replaceCharacters(in: range, with: str)
        let delta = (str as NSString).length - range.length
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: delta)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backing.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    private func applyDecorations(over range: NSRange) {
        beginEditing()
        backing.setAttributes([:], range: range)
        if let font = attributionMap.defaultFont {
            addAttribute(.font, value: font, range: range)
        }
        if let color = attributionMap.defaultForegroundColor {
            addAttribute(.foregroundColor, value: color, range: range)
        }
        for decoration in attributionMap.decorations where
            decoration.range.isValid(in: string) {
            let decoRange = NSRange(decoration.range, in: string)
            let overlap = NSIntersectionRange(decoRange, range)
            guard overlap.length > 0 else {
                continue
            }
            addAttributes(decoration.attributes, range: overlap)
        }
        appliedAttributionMap = attributionMap
        endEditing()
    }
}

extension String {
    var utf16FullRange: NSRange {
        NSRange(location: 0, length: utf16.count)
    }
}
