#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

private struct PlainHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text) }
}

@MainActor
final class FocusSelectionTests: XCTestCase {
    func testSelectionIsClearedAfterBlur() {
        let m = TestModel()
        let h = Hosted(PlainHost(m: m))
        h.focus()
        h.type("hello")
        h.textView.setSelectedRange(NSRange(location: 1, length: 3))
        h.blur()
        spin()
        XCTAssertEqual(h.textView.selectedRange(), NSRange(location: 0, length: 0))
    }

    func testSelectionIsKeptWhenRefocusedInSameRunLoopIteration() {
        let m = TestModel()
        let h = Hosted(PlainHost(m: m))
        h.focus()
        h.type("hello")
        h.window.makeFirstResponder(nil)
        XCTAssertTrue(h.window.makeFirstResponder(h.textView))
        h.textView.setSelectedRange(NSRange(location: 2, length: 0))
        spin()
        XCTAssertEqual(h.textView.selectedRange(), NSRange(location: 2, length: 0))
    }
}
#endif
