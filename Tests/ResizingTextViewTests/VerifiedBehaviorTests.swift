import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
final class VerifiedBehaviorTests: XCTestCase {
    func testDecorationRangeFromNativeNonASCIIStringIsApplied() {
        let text = "日本語 #タグ"
        let range = text.range(of: "#タグ")!
        let storage = DecoratableTextStorage()
        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
        storage.attributionMap = .init(
            defaultFont: .systemFont(ofSize: 12),
            defaultForegroundColor: .black,
            decorations: [TextDecoration(range: range, attributes: [.kern: 5])]
        )
        let location = NSRange(range, in: text).location
        XCTAssertEqual(storage.attribute(.kern, at: location, effectiveRange: nil) as? Int, 5)
        XCTAssertNil(storage.attribute(.kern, at: location - 1, effectiveRange: nil))
    }

#if canImport(AppKit)
    func testPastedRichTextAttributesAreReplacedByDefaultAttributes() {
        let storage = DecoratableTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100), textContainer: container)
        textView.isRichText = true
        let font = NSFont.systemFont(ofSize: 12)
        storage.attributionMap = .init(defaultFont: font, defaultForegroundColor: .black, decorations: [])

        let pasteboard = NSPasteboard(name: .init("ResizingTextViewTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.writeObjects([NSAttributedString(string: "pasted", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 30),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])])
        XCTAssertTrue(textView.readSelection(from: pasteboard, type: .rtf))

        XCTAssertEqual(textView.string, "pasted")
        XCTAssertEqual(storage.attribute(.font, at: 0, effectiveRange: nil) as? NSFont, font)
        XCTAssertNil(storage.attribute(.underlineStyle, at: 0, effectiveRange: nil))
    }
#endif
}
