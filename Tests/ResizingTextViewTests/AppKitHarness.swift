#if canImport(AppKit)
import AppKit
import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
func spin(_ seconds: TimeInterval = 0.3) {
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
}

@MainActor
func findTextView(in view: NSView) -> NSTextView? {
    if let tv = view as? NSTextView { return tv }
    for sub in view.subviews {
        if let found = findTextView(in: sub) { return found }
    }
    return nil
}

@MainActor
final class Hosted<V: View> {
    let window: NSWindow
    let hosting: NSHostingView<V>
    init(_ root: V) {
        _ = NSApplication.shared
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        hosting = NSHostingView(rootView: root)
        hosting.frame = window.contentLayoutRect
        window.contentView = hosting
        window.orderFront(nil)
        spin()
    }
    var textView: NSTextView { findTextView(in: hosting)! }
    var text: String { textView.string }
    func focus() {
        XCTAssertTrue(window.makeFirstResponder(textView))
        spin()
    }
    func blur() {
        window.makeFirstResponder(nil)
        spin()
    }
    func type(_ s: String) {
        textView.insertText(s, replacementRange: NSRange(location: NSNotFound, length: 0))
        spin()
    }
    func close() { window.orderOut(nil) }
}

@MainActor
func makeDecoratableTextView() -> NSTextView {
    let storage = DecoratableTextStorage()
    let lm = NSLayoutManager()
    let tc = NSTextContainer()
    storage.addLayoutManager(lm)
    lm.addTextContainer(tc)
    let tv = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100), textContainer: tc)
    tv.isRichText = true
    return tv
}
#endif
