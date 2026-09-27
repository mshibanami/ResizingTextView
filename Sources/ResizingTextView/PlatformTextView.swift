//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import SwiftUI

/// The operations on NSTextView/UITextView that the shared editing logic needs.
@MainActor
protocol PlatformTextView: AnyObject {
    var currentText: String { get }
    var selectedTextRanges: [NSRange] { get set }
    var typingAttributes: [NSAttributedString.Key: Any] { get set }
    /// Replaces the whole text without registering undo, and discards the undo actions that
    /// refer to the previous text.
    func replaceAllTextDiscardingUndo(with text: String)
    /// Inserts text through the regular input path so that it is registered for undo.
    func insertTextAsTyped(_ text: String, replacing range: NSRange)
}

@MainActor
struct TextEditingRules {
    var canHaveNewLineCharacters: Bool
    var font: UXFont
    var foregroundColor: UXColor

    func resetTypingAttributes(of textView: some PlatformTextView) {
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: foregroundColor,
        ]
    }

    /// Returns whether the text view may apply the change as proposed.
    func shouldChangeText(of textView: some PlatformTextView, in range: NSRange, replacementText: String) -> Bool {
        if !canHaveNewLineCharacters, replacementText.containsNewlines {
            let sanitized = replacementText.removingNewlines
            if !sanitized.isEmpty {
                resetTypingAttributes(of: textView)
                textView.insertTextAsTyped(sanitized, replacing: range)
            }
            return false
        }
        if !replacementText.isEmpty {
            resetTypingAttributes(of: textView)
        }
        return true
    }

    func textDidChange(in textView: some PlatformTextView, binding: Binding<String>) {
        if !canHaveNewLineCharacters, textView.currentText.containsNewlines {
            Self.removeNewlines(from: textView)
        }
        let text = textView.currentText
        if binding.wrappedValue != text {
            binding.wrappedValue = text
        }
    }

    static func applyExternalText(_ text: String, to textView: some PlatformTextView) {
        guard textView.currentText != text else {
            return
        }
        let length = (text as NSString).length
        let selectedRanges = textView.selectedTextRanges
        textView.replaceAllTextDiscardingUndo(with: text)
        textView.selectedTextRanges = selectedRanges.map { $0.clamped(toLength: length) }
    }

    private static func removeNewlines(from textView: some PlatformTextView) {
        let text = textView.currentText
        var removedOffsets: [Int] = []
        var offset = 0
        for character in text {
            let length = character.utf16.count
            if character.isNewline {
                removedOffsets.append(contentsOf: offset..<(offset + length))
            }
            offset += length
        }
        func newLocation(_ location: Int) -> Int {
            location - removedOffsets.prefix { $0 < location }.count
        }
        let selectedRanges = textView.selectedTextRanges.map { range in
            let start = newLocation(range.location)
            return NSRange(location: start, length: newLocation(range.upperBound) - start)
        }
        textView.replaceAllTextDiscardingUndo(with: text.removingNewlines)
        textView.selectedTextRanges = selectedRanges
    }
}

#if canImport(AppKit)
extension NSTextView: PlatformTextView {
    var currentText: String {
        string
    }

    var selectedTextRanges: [NSRange] {
        get { selectedRanges.map(\.rangeValue) }
        set { selectedRanges = newValue.isEmpty ? [NSValue(range: NSRange())] : newValue.map { NSValue(range: $0) } }
    }

    func replaceAllTextDiscardingUndo(with text: String) {
        string = text
        if let textStorage {
            undoManager?.removeAllActions(withTarget: textStorage)
        }
    }

    func insertTextAsTyped(_ text: String, replacing range: NSRange) {
        insertText(text, replacementRange: range)
    }
}
#elseif canImport(UIKit)
extension UITextView: PlatformTextView {
    var currentText: String {
        text ?? ""
    }

    var selectedTextRanges: [NSRange] {
        get { [selectedRange] }
        set { selectedRange = newValue.first ?? NSRange() }
    }

    func replaceAllTextDiscardingUndo(with text: String) {
        self.text = text
        undoManager?.removeAllActions()
    }

    func insertTextAsTyped(_ text: String, replacing range: NSRange) {
        selectedRange = range
        insertText(text)
    }
}
#endif
