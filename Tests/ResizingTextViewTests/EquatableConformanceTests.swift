import SwiftUI
import XCTest
@testable import ResizingTextView

@MainActor
final class EquatableConformanceTests: XCTestCase {
    func testEveryStoredPropertyIsComparedOrExplicitlyExcluded() {
        let labels = Set(Mirror(reflecting: ResizingTextView(text: .constant(""))).children.compactMap(\.label))
        var expected: Set<String> = ["_text", "configuration", "__isFocused", "_layoutDirection"]
#if canImport(AppKit)
        expected.formUnion(["onInsertNewline", "_controlActiveState", "__measurer"])
#endif
        XCTAssertEqual(labels, expected, "Add new properties to ResizingTextView.Configuration so that == compares them")
    }

    func testConfigurationChangesAreNotEqual() {
        let base = ResizingTextView(text: .constant("a"))
        XCTAssertEqual(base, ResizingTextView(text: .constant("a")))
        XCTAssertNotEqual(base, ResizingTextView(text: .constant("b")))
        XCTAssertNotEqual(base, ResizingTextView(text: .constant("a"), placeholder: "p"))
        XCTAssertNotEqual(base, base.decorations([TextDecoration(range: NSRange(location: 0, length: 1), attributes: [.kern: 1])]))
#if canImport(AppKit)
        XCTAssertNotEqual(base, base.textContainerInset(CGSize(width: 1, height: 1)))
        XCTAssertNotEqual(base, base.focusesNextKeyViewByTabKey(false))
#elseif canImport(UIKit)
        XCTAssertNotEqual(base, base.textContainerInset(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)))
        XCTAssertNotEqual(base, base.keyboardType(.numberPad))
        XCTAssertNotEqual(base, base.autocapitalizationType(.none))
#endif
    }
}
