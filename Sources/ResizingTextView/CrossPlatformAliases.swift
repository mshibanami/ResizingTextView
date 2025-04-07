//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

#if canImport(AppKit)
import AppKit
typealias UXColor = NSColor
typealias UXFont = NSFont
#elseif canImport(UIKit)
import UIKit
typealias UXColor = UIColor
typealias UXFont = UIFont
#endif
