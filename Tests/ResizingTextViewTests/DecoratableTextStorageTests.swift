import SwiftUI
import XCTest
@testable import ResizingTextView

private struct ThirdCharacterHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
        ResizingTextView(text: $m.text).decorations(Self.thirdCharacter(of: m.text))
    }

    static func thirdCharacter(of text: String) -> [TextDecoration] {
        guard text.count > 2 else {
            return []
        }
        let start = text.index(text.startIndex, offsetBy: 2)
        return [TextDecoration(range: start..<text.index(after: start), in: text, attributes: [.font: boldFont])]
    }
}

@MainActor private let regularFont = UXFont.systemFont(ofSize: 12)
@MainActor private let boldFont = UXFont.boldSystemFont(ofSize: 20)

@MainActor
final class DecoratableTextStorageTests: XCTestCase {
    func testAttributeLookupsAgreeWithTheAttributesOfEachCharacter() {
        let storage = DecoratableTextStorage()
        let text = "abc 日本語 😀 def\nghi"
        storage.replaceCharacters(in: NSRange(), with: text)
        storage.attributionMap = .init(defaultFont: regularFont, defaultForegroundColor: .black, decorations: [
            TextDecoration(range: NSRange(location: 1, length: 3), attributes: [.font: boldFont]),
            TextDecoration(range: NSRange(location: 2, length: 6), attributes: [.underlineStyle: 1]),
        ])
        let whole = NSRange(location: 0, length: storage.length)
        for location in 0..<storage.length {
            var range = NSRange()
            let attributes = storage.attributes(at: location, effectiveRange: &range)
            for key in [NSAttributedString.Key.font, .foregroundColor, .underlineStyle] {
                var attributeRange = NSRange()
                XCTAssertEqual(storage.attribute(key, at: location, effectiveRange: &attributeRange) as? NSObject, attributes[key] as? NSObject)
                XCTAssertTrue(NSLocationInRange(location, attributeRange))
                var longestRange = NSRange()
                XCTAssertEqual(storage.attribute(key, at: location, longestEffectiveRange: &longestRange, in: whole) as? NSObject, attributes[key] as? NSObject)
                XCTAssertTrue(NSLocationInRange(location, longestRange))
            }
            var longestRange = NSRange()
            XCTAssertEqual(NSDictionary(dictionary: storage.attributes(at: location, longestEffectiveRange: &longestRange, in: whole)), NSDictionary(dictionary: attributes))
            XCTAssertTrue(NSLocationInRange(location, longestRange))
        }
    }

    private func font(_ storage: NSTextStorage, _ location: Int) -> UXFont? {
        storage.attribute(.font, at: location, effectiveRange: nil) as? UXFont
    }

    private func map(_ string: String) -> DecoratableTextStorage.AttributionMap {
        .init(defaultFont: regularFont, defaultForegroundColor: .black, decorations: ThirdCharacterHost.thirdCharacter(of: string))
    }

    private func makeStorage(_ string: String) -> DecoratableTextStorage {
        let storage = DecoratableTextStorage()
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
        storage.attributionMap = map(storage.string)
        return storage
    }

    func testDecorationIsReappliedAfterInsertionBeforeIt() {
        let storage = makeStorage("The 3rd")
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "A")
        storage.attributionMap = map(storage.string)
        XCTAssertEqual(font(storage, 2), boldFont)
        XCTAssertEqual(font(storage, 3), regularFont)
    }

    func testDecorationIsReappliedAfterDeletionBeforeIt() {
        let storage = makeStorage("The 3rd")
        storage.replaceCharacters(in: NSRange(location: 0, length: 1), with: "")
        storage.attributionMap = map(storage.string)
        XCTAssertEqual(font(storage, 1), regularFont)
        XCTAssertEqual(font(storage, 2), boldFont)
    }

    func testDecorationIsKeptWhenNothingChanges() {
        let storage = makeStorage("The 3rd")
        storage.attributionMap = map(storage.string)
        XCTAssertEqual(font(storage, 2), boldFont)
        XCTAssertEqual(font(storage, 1), regularFont)
    }

    func testTypingBeforeFixedPositionDecorationInTextView() {
        let m = TestModel()
        m.text = "The 3rd"
        let h = Hosted(ThirdCharacterHost(m: m))
        h.focus()
#if canImport(AppKit)
        h.textView.setSelectedRange(NSRange(location: 0, length: 0))
#else
        h.textView.selectedRange = NSRange(location: 0, length: 0)
#endif
        h.type("A")
        XCTAssertEqual(m.text, "AThe 3rd")
#if canImport(AppKit)
        let storage = h.textView.textStorage!
#else
        let storage = h.textView.textStorage
#endif
        XCTAssertEqual(font(storage, 2), boldFont)
        XCTAssertNotEqual(font(storage, 3), boldFont)
    }
}
