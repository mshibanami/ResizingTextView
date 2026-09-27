//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

import Foundation

extension NSRange {
    func clamped(toLength maxLength: Int) -> NSRange {
        let location = Swift.min(location, maxLength)
        return NSRange(location: location, length: Swift.min(length, maxLength - location))
    }
}
