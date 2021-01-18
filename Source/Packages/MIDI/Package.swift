// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MIDI",
  platforms: [.macOS(.v10_15), .iOS(.v13)],
  products: [
    .library(
      name: "MIDI",
      targets: ["MIDI"]
    )
  ],
  dependencies: [
    .package(path: "/Users/Moondeer/Projects/MoonDev"),
    .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0")
  ],
  targets: [
    .target(
      name: "MIDI",
      dependencies: ["MoonDev"]
    ),
    .testTarget(
      name: "MIDITests",
      dependencies: ["MIDI", "Nimble", "MoonDev"]
    )
  ]
)
