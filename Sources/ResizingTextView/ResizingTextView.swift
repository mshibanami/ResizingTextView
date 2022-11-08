//  Copyright © 2022 Manabu Nakazawa. All rights reserved.

import Foundation
import SwiftUI
import Combine

public struct ResizingTextView: View, Equatable {
    @Binding var text: String
    var placeholder: String?
    var isEditable: Bool
    var isScrollable: Bool
    var lineLimit: Int?
    var font: UXFont = .preferredFont(forTextStyle: .body)
    var canHaveNewLineCharacters: Bool
    var foregroundColor: UXColor = defaultLabelColor
    var hasGreedyWidth: Bool
#if os(macOS)
    var focusesNextKeyViewByTabKey: Bool = true
    var onInsertNewline: (() -> Bool)?
#endif
    
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
        lineLimit: Int? = nil,
        canHaveNewLineCharacters: Bool = true,
        hasGreedyWidth: Bool = true
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.isScrollable = isScrollable
        self.lineLimit = lineLimit
        self.canHaveNewLineCharacters = canHaveNewLineCharacters
        self.hasGreedyWidth = hasGreedyWidth
    }
    
    public var body: some View {
        invisibleSizingText
            .overlay(visibleTextViewWrapper)
    }
    
    var invisibleSizingText: some View {
        Text(text.isEmpty ? " " : text)
            .lineLimit(lineLimit ?? .max)
#if os(macOS)
            .padding(.vertical, isEditable ? 8 : 0)
            .padding(.horizontal, isEditable ? 9 : 0)
            .padding(.bottom, (isEditable && canHaveNewLineCharacters) ? 20 : 0)
#elseif os(iOS)
            .padding(.vertical, 8)
            .padding(.horizontal, 5)
#endif
            .opacity(0)
            .font(Font(font))
            .frame(
                maxWidth: hasGreedyWidth ? .infinity : nil,
                maxHeight: (isEditable && isScrollable) ? .infinity : nil,
                alignment: .leading)
            .layoutPriority(1)
    }
    
    var visibleTextViewWrapper: some View {
#if os(macOS)
        TextView(
            $text,
            placeholder: placeholder,
            isEditable: isEditable,
            isScrollable: isScrollable,
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
            onInsertNewline: onInsertNewline
        )
        .padding(.vertical, isEditable ? 8 : 0)
        .padding(.horizontal, isEditable ? 9 : 0)
        .background(isEditable ? Color(UXColor.controlBackgroundColor) : .clear)
        .roundedFilledBorder(
            isEditable ? Color(UXColor.separatorColor) : .clear,
            width: isEditable ? 1 : 0,
            cornerRadius: isEditable ? 10 : 0)
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color.accentColor.opacity(0.5), lineWidth: 4)
            .opacity(isFocused && isEditable ? 1 : 0).scaleEffect(isFocused && isEditable ? 1 : 1.03))
#elseif os(iOS)
        ZStack(alignment: .topLeading) {
            TextView(
                $text,
                isEditable: isEditable,
                isScrollable: isScrollable,
                lineLimit: lineLimit ?? .max,
                font: font,
                canHaveNewLineCharacters: canHaveNewLineCharacters,
                foregroundColor: Color(foregroundColor))
            
            if text.isEmpty, let placeholder = placeholder {
                Text(placeholder)
                    .font(Font(font))
                    .foregroundColor(Color(foregroundColor.withAlphaComponent(0.2)))
                    .padding(.leading, 5)
                    .padding(.top, 9)
                    .allowsHitTesting(false)
            }
        }
#endif
    }
    
    public static func == (lhs: ResizingTextView, rhs: ResizingTextView) -> Bool {
        lhs.text == rhs.text
    }
}

public extension ResizingTextView {
#if os(macOS)
    func focusesNextKeyViewByTabKey(_ focuses: Bool) -> ResizingTextView {
        var newSelf = self
        newSelf.focusesNextKeyViewByTabKey = focuses
        return newSelf
    }
    
    func onInsertNewline(_ perform: (() -> Bool)?) -> ResizingTextView {
        var newSelf = self
        newSelf.onInsertNewline = perform
        return newSelf
    }
    
    func foregroundColor(_ color: NSColor) -> ResizingTextView {
        var newSelf = self
        newSelf.foregroundColor = color
        return newSelf
    }
    
    func font(_ font: NSFont) -> ResizingTextView {
        var newSelf = self
        newSelf.font = font
        return newSelf
    }
#elseif os(iOS)
    func foregroundColor(_ color: UIColor) -> ResizingTextView {
        var newSelf = self
        newSelf.foregroundColor = color
        return newSelf
    }
    
    func font(_ font: UIFont) -> ResizingTextView {
        var newSelf = self
        newSelf.font = font
        return newSelf
    }
#endif
}
