//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

import Combine
import Foundation
import SwiftUI

/// `ResizingTextView` is `Equatable` so that SwiftUI can skip redundant updates. Since a binding is
/// compared by its value, give the view a different identity (e.g. `.id(item.id)`) when the binding
/// starts pointing to other storage. Closures such as `onInsertNewline` are not compared either, so a new
/// closure takes effect only when another property changes as well.
@MainActor public struct ResizingTextView: View, @MainActor Equatable {
    /// Every property that affects the appearance or behavior. Keeping them in this `Equatable`
    /// struct makes `==` compare new properties without further changes.
    struct Configuration: Equatable {
        var placeholder: String?
#if !os(tvOS)
        var isEditable: Bool
#endif
        var isScrollable: Bool
        var isSelectable: Bool
        var lineLimit: Int?
        var font: UXFont = .preferredFont(forTextStyle: .body)
        var canHaveNewLineCharacters: Bool
#if canImport(AppKit)
        var foregroundColor: UXColor = .labelColor
#elseif canImport(UIKit)
        var foregroundColor: UXColor = .label
#endif
        var hasGreedyWidth: Bool
        var decorations: [TextDecoration]
#if canImport(AppKit)
        var focusesNextKeyViewByTabKey = true
        var textContainerInset: CGSize?
#elseif canImport(UIKit)
        var autocapitalizationType: UITextAutocapitalizationType = .sentences
        var textContainerInset: UIEdgeInsets?
        var keyboardType: UIKeyboardType = .default
#endif
    }

#if canImport(AppKit)
    @Environment(\.controlActiveState) private var controlActiveState
#endif
    
    @Binding var text: String
    var configuration: Configuration
#if canImport(AppKit)
    var onInsertNewline: (() -> Bool)?
    var effectiveTextContainerInset: CGSize {
        configuration.textContainerInset ?? {
            var inset = CGSize(width: -5, height: 0)
            inset.width += (configuration.isEditable ? 9 : 0)
            inset.height += (configuration.isEditable ? 8 : 0)
            return inset
        }()
    }
#endif
    
    @Environment(\.layoutDirection) private var layoutDirection
    
#if canImport(AppKit)
    public static var defaultLabelColor: NSColor {
        NSColor.labelColor
    }

#elseif canImport(UIKit)
    public static var defaultLabelColor: UIColor {
        UIColor.label
    }
#endif

    @State private var isFocused = false

#if os(tvOS)
    public init(
        text: Binding<String>,
        decorations: [TextDecoration] = [],
        placeholder: String? = nil,
        isScrollable: Bool = false,
        isSelectable: Bool = true,
        lineLimit: Int? = nil,
        canHaveNewLineCharacters: Bool = true,
        hasGreedyWidth: Bool = true
    ) {
        self._text = text
        self.configuration = Configuration(
            placeholder: placeholder,
            isScrollable: isScrollable,
            isSelectable: isSelectable,
            lineLimit: lineLimit,
            canHaveNewLineCharacters: canHaveNewLineCharacters,
            hasGreedyWidth: hasGreedyWidth,
            decorations: decorations
        )
    }
#else
    public init(
        text: Binding<String>,
        decorations: [TextDecoration] = [],
        placeholder: String? = nil,
        isEditable: Bool = true,
        isScrollable: Bool = false,
        isSelectable: Bool = true,
        lineLimit: Int? = nil,
        canHaveNewLineCharacters: Bool = true,
        hasGreedyWidth: Bool = true
    ) {
        self._text = text
        self.configuration = Configuration(
            placeholder: placeholder,
            isEditable: isEditable,
            isScrollable: isScrollable,
            isSelectable: isSelectable,
            lineLimit: lineLimit,
            canHaveNewLineCharacters: canHaveNewLineCharacters,
            hasGreedyWidth: hasGreedyWidth,
            decorations: decorations
        )
    }
#endif
    
    public var body: some View {
#if canImport(AppKit)
        if #available(macOS 13.0, *) {
            visibleTextViewWrapper
        } else {
            invisibleSizingText
                .overlay(visibleTextViewWrapper)
        }
#elseif canImport(UIKit)
        if configuration.hasGreedyWidth {
            visibleTextViewWrapper
        } else if #available(iOS 16.0, tvOS 16.0, *) {
            visibleTextViewWrapper
        } else {
            invisibleSizingText
                .overlay(visibleTextViewWrapper)
        }
