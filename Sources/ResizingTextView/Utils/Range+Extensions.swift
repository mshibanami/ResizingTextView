//  Copyright © 2025 Manabu Nakazawa. All rights reserved.

extension Range where Bound == String.Index {
    func isValid(in string: String) -> Bool {
        lowerBound >= string.startIndex
            && upperBound <= string.endIndex
    }
}
