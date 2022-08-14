//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

#if os(macOS)
import AppKit
typealias UXColor = NSColor
typealias UXFont = NSFont
#elseif os(iOS)
import UIKit
typealias UXColor = UIColor
typealias UXFont = UIFont
#endif
