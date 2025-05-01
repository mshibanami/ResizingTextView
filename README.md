# ResizingTextView

This is a SwiftUI text view that wraps the native UITextView (iOS) and NSTextView (macOS), providing:

- Automatic height adjustment to fit its content
- Placeholder support
- Custom text decorations
- Configurable line limits
- Optional scrolling
- Editable and selectable text

> [!NOTE]
> Initially `ResizingTextView` was just for automatic height adjustment, but now it has many features.
> Sorry for the confusing name, but to avoid breaking changes, I decided to keep it as `ResizingTextView`.

> [!NOTE]
> Since iOS 16, SwiftUI has officially supported multiline text in `TextField`.

## Usage

You can check how it works using [the Example project](./Example).
These are sample codes from the project:

```swift
// Self-sizing automatically (Default)
ResizingTextView(text: $text1)

// Fixed height, scrollable, newline characters not allowed
ResizingTextView(
    text: $text2,
    placeholder: "Placeholder",
    isScrollable: true,
    canHaveNewLineCharacters: false
)
.frame(height: 80)

// Uneditable, selectable, color/font changed
ResizingTextView(
    text: $text3,
    isEditable: false
)
.font(.boldSystemFont(ofSize: 16))
.foregroundColor(.magenta)

// Uneditable, selectable, max 2 lines
ResizingTextView(
    text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
    isEditable: false,
    lineLimit: 2
)

// Uneditable, unselectable, max 2 lines
ResizingTextView(
    text: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
    isEditable: false,
    isSelectable: false,
    lineLimit: 2
)

// Selectable, uneditable, non greedy
ResizingTextView(
    text: .constant("Lorem ipsum"),
    isEditable: false,
    hasGreedyWidth: false
)
.background(.yellow)

#if canImport(UIKit)
// No autocapitalization (iOS Only)
ResizingTextView(
    text: $text4,
    placeholder: "Placeholder"
)
.autocapitalizationType(.none)
#endif

// Customized textContentInset
ResizingTextView(
    text: $text5
)
#if canImport(AppKit)
.textContainerInset(CGSize(width: 40, height: 10))
#elseif canImport(UIKit)
.textContainerInset(UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40))
#endif
}

ResizingTextView(text: $text6)
    .decorations({
        let sequenceRegex = try! NSRegularExpression(pattern: "[A-Z]+", options: [])
        let sequences = sequenceRegex.matches(in: text6, options: [], range: .init(location: 0, length: text6.utf16.count))
        let decorations: [TextDecoration] = sequences
            .compactMap { sequence -> TextDecoration? in
                guard let range = Range(sequence.range, in: text6) else {
                    return nil
                }
                return TextDecoration(
                    range: range,
                    attributes: [
                        .font: UXFont.boldSystemFont(ofSize: 16),
                        .foregroundColor: UXColor.systemRed,
                    ]
                )
            }
        return decorations
    }())
```

## Demo

### iOS

https://user-images.githubusercontent.com/1333214/184529544-7165dea5-4d51-40b3-a2de-d887aa24a5a4.mov

### macOS

https://user-images.githubusercontent.com/1333214/184529535-ce92376b-ad31-47e5-8a0a-f79f60068ff5.mov

## Apps that use this package

- [Redirect Web for Safari](https://apps.apple.com/app/id1571283503)
