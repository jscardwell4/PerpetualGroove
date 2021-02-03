// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Sequencing",
  platforms: [.macOS(.v10_15), .iOS(.v13)],
  products: [
    .library(
      name: "Sequencing",
      targets: ["Sequencing"]
    )
  ],
  dependencies: [
    .package(path: "$(Projects)/MoonDev"),
    .package(path: "../Common"),
    .package(path: "../MIDI"),
    .package(path: "../SoundFont"),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0"))
  ],
  targets: [
    .target(
      name: "Sequencing",
      dependencies: ["MoonDev", "Common", "MIDI", "SoundFont"],
      exclude: [
        "UI/ViewControllers",
        "UI/Views/MixerLayout.swift",
        "UI/Views/Cells",
        "UI/Controls",
        "UI/Containers"
      ],
      resources: [
        .process("Resources/Media.xcassets"),
        .process("Resources/Woodblock.wav"),
        .copy("Resources/Fonts")
      ]
    ),
    .testTarget(
      name: "SequencingTests",
      dependencies: ["MoonDev", "Sequencing", "Nimble", "Common", "MIDI", "SoundFont"]
    )
  ]
)
