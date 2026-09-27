import XCTest
@testable import ResizingTextView

@MainActor
final class FontFallbackTests: XCTestCase {
    func testFontFallbackMatchesPlainTextStorage() {
        let font = UXFont.systemFont(ofSize: 12)
        let plain = NSTextStorage(string: "abc\n", attributes: [.font: font])
        let decoratable = DecoratableTextStorage()
        decoratable.replaceCharacters(in: NSRange(location: 0, length: 0), with: "abc\n")
        decoratable.attributionMap = .init(defaultFont: font, defaultForegroundColor: nil, decorations: [])
        for (location, text) in [(1, "日本語"), (0, "😀"), (6, "한국어 x")] {
            plain.replaceCharacters(in: NSRange(location: location, length: 0), with: NSAttributedString(string: text, attributes: [.font: font]))
            decoratable.replaceCharacters(in: NSRange(location: location, length: 0), with: text)
        }
        XCTAssertEqual(decoratable.string, plain.string)
        for location in 0..<plain.length {
            let expected = plain.attribute(.font, at: location, effectiveRange: nil) as? UXFont
            let actual = decoratable.attribute(.font, at: location, effectiveRange: nil) as? UXFont
            XCTAssertEqual(actual?.fontName, expected?.fontName, "at \(location)")
        }
    }

    func testEditingLongCJKTextIsNotMuchSlowerThanPlainTextStorage() {
        let font = UXFont.systemFont(ofSize: 12)
        let text = String(repeating: "日本語\n", count: 10_000)
        let plain = NSTextStorage(string: text, attributes: [.font: font])
        let decoratable = DecoratableTextStorage()
        decoratable.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
        decoratable.attributionMap = .init(defaultFont: font, defaultForegroundColor: nil, decorations: [])

        func duration(_ storage: NSTextStorage) -> TimeInterval {
            let start = Date()
            for _ in 0..<20 {
                storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "x")
            }
            return Date().timeIntervalSince(start)
        }
        let plainDuration = duration(plain)
        let decoratableDuration = duration(decoratable)
        XCTAssertLessThan(decoratableDuration, max(plainDuration, 0.001) * 20, "plain: \(plainDuration), decoratable: \(decoratableDuration)")
    }
}
