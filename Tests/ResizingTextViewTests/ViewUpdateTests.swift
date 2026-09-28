import SwiftUI
import XCTest
@testable import ResizingTextView

private struct SwitchingHost: View {
    @ObservedObject var m: TestModel
    var body: some View { ResizingTextView(text: $m.notes[m.selected]).id(m.selected) }
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

private struct LayoutChangingHost: View {
    enum Change {
        case lineLimit
        case font
    }

    @ObservedObject var m: TestModel
    let text: String
    let change: Change
    var body: some View {
        let isChanged = !m.flag
        let lineLimit = change == .lineLimit && !isChanged ? 1 : nil
        VStack(spacing: 0) {
            ResizingTextView(text: .constant(text), isEditable: false, lineLimit: lineLimit)
                .font(.systemFont(ofSize: change == .font && isChanged ? 30 : 13))
            Spacer(minLength: 0)
        }
        .frame(width: 200)
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
    func testSwitchingIdentifiedBindingWithEqualValueWritesIntoNewTarget() {
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

    func testLineLimitChangeResizesTheView() {
        assertViewGrows(text: "a\nb\nc", when: .lineLimit)
    }

    func testFontChangeResizesTheViewWithEmptyText() {
        assertViewGrows(text: "", when: .font)
    }

    private func assertViewGrows(
        text: String,
        when change: LayoutChangingHost.Change,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let m = TestModel()
        let h = Hosted(LayoutChangingHost(m: m, text: text, change: change))
#if canImport(AppKit)
        let view: NSView = h.textView.enclosingScrollView!
#else
        let view: UIView = h.textView
#endif
        let heightBefore = view.frame.height
        m.flag = false
        spin()
        XCTAssertGreaterThan(view.frame.height, heightBefore * 2, file: file, line: line)
#if canImport(AppKit)
        h.close()
#endif
    }

#if canImport(UIKit)
    func testKeyboardTypeChangeIsApplied() {
        let m = TestModel()
        let h = Hosted(KeyboardHost(m: m))
        m.flag = false
        spin()
        XCTAssertEqual(h.textView.keyboardType, .numberPad)
    }
#endif
}
