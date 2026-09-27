import SwiftUI
import XCTest
@testable import ResizingTextView

private struct SwitchingHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.notes[m.selected]) }
}

private struct NewlineFlagHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text, canHaveNewLineCharacters: m.allowNewlines) }
}

#if canImport(AppKit)
private struct SubmitHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
        let target = m.target
        // The placeholder changes together with the closure so that the view is re-rendered.
        ResizingTextView(text: $m.text, placeholder: target)
            .onInsertNewline { [m] in m.sent.append(target); return true }
    }
}

private struct TabHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text).focusesNextKeyViewByTabKey(m.flag) }
}
#endif

@MainActor
final class CoordinatorTests: XCTestCase {
    func testSwitchingBindingDoesNotWriteIntoPreviousTarget() {
        let m = TestModel()
        let h = Hosted(SwitchingHost(m: m))
        m.selected = 1
        spin()
        XCTAssertEqual(h.text, "second")
        XCTAssertEqual(m.notes, ["first", "second"])
    }

    func testTypingAfterSwitchingBindingWritesIntoNewTarget() {
        let m = TestModel()
        let h = Hosted(SwitchingHost(m: m))
        m.selected = 1
        spin()
        h.focus()
#if canImport(AppKit)
        h.textView.setSelectedRange(NSRange(location: 6, length: 0))
#else
        h.textView.selectedRange = NSRange(location: 6, length: 0)
#endif
        h.type("X")
        XCTAssertEqual(m.notes, ["first", "secondX"])
        XCTAssertEqual(h.text, "secondX")
    }

    func testEnablingNewLineCharactersTakesEffect() {
        let m = TestModel()
        m.allowNewlines = false
        let h = Hosted(NewlineFlagHost(m: m))
        m.allowNewlines = true
        spin()
        h.focus()
        h.type("a")
        h.type("\n")
        XCTAssertEqual(m.text, "a\n")
    }

    func testDisablingNewLineCharactersTakesEffect() {
        let m = TestModel()
        m.allowNewlines = true
        let h = Hosted(NewlineFlagHost(m: m))
        m.allowNewlines = false
        spin()
        h.focus()
        h.type("a")
        h.type("\n")
        XCTAssertEqual(m.text, "a")
    }

#if canImport(AppKit)
    func testOnInsertNewlineUsesLatestClosure() {
        let m = TestModel()
        let h = Hosted(SubmitHost(m: m))
        m.target = "B"
        spin()
        h.focus()
        h.textView.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        spin()
        XCTAssertEqual(m.sent, ["B"])
    }

    func testDisablingFocusesNextKeyViewByTabKeyTakesEffect() {
        let m = TestModel()
        m.flag = true
        let h = Hosted(TabHost(m: m))
        m.flag = false
        spin()
        h.focus()
        h.textView.doCommand(by: #selector(NSResponder.insertTab(_:)))
        spin()
        XCTAssertEqual(m.text, "\t")
    }
#endif
}
