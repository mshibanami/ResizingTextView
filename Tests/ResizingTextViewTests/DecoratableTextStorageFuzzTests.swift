import XCTest
@testable import ResizingTextView

private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

@MainActor
final class DecoratableTextStorageFuzzTests: XCTestCase {
    private let font = UXFont.systemFont(ofSize: 12)
    private let pieces = ["a", "B", "CD", "日本", "語", "😀", "e\u{301}", " ", "XYZ", "\n"]

    private func contentDecorations(_ string: String) -> [TextDecoration] {
        let regex = try! NSRegularExpression(pattern: "[A-Z]+|日本")
        return regex.matches(in: string, range: NSRange(location: 0, length: string.utf16.count)).map { match in
            TextDecoration(range: match.range, attributes: [.kern: match.range.length])
        }
    }

    private func positionalDecorations(_ string: String) -> [TextDecoration] {
        stride(from: 1, to: string.count, by: 4).map { offset in
            let start = string.index(string.startIndex, offsetBy: offset)
            return TextDecoration(range: start..<string.index(after: start), in: string, attributes: [.kern: offset])
        }
    }

    private func assertMatchesFullApplication(_ storage: DecoratableTextStorage, _ map: DecoratableTextStorage.AttributionMap, step: Int, file: StaticString = #filePath, line: UInt = #line) {
        let expected = NSMutableAttributedString(string: storage.string, attributes: [.font: map.defaultFont!])
        for decoration in map.decorations where decoration.range.isValid(inLength: storage.length) {
            expected.addAttributes(decoration.attributes, range: decoration.range)
        }
        for location in 0..<expected.length {
            let actualKern = storage.attribute(.kern, at: location, effectiveRange: nil) as? Int
            let expectedKern = expected.attribute(.kern, at: location, effectiveRange: nil) as? Int
            if actualKern != expectedKern {
                XCTFail("step \(step): kern at \(location) is \(String(describing: actualKern)), expected \(String(describing: expectedKern)) in \(storage.string.debugDescription)", file: file, line: line)
                return
            }
        }
    }

    func testIncrementalApplicationMatchesFullApplication() {
        for (name, decorations) in [("content", contentDecorations), ("positional", positionalDecorations)] {
            var random = SplitMix64(state: 42)
            let storage = DecoratableTextStorage()
            storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Hello World 日本語 ABC")
            for step in 0..<400 {
                let length = storage.length
                let location = Int.random(in: 0...length, using: &random)
                let deleteLength = Int.random(in: 0...min(3, length - location), using: &random)
                let insertion = Int.random(in: 0..<3, using: &random) == 0 ? "" : pieces.randomElement(using: &random)!
                var range = NSRange(location: location, length: deleteLength)
                range = (storage.string as NSString).rangeOfComposedCharacterSequences(for: range)
                storage.replaceCharacters(in: range, with: insertion)
                let map = DecoratableTextStorage.AttributionMap(defaultFont: font, defaultForegroundColor: .black, decorations: decorations(storage.string))
                storage.attributionMap = map
                assertMatchesFullApplication(storage, map, step: step)
                if testRun?.failureCount ?? 0 > 0 {
                    XCTFail("failed with \(name) decorations")
                    return
                }
            }
        }
    }
}
