#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

@available(macOS 13.0, *)
private struct MarkedTextHost: View {
    @ObservedObject var model: TestModel
    let guides: BaselineGuides

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BaselineReader(guides: guides) {
                ResizingTextView(text: $model.text)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 200)
    }
}

@MainActor
final class MarkedTextLayoutTests: XCTestCase {
    func testViewFollowsMarkedText() throws {
        guard #available(macOS 13.0, *) else {
            throw XCTSkip("Layout is unavailable")
        }
        let model = TestModel()
        model.text = "abc"
        let guides = BaselineGuides()
        let hosted = Hosted(MarkedTextHost(model: model, guides: guides))
        hosted.focus()
        let markedText = String(repeating: "にほんご", count: 10)
        hosted.textView.setMarkedText(
            markedText,
            selectedRange: NSRange(location: (markedText as NSString).length, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
        spin()
        XCTAssertTrue(hosted.textView.hasMarkedText())

        let textView = hosted.textView
        let usedRect = textView.layoutManager!.usedRect(for: textView.textContainer!)
        let textBottom = textView.textContainerOrigin.y + usedRect.maxY
        XCTAssertGreaterThanOrEqual(textView.enclosingScrollView!.frame.height, textBottom)
        let (expectedFirst, expectedLast) = BaselineAlignmentTests.baselines(of: textView)
        XCTAssertEqual(guides.first ?? -1, expectedFirst, accuracy: 0.5)
        XCTAssertEqual(guides.last ?? -1, expectedLast, accuracy: 0.5)
        hosted.close()
    }
}
#endif
