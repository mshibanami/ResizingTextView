# ResizingTextView

This is a SwiftUI resizing text view for iOS and macOS.

## Usage

```swift
// Resizing automatically
ResizingTextView(
    text: $text1,
    isScrollable: true,
    canHaveNewLineCharacters: true)

// Fixed-height, newline characters not allowed
ResizingTextView(
    text: $text2,
    placeholder: "Placeholder",
    isScrollable: true,
    canHaveNewLineCharacters: false)

// Uneditable, selectable, color/font changed
ResizingTextView(
    text: $text3,
    isEditable: false,
    font: .boldSystemFont(ofSize: 16),
    foregroundColor: .magenta)

// Uneditable, selectable, max 2 lines
ResizingTextView(
    text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
    isEditable: false,
    lineLimit: 2)
```

## Demo

### iOS

https://user-images.githubusercontent.com/1333214/184529544-7165dea5-4d51-40b3-a2de-d887aa24a5a4.mov

### macOS

https://user-images.githubusercontent.com/1333214/184529535-ce92376b-ad31-47e5-8a0a-f79f60068ff5.mov

You can find the code in the above demos here: https://github.com/mshibanami/ResizingTextView/blob/main/Sources/ResizingTextView/ResizingTextView.swift

## Apps that use this package

- [Redirect Web for Safari](https://apps.apple.com/app/id1571283503)
