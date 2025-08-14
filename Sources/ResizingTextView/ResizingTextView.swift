//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

import Combine
import Foundation
import SwiftUI

@MainActor public struct ResizingTextView: View, Equatable {
#if canImport(AppKit)
    @Environment(\.controlActiveState) var controlActiveState
#endif
    
    @Binding var text: String
    var placeholder: String?
#if !os(tvOS)
    var isEditable: Bool
#endif
    var isScrollable: Bool
    var isSelectable: Bool
    var lineLimit: Int?
    var font: UXFont = .preferredFont(forTextStyle: .body)
    var canHaveNewLineCharacters: Bool
    var foregroundColor: UXColor = defaultLabelColor
    var hasGreedyWidth: Bool
    var decorations: [TextDecoration] = []
#if canImport(AppKit)
    var focusesNextKeyViewByTabKey: Bool = true
    var onInsertNewline: (() -> Bool)?
    var textContainerInset: CGSize?
    var effectiveTextContainerInset: CGSize {
        textContainerInset ?? {
            var inset = CGSize(width: -5, height: 0)
            inset.width += (isEditable ? 9 : 0)
            inset.height += (isEditable ? 8 : 0)
            return inset
        }()
    }
#elseif canImport(UIKit)
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var textContainerInset: UIEdgeInsets?
    var keyboardType: UIKeyboardType = .default
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
        self.decorations = decorations
        self.placeholder = placeholder
        self.isScrollable = isScrollable
        self.isSelectable = isSelectable
        self.lineLimit = lineLimit
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
        self.hasGreedyWidth = hasGreedyWidth
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
        self.decorations = decorations
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.isScrollable = isScrollable
        self.isSelectable = isSelectable
        self.lineLimit = lineLimit
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
        self.hasGreedyWidth = hasGreedyWidth
    }
#endif
    
    public var body: some View {
#if canImport(AppKit)
        invisibleSizingText
            .overlay(visibleTextViewWrapper)
#elseif canImport(UIKit)
        if hasGreedyWidth {
            visibleTextViewWrapper
        } else {
            invisibleSizingText
                .overlay(visibleTextViewWrapper)
        }
#endif
    }

    @ViewBuilder var invisibleSizingText: some View {
#if canImport(AppKit)
        // https://developer.apple.com/documentation/uikit/nstextcontainer/1444527-linefragmentpadding
        let textViewLineFragmentPadding: CGFloat = 5
#endif
        Text(makeAttributedString())
            .lineLimit(lineLimit ?? .max)
#if canImport(AppKit)
            .padding(.bottom, (isEditable && canHaveNewLineCharacters) ? 20 : 0)
            .padding(EdgeInsets(
                top: effectiveTextContainerInset.height,
                leading: effectiveTextContainerInset.width + textViewLineFragmentPadding,
                bottom: effectiveTextContainerInset.height,
                trailing: effectiveTextContainerInset.width + textViewLineFragmentPadding
            ))
#elseif canImport(UIKit) && !os(tvOS)
            .padding(.top, isEditable ? 8 : 2)
            .padding(.bottom, isEditable ? 8 : 3)
#endif
#if os(tvOS)
            .frame(
                maxWidth: hasGreedyWidth ? .infinity : nil,
                maxHeight: isScrollable ? .infinity : nil,
                alignment: .topLeading
            )
#else
            .frame(
                maxWidth: hasGreedyWidth ? .infinity : nil,
                maxHeight: (isEditable && isScrollable) ? .infinity : nil,
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
            decorations: decorations,
            placeholder: placeholder,
            isEditable: isEditable,
            isScrollable: isScrollable,
            isSelectable: isSelectable,
            lineLimit: lineLimit ?? .max,
            font: font,
            canHaveNewLineCharacters: canHaveNewLineCharacters,
            focusesNextKeyViewByTabKey: focusesNextKeyViewByTabKey,
            foregroundColor: Color(foregroundColor),
            onFocusChanged: { isFocused in
                if isFocused {
                    DispatchQueue.main.async {
                        withAnimation(Animation.easeInOut(duration: 0.2)) {
                            self.isFocused = isFocused
                        }
                    }
                } else {
                    self.isFocused = false
                }
            },
            onInsertNewline: onInsertNewline,
            textContainerInset: effectiveTextContainerInset
        )
        .background(isEditable ? Color(UXColor.controlBackgroundColor) : .clear)
        .roundedFilledBorder(
            isEditable ? Color(UXColor.separatorColor) : .clear,
            width: isEditable ? 1 : 0,
            cornerRadius: isEditable ? 10 : 0
        )
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color.accentColor.opacity(0.5), lineWidth: 4)
            .opacity(isFocused && isEditable ? 1 : 0).scaleEffect(isFocused && isEditable ? 1 : 1.03)
            .opacity(controlActiveState == .inactive ? 0 : 1)
        )
