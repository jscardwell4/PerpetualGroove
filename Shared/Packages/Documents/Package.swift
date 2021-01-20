// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Documents",
  platforms: [.macOS(.v10_15), .iOS(.v13)],
  products: [
    .library(
      name: "Documents",
      targets: ["Documents"]
    )
  ],
  dependencies: [
    .package(path: "/Users/Moondeer/Projects/MoonDev"),
    .package(path: "../Common"),
    .package(path: "../MIDI"),
    .package(path: "../SoundFont"),
    .package(path: "../Sequencer"),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0"))
  ],
  targets: [
    .target(
      name: "Documents",
      dependencies: ["MoonDev", "Common", "MIDI", "SoundFont", "Sequencer"],
      exclude: [
        "Document/Document.swift",
        "Document/DocumentItem.swift",
        "Document/LocalDocumentItem.swift",
        "Document/NSMetadataItem.swift",
        "DocumentManager.swift"
      ],
      resources: [
        .process("Resources/Media.xcassets")
      ]
    ),
    .testTarget(
      name: "DocumentsTests",
      dependencies: ["Documents", "Nimble"]
    )
  ]
)
