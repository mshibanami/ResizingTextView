import SwiftUI
import XCTest
@testable import ResizingTextView

private struct SwitchingHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.notes[m.selected]) }
}

private struct SubmitHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
        let target = m.target
        ResizingTextView(text: $m.text)
#if canImport(AppKit)
            .onInsertNewline { [m] in m.sent.append(target); return true }
#endif
    }
}

private struct InsetHost: View {
    @ObservedObject var m: TestModel
    var body: some View {
#if canImport(AppKit)
        ResizingTextView(text: $m.text).textContainerInset(m.flag ? CGSize(width: 10, height: 10) : CGSize(width: 40, height: 20))
#else
        ResizingTextView(text: $m.text).textContainerInset(m.flag ? UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) : UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40))
#endif
    }
}

#if canImport(UIKit)
private struct KeyboardHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.text).keyboardType(m.flag ? .default : .numberPad) }
}
#endif

@MainActor
final class ViewUpdateTests: XCTestCase {
    func testSwitchingToBindingWithEqualValueWritesIntoNewTarget() {
        let m = TestModel()
        m.notes = ["same", "same"]
        let h = Hosted(SwitchingHost(m: m))
        m.selected = 1
        spin()
        h.focus()
        h.type("X")
        XCTAssertEqual(m.notes[0], "same")
        XCTAssertTrue(m.notes[1].contains("X"), m.notes[1])
    }

    func testTextContainerInsetChangeIsApplied() {
        let m = TestModel()
        let h = Hosted(InsetHost(m: m))
        m.flag = false
        spin()
#if canImport(AppKit)
        XCTAssertEqual(h.textView.textContainerInset, CGSize(width: 40, height: 20))
#else
        XCTAssertEqual(h.textView.textContainerInset, UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40))
#endif
    }

#if canImport(AppKit)
    func testOnInsertNewlineChangeIsApplied() {
        let m = TestModel()
        let h = Hosted(SubmitHost(m: m))
        h.focus()
        spin(1)
        m.target = "B"
        spin()
        h.textView.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        spin()
        XCTAssertEqual(m.sent, ["B"])
    }
#endif

#if canImport(UIKit)
    func testKeyboardTypeChangeIsApplied() {
        let m = TestModel()
        let h = Hosted(KeyboardHost(m: m))
        h.focus()
        spin(1)
        m.flag = false
        spin()
        XCTAssertEqual(h.textView.keyboardType, .numberPad)
    }
#endif
}
