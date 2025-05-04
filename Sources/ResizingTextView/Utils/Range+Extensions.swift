//  Copyright © 2025 Manabu Nakazawa. All rights reserved.

extension Range where Bound == String.Index {
    func isValid(in string: String) -> Bool {
        guard let lower16 = lowerBound.samePosition(in: string.utf16),
              let upper16 = upperBound.samePosition(in: string.utf16) else {
            return false
        }
        return lower16 >= string.utf16.startIndex
            && upper16 <= string.utf16.endIndex
    }
}
