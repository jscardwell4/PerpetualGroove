// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Sequencer",
  platforms: [.macOS(.v10_15), .iOS(.v13)],
  products: [
    .library(
      name: "Sequencer",
      targets: ["Sequencer"]
    )
  ],
  dependencies: [
    .package(path: "/Users/Moondeer/Projects/MoonDev"),
    .package(path: "../Common"),
    .package(path: "../MIDI"),
    .package(path: "../SoundFont"),
    .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0")
  ],
  targets: [
    .target(
      name: "Sequencer",
      dependencies: ["MoonDev", "Common", "MIDI", "SoundFont"],
      resources: [
        .process("Media.xcassets")
      ]
    ),
    .testTarget(
      name: "SequencerTests",
      dependencies: ["Sequencer", "MoonDev", "Nimble", "Common", "MIDI", "SoundFont"]
    )
  ]
)
