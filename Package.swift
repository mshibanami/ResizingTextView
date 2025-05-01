// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ResizingTextView",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "ResizingTextView",
            targets: ["ResizingTextView"])
    ],
    targets: [
        .target(
            name: "ResizingTextView",
            dependencies: []),
        .testTarget(
            name: "ResizingTextViewTests",
            dependencies: ["ResizingTextView"])
    ]
)
