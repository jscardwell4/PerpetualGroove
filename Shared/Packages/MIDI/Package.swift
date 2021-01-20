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
    .package(path: "../SoundFont"),
    .package(path: "../Common"),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0"))
  ],
  targets: [
    .target(
      name: "MIDI",
      dependencies: ["MoonDev", "SoundFont", "Common"],
      resources: [
        .process("Resources/Media.xcassets"),
        .copy("Resources/morse_code_a.mid"),
        .copy("Resources/Ping Puh Ping.mid"),
        .copy("Resources/test_morse_code_a.mid"),
        .copy("Resources/test.mid")
      ]
    ),
    .testTarget(
      name: "MIDITests",
      dependencies: ["MIDI", "Nimble", "MoonDev"]
    )
  ]
)
