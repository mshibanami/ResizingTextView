#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
private final class MarkedTextGuides {
    var first: CGFloat?
    var last: CGFloat?
}

@available(macOS 13.0, *)
private struct MarkedTextReader: Layout {
    let guides: MarkedTextGuides

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let dimensions = subviews[0].dimensions(in: proposal)
        let first = dimensions[.firstTextBaseline]
        let last = dimensions[.lastTextBaseline]
        MainActor.assumeIsolated {
            guides.first = first
            guides.last = last
        }
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

@available(macOS 13.0, *)
private struct MarkedTextHost: View {
    @ObservedObject var model: TestModel
    let guides: MarkedTextGuides

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MarkedTextReader(guides: guides) {
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
        let guides = MarkedTextGuides()
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
        let layoutManager = textView.layoutManager!
        let glyphRange = layoutManager.glyphRange(for: textView.textContainer!)
        func baseline(ofGlyphAt index: Int) -> CGFloat {
            textView.textContainerOrigin.y
                + layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: nil).minY
                + layoutManager.location(forGlyphAt: index).y
        }
        let textBottom = textView.textContainerOrigin.y + layoutManager.usedRect(for: textView.textContainer!).maxY
        XCTAssertGreaterThanOrEqual(textView.enclosingScrollView!.frame.height, textBottom)
        XCTAssertEqual(guides.first ?? -1, baseline(ofGlyphAt: glyphRange.location), accuracy: 0.5)
        XCTAssertEqual(guides.last ?? -1, baseline(ofGlyphAt: glyphRange.upperBound - 1), accuracy: 0.5)
        hosted.close()
    }
}
#endif
