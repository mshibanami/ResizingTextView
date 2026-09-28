#if !os(tvOS)
import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
private final class BaselineGuides {
    var first: CGFloat?
    var last: CGFloat?
}

@available(macOS 13.0, iOS 16.0, *)
private struct BaselineReader: Layout {
    let guides: BaselineGuides

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

@available(macOS 13.0, iOS 16.0, *)
private struct BaselineHost: View {
    let text: String
    let isEditable: Bool
    let lineLimit: Int?
    let font: UXFont
    let decorations: [TextDecoration]
    let guides: BaselineGuides

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BaselineReader(guides: guides) {
                ResizingTextView(text: .constant(text), isEditable: isEditable, lineLimit: lineLimit)
                    .font(font)
                    .decorations(decorations)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 200)
    }
}

@MainActor
final class BaselineAlignmentTests: XCTestCase {
    private struct Case {
        var text: String
        var isEditable = false
        var lineLimit: Int? = nil
        var font: UXFont = .preferredFont(forTextStyle: .body)
        var decorations: [TextDecoration] = []
    }

    private static let wrappingText = String(repeating: "wrap me ", count: 6)

    private let cases: [Case] = [
        Case(text: "hello"),
        Case(text: String(repeating: "wrap me ", count: 12)),
        Case(text: "hello\nworld"),
        Case(text: String(repeating: "wrap me ", count: 12), lineLimit: 2),
        Case(text: "hello", isEditable: true),
        Case(text: "hello\nworld", isEditable: true),
        Case(text: String(repeating: "title ", count: 8), font: .preferredFont(forTextStyle: .title1)),
        Case(text: "hello world", decorations: [BaselineAlignmentTests.decoration(at: 6, font: .boldSystemFont(ofSize: 26))]),
        Case(text: "hello world", decorations: [BaselineAlignmentTests.decoration(at: 0, font: .systemFont(ofSize: 8))]),
        Case(
            text: BaselineAlignmentTests.wrappingText + "\nend",
            decorations: [BaselineAlignmentTests.decoration(at: BaselineAlignmentTests.wrappingText.utf16.count + 1, font: .boldSystemFont(ofSize: 26))]
        ),
        Case(text: "hello\n" + BaselineAlignmentTests.wrappingText, decorations: [BaselineAlignmentTests.decoration(at: 0, font: .boldSystemFont(ofSize: 26))]),
        Case(
            text: "hello\n" + BaselineAlignmentTests.wrappingText,
            isEditable: true,
            decorations: [BaselineAlignmentTests.decoration(at: 0, font: .boldSystemFont(ofSize: 26))]
        ),
        Case(
            text: String(repeating: "wrap me ", count: 12),
            lineLimit: 2,
            decorations: [BaselineAlignmentTests.decoration(at: 0, font: .boldSystemFont(ofSize: 26))]
        ),
        Case(text: "https://example.com/*", decorations: [TextDecoration(
            range: NSRange(location: 8, length: 5),
            attributes: [.underlineStyle: NSUnderlineStyle.thick.rawValue, .foregroundColor: UXColor.systemRed]
        )]),
        Case(text: String(repeating: "日本語の文章", count: 6)),
        Case(text: "😀 hello"),
    ]

    private static func decoration(at location: Int, font: UXFont) -> TextDecoration {
        TextDecoration(range: NSRange(location: location, length: 1), attributes: [.font: font])
    }

    func testTextBaselinesMatchTheShownText() throws {
        guard #available(macOS 13.0, iOS 16.0, *) else {
            throw XCTSkip("Layout is unavailable")
        }
        for testCase in cases {
            let guides = BaselineGuides()
            let hosted = Hosted(BaselineHost(
                text: testCase.text,
                isEditable: testCase.isEditable,
                lineLimit: testCase.lineLimit,
                font: testCase.font,
                decorations: testCase.decorations,
                guides: guides
            ))
            let (expectedFirst, expectedLast) = Self.baselines(of: hosted.textView)
            let accuracy: CGFloat = 0.5
            XCTAssertEqual(guides.first ?? -1, expectedFirst, accuracy: accuracy, "first baseline: \(testCase)")
            XCTAssertEqual(guides.last ?? -1, expectedLast, accuracy: accuracy, "last baseline: \(testCase)")
#if canImport(AppKit)
            hosted.close()
#endif
        }
    }

    private static func baselines(of textView: some PlatformTextViewForTests) -> (CGFloat, CGFloat) {
        let layoutManager = textView.testLayoutManager
        let glyphRange = layoutManager.glyphRange(for: textView.testTextContainer)
        func baseline(ofGlyphAt index: Int) -> CGFloat {
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: nil)
            return textView.testTextContainerTop + lineRect.minY + layoutManager.location(forGlyphAt: index).y
        }
        return (baseline(ofGlyphAt: glyphRange.location), baseline(ofGlyphAt: glyphRange.upperBound - 1))
    }
}

@MainActor
private protocol PlatformTextViewForTests {
    var testLayoutManager: NSLayoutManager { get }
    var testTextContainer: NSTextContainer { get }
    var testTextContainerTop: CGFloat { get }
}

#if canImport(AppKit)
extension NSTextView: PlatformTextViewForTests {
    fileprivate var testLayoutManager: NSLayoutManager { layoutManager! }
    fileprivate var testTextContainer: NSTextContainer { textContainer! }
    fileprivate var testTextContainerTop: CGFloat { textContainerOrigin.y }
}
#else
extension UITextView: PlatformTextViewForTests {
    fileprivate var testLayoutManager: NSLayoutManager { layoutManager }
    fileprivate var testTextContainer: NSTextContainer { textContainer }
    fileprivate var testTextContainerTop: CGFloat { textContainerInset.top }
}
#endif
#endif
