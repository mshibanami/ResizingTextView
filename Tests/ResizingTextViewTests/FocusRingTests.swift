#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

private struct FocusHost: View {
    @State var text = "abc"
    var body: some View {
        ResizingTextView(text: $text)
            .padding(20)
            .environment(\.controlActiveState, .key)
    }
}

@MainActor
final class FocusRingTests: XCTestCase {
    private func render(_ view: NSView) -> NSBitmapImageRep {
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep
    }

    private func differingPixels(_ a: NSBitmapImageRep, _ b: NSBitmapImageRep) -> Int {
        var count = 0
        for x in 0..<a.pixelsWide {
            for y in 0..<a.pixelsHigh where a.colorAt(x: x, y: y) != b.colorAt(x: x, y: y) {
                count += 1
            }
        }
        return count
    }

    func testFocusRingIsHiddenAfterFocusAndBlurInSameRunLoopIteration() {
        let h = Hosted(FocusHost())
        let unfocused = render(h.hosting)

        h.focus()
        spin(0.6)
        let focused = render(h.hosting)
        h.blur()
        spin(0.6)
        XCTAssertGreaterThan(differingPixels(unfocused, focused), 0)
        XCTAssertEqual(differingPixels(unfocused, render(h.hosting)), 0)

        XCTAssertTrue(h.window.makeFirstResponder(h.textView))
        h.window.makeFirstResponder(nil)
        spin(0.6)
        XCTAssertEqual(differingPixels(unfocused, render(h.hosting)), 0)
    }
}
#endif
