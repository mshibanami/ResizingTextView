//
//  ContentView.swift
//  Example
//
//  Created by Manabu Nakazawa on 27/8/2022.
//

import SwiftUI
import ResizingTextView

struct ContentView: View {
    @State var text1 = "hello"
    @State var text2 = ""
    @State var text3 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Resizing automatically")
                    .bold()
                ResizingTextView(
                    text: $text1,
                    isScrollable: true,
                    canHaveNewLineCharacters: true)
                .padding(.bottom, 20)
                
                Text("Fixed-height, newline characters not allowed")
                    .bold()
                ResizingTextView(
                    text: $text2,
                    placeholder: "Placeholder",
                    isScrollable: true,
                    canHaveNewLineCharacters: false)
                .frame(height: 50)
                .padding(.bottom, 20)
                
                Text("Uneditable, selectable, color/font changed")
                    .bold()
                ResizingTextView(
                    text: $text3,
                    isEditable: false)
                .font(.boldSystemFont(ofSize: 16))
                .foregroundColor(.magenta)
                .padding(.bottom, 20)
                
                Text("Uneditable, selectable, max 2 lines")
                    .bold()
                ResizingTextView(
                    text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
                    isEditable: false,
                    lineLimit: 2)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