#elseif canImport(UIKit)
        ZStack(alignment: .topLeading) {
            /// HACK: In iOS 17, the last sentence of a non-editable text may not be drawn if the textContainerInset is `.zero`. To avoid it, we add this 0.00...1 value to the
            let defaultInsetsForiOS17Bug = UIEdgeInsets(top: 0.00000001, left: 0.00000001, bottom: 0.00000001, right: 0.00000001)
#if !os(tvOS)
            let defaultVerticalPadding: CGFloat = isEditable ? 8 : 0
#else
            let defaultVerticalPadding: CGFloat = 0
#endif
            let defaultInsets = UIEdgeInsets(
                top: defaultInsetsForiOS17Bug.top + defaultVerticalPadding,
                left: defaultInsetsForiOS17Bug.left,
                bottom: defaultInsetsForiOS17Bug.bottom + defaultVerticalPadding,
                right: defaultInsetsForiOS17Bug.right
            )
            let effectiveTextContainerInset = textContainerInset ?? defaultInsets
            
#if os(tvOS)
            let parameters = TextView.Parameters(
                text: $text,
                decorations: decorations,
                isScrollable: isScrollable,
                isSelectable: isSelectable,
                lineLimit: lineLimit ?? .max,
                font: font,
                canHaveNewLineCharacters: canHaveNewLineCharacters,
                foregroundColor: Color(foregroundColor),
                autocapitalizationType: autocapitalizationType,
                textContainerInset: effectiveTextContainerInset,
                keyboardType: keyboardType
            )
#else
            let parameters = TextView.Parameters(
                text: $text,
                decorations: decorations,
                isEditable: isEditable,
                isScrollable: isScrollable,
                isSelectable: isSelectable,
                lineLimit: lineLimit ?? .max,
                font: font,
                canHaveNewLineCharacters: canHaveNewLineCharacters,
                foregroundColor: Color(foregroundColor),
                autocapitalizationType: autocapitalizationType,
                textContainerInset: effectiveTextContainerInset,
                keyboardType: keyboardType
            )
#endif
            TextView(parameters: parameters)
            
            if let placeholder {
                let isLTR = layoutDirection == .leftToRight
                Text(placeholder)
                    .font(Font(font))
                    .lineLimit(1)
                    .foregroundColor(Color(foregroundColor.withAlphaComponent(0.2)))
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
                .font: font,
                .foregroundColor: foregroundColor,
            ]
        )
        for decoration in decorations where decoration.range.isValid(in: text) {
            let nsRange = NSRange(decoration.range, in: text)
            base.addAttributes(decoration.attributes, range: nsRange)
        }
        return AttributedString(base)
    }
    
    public static func == (lhs: ResizingTextView, rhs: ResizingTextView) -> Bool {
        var result = lhs.text == rhs.text
            && lhs.decorations == rhs.decorations
            && lhs.placeholder == rhs.placeholder
            && lhs.isScrollable == rhs.isScrollable
            && lhs.isSelectable == rhs.isSelectable
            && lhs.lineLimit == rhs.lineLimit
            && lhs.font == rhs.font
            && lhs.canHaveNewLineCharacters == rhs.canHaveNewLineCharacters
            && lhs.foregroundColor == rhs.foregroundColor
            && lhs.hasGreedyWidth == rhs.hasGreedyWidth
            && lhs.isFocused == rhs.isFocused
#if !os(tvOS)
        result = result && lhs.isEditable == rhs.isEditable
#endif
#if canImport(AppKit)
        result = result && lhs.focusesNextKeyViewByTabKey == rhs.focusesNextKeyViewByTabKey
#elseif canImport(UIKit)
        result = result && lhs.autocapitalizationType == rhs.autocapitalizationType
#endif
        return result
    }
}

public extension ResizingTextView {
    func decorations(_ value: [TextDecoration]) -> Self {
        var newSelf = self
        newSelf.decorations = value
        return newSelf
    }
    
#if canImport(AppKit)
    func focusesNextKeyViewByTabKey(_ focuses: Bool) -> Self {
        var newSelf = self
        newSelf.focusesNextKeyViewByTabKey = focuses
        return newSelf
    }
    
    func onInsertNewline(_ perform: (() -> Bool)?) -> Self {
        var newSelf = self
        newSelf.onInsertNewline = perform
        return newSelf
    }
    
    func foregroundColor(_ color: NSColor) -> Self {
        var newSelf = self
        newSelf.foregroundColor = color
        return newSelf
    }
    
    func font(_ font: NSFont) -> Self {
        var newSelf = self
        newSelf.font = font
        return newSelf
    }
    
    func textContainerInset(_ inset: CGSize?) -> Self {
        var newSelf = self
        newSelf.textContainerInset = inset
        return newSelf
    }

#elseif canImport(UIKit)
    func foregroundColor(_ color: UIColor) -> Self {
        var newSelf = self
        newSelf.foregroundColor = color
        return newSelf
    }
    
    func font(_ font: UIFont) -> Self {
        var newSelf = self
        newSelf.font = font
        return newSelf
    }
    
    func autocapitalizationType(_ autocapitalizationType: UITextAutocapitalizationType) -> Self {
        var newSelf = self
        newSelf.autocapitalizationType = autocapitalizationType
        return newSelf
    }
    
    func textContainerInset(_ inset: UIEdgeInsets?) -> Self {
        var newSelf = self
        newSelf.textContainerInset = inset
        return newSelf
    }
    
    func keyboardType(_ keyboardType: UIKeyboardType) -> Self {
        var newSelf = self
        newSelf.keyboardType = keyboardType
        return newSelf
    }
#endif
}
