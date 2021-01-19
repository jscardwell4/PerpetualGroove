// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SoundFont",
  platforms: [.macOS(.v10_15), .iOS(.v13)],
  products: [
    .library(
      name: "SoundFont",
      targets: ["SoundFont"]
    )
  ],
  dependencies: [
    .package(path: "/Users/Moondeer/Projects/MoonDev"),
    .package(path: "../Common"),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0"))
  ],
  targets: [
    .target(
      name: "SoundFont",
      dependencies: ["MoonDev", "Common"],
      resources: [
        .process("Media.xcassets"),
        .process("Resources/sf2"),
        .process("Resources/json")
      ]
    ),
    .testTarget(
      name: "SoundFontTests",
      dependencies: ["SoundFont", "Nimble"]
    )
  ]
)
