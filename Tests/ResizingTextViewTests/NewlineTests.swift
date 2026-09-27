import SwiftUI
import XCTest
@testable import ResizingTextView

private struct SingleLineHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text, canHaveNewLineCharacters: false) }
}

@MainActor
final class NewlineTests: XCTestCase {
    func testLineBreakVariantsAreRemovedInSingleLineField() {
        for newline in ["\n", "\r\n", "\r", "\u{2028}", "\u{2029}", "\u{85}"] {
            let m = TestModel()
            let h = Hosted(SingleLineHost(m: m))
            h.focus()
            h.type("a\(newline)b")
            XCTAssertEqual(m.text, "ab", newline.debugDescription)
            XCTAssertEqual(h.text, "ab", newline.debugDescription)
        }
    }

    func testNewlineOnlyInputIsRejected() {
        let m = TestModel()
        let h = Hosted(SingleLineHost(m: m))
        h.focus()
        h.type("a")
        h.type("\r\n")
        XCTAssertEqual(m.text, "a")
    }

#if canImport(AppKit)
    func testLineBreakCommandsDoNotInsertLineBreaks() {
        let selectors = [
            #selector(NSResponder.insertLineBreak(_:)),
            #selector(NSResponder.insertParagraphSeparator(_:)),
            #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)),
        ]
        for selector in selectors {
            let m = TestModel()
            let h = Hosted(SingleLineHost(m: m))
            h.focus()
            h.type("a")
            h.textView.doCommand(by: selector)
            spin()
            h.type("b")
            XCTAssertEqual(m.text, "ab", NSStringFromSelector(selector))
        }
    }
#endif

    func testNewlineHelpers() {
        XCTAssertTrue("a\r\nb".containsNewlines)
        XCTAssertEqual("a\r\nb\u{2028}c".removingNewlines, "abc")
        XCTAssertFalse("abc".containsNewlines)
    }
}
