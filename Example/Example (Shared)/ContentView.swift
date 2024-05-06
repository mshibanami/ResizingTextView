//
//  ContentView.swift
//  Example
//
//  Created by Manabu Nakazawa on 27/8/2022.
//

import ResizingTextView
import SwiftUI

struct ContentView: View {
    @State var text1 = ""
    @State var text2 = ""
    @State var text3 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    @State var text4 = ""
    @State var text5 = "I have greater horizontal padding than the others."
    
    var body: some View {
        ScrollView {
            VStack {
                ExampleSection("Self-sizing automatically (Default)") {
                    ResizingTextView(text: $text1)
                }
                
                ExampleSection("Fixed height, scrollable, newline characters not allowed") {
                    ResizingTextView(
                        text: $text2,
                        placeholder: "Placeholder",
                        isScrollable: true,
                        canHaveNewLineCharacters: false
                    )
                    .frame(height: 80)
                }
                
                ExampleSection("Uneditable, selectable, color/font changed") {
                    ResizingTextView(
                        text: $text3,
                        isEditable: false
                    )
                    .font(.boldSystemFont(ofSize: 16))
                    .foregroundColor(.magenta)
                }
                
                ExampleSection("Uneditable, selectable, max 2 lines") {
                    ResizingTextView(
                        text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
                        isEditable: false,
                        lineLimit: 2
                    )
                }
                
                ExampleSection("Uneditable, unselectable, max 2 lines") {
                    ResizingTextView(
                        text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
                        isEditable: false,
                        isSelectable: false,
                        lineLimit: 2
                    )
                }
                
                ExampleSection("Selectable, uneditable, non greedy") {
                    ResizingTextView(
                        text: .constant("Lorem ipsum"),
                        isEditable: false,
                        hasGreedyWidth: false
                    )
                    .background(.yellow)
                }
#if os(iOS)
                ExampleSection("No autocapitalization") {
                    ResizingTextView(
                        text: $text4,
                        placeholder: "Placeholder"
                    )
                    .autocapitalizationType(.none)
                }
#endif
                ExampleSection("Customized textContentInset") {
                    ResizingTextView(
                        text: $text5,
                        placeholder: ""
                    )
#if os(macOS)
                    .textContainerInset(CGSize(width: 40, height: 10))
#elseif os(iOS)
                    .textContainerInset(UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40))
#endif
                }
            }
            .scenePadding()
        }
    }
}

private struct ExampleSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content
    
    init(_ title: String, content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
            content()
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
