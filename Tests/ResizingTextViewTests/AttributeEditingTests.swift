#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

private struct DecoratedHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
        ResizingTextView(text: $m.text).decorations(m.text.count > 1 ? [
            TextDecoration(range: NSRange(location: 0, length: 1), attributes: [.foregroundColor: NSColor.red])
        ] : [])
    }
}

@MainActor
final class AttributeEditingTests: XCTestCase {
    func testFontMenuFormattingIsNotKept() {
        let m = TestModel()
        m.text = "hello"
        let h = Hosted(DecoratedHost(m: m))
        h.focus()
        h.textView.setSelectedRange(NSRange(location: 0, length: 5))
        h.textView.underline(nil)
        spin()
        let storage = h.textView.textStorage!
        XCTAssertNil(storage.attribute(.underlineStyle, at: 0, effectiveRange: nil))
        XCTAssertNil(storage.attribute(.underlineStyle, at: 4, effectiveRange: nil))
        XCTAssertEqual(storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor, .red)
        XCTAssertNotEqual(storage.attribute(.foregroundColor, at: 1, effectiveRange: nil) as? NSColor, .red)
    }

    func testMarkedTextCompositionStillWorks() {
        let m = TestModel()
        let h = Hosted(DecoratedHost(m: m))
        h.focus()
        h.textView.setMarkedText("にほん", selectedRange: NSRange(location: 3, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
        spin()
        XCTAssertTrue(h.textView.hasMarkedText())
        XCTAssertEqual(h.text, "にほん")
        h.textView.insertText("日本", replacementRange: h.textView.markedRange())
        spin()
        XCTAssertFalse(h.textView.hasMarkedText())
        XCTAssertEqual(h.text, "日本")
        XCTAssertEqual(m.text, "日本")
    }

    func testChangingFontAttributesIsNotKept() {
        let m = TestModel()
        m.text = "hello"
        let h = Hosted(DecoratedHost(m: m))
        h.focus()
        let fontBefore = h.textView.textStorage!.attribute(.font, at: 2, effectiveRange: nil) as? NSFont
        h.textView.setSelectedRange(NSRange(location: 0, length: 5))
        h.textView.textStorage!.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 30), range: NSRange(location: 0, length: 5))
        spin()
        XCTAssertEqual(h.textView.textStorage!.attribute(.font, at: 2, effectiveRange: nil) as? NSFont, fontBefore)
    }
}
#endif
