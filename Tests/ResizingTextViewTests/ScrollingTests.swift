#if canImport(UIKit) && !os(tvOS)
import SwiftUI
import UIKit
import XCTest
@testable import ResizingTextView

@MainActor
final class ScrollingTests: XCTestCase {
    func testFittingLabelsHaveNoScrollRange() {
        for greedy in [true, false] {
            for inset: UIEdgeInsets? in [nil, UIEdgeInsets(top: 0.2, left: 0.2, bottom: 0.2, right: 0.2)] {
                for text in ["", "hello", "hello\nworld", "hello\n", String(repeating: "日本語の文章", count: 8)] {
                    let host = Hosted(VStack {
                        ResizingTextView(text: .constant(text), isEditable: false, hasGreedyWidth: greedy)
                            .textContainerInset(inset)
                        Spacer()
                    }.frame(width: 200))
                    let view = host.textView
                    assertNoScrollRange(view)
                    XCTAssertTrue(view.isSelectable)
                    view.selectedRange = NSRange(location: 0, length: (text as NSString).length)
                    XCTAssertEqual(view.selectedRange.length, (text as NSString).length)
                }
            }
        }
    }

    func testTruncatedLabelHasNoScrollRange() {
        let host = Hosted(VStack {
            ResizingTextView(text: .constant("first\nsecond\nthird"), isEditable: false, lineLimit: 2)
            Spacer()
        }.frame(width: 200))
        assertNoScrollRange(host.textView)
    }

    func testOverflowingContentCanStillScroll() {
        for editable in [false, true] {
            let host = Hosted(ResizingTextView(
                text: .constant(String(repeating: "another line\n", count: 20)),
                isEditable: editable,
                isScrollable: true
            ).frame(width: 200, height: 80))
            let view = host.textView
            XCTAssertTrue(view.isScrollEnabled)
            XCTAssertGreaterThan(view.contentSize.height, view.bounds.height)
            view.setContentOffset(CGPoint(x: 0, y: 40), animated: false)
            spin()
            XCTAssertEqual(view.contentOffset.y, 40, accuracy: 0.01)
        }
    }

    private func assertNoScrollRange(_ view: UITextView, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertLessThanOrEqual(view.contentSize.height, view.bounds.height + 0.01,
                                 "text: \(view.text ?? ""), content: \(view.contentSize), bounds: \(view.bounds)", file: file, line: line)
        XCTAssertLessThanOrEqual(view.contentSize.width, view.bounds.width + 0.01, file: file, line: line)
    }
}
#endif