#endif
    }

    /// Sizes the view before `sizeThatFits(_:nsView:context:)`/`sizeThatFits(_:uiView:context:)` is available.
    @ViewBuilder var invisibleSizingText: some View {
#if canImport(AppKit)
        // https://developer.apple.com/documentation/uikit/nstextcontainer/1444527-linefragmentpadding
        let textViewLineFragmentPadding: CGFloat = 5
#endif
        Text(makeAttributedString())
            .lineLimit(configuration.lineLimit ?? .max)
#if canImport(AppKit)
            .padding(.bottom, (configuration.isEditable && configuration.canHaveNewLineCharacters) ? 20 : 0)
            .padding(EdgeInsets(
                top: effectiveTextContainerInset.height,
                leading: effectiveTextContainerInset.width + textViewLineFragmentPadding,
                bottom: effectiveTextContainerInset.height,
                trailing: effectiveTextContainerInset.width + textViewLineFragmentPadding
            ))
#elseif canImport(UIKit) && !os(tvOS)
            .padding(.top, configuration.isEditable ? 8 : 2)
            .padding(.bottom, configuration.isEditable ? 8 : 3)
#endif
#if os(tvOS)
            .frame(
                maxWidth: configuration.hasGreedyWidth ? .infinity : nil,
                maxHeight: configuration.isScrollable ? .infinity : nil,
                alignment: .topLeading
            )
#else
            .frame(
                maxWidth: configuration.hasGreedyWidth ? .infinity : nil,
                maxHeight: (configuration.isEditable && configuration.isScrollable) ? .infinity : nil,
                alignment: .topLeading
            )
#endif
            .opacity(0)
            .layoutPriority(1)
    }
    
    private var visibleTextViewWrapper: some View {
#if canImport(AppKit)
        TextView(
            $text,
            decorations: configuration.decorations,
            placeholder: configuration.placeholder,
            isEditable: configuration.isEditable,
            isScrollable: configuration.isScrollable,
            isSelectable: configuration.isSelectable,
            lineLimit: configuration.lineLimit ?? .max,
            font: configuration.font,
            canHaveNewLineCharacters: configuration.canHaveNewLineCharacters,
            focusesNextKeyViewByTabKey: configuration.focusesNextKeyViewByTabKey,
            foregroundColor: Color(configuration.foregroundColor),
            onFocusChanged: { isFocused in
                DispatchQueue.main.async {
                    if isFocused {
                        withAnimation(Animation.easeInOut(duration: 0.2)) {
                            self.isFocused = true
                        }
                    } else {
                        self.isFocused = false
                    }
                }
            },
            onInsertNewline: onInsertNewline,
            textContainerInset: effectiveTextContainerInset,
            hasGreedyWidth: configuration.hasGreedyWidth
        )
        .background(configuration.isEditable ? Color(UXColor.controlBackgroundColor) : .clear)
        .roundedFilledBorder(
            configuration.isEditable ? Color(UXColor.separatorColor) : .clear,
            width: configuration.isEditable ? 1 : 0,
            cornerRadius: configuration.isEditable ? 10 : 0
        )
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color.accentColor.opacity(0.5), lineWidth: 4)
            .opacity(isFocused && configuration.isEditable ? 1 : 0).scaleEffect(isFocused && configuration.isEditable ? 1 : 1.03)
            .opacity(controlActiveState == .inactive ? 0 : 1)
        )
