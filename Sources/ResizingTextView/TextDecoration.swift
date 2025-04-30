//  Copyright © 2025 Manabu Nakazawa. All rights reserved.

import Foundation

public struct TextDecoration: Equatable {
    public var range: Range<String.Index>
    public var attributes: [NSAttributedString.Key: Any]
    
    public init(range: Range<String.Index>, attributes: [NSAttributedString.Key: Any]) {
        self.range = range
        self.attributes = attributes
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.range == rhs.range &&
            NSDictionary(dictionary: lhs.attributes).isEqual(to: rhs.attributes)
    }
}
