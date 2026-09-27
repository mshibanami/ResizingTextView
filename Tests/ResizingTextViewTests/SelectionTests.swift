import SwiftUI
import XCTest
@testable import ResizingTextView

private struct DecorationToggleHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
        ResizingTextView(text: $m.text)
            .decorations(m.flag || m.text.isEmpty ? [] : [
                TextDecoration(range: m.text.startIndex..<m.text.index(after: m.text.startIndex), attributes: [.kern: 1])
            ])
    }
}

#if canImport(AppKit)
private struct ActiveStateHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
        ResizingTextView(text: $m.text)
            .environment(\.controlActiveState, m.flag ? .key : .inactive)
    }
}
#endif

@MainActor
final class SelectionTests: XCTestCase {
    private func select<V>(_ range: NSRange, in h: Hosted<V>) {
#if canImport(AppKit)
        h.textView.setSelectedRange(range)
#else
        h.textView.selectedRange = range
#endif
        spin()
    }

    private func selection<V>(of h: Hosted<V>) -> NSRange {
#if canImport(AppKit)
        h.textView.selectedRange()
#else
        h.textView.selectedRange
#endif
    }

    func testCaretIsKeptOnUnrelatedUpdate() {
        let m = TestModel()
        let h = Hosted(DecorationToggleHost(m: m))
        h.focus()
        h.type("hello world")
        select(NSRange(location: 3, length: 0), in: h)
        m.flag.toggle()
        spin()
        XCTAssertEqual(selection(of: h), NSRange(location: 3, length: 0))
    }

    func testSelectedRangeIsKeptOnUnrelatedUpdate() {
        let m = TestModel()
        let h = Hosted(DecorationToggleHost(m: m))
        h.focus()
        h.type("hello world")
        select(NSRange(location: 0, length: 5), in: h)
        m.flag.toggle()
        spin()
        XCTAssertEqual(selection(of: h), NSRange(location: 0, length: 5))
    }

    func testCaretIsKeptWhenTextIsReplacedExternally() {
        let m = TestModel()
        let h = Hosted(DecorationToggleHost(m: m))
        h.focus()
        h.type("hello world")
        select(NSRange(location: 3, length: 0), in: h)
        m.text = "HELLO WORLD"
        spin()
        XCTAssertEqual(h.text, "HELLO WORLD")
        XCTAssertEqual(selection(of: h), NSRange(location: 3, length: 0))
    }

    func testSelectionIsClampedWhenTextIsShortenedExternally() {
        let m = TestModel()
        let h = Hosted(DecorationToggleHost(m: m))
        h.focus()
        h.type("hello world")
        select(NSRange(location: 6, length: 5), in: h)
        m.text = "hello"
        spin()
        XCTAssertEqual(selection(of: h), NSRange(location: 5, length: 0))
        m.text = ""
        spin()
        XCTAssertEqual(selection(of: h), NSRange(location: 0, length: 0))
    }

#if canImport(AppKit)
    func testCaretIsKeptWhenWindowBecomesInactive() {
        let m = TestModel()
        let h = Hosted(ActiveStateHost(m: m))
        h.focus()
        h.type("hello world")
        select(NSRange(location: 3, length: 0), in: h)
        m.flag = false
        spin()
        XCTAssertEqual(selection(of: h), NSRange(location: 3, length: 0))
    }
#endif
}
