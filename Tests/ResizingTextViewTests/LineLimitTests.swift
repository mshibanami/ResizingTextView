import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
final class LineLimitTests: XCTestCase {
    func testLineLimitedTextWithNewlinesIsLaidOut() {
        for isEditable in [false, true] {
            let h = Hosted(
                VStack(spacing: 0) {
                    ResizingTextView(text: .constant("a\nb\nc"), isEditable: isEditable, lineLimit: 2)
                    Spacer(minLength: 0)
                }
                .frame(width: 200)
            )
            let textView = h.textView
#if canImport(AppKit)
            let layoutManager = textView.layoutManager!
            let container = textView.textContainer!
#else
            let layoutManager = textView.layoutManager
            let container = textView.textContainer
#endif
            layoutManager.ensureLayout(for: container)
            var lineCount = 0
            layoutManager.enumerateLineFragments(forGlyphRange: layoutManager.glyphRange(for: container)) { rect, _, _, _, _ in
                if rect.height > 0 {
                    lineCount += 1
                }
            }
            XCTAssertEqual(lineCount, 2, "editable: \(isEditable)")
#if canImport(AppKit)
            h.close()
#endif
        }
    }
}
