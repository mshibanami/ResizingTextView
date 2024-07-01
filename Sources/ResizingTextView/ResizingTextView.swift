//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

import Combine
import Foundation
import SwiftUI

public struct ResizingTextView: View, Equatable {
    @Binding var text: String
    var placeholder: String?
    var isEditable: Bool
    var isScrollable: Bool
    var isSelectable: Bool
    var lineLimit: Int?
    var font: UXFont = .preferredFont(forTextStyle: .body)
    var canHaveNewLineCharacters: Bool
    var foregroundColor: UXColor = defaultLabelColor
    var hasGreedyWidth: Bool
#if os(macOS)
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

#elseif os(iOS)
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var textContainerInset: UIEdgeInsets?
#endif
    
    @Environment(\.layoutDirection) private var layoutDirection
    
#if os(macOS)
    public static var defaultLabelColor: NSColor {
        NSColor.labelColor
    }

#elseif os(iOS)
    public static var defaultLabelColor: UIColor {
        UIColor.label
    }
#endif

    @State private var isFocused = false
    
    public init(
        text: Binding<String>,
        placeholder: String? = nil,
        isEditable: Bool = true,
        isScrollable: Bool = false,
        isSelectable: Bool = true,
        lineLimit: Int? = nil,
        canHaveNewLineCharacters: Bool = true,
        hasGreedyWidth: Bool = true
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.isScrollable = isScrollable
        self.isSelectable = isSelectable
        self.lineLimit = lineLimit
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
        self.hasGreedyWidth = hasGreedyWidth
    }
    
    public var body: some View {
#if os(macOS)
        invisibleSizingText
            .overlay(visibleTextViewWrapper)
#elseif os(iOS)
        if hasGreedyWidth {
            visibleTextViewWrapper
        } else {
            invisibleSizingText
                .overlay(visibleTextViewWrapper)
        }
#endif
    }

    @ViewBuilder var invisibleSizingText: some View {
#if os(macOS)
        // https://developer.apple.com/documentation/uikit/nstextcontainer/1444527-linefragmentpadding
        let textViewLineFragmentPadding: CGFloat = 5
#endif
        Text(text.isEmpty ? " " : text)
            .lineLimit(lineLimit ?? .max)
#if os(macOS)
            .padding(.bottom, (isEditable && canHaveNewLineCharacters) ? 20 : 0)
            .padding(EdgeInsets(
                top: effectiveTextContainerInset.height,
                leading: effectiveTextContainerInset.width + textViewLineFragmentPadding,
                bottom: effectiveTextContainerInset.height,
                trailing: effectiveTextContainerInset.width + textViewLineFragmentPadding
            ))
#elseif os(iOS)
            .padding(.top, isEditable ? 8 : 2)
            .padding(.bottom, isEditable ? 8 : 3)
#endif
            .foregroundColor(Color.pink)
            .font(Font(font))
            .frame(
                maxWidth: hasGreedyWidth ? .infinity : nil,
                maxHeight: (isEditable && isScrollable) ? .infinity : nil,
                alignment: .topLeading
            )
            .opacity(0)
            .layoutPriority(1)
    }
    
    private var visibleTextViewWrapper: some View {
#if os(macOS)
        TextView(
            $text,
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
            .opacity(isFocused && isEditable ? 1 : 0).scaleEffect(isFocused && isEditable ? 1 : 1.03))
#elseif os(iOS)
        ZStack(alignment: .topLeading) {
            /// HACK: In iOS 17, the last sentence of a non-editable text may not be drawn if the textContainerInset is `.zero`. To avoid it, we add this 0.00...1 value to the
            let defaultInsetsForiOS17Bug = UIEdgeInsets(top: 0.00000001, left: 0.00000001, bottom: 0.00000001, right: 0.00000001)
            let defaultVerticalPadding: CGFloat = isEditable ? 8 : 0
            let defaultInsets = UIEdgeInsets(
                top: defaultInsetsForiOS17Bug.top + defaultVerticalPadding,
                left: defaultInsetsForiOS17Bug.left,
                bottom: defaultInsetsForiOS17Bug.bottom + defaultVerticalPadding,
                right: defaultInsetsForiOS17Bug.right
            )
            let effectiveTextContainerInset = textContainerInset ?? defaultInsets
            
            TextView(
                $text,
                isEditable: isEditable,
                isScrollable: isScrollable,
                isSelectable: isSelectable,
                lineLimit: lineLimit ?? .max,
                font: font,
                canHaveNewLineCharacters: canHaveNewLineCharacters,
                foregroundColor: Color(foregroundColor),
                autocapitalizationType: autocapitalizationType,
                textContainerInset: effectiveTextContainerInset
            )
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
    
    public static func == (lhs: ResizingTextView, rhs: ResizingTextView) -> Bool {
        var result = lhs.text == rhs.text
            && lhs.placeholder == rhs.placeholder
            && lhs.isEditable == rhs.isEditable
            && lhs.isScrollable == rhs.isScrollable
            && lhs.isSelectable == rhs.isSelectable
            && lhs.lineLimit == rhs.lineLimit
            && lhs.font == rhs.font
            && lhs.canHaveNewLineCharacters == rhs.canHaveNewLineCharacters
            && lhs.foregroundColor == rhs.foregroundColor
            && lhs.hasGreedyWidth == rhs.hasGreedyWidth
            && lhs.isFocused == rhs.isFocused
#if os(macOS)
        result = result && lhs.focusesNextKeyViewByTabKey == rhs.focusesNextKeyViewByTabKey
#elseif os(iOS)
        result = result && lhs.autocapitalizationType == rhs.autocapitalizationType
#endif
        return result
    }
}

public extension ResizingTextView {
#if os(macOS)
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

#elseif os(iOS)
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
#endif
}
