#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

private struct TwoFieldsHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
        VStack {
            ResizingTextView(text: $m.notes[0])
            ResizingTextView(text: $m.notes[1])
        }
    }
}

private struct SingleLineHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text, canHaveNewLineCharacters: false) }
}

@MainActor
final class UnfocusedUndoTests: XCTestCase {
    private func textViews<V>(_ h: Hosted<V>) -> [NSTextView] {
        func collect(_ view: NSView) -> [NSTextView] {
            (view as? NSTextView).map { [$0] } ?? view.subviews.flatMap(collect)
        }
        return collect(h.hosting)
    }

    func testUndoInUnfocusedTextViewUpdatesBinding() {
        let m = TestModel()
        m.notes = ["", ""]
        let h = Hosted(TwoFieldsHost(m: m))
        let (first, second) = (textViews(h)[0], textViews(h)[1])
        XCTAssertTrue(h.window.makeFirstResponder(first))
        first.insertText("abc", replacementRange: NSRange(location: NSNotFound, length: 0))
        spin()
        XCTAssertEqual(m.notes, ["abc", ""])
        XCTAssertTrue(h.window.makeFirstResponder(second))
        spin()
        h.window.undoManager?.undo()
        spin()
        XCTAssertEqual(first.string, "")
        XCTAssertEqual(m.notes, ["", ""])
        h.window.undoManager?.redo()
        spin()
        XCTAssertEqual(m.notes, ["abc", ""])
    }

    func testExternalTextIsNotRewrittenRegardlessOfFocus() {
        for focused in [false, true] {
            let m = TestModel()
            let h = Hosted(SingleLineHost(m: m))
            if focused {
                h.focus()
            }
            m.text = "a\nb"
            spin()
            XCTAssertEqual(m.text, "a\nb", "focused: \(focused)")
            h.close()
        }
    }
}
#endif
