#if canImport(UIKit)
import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
final class RepeatedSizingTests: XCTestCase {
    func testEveryInstanceGetsTheSameHeight() {
        var heights: [CGFloat] = []
        for _ in 0..<30 {
            let text = String(repeating: "日本語の文章", count: 8)
            let h = Hosted(VStack(spacing: 0) { ResizingTextView(text: .constant(text), isEditable: false); Spacer(minLength: 0) }.frame(width: 200))
            heights.append(h.textView.frame.height)
        }
        XCTAssertEqual(Set(heights).count, 1, "\(heights)")
    }
}
#endif
