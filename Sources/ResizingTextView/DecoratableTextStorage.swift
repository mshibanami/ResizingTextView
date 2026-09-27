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

    private struct ResolvedDecoration {
        var range: NSRange
        var attributes: [NSAttributedString.Key: Any]

        func isSame(as other: ResolvedDecoration) -> Bool {
            range == other.range
                && NSDictionary(dictionary: attributes).isEqual(to: other.attributes)
        }
    }

    var attributionMap = AttributionMap() {
        didSet {
            guard attributionMap != oldValue || hasCharacterEditsSinceResolution else {
                return
            }
            apply(attributionMap, replacing: oldValue)
        }
    }

#if canImport(AppKit)
    /// NSTextView lets users change attributes of rich text (e.g. from the Font menu),
    /// but the attributes must always be derived from `attributionMap`.
    private static let normalizesAttributeOnlyEdits = true
#else
    private static let normalizesAttributeOnlyEdits = false
#endif

    private let backing = NSMutableAttributedString()
    /// The decorations whose attributes are in `backing`, in the coordinates of the current string.
    /// Attributes outside an edited range move with the text and the edited range is normalized,
    /// so `backing` always equals the default attributes plus these decorations.
    private var appliedDecorations: [ResolvedDecoration] = []
    private var hasCharacterEditsSinceResolution = false
    private var isApplyingAttributionMap = false

    override var string: String {
        backing.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backing.attributes(at: location, effectiveRange: range)
    }

    /// The default implementation reads attribute runs through `attributes(at:effectiveRange:)`,
    /// which scans far beyond `range` when runs are fragmented by font fallback (e.g. CJK text).
    override func fixAttributes(in range: NSRange) {
        backing.fixAttributes(in: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    override func processEditing() {
        let needsNormalization = isApplyingAttributionMap
            || editedMask.contains(.editedCharacters)
            || (Self.normalizesAttributeOnlyEdits && editedMask.contains(.editedAttributes))
        if needsNormalization, editedRange.length > 0 {
            normalizeAttributes(in: editedRange)
        }
        super.processEditing()
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        let replacementLength = (str as NSString).length
        beginEditing()
        backing.replaceCharacters(in: range, with: str)
        let delta = replacementLength - range.length
        shiftDecorations(forReplacingCharactersIn: range, replacementLength: replacementLength)
        hasCharacterEditsSinceResolution = true
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: delta)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backing.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    private func apply(_ map: AttributionMap, replacing oldMap: AttributionMap) {
        let string = string
        let resolved = map.decorations.compactMap { decoration -> ResolvedDecoration? in
            guard decoration.range.isValid(in: string) else {
                return nil
            }
            return ResolvedDecoration(range: NSRange(decoration.range, in: string), attributes: decoration.attributes)
        }

        var dirtyIndexes = IndexSet()
        if map.defaultFont != oldMap.defaultFont || map.defaultForegroundColor != oldMap.defaultForegroundColor {
            dirtyIndexes.insert(integersIn: 0..<backing.length)
        } else {
            for index in 0..<max(resolved.count, appliedDecorations.count) {
                let new = resolved.indices.contains(index) ? resolved[index] : nil
                let old = appliedDecorations.indices.contains(index) ? appliedDecorations[index] : nil
                if let new, let old, new.isSame(as: old) {
                    continue
                }
                for range in [new?.range, old?.range].compactMap({ $0 }) {
                    dirtyIndexes.insert(integersIn: Range(range)!)
                }
            }
        }

        appliedDecorations = resolved
        hasCharacterEditsSinceResolution = false
        dirtyIndexes.remove(integersIn: backing.length..<Int.max)
        guard !dirtyIndexes.isEmpty else {
            return
        }

        isApplyingAttributionMap = true
        beginEditing()
        for range in dirtyIndexes.rangeView {
            edited(.editedAttributes, range: NSRange(range), changeInLength: 0)
        }
        endEditing()
        isApplyingAttributionMap = false
    }

    private func shiftDecorations(forReplacingCharactersIn range: NSRange, replacementLength: Int) {
        let delta = replacementLength - range.length
        let replacedEnd = range.upperBound
        func newStart(_ location: Int) -> Int {
            location < range.location ? location : location >= replacedEnd ? location + delta : range.location
        }
        func newEnd(_ location: Int) -> Int {
            location <= range.location ? location : location >= replacedEnd ? location + delta : range.location + replacementLength
        }

        for index in appliedDecorations.indices {
            let old = appliedDecorations[index].range
            let start = newStart(old.location)
            let end = max(start, newEnd(old.upperBound))
            appliedDecorations[index].range = NSRange(location: start, length: end - start)
        }
    }

    private func normalizeAttributes(in range: NSRange) {
        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[.font] = attributionMap.defaultFont
        attributes[.foregroundColor] = attributionMap.defaultForegroundColor
        backing.setAttributes(attributes, range: range)
        for decoration in appliedDecorations {
            let overlap = NSIntersectionRange(decoration.range, range)
            if overlap.length > 0 {
                backing.addAttributes(decoration.attributes, range: overlap)
            }
        }
    }
}
