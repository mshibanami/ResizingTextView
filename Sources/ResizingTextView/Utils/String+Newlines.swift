//  Copyright © 2026 Manabu Nakazawa. All rights reserved.

extension String {
    var containsNewlines: Bool {
        contains(where: Self.isNewline)
    }

    var removingNewlines: String {
        filter { !Self.isNewline($0) }
    }

    private static func isNewline(_ character: Character) -> Bool {
        character == "\n"
    }
}
