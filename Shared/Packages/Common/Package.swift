// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Common",
  platforms: [.macOS(.v10_14), .iOS(.v13)],
  products: [
    .library(
      name: "Common",
      targets: ["Common"]
    )
  ],
  dependencies: [
    .package(path: "/Users/Moondeer/Projects/MoonDev")
  ],
  targets: [
    .target(
      name: "Common",
      dependencies: ["MoonDev"],
      resources: [
        .process("Colors.xcassets"),
        .copy("Resources/Fonts")
      ]
    ),
    .testTarget(
      name: "CommonTests",
      dependencies: ["Common"]
    )
  ]
)
