// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SoundFont",
  platforms: [.macOS(.v10_15), .iOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "SoundFont",
      targets: ["SoundFont"]
    )
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(path: "/Users/Moondeer/Projects/MoonDev"),
    .package(path: "../Common"),
    .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "SoundFont",
      dependencies: ["MoonDev", "Common"],
      resources: [
        .process("Media.xcassets"),
        .process("Resources/sf2"),
        .process("Resources/json")
      ]
    ),
    .target(
      name: "sf2info",
      dependencies: ["MoonDev", "SoundFont"]
    ),
    .testTarget(
      name: "SoundFontTests",
      dependencies: ["SoundFont", "Nimble"]
    )
  ]
)
