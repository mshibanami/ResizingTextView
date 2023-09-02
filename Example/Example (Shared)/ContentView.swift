//
//  ContentView.swift
//  Example
//
//  Created by Manabu Nakazawa on 27/8/2022.
//

import SwiftUI
import ResizingTextView

struct ContentView: View {
    @State var text1 = ""
    @State var text2 = ""
    @State var text3 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    @State var text4 = ""
    
    var body: some View {
        List {
            let textBackgroundColor = Color.black.opacity(0.1)

            Section("Resizing automatically (Default)") {
                ResizingTextView(text: $text1)
                    .background(textBackgroundColor)
            }

            Section("Fixed height, scrollable, newline characters not allowed") {
                ResizingTextView(
                    text: $text2,
                    placeholder: "Placeholder",
                    isScrollable: true,
                    canHaveNewLineCharacters: false)
                .frame(height: 80)
                .background(textBackgroundColor)
            }

            Section("Uneditable, selectable, color/font changed") {
                ResizingTextView(
                    text: $text3,
                    isEditable: false)
                .font(.boldSystemFont(ofSize: 16))
                .foregroundColor(.magenta)
                .background(textBackgroundColor)
            }

            Section("Uneditable, selectable, max 2 lines") {
                ResizingTextView(
                    text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
                    isEditable: false,
                    lineLimit: 2)
                .background(textBackgroundColor)
            }

            Section("Uneditable, unselectable, max 2 lines") {
                ResizingTextView(
                    text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
                    isEditable: false,
                    isSelectable: false,
                    lineLimit: 2)
                .background(textBackgroundColor)
            }

            Section("Selectable, uneditable, non-greedy short label") {
                ResizingTextView(
                    text: .constant("Lorem ipsum"),
                    isEditable: false,
                    hasGreedyWidth: false)
                .background(textBackgroundColor)
            }
            
            Section("No autocapitalization") {
                ResizingTextView(
                    text: $text4,
                    placeholder: "Placeholder")
                .autocapitalizationType(.none)
                .background(textBackgroundColor)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