#elseif canImport(UIKit)
        ZStack(alignment: .topLeading) {
            /// HACK: In iOS 17, the last sentence of a non-editable text may not be drawn if the textContainerInset is `.zero`. To avoid it, we add this 0.00...1 value to the
            let defaultInsetsForiOS17Bug = UIEdgeInsets(top: 0.00000001, left: 0.00000001, bottom: 0.00000001, right: 0.00000001)
#if !os(tvOS)
            let defaultVerticalPadding: CGFloat = configuration.isEditable ? 8 : 0
#else
            let defaultVerticalPadding: CGFloat = 0
#endif
            let defaultInsets = UIEdgeInsets(
                top: defaultInsetsForiOS17Bug.top + defaultVerticalPadding,
                left: defaultInsetsForiOS17Bug.left,
                bottom: defaultInsetsForiOS17Bug.bottom + defaultVerticalPadding,
                right: defaultInsetsForiOS17Bug.right
            )
            let effectiveTextContainerInset = configuration.textContainerInset ?? defaultInsets
            
#if os(tvOS)
            let parameters = TextView.Parameters(
                text: $text,
                decorations: configuration.decorations,
                isScrollable: configuration.isScrollable,
                isSelectable: configuration.isSelectable,
                lineLimit: configuration.lineLimit ?? .max,
                font: configuration.font,
                canHaveNewLineCharacters: configuration.canHaveNewLineCharacters,
                foregroundColor: Color(configuration.foregroundColor),
                autocapitalizationType: configuration.autocapitalizationType,
                textContainerInset: effectiveTextContainerInset,
                keyboardType: configuration.keyboardType,
                hasGreedyWidth: configuration.hasGreedyWidth
            )
#else
            let parameters = TextView.Parameters(
                text: $text,
                decorations: configuration.decorations,
                isEditable: configuration.isEditable,
                isScrollable: configuration.isScrollable,
                isSelectable: configuration.isSelectable,
                lineLimit: configuration.lineLimit ?? .max,
                font: configuration.font,
                canHaveNewLineCharacters: configuration.canHaveNewLineCharacters,
                foregroundColor: Color(configuration.foregroundColor),
                autocapitalizationType: configuration.autocapitalizationType,
                textContainerInset: effectiveTextContainerInset,
                keyboardType: configuration.keyboardType,
                hasGreedyWidth: configuration.hasGreedyWidth
            )
#endif
            TextView(parameters: parameters)
            
            if let placeholder = configuration.placeholder {
                let isLTR = layoutDirection == .leftToRight
                Text(placeholder)
                    .font(Font(configuration.font))
                    .lineLimit(1)
                    .foregroundColor(Color(configuration.foregroundColor.withAlphaComponent(0.2)))
                    .padding(.top, effectiveTextContainerInset.top)
                    .padding(isLTR ? .leading : .trailing, effectiveTextContainerInset.left)
                    .padding(.bottom, effectiveTextContainerInset.bottom)
                    .padding(isLTR ? .trailing : .leading, effectiveTextContainerInset.right)
                    .allowsHitTesting(false)
                    .opacity(text.isEmpty ? 1 : 0)
            }
        }
#endif
    }
    
    func makeAttributedString() -> AttributedString {
        let base = NSMutableAttributedString(
            string: text.isEmpty ? " " : text,
            attributes: [
                .font: configuration.font,
                .foregroundColor: configuration.foregroundColor,
            ]
        )
        for decoration in configuration.decorations where decoration.range.isValid(in: text) {
            let nsRange = NSRange(decoration.range, in: text)
            base.addAttributes(decoration.attributes, range: nsRange)
        }
        return AttributedString(base)
    }
    
    public static func == (lhs: ResizingTextView, rhs: ResizingTextView) -> Bool {
        lhs.text == rhs.text && lhs.configuration == rhs.configuration
    }
}

public extension ResizingTextView {
    func decorations(_ value: [TextDecoration]) -> Self {
        var newSelf = self
        newSelf.configuration.decorations = value
        return newSelf
    }
    
#if canImport(AppKit)
    func focusesNextKeyViewByTabKey(_ focuses: Bool) -> Self {
        var newSelf = self
        newSelf.configuration.focusesNextKeyViewByTabKey = focuses
        return newSelf
    }
    
    func onInsertNewline(_ perform: (() -> Bool)?) -> Self {
        var newSelf = self
        newSelf.onInsertNewline = perform
        return newSelf
    }
    
    func foregroundColor(_ color: NSColor) -> Self {
        var newSelf = self
        newSelf.configuration.foregroundColor = color
        return newSelf
    }
    
    func font(_ font: NSFont) -> Self {
        var newSelf = self
        newSelf.configuration.font = font
        return newSelf
    }
    
    func textContainerInset(_ inset: CGSize?) -> Self {
        var newSelf = self
        newSelf.configuration.textContainerInset = inset
        return newSelf
    }

#elseif canImport(UIKit)
    func foregroundColor(_ color: UIColor) -> Self {
        var newSelf = self
        newSelf.configuration.foregroundColor = color
        return newSelf
    }
    
    func font(_ font: UIFont) -> Self {
        var newSelf = self
        newSelf.configuration.font = font
        return newSelf
    }
    
    func autocapitalizationType(_ autocapitalizationType: UITextAutocapitalizationType) -> Self {
        var newSelf = self
        newSelf.configuration.autocapitalizationType = autocapitalizationType
        return newSelf
    }
    
    func textContainerInset(_ inset: UIEdgeInsets?) -> Self {
        var newSelf = self
        newSelf.configuration.textContainerInset = inset
        return newSelf
    }
    
    func keyboardType(_ keyboardType: UIKeyboardType) -> Self {
        var newSelf = self
        newSelf.configuration.keyboardType = keyboardType
        return newSelf
    }
#endif
}
