//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

import SwiftUI

extension View {
    func roundedFilledBorder<S>(_ content: S, width: CGFloat, cornerRadius: CGFloat) -> some View where S: ShapeStyle {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
            .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }

    @ViewBuilder
    func isHidden(_ hidden: Bool, removes: Bool = false) -> some View {
        if !(removes && hidden) {
            self.opacity(hidden ? 0 : 1)
        }
    }
}
