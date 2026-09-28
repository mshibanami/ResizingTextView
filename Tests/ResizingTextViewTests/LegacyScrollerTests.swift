#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
private final class ScrollerGuides {
    var first: CGFloat?
    var last: CGFloat?
}

@available(macOS 13.0, *)
private struct ScrollerGuideReader: Layout {
    let guides: ScrollerGuides

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

@MainActor
final class LegacyScrollerTests: XCTestCase {
    private var originalImplementation: IMP?

    override func setUp() async throws {
        let method = class_getClassMethod(NSScroller.self, #selector(getter: NSScroller.preferredScrollerStyle))!
        let legacy: @convention(block) (AnyObject) -> NSScroller.Style = { _ in .legacy }
        originalImplementation = method_setImplementation(method, imp_implementationWithBlock(legacy))
        XCTAssertEqual(NSScroller.preferredScrollerStyle, .legacy)
    }

    override func tearDown() async throws {
        let method = class_getClassMethod(NSScroller.self, #selector(getter: NSScroller.preferredScrollerStyle))!
        if let originalImplementation {
            method_setImplementation(method, originalImplementation)
        }
    }

    func testFittingTextTakesTheWholeWidth() {
        for (editable, text) in [(false, String(repeating: "wrap me please ", count: 30)), (true, "hello")] {
            let hosted = Hosted(VStack(alignment: .leading, spacing: 0) {
                ResizingTextView(text: .constant(text), isEditable: editable, isScrollable: true)
                    .frame(height: editable ? 100 : nil)
                Spacer(minLength: 0)
            }.frame(width: 200))
            let textView = hosted.textView
            let scrollView = textView.enclosingScrollView!
            XCTAssertEqual(textView.frame.width, scrollView.frame.width, "editable: \(editable)")
            XCTAssertLessThanOrEqual(textView.frame.height, scrollView.frame.height + 0.5, "editable: \(editable)")
            hosted.close()
        }
    }

    func testTextBaselinesOfOverflowingTextMatchTheShownText() throws {
        guard #available(macOS 13.0, *) else {
            throw XCTSkip("Layout is unavailable")
        }
        let text = String(repeating: "wrap me please ", count: 30)
        for location in stride(from: 0, to: 60, by: 3) {
            let guides = ScrollerGuides()
            let hosted = Hosted(VStack(alignment: .leading, spacing: 0) {
                ScrollerGuideReader(guides: guides) {
                    ResizingTextView(text: .constant(text), isScrollable: true)
                        .decorations([TextDecoration(
                            range: NSRange(location: location, length: 1),
                            attributes: [.font: NSFont.boldSystemFont(ofSize: 26)]
                        )])
                }
                .frame(height: 100)
                Spacer(minLength: 0)
            }.frame(width: 200))
            let textView = hosted.textView
            let layoutManager = textView.layoutManager!
            var lines: [(baseline: CGFloat, maxY: CGFloat)] = []
            layoutManager.enumerateLineFragments(forGlyphRange: layoutManager.glyphRange(for: textView.textContainer!)) { rect, usedRect, _, glyphRange, _ in
                lines.append((textView.textContainerOrigin.y + rect.minY + layoutManager.location(forGlyphAt: glyphRange.location).y, usedRect.maxY))
            }
            let textHeight = textView.enclosingScrollView!.frame.height - textView.textContainerInset.height * 2 - 20
            let lastShownLine = lines.last { $0.maxY <= textHeight + 0.5 } ?? lines[0]
            XCTAssertEqual(guides.first ?? -1, lines[0].baseline, accuracy: 0.5, "location: \(location)")
            XCTAssertEqual(guides.last ?? -1, lastShownLine.baseline, accuracy: 0.5, "location: \(location)")
            hosted.close()
        }
    }

    func testOverflowingTextShowsTheScroller() {
        let hosted = Hosted(VStack(alignment: .leading, spacing: 0) {
            ResizingTextView(text: .constant(String(repeating: "another line\n", count: 20)), isScrollable: true)
                .frame(height: 100)
            Spacer(minLength: 0)
        }.frame(width: 200))
        let textView = hosted.textView
        let scrollView = textView.enclosingScrollView!
        XCTAssertGreaterThan(textView.frame.height, scrollView.frame.height)
        XCTAssertFalse(scrollView.verticalScroller?.isHidden ?? true)
        XCTAssertLessThan(textView.frame.width, scrollView.frame.width)
        hosted.close()
    }
}
#endif
