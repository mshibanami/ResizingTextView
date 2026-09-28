#if canImport(AppKit)
import AppKit
import XCTest
@testable import ResizingTextView

@MainActor
final class TextBaselineMeasurerTests: XCTestCase {
    func testEditsGiveTheSameLinesAsANewMeasurer() {
        let font = NSFont.preferredFont(forTextStyle: .body)
        let decorations = [TextDecoration(range: NSRange(location: 2, length: 2), attributes: [.font: NSFont.boldSystemFont(ofSize: 26)])]
        let texts = [
            "",
            "hello world",
            "hello 😀 world",
            "hello 😃 world",
            "hello 😃😃 world",
            "😃hello 😃 world😀",
            "日本語の文章 " + String(repeating: "wrap me ", count: 10),
            "日本語の文章 " + String(repeating: "wrap me ", count: 10) + "\n",
            "x",
            "",
        ]
        let measurer = TextBaselineMeasurer()
        for text in texts {
            for width in [120, 300] as [CGFloat] {
                let content = TextBaselineMeasurer.Content(text: text, font: font, decorations: decorations, lineLimit: .max)
                measurer.content = content
                let fresh = TextBaselineMeasurer()
                fresh.content = content
                XCTAssertEqual(measurer.lines(width: width), fresh.lines(width: width), "\(text) in \(width)")
            }
        }
    }
}
#endif
