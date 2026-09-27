//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

extension String {
    var containsNewlines: Bool {
        contains(where: \.isNewline)
    }

    var removingNewlines: String {
        filter { !$0.isNewline }
    }
}
