#if canImport(UIKit) && !os(tvOS)
import SwiftUI
import UIKit
import XCTest
@testable import ResizingTextView

@MainActor
func spin(_ seconds: TimeInterval = 0.3) {
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
}

/// Hosts a SwiftUI view in a real window and returns the backing UITextView.
@MainActor
final class Hosted<V: View> {
    let window: UIWindow
    init(_ root: V) {
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 600))
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        spin()
    }
    var textView: UITextView { find(window)! }
    private func find(_ v: UIView) -> UITextView? {
        if let t = v as? UITextView { return t }
        for s in v.subviews { if let t = find(s) { return t } }
        return nil
    }
    func focus() {
        textView.becomeFirstResponder()
        spin()
    }
    /// Simulates keyboard input (shouldChangeTextIn -> storage edit -> textViewDidChange).
    func type(_ s: String) {
        textView.insertText(s)
        spin()
    }
}
#endif
