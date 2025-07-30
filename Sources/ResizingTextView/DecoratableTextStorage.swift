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
            if attributionMap != oldValue {
                needsFullReapplication = true
                let fullRange = string.utf16FullRange
                if fullRange.length > 0 {
                    beginEditing()
                    edited(.editedAttributes, range: fullRange, changeInLength: 0)
                    endEditing()
                }
            }
        }
    }
    
    private let backing = NSMutableAttributedString()
    private var appliedAttributionMap = AttributionMap()
    private var needsFullReapplication = false

    override var string: String {
        backing.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backing.attributes(at: location, effectiveRange: range)
    }

    override func processEditing() {
        let editedRange = self.editedRange
        
        if needsFullReapplication {
            applyDecorationsDirectly(over: string.utf16FullRange)
            needsFullReapplication = false
            appliedAttributionMap = attributionMap
        } else if editedMask.contains(.editedCharacters),
                  editedRange.length > 0 {
            applyDecorationsDirectly(over: editedRange)
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

    private func applyDecorationsDirectly(over range: NSRange) {
        backing.setAttributes([:], range: range)
        if let font = attributionMap.defaultFont {
            backing.addAttribute(.font, value: font, range: range)
        }
        if let color = attributionMap.defaultForegroundColor {
            backing.addAttribute(.foregroundColor, value: color, range: range)
        }
        for decoration in attributionMap.decorations {
            guard decoration.range.isValid(in: string) else { continue }
            
            let decoRange = NSRange(decoration.range, in: string)
            let overlap = NSIntersectionRange(decoRange, range)
            guard overlap.length > 0 else {
                continue
            }
            backing.addAttributes(decoration.attributes, range: overlap)
        }
    }
}

extension String {
    var utf16FullRange: NSRange {
        NSRange(location: 0, length: utf16.count)
    }
}
