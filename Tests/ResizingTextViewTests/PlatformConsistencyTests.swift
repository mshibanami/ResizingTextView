import SwiftUI
import XCTest
@testable import ResizingTextView

private struct NewlineFlagHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text, canHaveNewLineCharacters: m.allowNewlines) }
}

@MainActor
final class PlatformConsistencyTests: XCTestCase {
    func testUndoAfterNewlinesAreRemovedByDisallowingThem() {
        let m = TestModel()
        m.allowNewlines = true
        let h = Hosted(NewlineFlagHost(m: m))
        h.focus()
        h.type("a")
        h.type("\n")
        h.type("b")
        XCTAssertEqual(m.text, "a\nb")
        m.allowNewlines = false
        spin()
        h.type("c")
        XCTAssertEqual(m.text, "abc")
        XCTAssertEqual(h.text, "abc")
        h.textView.undoManager?.undo()
        spin()
        XCTAssertEqual(h.text, m.text)
    }

    func testSelectionIsKeptWhenNewlinesAreRemoved() {
        let m = TestModel()
        m.allowNewlines = true
        let h = Hosted(NewlineFlagHost(m: m))
        h.focus()
        h.type("a\nbcd")
        m.allowNewlines = false
        spin()
#if canImport(AppKit)
        h.textView.setSelectedRange(NSRange(location: 3, length: 0))
#else
        h.textView.selectedRange = NSRange(location: 3, length: 0)
#endif
        h.type("X")
        XCTAssertEqual(m.text, "abXcd")
#if canImport(AppKit)
        XCTAssertEqual(h.textView.selectedRange(), NSRange(location: 3, length: 0))
#else
        XCTAssertEqual(h.textView.selectedRange, NSRange(location: 3, length: 0))
#endif
    }
}
