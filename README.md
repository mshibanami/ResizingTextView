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

TBD

## Apps that uses this package

- [Redirect Web for Safari](https://apps.apple.com/app/id1571283503)
