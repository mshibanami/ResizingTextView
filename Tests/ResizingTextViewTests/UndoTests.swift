import SwiftUI
import XCTest
@testable import ResizingTextView

private struct SingleLineHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text, canHaveNewLineCharacters: false) }
}

private struct MultiLineHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text) }
}

@MainActor
final class UndoTests: XCTestCase {
    func testUndoAfterExternalReplacementKeepsViewAndBindingInSync() {
        let m = TestModel()
        let h = Hosted(MultiLineHost(m: m))
        h.focus()
        h.type("hello world")
        m.text = ""
        spin()
        XCTAssertEqual(h.text, "")
        h.textView.undoManager?.undo()
        spin()
        XCTAssertEqual(h.text, m.text)
    }

    func testUndoAfterRejectedNewlineInSingleLineField() {
        let m = TestModel()
        let h = Hosted(SingleLineHost(m: m))
        h.focus()
        h.type("abc")
        h.type("\n")
        XCTAssertEqual(m.text, "abc")
        h.textView.undoManager?.undo()
        spin()
        XCTAssertEqual(h.text, m.text)
    }

    func testUndoAfterPastingNewlinesIntoSingleLineField() {
        let m = TestModel()
        let h = Hosted(SingleLineHost(m: m))
        h.focus()
        h.type("abc")
#if canImport(AppKit)
        h.textView.breakUndoCoalescing()
#endif
        h.type("x\ny")
        XCTAssertEqual(m.text, "abcxy")
        h.textView.undoManager?.undo()
        spin()
        XCTAssertEqual(h.text, "abc")
        XCTAssertEqual(m.text, "abc")
    }
}
