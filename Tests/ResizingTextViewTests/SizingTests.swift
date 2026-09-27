import SwiftUI
import XCTest
@testable import ResizingTextView

private struct SizingHost: View {
    let text: String
    let isEditable: Bool
    let lineLimit: Int?
    let hasGreedyWidth: Bool
    let decorated: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ResizingTextView(text: .constant(text), isEditable: isEditable, lineLimit: lineLimit, hasGreedyWidth: hasGreedyWidth)
                .decorations(decorated && !text.isEmpty ? [
                    TextDecoration(range: text.startIndex..<text.index(after: text.startIndex), attributes: [.font: UXFont.boldSystemFont(ofSize: 40)])
                ] : [])
            Spacer(minLength: 0)
        }
        .frame(width: 200)
    }
}

@MainActor
final class SizingTests: XCTestCase {
    private struct Case {
        var text: String
        var lineLimit: Int? = nil
        var hasGreedyWidth = true
        var decorated = false
    }

    private let cases: [Case] = [
        Case(text: ""), Case(text: "hello"), Case(text: "hello\nworld"), Case(text: "hello\n"), Case(text: "\n\n\n"),
        Case(text: String(repeating: "wrap me ", count: 12)), Case(text: String(repeating: "日本語の文章", count: 8)),
        Case(text: "😀😀😀\n👍"), Case(text: "Hello world", decorated: true),
        Case(text: String(repeating: "wrap me ", count: 12), lineLimit: 2),
        Case(text: String(repeating: "wrap me gjpqy ", count: 12), lineLimit: 2),
        Case(text: "hello", hasGreedyWidth: false), Case(text: "hello\nworld", hasGreedyWidth: false),
        Case(text: String(repeating: "wrap me ", count: 12), hasGreedyWidth: false), Case(text: "", hasGreedyWidth: false),
    ]

    func testViewFitsTheTextViewContent() {
        for isEditable in [true, false] {
            for testCase in cases {
                let h = Hosted(SizingHost(text: testCase.text, isEditable: isEditable, lineLimit: testCase.lineLimit, hasGreedyWidth: testCase.hasGreedyWidth, decorated: testCase.decorated))
                let description = "\(testCase) editable: \(isEditable)"
                let textView = h.textView
#if canImport(AppKit)
                let layoutManager = textView.layoutManager!
                let container = textView.textContainer!
                let viewFrame = textView.enclosingScrollView!.frame
                let verticalInsets = textView.textContainerInset.height * 2
                let allowedExtraSpace: CGFloat = isEditable ? 20 : 0
#else
                let layoutManager = textView.layoutManager
                let container = textView.textContainer
                let viewFrame = textView.frame
                let verticalInsets = textView.textContainerInset.top + textView.textContainerInset.bottom
                let allowedExtraSpace: CGFloat = 0
#endif
                layoutManager.ensureLayout(for: container)
                let neededHeight = layoutManager.usedRect(for: container).height + verticalInsets
                XCTAssertGreaterThanOrEqual(viewFrame.height, neededHeight - 0.01, description)
                XCTAssertLessThanOrEqual(viewFrame.height, neededHeight + allowedExtraSpace + 1.5, description)

                var lastGlyphBottom: CGFloat = 0
                let glyphRange = layoutManager.glyphRange(for: container)
                layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, _, _, lineGlyphRange, _ in
                    let bounds = layoutManager.boundingRect(forGlyphRange: lineGlyphRange, in: container)
                    lastGlyphBottom = max(lastGlyphBottom, bounds.maxY, rect.maxY)
                }
                XCTAssertGreaterThanOrEqual(viewFrame.height, lastGlyphBottom + verticalInsets / 2 - 0.01, description)
#if canImport(AppKit)
                h.close()
#endif
            }
        }
    }
}
