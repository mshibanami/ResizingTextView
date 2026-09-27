//  Copyright © 2025 Manabu Nakazawa. All rights reserved.

import Foundation

public struct TextDecoration: Equatable {
    /// The range in UTF-16 offsets of the text shown by the view.
    /// Decorations whose range exceeds the text are ignored.
    public var range: NSRange
    public var attributes: [NSAttributedString.Key: Any]

    public init(range: NSRange, attributes: [NSAttributedString.Key: Any]) {
        self.range = range
        self.attributes = attributes
    }

    /// `range` must be made from `string`, which should be the text shown by the view.
    /// A `String.Index` does not know which string it belongs to, so the string has to be given explicitly.
    public init(range: Range<String.Index>, in string: String, attributes: [NSAttributedString.Key: Any]) {
        self.init(range: NSRange(range, in: string), attributes: attributes)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.range == rhs.range &&
            NSDictionary(dictionary: lhs.attributes).isEqual(to: rhs.attributes)
    }
}
